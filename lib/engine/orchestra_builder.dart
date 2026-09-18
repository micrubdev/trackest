import '../model/instrument.dart';
import '../model/pattern.dart';

/// Generates the Csound orchestra for a set of instrument slots.
///
/// Layout: tables 1..3 hold the pattern (note / instrument / volume, row-major),
/// `instr 1` is the always-on sequencer, `instr 10+id` is instrument slot `id`.
/// Voices are addressed as `10 + id + (ch+1)/10` so a channel can release its
/// own note without touching the same instrument on other channels.
class OrchestraBuilder {
  static const int noteTable = 1;
  static const int instTable = 2;
  static const int volTable = 3;
  static const int sineTable = 100;
  static const int sampleTable = 101;
  static const int firstInstr = 10;

  static String channelFor(int id, String param) => 'i$id.$param';

  static String build(List<Instrument> instruments, {String samplePath = ''}) {
    final b = StringBuffer();
    final size = Pattern.rows * Pattern.channels;
    b.writeln('''
sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

giNote ftgen $noteTable, 0, $size, -7, -1, $size, -1
giInst ftgen $instTable, 0, $size, -7, -1, $size, -1
giVol ftgen $volTable, 0, $size, -7, -1, $size, -1
giSine ftgen $sineTable, 0, 4096, 10, 1
''');
    if (samplePath.isNotEmpty) {
      b.writeln('giSample ftgen $sampleTable, 0, 0, 1, "$samplePath", 0, 0, 0');
    }
    b.writeln(_sequencer);
    for (final inst in instruments) {
      b.writeln(_instrument(inst, hasSample: samplePath.isNotEmpty));
    }
    b.writeln('schedule 1, 0, -1');
    return b.toString();
  }

  static const _sequencer =
      '''
instr 1
  kBpm chnget "bpm"
  kLpb chnget "lpb"
  kPlay chnget "playing"
  kLen chnget "length"
  if kLen < 1 then
    kLen = ${Pattern.rows}
  endif
  kRow init 0
  kPhase init 0
  kWasPlaying init 0
  kCur[] init ${Pattern.channels}
  kRate = kBpm / 60 * kLpb
  if kPlay == 0 && kWasPlaying == 1 then
    kCh = 0
    while kCh < ${Pattern.channels} do
      if kCur[kCh] > 0 then
        turnoff2 kCur[kCh], 0, 1
        kCur[kCh] = 0
      endif
      kCh += 1
    od
    kRow = 0
    chnset kRow, "row"
  endif
  if kPlay == 1 then
    if kWasPlaying == 0 then
      kRow = 0
      kPhase = 1
    else
      kPhase += kRate / kr
    endif
    if kPhase >= 1 then
      kPhase -= 1
      if kRow >= kLen then
        kRow = 0
      endif
      kCh = 0
      while kCh < ${Pattern.channels} do
        kIdx = kRow * ${Pattern.channels} + kCh
        kNote tab kIdx, $noteTable
        kInst tab kIdx, $instTable
        kVol tab kIdx, $volTable
        if kNote >= 0 || kNote == -2 then
          if kCur[kCh] > 0 then
            turnoff2 kCur[kCh], 0, 1
            kCur[kCh] = 0
          endif
        endif
        if kNote >= 0 then
          kInstUse = (kInst >= 0 ? kInst : 0)
          kVolUse = (kVol >= 0 ? kVol / 64 : 0.8)
          kNum = $firstInstr + kInstUse + (kCh + 1) / 10
          event "i", kNum, 0, -1, kNote, kVolUse
          kCur[kCh] = kNum
        endif
        kCh += 1
      od
      chnset kRow, "row"
      kRow = (kRow + 1) % kLen
    endif
  endif
  kWasPlaying = kPlay
endin
''';

  static String _instrument(Instrument inst, {required bool hasSample}) {
    final id = inst.id;
    final n = firstInstr + id;
    String ch(String p) => 'chnget "${channelFor(id, p)}"';
    switch (inst.template) {
      case Template.subtractive:
        return '''
instr $n
  iFreq = cpsmidinn(p4)
  iVel = p5
  iA ${ch('attack')}
  iD ${ch('decay')}
  iS ${ch('sustain')}
  iR ${ch('release')}
  kCut ${ch('cutoff')}
  kRes ${ch('res')}
  kWave ${ch('wave')}
  aEnv madsr iA, iD, iS, iR
  aSaw vco2 1, iFreq, 0
  aSq vco2 1, iFreq, 10
  aOsc = aSaw * (1 - kWave) + aSq * kWave
  aOut moogladder aOsc, kCut, kRes
  outs aOut * aEnv * iVel * 0.3, aOut * aEnv * iVel * 0.3
endin''';
      case Template.fm:
        return '''
instr $n
  iFreq = cpsmidinn(p4)
  iVel = p5
  iA ${ch('attack')}
  iD ${ch('decay')}
  iS ${ch('sustain')}
  iR ${ch('release')}
  kRatio ${ch('ratio')}
  kIndex ${ch('index')}
  aEnv madsr iA, iD, iS, iR
  aOut foscili 1, iFreq, 1, kRatio, kIndex, giSine
  outs aOut * aEnv * iVel * 0.3, aOut * aEnv * iVel * 0.3
endin''';
      case Template.sampler:
        final source = hasSample
            ? 'aOut loscil3 1, iFreq * kPitch, giSample, cpsmidinn(48)'
            : 'aOut oscili 1, iFreq * kPitch, giSine';
        return '''
instr $n
  iFreq = cpsmidinn(p4)
  iVel = p5
  iA ${ch('attack')}
  iR ${ch('release')}
  kPitch ${ch('pitch')}
  aEnv madsr iA, 0.001, 1, iR
  $source
  outs aOut * aEnv * iVel * 0.5, aOut * aEnv * iVel * 0.5
endin''';
      case Template.noise:
        return '''
instr $n
  iVel = p5
  iDecay ${ch('decay')}
  kCut ${ch('cutoff')}
  aN noise 1, 0
  aOut butlp aN, kCut
  aEnv expsegr 1, iDecay, 0.001, 0.01, 0.001
  if timeinsts() > iDecay + 0.05 then
    turnoff
  endif
  outs aOut * aEnv * iVel * 0.4, aOut * aEnv * iVel * 0.4
endin''';
    }
  }
}
