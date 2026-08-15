import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('viewport preserves landscape and portrait aspect ratios', (
    tester,
  ) async {
    Future<Size> pump(PokeMapCinematicComposition composition) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 640,
                height: 500,
                child: PokeMapCinematicViewport(
                  composition: composition,
                  semanticLabel: 'Aperçu',
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getSize(
        find.byKey(const ValueKey('pokemap-cinematic-viewport-frame')),
      );
    }

    final landscape = await pump(PokeMapCinematicComposition.landscape16x9);
    expect(landscape.width / landscape.height, closeTo(16 / 9, 0.001));

    final portrait = await pump(PokeMapCinematicComposition.portrait9x16);
    expect(portrait.width / portrait.height, closeTo(9 / 16, 0.001));
  });

  testWidgets('safe areas and retryable error remain explicit', (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 640,
            height: 420,
            child: PokeMapCinematicViewport(
              composition: PokeMapCinematicComposition.landscape16x9,
              semanticLabel: 'Canvas paysage',
              showSafeArea: true,
              state: PokeMapCinematicViewportState.error,
              statusLabel: 'Média impossible à afficher',
              retryLabel: 'Réessayer',
              onRetry: () => retries += 1,
              child: const Placeholder(),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('pokemap-cinematic-safe-area')),
      findsOneWidget,
    );
    expect(find.text('Média impossible à afficher'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    expect(retries, 1);
  });

  testWidgets('transform handle forwards pointer deltas', (tester) async {
    var delta = Offset.zero;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Center(
            child: PokeMapCinematicTransformHandle(
              semanticLabel: 'Redimensionner le calque',
              onDrag: (value) => delta += value,
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byType(PokeMapCinematicTransformHandle),
      const Offset(20, 12),
    );

    expect(delta.dx, greaterThan(0));
    expect(delta.dy, greaterThan(0));
    expect(find.bySemanticsLabel('Redimensionner le calque'), findsOneWidget);
  });
}
