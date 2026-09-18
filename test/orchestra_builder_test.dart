import 'package:flutter_test/flutter_test.dart';
import 'package:trackest/engine/orchestra_builder.dart';
import 'package:trackest/model/instrument.dart';
import 'package:trackest/model/project.dart';

void main() {
  final instruments = Project.initial().instruments;

  test('header and tables', () {
    final orc = OrchestraBuilder.build(instruments);
    expect(orc, contains('sr = 44100'));
    expect(orc, contains('ksmps = 32'));
    expect(orc, contains('nchnls = 2'));
    expect(orc, contains('0dbfs = 1'));
    expect(orc, contains('giNote ftgen ${OrchestraBuilder.noteTable}, 0, 256, -7, -1, 256, -1'));
    expect(orc, contains('giInst ftgen ${OrchestraBuilder.instTable}, 0, 256, -7, -1, 256, -1'));
    expect(orc, contains('giVol ftgen ${OrchestraBuilder.volTable}, 0, 256, -7, -1, 256, -1'));
  });

  test('sequencer and 16 instrument slots', () {
    final orc = OrchestraBuilder.build(instruments);
    expect(orc, contains('instr 1\n'));
    for (var id = 0; id < 16; id++) {
      expect(RegExp('^instr ${10 + id}\$', multiLine: true).allMatches(orc).length, 1,
          reason: 'instr ${10 + id}');
    }
    expect(orc, contains('schedule 1, 0, -1'));
    expect(orc, contains('chnget "length"'), reason: 'pattern length is a live channel');
  });

  test('slot params are read from named channels', () {
    final list = List<Instrument>.of(instruments);
    list[3] = Instrument.defaultFor(3, Template.fm);
    final orc = OrchestraBuilder.build(list);
    expect(orc, contains('chnget "i3.ratio"'));
    expect(orc, contains('chnget "i3.index"'));
    expect(OrchestraBuilder.channelFor(3, 'ratio'), 'i3.ratio');
  });

  test('sampler references the sample path', () {
    final orc = OrchestraBuilder.build(instruments, samplePath: '/tmp/kick.wav');
    expect(orc, contains('"/tmp/kick.wav"'));
  });

  test('deterministic', () {
    expect(OrchestraBuilder.build(instruments), OrchestraBuilder.build(instruments));
  });
}
