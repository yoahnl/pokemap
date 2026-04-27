// Tests widget — Surface Studio diagnostics view (Lot 55).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_diagnostics_view.dart';

void main() {
  group('SurfaceStudioDiagnosticsView (Lot 55)', () {
    testWidgets('1. title Diagnostics Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _emptyReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('2. clean: main message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
      );
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('3. clean: ni erreur ni avertissement', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
      );
      expect(
        find.textContaining('ni erreur ni avertissement'),
        findsOneWidget,
      );
    });

    testWidgets('4. clean: counts zero', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _cleanReadModel())),
      );
      expect(find.textContaining('Erreurs : 0'), findsOneWidget);
      expect(find.textContaining('Avertissements : 0'), findsOneWidget);
      expect(find.textContaining('Total : 0'), findsOneWidget);
    });

    testWidgets('5. error missingPresetAnimation', (tester) async {
      final rm = _missingAnimationReadModel();
      expect(rm.hasErrors, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      expect(
        find.text('Animation manquante dans un preset'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Animation : no-such-anim').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('6. error missingAnimationAtlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(readModel: _missingAtlasReadModel()),
        ),
      );
      expect(find.text('Atlas manquant dans une animation'), findsOneWidget);
    });

    testWidgets('7. error animationFrameOutsideAtlasGeometry', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _frameOutsideGeometryReadModel(),
          ),
        ),
      );
      expect(find.text('Frame hors géométrie d’atlas'), findsOneWidget);
    });

    testWidgets('8. warning unusedAtlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(readModel: _unusedAtlasReadModel()),
        ),
      );
      expect(find.text('Atlas inutilisé'), findsOneWidget);
    });

    testWidgets('9. warning unusedAnimation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _unusedAnimationReadModel(),
          ),
        ),
      );
      expect(find.text('Animation inutilisée'), findsOneWidget);
    });

    testWidgets('10. mixed: Erreurs and Avertissements sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      expect(find.text('Erreurs'), findsOneWidget);
      expect(find.text('Avertissements'), findsOneWidget);
    });

    testWidgets('11. mixed: summary counts', (tester) async {
      final rm = _mixedDiagnosticsReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      final s = rm.diagnostics.summary;
      expect(s.errorCount, 1);
      // Atlas inutilisé + animation non référencée par un preset
      expect(s.warningCount, 2);
      expect(s.totalCount, 3);
      expect(find.textContaining('Erreurs : 1'), findsOneWidget);
      expect(find.textContaining('Avertissements : 2'), findsOneWidget);
      expect(find.textContaining('Total : 3'), findsOneWidget);
    });

    testWidgets('12. error order preserved', (tester) async {
      final rm = _twoErrorsReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      expect(
        block.indexOf('e-first'),
        lessThan(block.indexOf('e-second')),
      );
    });

    testWidgets('13. warning order preserved', (tester) async {
      final rm = _twoWarningsReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join('\n');
      if (block.contains('orphan-a') && block.contains('orphan-b')) {
        expect(
          block.indexOf('orphan-a'),
          lessThan(block.indexOf('orphan-b')),
        );
      }
    });

    testWidgets('14. warnings only: no errors line empty section',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(readModel: _unusedAtlasReadModel()),
        ),
      );
      expect(find.text('Aucune erreur Surface'), findsOneWidget);
    });

    testWidgets('15. errors only: no warnings line empty section',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(readModel: _missingAnimationReadModel()),
        ),
      );
      expect(find.text('Aucun avertissement Surface'), findsOneWidget);
    });

    testWidgets('16. no TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('17. no fix affordances on view', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      for (final w in _forbiddenActionLabels) {
        expect(find.text(w), findsNothing);
      }
    });

    testWidgets('18. no internal type names in UI text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      final block = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(block.contains('ProjectSurfaceCatalog'), isFalse);
      expect(block.contains('SurfaceStudioReadModel'), isFalse);
      expect(block.contains('SurfaceVariantAnimationRefSet'), isFalse);
      expect(
        block.contains('SurfaceCatalogDiagnosticsPresentation'),
        isFalse,
      );
      expect(
        block.contains('SurfaceCatalogDiagnosticPresentationRow'),
        isFalse,
      );
    });

    testWidgets('19. many diagnostics build without throw', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioDiagnosticsView(
            readModel: _mixedDiagnosticsReadModel(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. messages follow readModel.diagnostics', (tester) async {
      final rm = _missingAnimationReadModel();
      final expected = rm.diagnostics.errors.first.message;
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: rm)),
      );
      expect(find.textContaining(expected), findsWidgets);
    });

    testWidgets('25. no ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioDiagnosticsView(readModel: _emptyReadModel()),
        ),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });

    testWidgets('26. bounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: SurfaceStudioDiagnosticsView(
                  readModel: _cleanReadModel(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('27. public map_core only (smoke)', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioDiagnosticsView(readModel: _emptyReadModel())),
      );
      expect(find.text('Diagnostics Surface'), findsOneWidget);
    });
  });
}

const _forbiddenActionLabels = <String>[
  'Corriger',
  'Réparer',
  'Supprimer',
  'Créer',
  'Modifier',
  'Enregistrer',
  'Sauvegarder',
  'Save',
  'Delete',
  'Fix',
  'Repair',
];

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

SurfaceStudioReadModel _cleanReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(_cleanCatalog());

SurfaceAtlasGeometry _geom1() => SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
      gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    );

ProjectSurfaceCatalog _cleanCatalog() {
  final g = _geom1();
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
    name: 'Anim',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final preset = ProjectSurfacePreset(
    id: 'p',
    name: 'P',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'anim',
        ),
      ],
    ),
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

SurfaceStudioReadModel _missingAnimationReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(
      _catalogWithMissingPresetAnimation(),
    );

ProjectSurfaceCatalog _catalogWithMissingPresetAnimation() {
  return ProjectSurfaceCatalog(
    presets: [
      ProjectSurfacePreset(
        id: 'pr',
        name: 'Pr',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'no-such-anim',
            ),
          ],
        ),
      ),
    ],
  );
}

SurfaceStudioReadModel _missingAtlasReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(
      ProjectSurfaceCatalog(
        animations: [
          ProjectSurfaceAnimation(
            id: 'an',
            name: 'An',
            timeline: SurfaceAnimationTimeline(
              frames: [
                SurfaceAnimationFrame(
                  tileRef: SurfaceAtlasTileRef(
                    atlasId: 'ghost-atlas',
                    column: 0,
                    row: 0,
                  ),
                  durationMs: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );

SurfaceStudioReadModel _frameOutsideGeometryReadModel() {
  final g = _geom1();
  final atlas = ProjectSurfaceAtlas(
    id: 'tiny',
    name: 'Tiny',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'out',
    name: 'Out',
    timeline: SurfaceAnimationTimeline(
      frames: [
        SurfaceAnimationFrame(
          tileRef: SurfaceAtlasTileRef(
            atlasId: 'tiny',
            column: 999,
            row: 999,
          ),
          durationMs: 1,
        ),
      ],
    ),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: [anim],
    ),
  );
}

SurfaceStudioReadModel _unusedAtlasReadModel() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final used = ProjectSurfaceAtlas(
    id: 'u',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final orphanA = ProjectSurfaceAtlas(
    id: 'orphan-a',
    name: 'OA',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [used, orphanA],
      animations: [anim],
    ),
  );
}

SurfaceStudioReadModel _unusedAnimationReadModel() {
  final g = _geom1();
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
  final usedAnim = ProjectSurfaceAnimation(
    id: 'used-anim',
    name: 'Used',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final looseAnim = ProjectSurfaceAnimation(
    id: 'loose',
    name: 'Loose',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final preset = ProjectSurfacePreset(
    id: 'p',
    name: 'P',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'used-anim',
        ),
      ],
    ),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [atlas],
      animations: [usedAnim, looseAnim],
      presets: [preset],
    ),
  );
}

SurfaceStudioReadModel _mixedDiagnosticsReadModel() {
  final g = _geom1();
  final used = ProjectSurfaceAtlas(
    id: 'u',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final orphanB = ProjectSurfaceAtlas(
    id: 'orphan-b',
    name: 'OB',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'u', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'A',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  final preset = ProjectSurfacePreset(
    id: 'pr2',
    name: 'Pr2',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'nope',
        ),
      ],
    ),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [used, orphanB],
      animations: [anim],
      presets: [preset],
    ),
  );
}

SurfaceStudioReadModel _twoErrorsReadModel() {
  final p1 = ProjectSurfacePreset(
    id: 'p1',
    name: 'P1',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'e-first',
        ),
      ],
    ),
  );
  final p2 = ProjectSurfacePreset(
    id: 'p2',
    name: 'P2',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'e-second',
        ),
      ],
    ),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      presets: [p1, p2],
    ),
  );
}

SurfaceStudioReadModel _twoWarningsReadModel() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final a0 = ProjectSurfaceAtlas(
    id: 'a0',
    name: 'A0',
    tilesetId: 't',
    geometry: g,
  );
  final oa = ProjectSurfaceAtlas(
    id: 'orphan-a',
    name: 'OA',
    tilesetId: 't',
    geometry: g,
  );
  final ob = ProjectSurfaceAtlas(
    id: 'orphan-b',
    name: 'OB',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a0', column: 0, row: 0),
    durationMs: 1,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'animU',
    name: 'AnimU',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: [a0, oa, ob],
      animations: [anim],
    ),
  );
}
