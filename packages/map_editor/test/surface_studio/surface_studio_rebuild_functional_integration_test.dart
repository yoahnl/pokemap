import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets(
      'Surface Studio renders one integrated wizard without legacy below',
      (tester) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
    expect(
      find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
      findsNothing,
    );
    expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
    expect(find.text('Assistant de création'), findsNothing);
    expect(
      find.text('Surface Studio — Assistant de mapping d’atlas'),
      findsOneWidget,
    );
  });

  testWidgets('new import step can create an atlas in the work catalog',
      (tester) async {
    ProjectSurfaceCatalog? saved;
    await pumpSurfaceStudioForTest(
      tester,
      readModel:
          buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog()),
      onSurfaceCatalogSaveRequested: (catalog) => saved = catalog,
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.step.import')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.atlasId')),
      'v21-water',
    );
    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.atlasName')),
      'V2.1 Water',
    );
    await tester.enterText(
      find.byKey(const Key('surfaceStudio.import.tilesetId')),
      'water_tiles',
    );
    await tester.tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
    await tester.pump();

    expect(
      find.text(
          'Catalogue de travail modifié — sauvegarde projet non effectuée.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.atlases.map((atlas) => atlas.id), contains('v21-water'));
  });
}
