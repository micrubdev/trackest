import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/engine.dart';
import '../engine/orchestra_builder.dart';
import '../model/cell.dart';
import '../model/instrument.dart';
import '../model/pattern.dart';
import '../model/project.dart';
import 'providers.dart';

/// Single source of truth for the project; every edit is mirrored to the engine.
class ProjectNotifier extends Notifier<Project> {
  static const minBpm = 20;
  static const maxBpm = 300;

  /// Path of the bundled drum sample once extracted; empty until then.
  String samplePath = '';

  Engine get _engine => ref.read(engineProvider);

  @override
  Project build() => Project.initial();

  String orchestra() =>
      OrchestraBuilder.build(state.instruments, samplePath: samplePath);

  void setCell(int row, int ch, Cell cell) {
    state = state.copyWith(pattern: state.pattern.setCell(row, ch, cell));
    _engine.setCell(row, ch, cell);
  }

  /// Empties the whole pattern; instruments, bpm and lpb are kept.
  void clearPattern() {
    state = state.copyWith(pattern: Pattern.empty());
    for (var r = 0; r < Pattern.rows; r++) {
      for (var ch = 0; ch < Pattern.channels; ch++) {
        _engine.setCell(r, ch, Cell.empty);
      }
    }
  }

  void setParam(int id, String param, double value) {
    state = state.setInstrument(state.instruments[id].withParam(param, value));
    _engine.setParam(id, param, value);
  }

  void setBpm(int bpm) {
    final v = bpm.clamp(minBpm, maxBpm);
    state = state.copyWith(bpm: v);
    _engine.setBpm(v);
  }

  void setLength(int rows) {
    final v = rows.clamp(1, Pattern.rows);
    state = state.copyWith(length: v);
    _engine.setLength(v);
  }

  /// Changing a template changes the orchestra, so the engine is restarted.
  Future<void> setTemplate(int id, Template template) async {
    if (state.instruments[id].template == template) return;
    state = state.setInstrument(Instrument.defaultFor(id, template));
    await restartEngine();
  }

  Future<void> restartEngine() async {
    final wasPlaying = _engine.isPlaying;
    _engine.stop();
    await _engine.start(orchestra());
    syncAll();
    if (wasPlaying) _engine.play();
  }

  /// Pushes the whole project into the engine (after a start/restart).
  void syncAll() {
    final e = _engine;
    e.setBpm(state.bpm);
    e.setLpb(state.linesPerBeat);
    e.setLength(state.length);
    for (final inst in state.instruments) {
      for (final p in inst.params.entries) {
        e.setParam(inst.id, p.key, p.value);
      }
    }
    for (var r = 0; r < Pattern.rows; r++) {
      for (var ch = 0; ch < Pattern.channels; ch++) {
        e.setCell(r, ch, state.pattern.at(r, ch));
      }
    }
  }
}
