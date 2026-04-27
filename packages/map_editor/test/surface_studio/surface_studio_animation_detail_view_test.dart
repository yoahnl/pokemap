// Tests widget — Surface Studio animation detail (Lot 57).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_animation_detail_view.dart';

void main() {
  group('SurfaceStudioAnimationDetailView (Lot 57)', () {
    testWidgets('1. title Animations Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Animations Surface'), findsOneWidget);
    });

    testWidgets('2. empty: main message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Aucune animation Surface'), findsOneWidget);
    });

    testWidgets('3. empty: explainer', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioAnimationDetailView(readModel: _emptyReadModel())),
      );
      final t = _allText(tester);
      expect(
        t.contains('frames') || t.contains('surfaces animées'),
        isTrue,
      );
    });

    testWidgets('4. simple: name and id', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.text('Water Loop'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-loop'),
        findsOneWidget,
      );
    });

    testWidgets('5. simple: 1 frame', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
    });

    testWidgets('6. simple: total duration 120 ms', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.textContaining('Durée totale : 120 ms'), findsOneWidget);
    });

    testWidgets('7. simple: referenced atlas', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.text('Atlas référencés'), findsOneWidget);
      expect(find.text('water-atlas'), findsOneWidget);
    });

    testWidgets('8. two referenced atlases order', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationTwoAtlasesReadModel(),
          ),
        ),
      );
      expect(find.text('2 atlas référencés'), findsOneWidget);
      final t = _allText(tester);
      expect(t.indexOf('atlas-b'), lessThan(t.indexOf('atlas-a')));
    });

    testWidgets('9. no sync group', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Groupe de synchronisation : Aucun groupe'),
        findsOneWidget,
      );
    });

    testWidgets('10. sync group water', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationWithSyncAndCategoryReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Groupe de synchronisation : water'),
        findsOneWidget,
      );
    });

    testWidgets('11. no category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('12. category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationWithSyncAndCategoryReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Catégorie : animated-surfaces'),
        findsOneWidget,
      );
    });

    testWidgets('13. sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.textContaining('Ordre : 42'), findsOneWidget);
    });

    testWidgets('14. referenced atlas order preserved b,a,c', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationThreeAtlasesReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('atlas-b'), lessThan(t.indexOf('atlas-a')));
      expect(t.indexOf('atlas-a'), lessThan(t.indexOf('atlas-c')));
    });

    testWidgets('15. animation order preserved a,b,c', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _multipleAnimationsReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('water-a'), lessThan(t.indexOf('water-b')));
      expect(t.indexOf('water-b'), lessThan(t.indexOf('water-c')));
    });

    testWidgets('16. does not sort by sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _animationSortOrderContradictionReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('first'), lessThan(t.indexOf('second')));
    });

    testWidgets('17. no TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('18. no active edit save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      for (final s in <String>[
        'Créer',
        'Modifier',
        'Supprimer',
        'Enregistrer',
        'Sauvegarder',
        'Save',
        'Delete',
        'Edit',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('19. no internal type names in UI', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _oneAnimationReadModel(),
          ),
        ),
      );
      expect(find.textContaining('ProjectSurfaceAnimation'), findsNothing);
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceStudioAnimationReadModel'), findsNothing);
      expect(find.textContaining('SurfaceAnimationTimeline'), findsNothing);
    });

    testWidgets('20. read model with diagnostics builds', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioAnimationDetailView(
            readModel: _readModelWithDiagnosticsAndAnimation(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('loop'), findsOneWidget);
    });

    testWidgets('21. no ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioAnimationDetailView(
            readModel: _emptyReadModel(),
          ),
        ),
      );
      expect(find.text('Animations Surface'), findsOneWidget);
    });

    testWidgets('22. accepts bounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: SurfaceStudioAnimationDetailView(
                  readModel: _oneAnimationReadModel(),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}

String _allText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((e) => e.data ?? '')
      .join('\n');
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

SurfaceAtlasGeometry _g2x2() => SurfaceAtlasGeometry(
      tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
      gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
      layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
    );

SurfaceStudioReadModel _emptyReadModel() =>
    buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());

SurfaceStudioReadModel _oneAnimationReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-loop',
    name: 'Water Loop',
    sortOrder: 42,
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
    ),
  );
}

SurfaceStudioReadModel _animationWithSyncAndCategoryReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'a',
    name: 'A',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'x',
    name: 'X',
    syncGroupId: 'water',
    categoryId: 'animated-surfaces',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
    ),
  );
}

SurfaceStudioReadModel _animationTwoAtlasesReadModel() {
  final ga = _g2x2();
  final gb = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final a = ProjectSurfaceAtlas(
      id: 'atlas-a', name: 'A', tilesetId: 't', geometry: ga);
  final b = ProjectSurfaceAtlas(
      id: 'atlas-b', name: 'B', tilesetId: 't', geometry: gb);
  final frames = <SurfaceAnimationFrame>[
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
      durationMs: 10,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
      durationMs: 10,
    ),
  ];
  final anim = ProjectSurfaceAnimation(
    id: 'anim2',
    name: 'Anim2',
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[a, b],
      animations: <ProjectSurfaceAnimation>[anim],
    ),
  );
}

SurfaceStudioReadModel _animationThreeAtlasesReadModel() {
  final g = _g2x2();
  final ba = ProjectSurfaceAtlas(
    id: 'atlas-b',
    name: 'B',
    tilesetId: 't',
    geometry: g,
  );
  final aa = ProjectSurfaceAtlas(
    id: 'atlas-a',
    name: 'A2',
    tilesetId: 't',
    geometry: g,
  );
  final ca = ProjectSurfaceAtlas(
    id: 'atlas-c',
    name: 'C',
    tilesetId: 't',
    geometry: g,
  );
  final frames = <SurfaceAnimationFrame>[
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-b', column: 0, row: 0),
      durationMs: 1,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-a', column: 0, row: 0),
      durationMs: 1,
    ),
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'atlas-c', column: 0, row: 0),
      durationMs: 1,
    ),
  ];
  final anim = ProjectSurfaceAnimation(
    id: 'tri',
    name: 'Tri',
    timeline: SurfaceAnimationTimeline(frames: frames),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[ba, aa, ca],
      animations: <ProjectSurfaceAnimation>[anim],
    ),
  );
}

SurfaceStudioReadModel _multipleAnimationsReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  SurfaceAnimationFrame f() => SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
        durationMs: 1,
      );
  final a = ProjectSurfaceAnimation(
    id: 'water-a',
    name: 'water-a',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
  );
  final b = ProjectSurfaceAnimation(
    id: 'water-b',
    name: 'water-b',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
  );
  final c = ProjectSurfaceAnimation(
    id: 'water-c',
    name: 'water-c',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f()]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[a, b, c],
    ),
  );
}

SurfaceStudioReadModel _animationSortOrderContradictionReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
    durationMs: 1,
  );
  final first = ProjectSurfaceAnimation(
    id: 'f',
    name: 'first',
    sortOrder: 99,
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
  );
  final second = ProjectSurfaceAnimation(
    id: 's',
    name: 'second',
    sortOrder: 1,
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[f]),
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[first, second],
    ),
  );
}

SurfaceStudioReadModel _readModelWithDiagnosticsAndAnimation() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final fr = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'loop',
    name: 'loop',
    timeline: SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[fr]),
  );
  final bad = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'nope',
      ),
    ],
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[
        ProjectSurfacePreset(
          id: 'p',
          name: 'p',
          variantAnimations: bad,
        ),
      ],
    ),
  );
}
