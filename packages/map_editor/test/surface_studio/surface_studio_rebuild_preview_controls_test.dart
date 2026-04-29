import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets(
      'preview panel exposes playback, scrub, loop grid and size controls', (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(
        find.byKey(const Key('surfaceStudio.preview.panel')), findsOneWidget);
    expect(find.text('Prévisualisation'), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.previous')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.playPause')),
        findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.next')), findsOneWidget);
    expect(find.byKey(const Key('surfaceStudio.preview.scrubSlider')),
        findsOneWidget);
    expect(find.text('Frame 1 / 32'), findsOneWidget);
    expect(find.text('Boucle'), findsOneWidget);
    expect(find.text('Grille'), findsOneWidget);
    expect(find.text('10 × 10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('surfaceStudio.preview.next')));
    await tester.pump();
    expect(find.text('Frame 2 / 32'), findsOneWidget);

    await tester.tap(find.byKey(const Key('surfaceStudio.preview.sizeButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 × 15').last);
    await tester.pumpAndSettle();
    expect(find.text('15 × 15'), findsOneWidget);
  });
}
