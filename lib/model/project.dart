import 'instrument.dart';
import 'pattern.dart';

class Project {
  static const int instrumentCount = 16;

  final String name;
  final int bpm;
  final int linesPerBeat;

  /// Rows played before looping (1..[Pattern.rows]); cells beyond it are kept.
  final int length;
  final Pattern pattern;
  final List<Instrument> instruments;

  const Project({
    required this.name,
    required this.bpm,
    required this.linesPerBeat,
    this.length = Pattern.rows,
    required this.pattern,
    required this.instruments,
  });

  factory Project.initial() {
    const defaults = [
      Template.subtractive,
      Template.fm,
      Template.sampler,
      Template.noise,
    ];
    return Project(
      name: 'untitled',
      bpm: 125,
      linesPerBeat: 4,
      pattern: Pattern.empty(),
      instruments: List.generate(
        instrumentCount,
        (i) => Instrument.defaultFor(i, defaults[i % defaults.length]),
        growable: false,
      ),
    );
  }

  Project copyWith({
    String? name,
    int? bpm,
    int? linesPerBeat,
    int? length,
    Pattern? pattern,
    List<Instrument>? instruments,
  }) => Project(
    name: name ?? this.name,
    bpm: bpm ?? this.bpm,
    linesPerBeat: linesPerBeat ?? this.linesPerBeat,
    length: length ?? this.length,
    pattern: pattern ?? this.pattern,
    instruments: instruments ?? this.instruments,
  );

  Project setInstrument(Instrument inst) {
    final next = List<Instrument>.of(instruments, growable: false);
    next[inst.id] = inst;
    return copyWith(instruments: next);
  }
}
