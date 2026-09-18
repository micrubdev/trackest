import 'package:flutter_test/flutter_test.dart';
import 'package:trackest/model/cell.dart';
import 'package:trackest/model/instrument.dart';
import 'package:trackest/model/pattern.dart';
import 'package:trackest/model/project.dart';

void main() {
  group('Cell', () {
    test('noteName formats midi, empty and off', () {
      expect(const Cell(note: 60).noteName, 'C-5');
      expect(const Cell(note: 61).noteName, 'C#5');
      expect(const Cell(note: 0).noteName, 'C-0');
      expect(const Cell(note: 119).noteName, 'B-9');
      expect(const Cell().noteName, '---');
      expect(const Cell(note: Cell.noteOff).noteName, 'OFF');
    });
    test('copyWith keeps unspecified fields', () {
      const c = Cell(note: 60, instrument: 3, volume: 40);
      expect(c.copyWith(note: 62), const Cell(note: 62, instrument: 3, volume: 40));
    });
    test('display strings for instrument and volume', () {
      expect(const Cell(note: 60, instrument: 3, volume: 40).instrumentText, '03');
      expect(const Cell().instrumentText, '--');
      expect(const Cell(volume: 40).volumeText, '40');
      expect(const Cell().volumeText, '--');
    });
  });

  group('Pattern', () {
    test('index is row-major', () {
      expect(Pattern.index(1, 2), 6);
      expect(Pattern.index(0, 0), 0);
    });
    test('empty pattern has rows*channels empty cells', () {
      final p = Pattern.empty();
      expect(p.cells.length, Pattern.rows * Pattern.channels);
      expect(p.at(63, 3), Cell.empty);
    });
    test('setCell is immutable', () {
      final p = Pattern.empty();
      final q = p.setCell(5, 1, const Cell(note: 60));
      expect(p.at(5, 1), Cell.empty);
      expect(q.at(5, 1), const Cell(note: 60));
    });
  });

  group('Instrument', () {
    test('defaultFor fills all template params with defaults', () {
      final i = Instrument.defaultFor(0, Template.fm);
      for (final s in Template.fm.specs) {
        expect(i.params[s.name], s.def);
      }
      expect(i.params.length, Template.fm.specs.length);
    });
    test('every template has specs', () {
      for (final t in Template.values) {
        expect(t.specs, isNotEmpty);
      }
    });
  });

  group('Project', () {
    test('initial has 16 instruments, bpm 125, lpb 4', () {
      final p = Project.initial();
      expect(p.instruments.length, 16);
      expect(p.bpm, 125);
      expect(p.linesPerBeat, 4);
      expect(p.length, 64);
      expect(p.instruments[0].id, 0);
      expect(p.instruments[15].id, 15);
    });
  });
}
