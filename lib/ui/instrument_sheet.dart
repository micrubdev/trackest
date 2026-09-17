import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/instrument.dart';
import '../state/providers.dart';

Future<void> showInstrumentSheet(BuildContext context, int id) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => InstrumentSheet(id: id),
    );

class InstrumentSheet extends ConsumerWidget {
  final int id;
  const InstrumentSheet({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inst = ref.watch(projectProvider.select((p) => p.instruments[id]));
    final notifier = ref.read(projectProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Instrument ${id.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              DropdownButton<Template>(
                key: const Key('template'),
                value: inst.template,
                items: [
                  for (final t in Template.values) DropdownMenuItem(value: t, child: Text(t.name)),
                ],
                onChanged: (t) {
                  if (t != null) notifier.setTemplate(id, t);
                },
              ),
            ],
          ),
          for (final spec in inst.template.specs)
            Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(spec.name, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
                Expanded(
                  child: Slider(
                    key: Key('param-${spec.name}'),
                    min: spec.min,
                    max: spec.max,
                    value: (inst.params[spec.name] ?? spec.def).clamp(spec.min, spec.max),
                    onChanged: (v) => notifier.setParam(id, spec.name, v),
                  ),
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    _fmt(inst.params[spec.name] ?? spec.def),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  static String _fmt(double v) => v >= 100 ? v.round().toString() : v.toStringAsFixed(2);
}
