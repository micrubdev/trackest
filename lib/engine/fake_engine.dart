import 'dart:async';

import '../model/cell.dart';
import 'engine.dart';

/// Records every call; used by tests and desktop runs.
class FakeEngine implements Engine {
  final List<String> log = [];
  final _row = StreamController<int>.broadcast();
  bool _playing = false;
  String? orc;

  @override
  Future<void> start(String orc) async {
    this.orc = orc;
    log.add('start');
  }

  @override
  void setCell(int row, int ch, Cell cell) =>
      log.add('setCell $row $ch ${cell.note} ${cell.instrument} ${cell.volume}');

  @override
  void setParam(int id, String param, double value) => log.add('setParam $id $param $value');

  @override
  void setBpm(int bpm) => log.add('setBpm $bpm');

  @override
  void setLpb(int lpb) => log.add('setLpb $lpb');

  @override
  void play() {
    _playing = true;
    log.add('play');
  }

  @override
  void stop() {
    _playing = false;
    log.add('stop');
  }

  void emitRow(int r) => _row.add(r);

  @override
  Stream<int> get row => _row.stream;

  @override
  bool get isPlaying => _playing;

  @override
  Future<void> dispose() async => _row.close();
}
