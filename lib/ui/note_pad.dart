import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell.dart';
import '../model/pattern.dart';
import '../state/providers.dart';

const _names = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

/// Two-octave key pad plus OFF / DEL. Writes into the cursor cell and steps down.
class NotePad extends ConsumerWidget {
  const NotePad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final octave = ref.watch(octaveProvider);
    final scheme = Theme.of(context).colorScheme;

    void write(Cell cell) {
      final cursor = ref.read(cursorProvider);
      ref.read(projectProvider.notifier).setCell(cursor.row, cursor.ch, cell);
      final step = ref.read(editStepProvider);
      ref.read(cursorProvider.notifier).state = (
        row: (cursor.row + step) % Pattern.rows,
        ch: cursor.ch,
      );
    }

    void note(int midi) {
      if (midi > 119) return;
      final cursor = ref.read(cursorProvider);
      final keep = ref.read(keepVolumeProvider);
      final volume = keep
          ? ref.read(projectProvider).pattern.at(cursor.row, cursor.ch).volume
          : -1;
      write(
        Cell(
          note: midi,
          instrument: ref.read(currentInstrumentProvider),
          volume: volume,
        ),
      );
    }

    Widget key(String label, VoidCallback onTap, {Color? color, Key? k}) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: Material(
              key: k,
              color: color ?? scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
              child: InkWell(
                onTap: onTap,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    Widget octaveRow(int oct) => Expanded(
      child: Row(
        children: [
          for (var i = 0; i < 12; i++)
            key(
              '${_names[i]}$oct',
              () => note(oct * 12 + i),
              color: _names[i].endsWith('#')
                  ? scheme.surfaceContainerLow
                  : null,
              k: Key('key-${_names[i]}$oct'),
            ),
        ],
      ),
    );

    return SizedBox(
      height: 132,
      child: Column(
        children: [
          octaveRow(octave + 1),
          octaveRow(octave),
          Expanded(
            child: Row(
              children: [
                key(
                  'OFF',
                  () => write(const Cell(note: Cell.noteOff)),
                  color: scheme.tertiaryContainer,
                  k: const Key('key-off'),
                ),
                key(
                  'DEL',
                  () => write(Cell.empty),
                  color: scheme.errorContainer,
                  k: const Key('key-del'),
                ),
                key('↑', () {
                  final c = ref.read(cursorProvider);
                  ref.read(cursorProvider.notifier).state = (
                    row: (c.row - 1 + Pattern.rows) % Pattern.rows,
                    ch: c.ch,
                  );
                }),
                key('↓', () {
                  final c = ref.read(cursorProvider);
                  ref.read(cursorProvider.notifier).state = (
                    row: (c.row + 1) % Pattern.rows,
                    ch: c.ch,
                  );
                }),
                key('←', () {
                  final c = ref.read(cursorProvider);
                  ref.read(cursorProvider.notifier).state = (
                    row: c.row,
                    ch: (c.ch - 1 + Pattern.channels) % Pattern.channels,
                  );
                }),
                key('→', () {
                  final c = ref.read(cursorProvider);
                  ref.read(cursorProvider.notifier).state = (
                    row: c.row,
                    ch: (c.ch + 1) % Pattern.channels,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
