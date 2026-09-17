import 'cell.dart';

/// A fixed-size grid of [Cell]s stored row-major.
class Pattern {
  static const int rows = 64;
  static const int channels = 4;

  final List<Cell> cells;

  const Pattern._(this.cells);

  factory Pattern.empty() =>
      Pattern._(List.filled(rows * channels, Cell.empty, growable: false));

  static int index(int row, int ch) => row * channels + ch;

  Cell at(int row, int ch) => cells[index(row, ch)];

  Pattern setCell(int row, int ch, Cell cell) {
    final next = List<Cell>.of(cells, growable: false);
    next[index(row, ch)] = cell;
    return Pattern._(next);
  }
}
