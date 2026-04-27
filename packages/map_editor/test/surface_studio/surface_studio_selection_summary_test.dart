// Widget test — [SurfaceStudioSelectionSummary] (Lot 58).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_summary.dart';

void main() {
  testWidgets('résumé none + hint', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SurfaceStudioSelectionSummary(
          selection: SurfaceStudioSelection.none(),
        ),
      ),
    );
    expect(find.text('Aucune sélection'), findsOneWidget);
    expect(
      find.text('Sélectionnez un élément du catalogue pour l’inspecter.'),
      findsOneWidget,
    );
  });

  testWidgets('résumé atlas + id', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SurfaceStudioSelectionSummary(
          selection: SurfaceStudioSelection.atlas('water-atlas'),
        ),
      ),
    );
    expect(find.text('Atlas sélectionné'), findsOneWidget);
    expect(find.text('water-atlas'), findsOneWidget);
  });
}
