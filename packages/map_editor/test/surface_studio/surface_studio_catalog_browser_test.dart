// Tests widget — Surface Studio catalog browser (Lot 54).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_catalog_browser.dart';

void main() {
  group('SurfaceStudioCatalogBrowser (Lot 54)', () {
    testWidgets('1. browser shows title Catalogue Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
    });

    testWidgets('2. empty catalog: global empty message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
      );
      expect(find.text('Le catalogue Surface est vide'), findsOneWidget);
    });

    testWidgets('3. empty catalog: per-section empty lines', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
      );
      expect(find.text('Aucun atlas Surface'), findsOneWidget);
      expect(find.text('Aucune animation Surface'), findsOneWidget);
      expect(find.text('Aucun preset Surface'), findsOneWidget);
    });

    testWidgets('4. minimal catalog: section headers visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Presets Surface'), findsOneWidget);
    });

    testWidgets('5. minimal catalog: atlas details (736-tile grid)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogWaterBigGrid(),
            ),
          ),
        ),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(find.textContaining('Identifiant : water-atlas'), findsOneWidget);
      expect(find.textContaining('Tileset : nature-tileset'), findsOneWidget);
      expect(find.textContaining('32×32'), findsWidgets);
      expect(find.textContaining('23×32'), findsOneWidget);
      expect(find.textContaining('736 tuiles'), findsOneWidget);
      expect(
        find.textContaining('Colonnes = variantes, lignes = frames'),
        findsOneWidget,
      );
    });

    testWidgets('6. minimal catalog: animation details', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-isolated-loop'),
        findsOneWidget,
      );
      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
      expect(find.textContaining('Durée totale : 120 ms'), findsOneWidget);
      expect(find.textContaining('water-atlas'), findsWidgets);
    });

    testWidgets('7. minimal catalog: preset details', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Water Surface'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-surface'),
        findsOneWidget,
      );
      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
      expect(find.text('Isolé'), findsOneWidget);
      expect(find.text('Animations liées'), findsOneWidget);
      expect(find.text('1 animation liée'), findsOneWidget);
      // Id visible dans la fiche atlas (utilisé par …) et dans le preset.
      expect(find.text('water-isolated-loop'), findsNWidgets(2));
      expect(find.text('Rôles standards incomplets'), findsOneWidget);
    });

    testWidgets('8. full animation: sync group and category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel:
                buildSurfaceStudioReadModelFromCatalog(_catalogSyncCat()),
          ),
        ),
      );
      expect(find.textContaining('Groupe de synchronisation : water'),
          findsOneWidget);
      expect(
          find.textContaining('Catégorie : animated-surfaces'), findsOneWidget);
    });

    testWidgets('9. atlas used by two animations', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogSharedAtlasTwoAnims(),
            ),
          ),
        ),
      );
      expect(find.textContaining('Utilisé par 2 animations'), findsOneWidget);
    });

    testWidgets('10. atlas unused', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogUnusedAtlas(),
            ),
          ),
        ),
      );
      expect(find.textContaining('Non utilisé'), findsOneWidget);
    });

    testWidgets('11. animation referenced atlas ids deduped order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogDedupeAtlasOrder(),
            ),
          ),
        ),
      );
      // Ordre visible dans la fiche animation (pas le blob texte global : les ids
      // apparaissent aussi dans les fiches atlas).
      expect(
        tester.getTopLeft(find.text('atlas-b')).dy,
        lessThan(tester.getTopLeft(find.text('atlas-a')).dy),
      );
    });

    testWidgets('12. preset referenced animation ids deduped order', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogDedupeAnimOrder(),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('anim-b').first).dy,
        lessThan(tester.getTopLeft(find.text('anim-a').first).dy),
      );
    });

    testWidgets('13. preset roles source order', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogRoleOrder(),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Croix')).dy,
        lessThan(tester.getTopLeft(find.text('Isolé')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Isolé')).dy,
        lessThan(tester.getTopLeft(find.text('Horizontal')).dy),
      );
    });

    testWidgets('14. atlas order preserved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogThreeAtlases(),
            ),
          ),
        ),
      );
      final names = ['W', 'L', 'G'];
      for (final n in names) {
        expect(find.text(n), findsOneWidget);
      }
    });

    testWidgets('15. animation order preserved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogThreeAnims(),
            ),
          ),
        ),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(block.indexOf('water-a'), lessThan(block.indexOf('water-b')));
      expect(block.indexOf('water-b'), lessThan(block.indexOf('water-c')));
    });

    testWidgets('16. preset order preserved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogThreePresets(),
            ),
          ),
        ),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(block.indexOf('water-surface'),
          lessThan(block.indexOf('lava-surface')));
      expect(block.indexOf('lava-surface'),
          lessThan(block.indexOf('grass-surface')));
    });

    testWidgets('17. order is list order not sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioCatalogBrowser(
            readModel: buildSurfaceStudioReadModelFromCatalog(
              _catalogSortOrderConflict(),
            ),
          ),
        ),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(block.indexOf('First'), lessThan(block.indexOf('Second')));
    });

    testWidgets('18. browser in scrollable ancestor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SingleChildScrollView(
            child: SurfaceStudioCatalogBrowser(readModel: _emptyReadModel()),
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('19. no TextField in browser', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('20. browser has no active edit affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Créer'), findsNothing);
      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
      expect(find.text('Enregistrer'), findsNothing);
      expect(find.text('Sauvegarder'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('21. no internal type names in UI', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
      expect(find.textContaining('SurfaceStudioAtlasReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceStudioAnimationReadModel'), findsNothing);
      expect(find.textContaining('SurfaceStudioPresetReadModel'), findsNothing);
    });

    testWidgets('24. error read model builds without throw', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _errorReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. derived row fields drive display', (tester) async {
      final rm = _minimalWaterReadModel();
      expect(rm.atlases.first.usedByAnimationIds, isNotEmpty);
      expect(rm.animations.first.referencedAtlasIds, isNotEmpty);
      expect(rm.presets.first.referencedAnimationIds, isNotEmpty);
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: rm)),
      );
      expect(find.textContaining('Utilisé par 1 animation'), findsOneWidget);
    });

    testWidgets('28. builds without ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioCatalogBrowser(readModel: _emptyReadModel()),
        ),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
    });

    testWidgets('29. accepts bounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: SurfaceStudioCatalogBrowser(
                  readModel: _minimalWaterReadModel(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('30. public map_core only (import smoke)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _emptyReadModel())),
      );
      expect(find.text('Catalogue Surface'), findsOneWidget);
    });

    testWidgets('45. Lot 57 — browser integrates Animation Detail', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Animations Surface'), findsOneWidget);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(find.textContaining('Durée totale'), findsOneWidget);
    });

    testWidgets('46. Lot 57 — browser integrates Preset Detail',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Presets Surface'), findsOneWidget);
      expect(find.text('Water Surface'), findsOneWidget);
      expect(find.text('Rôles standards incomplets'), findsOneWidget);
    });

    testWidgets('47. Lot 57 — browser keeps Atlas Detail', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioCatalogBrowser(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Atlas Surface'), findsOneWidget);
      expect(find.text('Water Atlas'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _emptyReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());

SurfaceStudioReadModel _minimalWaterReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());

SurfaceStudioReadModel _errorReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(_catalogPresetMissingAnim());

SurfaceAtlasGeometry _geom2x2() => SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    );

ProjectSurfaceCatalog _minimalWaterCatalog() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _catalogWaterBigGrid() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogSyncCat() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'anim-sync',
    name: 'Anim Sync',
    syncGroupId: 'water',
    categoryId: 'animated-surfaces',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogSharedAtlasTwoAnims() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'shared',
    name: 'Shared',
    tilesetId: 't',
    geometry: g,
  );
  final f1 = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 0, row: 0),
    durationMs: 10,
  );
  final f2 = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'shared', column: 1, row: 0),
    durationMs: 10,
  );
  final a1 = ProjectSurfaceAnimation(
    id: 'anim-1',
    name: 'A1',
    timeline: SurfaceAnimationTimeline(frames: [f1]),
  );
  final a2 = ProjectSurfaceAnimation(
    id: 'anim-2',
    name: 'A2',
    timeline: SurfaceAnimationTimeline(frames: [f2]),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [a1, a2],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogUnusedAtlas() {
  final g = _geom2x2();
  final used = ProjectSurfaceAtlas(
    id: 'u',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final orphan = ProjectSurfaceAtlas(
    id: 'orphan',
    name: 'Orphan',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, orphan],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogDedupeAtlasOrder() {
  final ga = _geom2x2();
  final gb = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlasA = ProjectSurfaceAtlas(
    id: 'atlas-a',
    name: 'A',
    tilesetId: 't',
    geometry: ga,
  );
  final atlasB = ProjectSurfaceAtlas(
    id: 'atlas-b',
    name: 'B',
    tilesetId: 't',
    geometry: gb,
  );
  final frames = <SurfaceAnimationFrame>[
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
      durationMs: 10,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
      durationMs: 10,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 1, row: 0),
      durationMs: 10,
    ),
  ];
  final anim = ProjectSurfaceAnimation(
    id: 'dedupe-atlas',
    name: 'Dedupe Atlas',
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlasA, atlasB],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogDedupeAnimOrder() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'x',
    name: 'X',
    tilesetId: 't',
    geometry: g,
  );
  final f1 = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'x', column: 0, row: 0),
    durationMs: 10,
  );
  final a1 = ProjectSurfaceAnimation(
    id: 'anim-b',
    name: 'B',
    timeline: SurfaceAnimationTimeline(frames: [f1]),
  );
  final a2 = ProjectSurfaceAnimation(
    id: 'anim-a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f1]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'anim-b',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.endNorth,
        animationId: 'anim-a',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.endEast,
        animationId: 'anim-b',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'p',
    name: 'P',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [a1, a2],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _catalogRoleOrder() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'r',
    name: 'R',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'r', column: 0, row: 0),
    durationMs: 1,
  );
  final aCross = ProjectSurfaceAnimation(
    id: 'ac',
    name: 'AC',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final aIso = ProjectSurfaceAnimation(
    id: 'ai',
    name: 'AI',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final aH = ProjectSurfaceAnimation(
    id: 'ah',
    name: 'AH',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.cross,
        animationId: 'ac',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'ai',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.horizontal,
        animationId: 'ah',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'proles',
    name: 'Proles',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [aCross, aIso, aH],
    presets: [preset],
  );
}

ProjectSurfaceCatalog _catalogThreeAtlases() {
  final g = _geom2x2();
  ProjectSurfaceAtlas ax(String id, String name) => ProjectSurfaceAtlas(
        id: id,
        name: name,
        tilesetId: 't',
        geometry: g,
      );
  return ProjectSurfaceCatalog(
    atlases: [ax('w', 'W'), ax('l', 'L'), ax('g', 'G')],
    animations: const [],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogThreeAnims() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 1,
  );
  ProjectSurfaceAnimation anim(String id) => ProjectSurfaceAnimation(
        id: id,
        name: id,
        timeline: SurfaceAnimationTimeline(frames: [f]),
      );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim('water-a'), anim('water-b'), anim('water-c')],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogThreePresets() {
  final g = _geom2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'anim',
    name: 'anim',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final ref = SurfaceVariantAnimationRef(
    role: SurfaceVariantRole.isolated,
    animationId: 'anim',
  );
  ProjectSurfacePreset pr(String id) => ProjectSurfacePreset(
        id: id,
        name: id,
        variantAnimations: SurfaceVariantAnimationRefSet(refs: [ref]),
      );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [pr('water-surface'), pr('lava-surface'), pr('grass-surface')],
  );
}

ProjectSurfaceCatalog _catalogSortOrderConflict() {
  final g = _geom2x2();
  final aFirst = ProjectSurfaceAtlas(
    id: 'first-atlas',
    name: 'First',
    tilesetId: 't',
    geometry: g,
    sortOrder: 99,
  );
  final aSecond = ProjectSurfaceAtlas(
    id: 'second-atlas',
    name: 'Second',
    tilesetId: 't',
    geometry: g,
    sortOrder: 1,
  );
  return ProjectSurfaceCatalog(
    atlases: [aFirst, aSecond],
    animations: const [],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogPresetMissingAnim() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'missing-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      ),
    ],
  );
}
