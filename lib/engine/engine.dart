import '../model/cell.dart';

class EngineException implements Exception {
  final String message;
  EngineException(this.message);
  @override
  String toString() => 'EngineException: $message';
}

/// Playback engine contract. All calls after [start] are synchronous fire-and-forget.
abstract class Engine {
  Future<void> start(String orc);
  void setCell(int row, int ch, Cell cell);
  void setParam(int id, String param, double value);
  void setBpm(int bpm);
  void setLpb(int lpb);
  void play();
  void stop();
  Stream<int> get row;
  bool get isPlaying;
  Future<void> dispose();
}
