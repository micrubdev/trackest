import 'dart:async';
import 'dart:ffi';

import '../model/cell.dart';
import '../model/pattern.dart';
import 'csound_bindings.dart';
import 'engine.dart';
import 'orchestra_builder.dart';

/// Engine backed by the bundled Csound Android library.
///
/// Csound is driven from the OpenSL ES callback thread (non-async mode), so
/// no perform loop is needed here; this class only writes tables/channels and
/// polls the `row` channel for the UI.
class CsoundEngine implements Engine {
  final CsoundBindings _b;
  int _handle = 0;
  Pointer<Void> _cs = nullptr;
  bool _playing = false;
  Timer? _poll;
  int _lastRow = -1;
  final _row = StreamController<int>.broadcast();

  CsoundEngine([CsoundBindings? bindings]) : _b = bindings ?? CsoundBindings.open();

  bool get isStarted => _cs != nullptr;

  @override
  Future<void> start(String orc) async {
    if (isStarted) await dispose();
    if (_b.sizeOfMyflt() != 4) {
      throw EngineException('Unexpected MYFLT size ${_b.sizeOfMyflt()}');
    }
    _handle = _b.newAndroidCsound(async: false);
    _cs = _b.csoundOf(_handle);
    _b.createMessageBuffer(_cs, 0);
    _b.setOpenSlCallbacks(_handle);
    _b.pause(_handle, true);
    for (final o in const ['-odac', '-d', '-m0', '-b256', '-B1024']) {
      _b.setOption(_cs, o);
    }
    if (_b.compileOrc(_cs, orc) != 0) {
      final msg = _b.drainMessages(_cs);
      await dispose();
      throw EngineException('Orchestra compile failed:\n$msg');
    }
    if (_b.start(_cs) != 0) {
      final msg = _b.drainMessages(_cs);
      await dispose();
      throw EngineException('Csound start failed:\n$msg');
    }
    _b.setControlChannel(_cs, 'playing', 0);
    _b.pause(_handle, false);
    _poll = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!isStarted) return;
      final r = _b.getControlChannel(_cs, 'row').round();
      if (r != _lastRow) {
        _lastRow = r;
        _row.add(r);
      }
    });
  }

  @override
  void setCell(int row, int ch, Cell cell) {
    if (!isStarted) return;
    final i = Pattern.index(row, ch);
    _b.tableSet(_cs, OrchestraBuilder.noteTable, i, cell.note.toDouble());
    _b.tableSet(_cs, OrchestraBuilder.instTable, i, cell.instrument.toDouble());
    _b.tableSet(_cs, OrchestraBuilder.volTable, i, cell.volume.toDouble());
  }

  @override
  void setParam(int id, String param, double value) {
    if (!isStarted) return;
    _b.setControlChannel(_cs, OrchestraBuilder.channelFor(id, param), value);
  }

  @override
  void setBpm(int bpm) {
    if (isStarted) _b.setControlChannel(_cs, 'bpm', bpm.toDouble());
  }

  @override
  void setLpb(int lpb) {
    if (isStarted) _b.setControlChannel(_cs, 'lpb', lpb.toDouble());
  }

  @override
  void play() {
    if (!isStarted) return;
    _playing = true;
    _b.setControlChannel(_cs, 'playing', 1);
  }

  @override
  void stop() {
    if (!isStarted) return;
    _playing = false;
    _b.setControlChannel(_cs, 'playing', 0);
  }

  @override
  Stream<int> get row => _row.stream;

  @override
  bool get isPlaying => _playing;

  /// Any messages Csound has logged since the last call (for diagnostics).
  String drainMessages() => isStarted ? _b.drainMessages(_cs) : '';

  @override
  Future<void> dispose() async {
    _poll?.cancel();
    _poll = null;
    _playing = false;
    if (_cs != nullptr) {
      _b.stop(_cs);
      _cs = nullptr;
    }
    if (_handle != 0) {
      _b.deleteAndroidCsound(_handle);
      _handle = 0;
    }
  }
}
