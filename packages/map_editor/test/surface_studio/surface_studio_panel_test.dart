// Surface Studio V2.1 panel tests.
//
// These assertions intentionally replace the old Lot 52-69 panel expectations:
// the catalog browser, diagnostics and paintable-surface panels still exist, but
// they must no longer render as a second Surface Studio under the wizard.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_workflow_layout.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  group('SurfaceStudioPanel V2.1', () {
    testWidgets('renders one wizard and no legacy workflow underneath',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(
        find.text('Surface Studio — Assistant de mapping d’atlas'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('surface_studio_legacy_authoring_bridge')),
        findsNothing,
      );
      expect(find.byType(SurfaceStudioWorkflowLayout), findsNothing);
      expect(find.text('Assistant de création'), findsNothing);
      expect(find.text('Catalogue Surface'), findsNothing);
      expect(find.text('Diagnostics Surface'), findsNothing);
    });

    testWidgets('keeps catalog and diagnostics in the advanced drawer',
        (tester) async {
      await pumpSurfaceStudioForTest(tester);
      await tester.pump();

      await tester.tap(find.byIcon(CupertinoIcons.gear_alt));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('surfaceStudio.advanced.drawer')),
        findsOneWidget,
      );
      expect(find.text('Catalogue & diagnostics'), findsOneWidget);
      expect(find.text('Détails avancés'), findsOneWidget);
      expect(find.text('Catalogue Surface'), findsOneWidget);
      expect(find.text('Animations TSX importées'), findsOneWidget);
      expect(find.text('Diagnostics Surface'), findsOneWidget);
      expect(find.text('Surfaces prêtes à peindre'), findsOneWidget);
    });

    testWidgets(
        'SurfaceStudioPanelFromManifest saves the work catalog by action',
        (tester) async {
      ProjectManifest? changedManifest;
      await pumpSurfaceStudioPanelFromManifest(
        tester,
        manifest: _manifest(ProjectSurfaceCatalog()),
        onProjectManifestChanged: (manifest) => changedManifest = manifest,
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.atlasId')),
        'v21-atlas',
      );
      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.atlasName')),
        'V2.1 Atlas',
      );
      await tester.enterText(
        find.byKey(const Key('surfaceStudio.import.tilesetId')),
        'tiles',
      );
      await tester
          .tap(find.byKey(const Key('surfaceStudio.import.createAtlas')));
      await tester.pump();

      expect(
        find.text(SurfaceStudioPanel.workCatalogDirtyStateText),
        findsOneWidget,
      );
      expect(changedManifest, isNull);

      await tester
          .tap(find.byKey(const Key('surfaceStudio.action.saveCatalog')));
      await tester.pump();

      expect(changedManifest, isNotNull);
      expect(
        changedManifest!.surfaceCatalog.atlases.map((atlas) => atlas.id),
        contains('v21-atlas'),
      );
    });

    testWidgets('SurfaceStudioPanel still builds without ProviderScope',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1800,
            height: 1000,
            child: SurfaceStudioPanel(
              readModel: buildSurfaceStudioReadModelFromCatalog(_catalog()),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('surfaceStudio.shell')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> pumpSurfaceStudioPanelFromManifest(
  WidgetTester tester, {
  required ProjectManifest manifest,
  ValueChanged<ProjectManifest>? onProjectManifestChanged,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(2048, 1120);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 2048,
        height: 1120,
        child: SurfaceStudioPanelFromManifest(
          manifest: manifest,
          projectRootPath: '/missing/project',
          onProjectManifestChanged: onProjectManifestChanged,
        ),
      ),
    ),
  );
}

ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'missing/tiles.png',
      ),
    ],
    surfaceCatalog: catalog,
  );
}

ProjectSurfaceCatalog _catalog() {
  const atlasId = 'water-atlas';
  final animation = ProjectSurfaceAnimation(
    id: 'water-col-0',
    name: 'Water Column 0',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: atlasId,
            column: 0,
            row: 0,
          ),
          durationMs: 120,
        ),
      ],
    ),
    syncGroupId: atlasId,
  );
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: atlasId,
        name: 'Water Atlas',
        tilesetId: 'tiles',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 12, rows: 32),
          layout: SurfaceAtlasLayout.grid,
        ),
      ),
    ],
    animations: [animation],
    presets: [
      ProjectSurfacePreset(
        id: 'water',
        name: 'Water Surface',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-col-0',
            ),
          ],
        ),
      ),
    ],
  );
}
