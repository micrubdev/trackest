import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackest/engine/fake_engine.dart';
import 'package:trackest/model/cell.dart';
import 'package:trackest/model/instrument.dart';
import 'package:trackest/state/providers.dart';

void main() {
  late FakeEngine fake;
  late ProviderContainer c;

  setUp(() {
    fake = FakeEngine();
    c = ProviderContainer(overrides: [engineProvider.overrideWithValue(fake)]);
  });
  tearDown(() => c.dispose());

  test('setCell updates state and forwards to engine', () {
    c.read(projectProvider.notifier).setCell(2, 1, const Cell(note: 48, instrument: 0));
    expect(c.read(projectProvider).pattern.at(2, 1), const Cell(note: 48, instrument: 0));
    expect(fake.log, ['setCell 2 1 48 0 -1']);
  });

  test('setParam updates instrument and forwards', () {
    c.read(projectProvider.notifier).setParam(2, 'attack', 0.5);
    expect(c.read(projectProvider).instruments[2].params['attack'], 0.5);
    expect(fake.log, ['setParam 2 attack 0.5']);
  });

  test('setBpm clamps and forwards', () {
    final n = c.read(projectProvider.notifier);
    n.setBpm(999);
    expect(c.read(projectProvider).bpm, 300);
    n.setBpm(1);
    expect(c.read(projectProvider).bpm, 20);
    expect(fake.log, ['setBpm 300', 'setBpm 20']);
  });

  test('syncAll pushes every cell, param, bpm and lpb', () {
    c.read(projectProvider.notifier).syncAll();
    final cells = fake.log.where((l) => l.startsWith('setCell')).length;
    final params = fake.log.where((l) => l.startsWith('setParam')).length;
    final expectedParams = c
        .read(projectProvider)
        .instruments
        .fold<int>(0, (n, i) => n + i.params.length);
    expect(cells, 256);
    expect(params, expectedParams);
    expect(fake.log, contains('setBpm 125'));
    expect(fake.log, contains('setLpb 4'));
  });

  test('setTemplate restarts engine with a new orchestra and resyncs', () async {
    final n = c.read(projectProvider.notifier);
    await n.setTemplate(0, Template.noise);
    expect(c.read(projectProvider).instruments[0].template, Template.noise);
    expect(c.read(projectProvider).instruments[0].params.keys, ['cutoff', 'decay']);
    expect(fake.orc, contains('chnget "i0.decay"'));
    expect(fake.log.take(2), ['stop', 'start']);
    expect(fake.log.where((l) => l.startsWith('setCell')).length, 256);
  });
}
