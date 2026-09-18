import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/cell.dart';
import '../model/pattern.dart';
import '../state/providers.dart';

const double kRowHeight = 22;

class PatternGrid extends ConsumerStatefulWidget {
  const PatternGrid({super.key});

  @override
  ConsumerState<PatternGrid> createState() => _PatternGridState();
}

class _PatternGridState extends ConsumerState<PatternGrid> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _follow(int row) {
    if (!_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    final target = (row * kRowHeight - viewport / 2 + kRowHeight / 2).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final pattern = ref.watch(projectProvider.select((p) => p.pattern));
    final length = ref.watch(projectProvider.select((p) => p.length));
    final cursor = ref.watch(cursorProvider);
    final playRow = ref.watch(playRowProvider).value ?? -1;
    final playing = ref.watch(playingProvider);

    ref.listen<AsyncValue<int>>(playRowProvider, (_, next) {
      final r = next.value;
      if (r != null && ref.read(playingProvider)) _follow(r);
    });

    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      controller: _scroll,
      itemExtent: kRowHeight,
      itemCount: Pattern.rows,
      itemBuilder: (context, row) {
        final isPlayRow = playing && row == playRow;
        final isBeat = row % 4 == 0;
        return Container(
          color: isPlayRow
              ? scheme.secondaryContainer
              : isBeat
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : null,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  row.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: scheme.outline,
                  ),
                ),
              ),
              for (var ch = 0; ch < Pattern.channels; ch++)
                Expanded(
                  child: _CellView(
                    key: ValueKey('cell-$row-$ch'),
                    cell: pattern.at(row, ch),
                    inactive: row >= length,
                    selected: cursor.row == row && cursor.ch == ch,
                    onTap: () => ref.read(cursorProvider.notifier).state = (
                      row: row,
                      ch: ch,
                    ),
                    onLongPress: () =>
                        _editVolume(context, row, ch, pattern.at(row, ch)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editVolume(
    BuildContext context,
    int row,
    int ch,
    Cell cell,
  ) async {
    var v = cell.volume < 0 ? 64 : cell.volume;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Volume  ${v.toString().padLeft(2, '0')}'),
          content: Slider(
            min: 0,
            max: 64,
            divisions: 64,
            value: v.toDouble(),
            onChanged: (x) => setState(() => v = x.round()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, -1),
              child: const Text('Default'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, v),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    ref
        .read(projectProvider.notifier)
        .setCell(row, ch, cell.copyWith(volume: result));
  }
}

class _CellView extends StatelessWidget {
  final Cell cell;

  /// Past the pattern length: shown but not played.
  final bool inactive;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CellView({
    super.key,
    required this.cell,
    required this.inactive,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = cell.note < 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : null,
          borderRadius: BorderRadius.circular(3),
        ),
        // Never wrap: a second line would be clipped by the fixed row height
        // and hide the volume column. Shrink instead when the channel is narrow.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${cell.noteName} ${cell.instrumentText} ${cell.volumeText}',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: selected
                  ? scheme.onPrimary
                  : empty || inactive
                  ? scheme.outline
                  : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
