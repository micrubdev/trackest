import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackest/engine/fake_engine.dart';
import 'package:trackest/model/cell.dart';
import 'package:trackest/state/providers.dart';
import 'package:trackest/ui/pattern_grid.dart';

void main() {
  testWidgets('cell keeps note, instrument and volume on one line at phone width', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(overrides: [engineProvider.overrideWithValue(FakeEngine())]);
    addTearDown(container.dispose);
    container.read(projectProvider.notifier).setCell(0, 0, const Cell(note: 48, instrument: 0, volume: 40));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Scaffold(body: PatternGrid()),
        ),
      ),
    ));

    final paragraph = tester.renderObject<RenderParagraph>(find.text('C-4 00 40'));
    final oneLine = TextPainter(
      text: paragraph.text,
      textDirection: TextDirection.ltr,
      textScaler: const TextScaler.linear(1.3),
      maxLines: 1,
    )..layout();
    expect(paragraph.size.height, oneLine.height, reason: 'text wrapped onto a second line');
    expect(paragraph.size.width, oneLine.width, reason: 'text was clipped');
  });

  testWidgets('rows past the pattern length are dimmed', (tester) async {
    final container = ProviderContainer(overrides: [engineProvider.overrideWithValue(FakeEngine())]);
    addTearDown(container.dispose);
    final n = container.read(projectProvider.notifier);
    n.setCell(0, 0, const Cell(note: 48, instrument: 0));
    n.setCell(1, 0, const Cell(note: 50, instrument: 0));
    n.setLength(1);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: PatternGrid())),
    ));

    Color colorOf(String t) => tester.widget<Text>(find.text(t)).style!.color!;
    expect(colorOf('D-4 00 --'), isNot(colorOf('C-4 00 --')));
  });
}
