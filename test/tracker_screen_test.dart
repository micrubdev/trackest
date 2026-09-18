import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackest/engine/fake_engine.dart';
import 'package:trackest/state/providers.dart';
import 'package:trackest/ui/tracker_screen.dart';

void main() {
  late FakeEngine fake;

  Future<void> pumpApp(WidgetTester tester) async {
    fake = FakeEngine();
    await tester.runAsync(() async {
      await tester.pumpWidget(ProviderScope(
        overrides: [engineProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: TrackerScreen()),
      ));
      await tester.pump();
      // Boot does real file I/O (sample extraction); let it finish.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('boot starts engine and syncs', (tester) async {
    await pumpApp(tester);
    expect(fake.log, contains('start'));
    expect(fake.log.where((l) => l.startsWith('setCell')).length, 256);
  });

  testWidgets('pressing a key writes the cell and advances the cursor', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('key-C4')));
    await tester.pump();
    expect(find.text('C-4 00 --'), findsOneWidget);
    expect(fake.log.last, 'setCell 0 0 48 0 -1');
    await tester.tap(find.byKey(const Key('key-off')));
    await tester.pump();
    expect(fake.log.last, 'setCell 1 0 -2 -1 -1');
    expect(find.text('OFF -- --'), findsOneWidget);
  });

  testWidgets('play button toggles engine', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('play')));
    await tester.pump();
    expect(fake.log.last, 'play');
    expect(find.byIcon(Icons.stop), findsOneWidget);
    await tester.tap(find.byKey(const Key('play')));
    await tester.pump();
    expect(fake.log.last, 'stop');
  });

  testWidgets('instrument sheet slider forwards param', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('edit-instrument')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('param-cutoff')), findsOneWidget);
    await tester.drag(find.byKey(const Key('param-cutoff')), const Offset(50, 0));
    await tester.pump();
    expect(fake.log.last, startsWith('setParam 0 cutoff'));
  });

  testWidgets('clear button asks for confirmation, then empties the pattern', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('key-C4')));
    await tester.pump();
    expect(find.text('C-4 00 --'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('C-4 00 --'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('C-4 00 --'), findsNothing);
    expect(fake.log.last, 'setCell 63 3 -1 -1 -1');
  });
}
