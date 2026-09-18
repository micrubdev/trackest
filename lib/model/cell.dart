/// One tracker cell: note, instrument slot, volume.
///
/// Encodings: [note] -1 empty, [noteOff] (-2) note-off, else MIDI 0..119.
/// [instrument] -1 = keep the channel's last instrument. [volume] -1 = use
/// instrument default, else 0..64.
class Cell {
  static const int empty_ = -1;
  static const int noteOff = -2;
  static const Cell empty = Cell();

  final int note;
  final int instrument;
  final int volume;

  const Cell({this.note = -1, this.instrument = -1, this.volume = -1});

  Cell copyWith({int? note, int? instrument, int? volume}) => Cell(
    note: note ?? this.note,
    instrument: instrument ?? this.instrument,
    volume: volume ?? this.volume,
  );

  static const _names = [
    'C-',
    'C#',
    'D-',
    'D#',
    'E-',
    'F-',
    'F#',
    'G-',
    'G#',
    'A-',
    'A#',
    'B-',
  ];

  String get noteName {
    if (note == noteOff) return 'OFF';
    if (note < 0) return '---';
    return '${_names[note % 12]}${note ~/ 12}';
  }

  String get instrumentText =>
      instrument < 0 ? '--' : instrument.toString().padLeft(2, '0');

  String get volumeText =>
      volume < 0 ? '--' : volume.toString().padLeft(2, '0');

  @override
  bool operator ==(Object other) =>
      other is Cell &&
      other.note == note &&
      other.instrument == instrument &&
      other.volume == volume;

  @override
  int get hashCode => Object.hash(note, instrument, volume);

  @override
  String toString() => 'Cell($noteName $instrumentText $volumeText)';
}
