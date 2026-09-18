import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackest/engine/fake_engine.dart';
import 'package:trackest/state/providers.dart';
import 'package:trackest/ui/transport_bar.dart';

void main() {
  testWidgets('every control is on screen at phone width', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [engineProvider.overrideWithValue(FakeEngine())],
      child: const MaterialApp(home: Scaffold(body: TransportBar())),
    ));
    expect(tester.takeException(), isNull, reason: 'row overflowed');

    for (final k in const ['play', 'length', 'instrument', 'clear', 'edit-instrument', 'settings']) {
      final rect = tester.getRect(find.byKey(Key(k)));
      expect(rect.right, lessThanOrEqualTo(360), reason: '$k is off screen');
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$k is off screen');
    }
  });
}
