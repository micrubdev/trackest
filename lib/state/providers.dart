import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../engine/engine.dart';
import '../model/project.dart';
import 'project_notifier.dart';

/// Overridden in `main` with the platform engine.
final engineProvider = Provider<Engine>((_) => throw UnimplementedError('override engineProvider'));

final projectProvider = NotifierProvider<ProjectNotifier, Project>(ProjectNotifier.new);

typedef Cursor = ({int row, int ch});

final cursorProvider = StateProvider<Cursor>((_) => (row: 0, ch: 0));
final currentInstrumentProvider = StateProvider<int>((_) => 0);
final octaveProvider = StateProvider<int>((_) => 4);
final editStepProvider = StateProvider<int>((_) => 1);
final playingProvider = StateProvider<bool>((_) => false);
final playRowProvider = StreamProvider<int>((ref) => ref.watch(engineProvider).row);
