import 'package:flutter_test/flutter_test.dart';
import 'package:trackest/engine/fake_engine.dart';
import 'package:trackest/model/cell.dart';

void main() {
  test('logs calls in a stable format', () async {
    final e = FakeEngine();
    await e.start('orc');
    e.setCell(3, 1, const Cell(note: 60, instrument: 0));
    e.setParam(2, 'cutoff', 500);
    e.play();
    expect(e.isPlaying, isTrue);
    e.stop();
    expect(e.log, ['start', 'setCell 3 1 60 0 -1', 'setParam 2 cutoff 500.0', 'play', 'stop']);
  });

  test('row stream forwards emitted rows', () async {
    final e = FakeEngine();
    final rows = <int>[];
    final sub = e.row.listen(rows.add);
    e.emitRow(5);
    e.emitRow(6);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(rows, [5, 6]);
  });
}
