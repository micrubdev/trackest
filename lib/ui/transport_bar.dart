import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'instrument_sheet.dart';

class TransportBar extends ConsumerWidget {
  const TransportBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectProvider);
    final playing = ref.watch(playingProvider);
    final octave = ref.watch(octaveProvider);
    final current = ref.watch(currentInstrumentProvider);
    final notifier = ref.read(projectProvider.notifier);

    void togglePlay() {
      final engine = ref.read(engineProvider);
      if (playing) {
        engine.stop();
      } else {
        engine.play();
      }
      ref.read(playingProvider.notifier).state = !playing;
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton.filled(
              key: const Key('play'),
              tooltip: playing ? 'Stop' : 'Play',
              onPressed: togglePlay,
              icon: Icon(playing ? Icons.stop : Icons.play_arrow),
            ),
            const SizedBox(width: 4),
            _Stepper(
              label: 'BPM',
              value: '${project.bpm}',
              onDec: () => notifier.setBpm(project.bpm - 1),
              onInc: () => notifier.setBpm(project.bpm + 1),
              onDecLong: () => notifier.setBpm(project.bpm - 10),
              onIncLong: () => notifier.setBpm(project.bpm + 10),
            ),
            _Stepper(
              label: 'Oct',
              value: '$octave',
              onDec: () => ref.read(octaveProvider.notifier).state = (octave - 1).clamp(1, 8),
              onInc: () => ref.read(octaveProvider.notifier).state = (octave + 1).clamp(1, 8),
            ),
            const Spacer(),
            DropdownButton<int>(
              key: const Key('instrument'),
              value: current,
              underline: const SizedBox.shrink(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
              items: [
                for (final i in project.instruments)
                  DropdownMenuItem(
                    value: i.id,
                    child: Text('${i.id.toString().padLeft(2, '0')} ${i.name}'),
                  ),
              ],
              onChanged: (v) => ref.read(currentInstrumentProvider.notifier).state = v ?? 0,
            ),
            IconButton(
              key: const Key('edit-instrument'),
              tooltip: 'Edit instrument',
              icon: const Icon(Icons.tune),
              onPressed: () => showInstrumentSheet(context, current),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback? onDecLong;
  final VoidCallback? onIncLong;

  const _Stepper({
    required this.label,
    required this.value,
    required this.onDec,
    required this.onInc,
    this.onDecLong,
    this.onIncLong,
  });

  @override
  Widget build(BuildContext context) {
    final style = const TextStyle(fontFamily: 'monospace', fontSize: 13);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: style.copyWith(color: Colors.white54)),
        GestureDetector(
          onLongPress: onDecLong,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onDec,
            icon: const Icon(Icons.remove, size: 18),
          ),
        ),
        SizedBox(width: 30, child: Text(value, style: style, textAlign: TextAlign.center)),
        GestureDetector(
          onLongPress: onIncLong,
          child: IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onInc,
            icon: const Icon(Icons.add, size: 18),
          ),
        ),
      ],
    );
  }
}
