// Tests widget — Surface Studio preset detail (Lot 57).
// API publique `map_core` uniquement (pas de `package:map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_preset_detail_view.dart';

void main() {
  group('SurfaceStudioPresetDetailView (Lot 57)', () {
    testWidgets('23. title Presets Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Presets Surface'), findsOneWidget);
    });

    testWidgets('24. empty: main message', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
      );
      expect(find.text('Aucun preset Surface'), findsOneWidget);
    });

    testWidgets('25. empty: explainer', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPresetDetailView(readModel: _emptyReadModel())),
      );
      final t = _allText(tester);
      expect(t.contains('rôles') || t.contains('animations'), isTrue);
    });

    testWidgets('26. simple: name and id', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.text('Water Surface'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-surface'),
        findsOneWidget,
      );
    });

    testWidgets('27. 1 variante', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
    });

    testWidgets('28. isolated role humanized', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.text('Isolé'), findsOneWidget);
    });

    testWidgets('29. multiple roles order', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _multipleRolesReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('Croix'), lessThan(t.indexOf('Isolé')));
      expect(t.indexOf('Isolé'), lessThan(t.indexOf('Horizontal')));
    });

    testWidgets('30. one linked animation', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.text('Animations liées'), findsOneWidget);
      expect(find.text('1 animation liée'), findsOneWidget);
      expect(find.text('water-loop'), findsOneWidget);
    });

    testWidgets('31. two linked animations order', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _presetTwoAnimationsReadModel(),
          ),
        ),
      );
      expect(find.text('2 animations liées'), findsOneWidget);
      final t = _allText(tester);
      expect(t.indexOf('water-b'), lessThan(t.indexOf('water-a')));
    });

    testWidgets('32. covers standard false', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(find.text('Rôles standards incomplets'), findsOneWidget);
    });

    testWidgets('33. covers standard true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _presetCompleteRolesReadModel(),
          ),
        ),
      );
      expect(find.text('Rôles standards complets'), findsOneWidget);
    });

    testWidgets('34. no category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(readModel: _onePresetReadModel()),
        ),
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('35. category', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _presetWithCategoryReadModel(),
          ),
        ),
      );
      expect(
        find.textContaining('Catégorie : animated-surfaces'),
        findsOneWidget,
      );
    });

    testWidgets('36. sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _onePresetReadModel(),
          ),
        ),
      );
      expect(find.textContaining('Ordre : 42'), findsOneWidget);
    });

    testWidgets('37. preset order preserved', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _multiplePresetsReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('water-surface'), lessThan(t.indexOf('lava-surface')));
      expect(t.indexOf('lava-surface'), lessThan(t.indexOf('grass-surface')));
    });

    testWidgets('38. does not sort by sortOrder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _presetSortOrderContradictionReadModel(),
          ),
        ),
      );
      final t = _allText(tester);
      expect(t.indexOf('first'), lessThan(t.indexOf('second')));
    });

    testWidgets('39. no TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _onePresetReadModel(),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('40. no active edit save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _onePresetReadModel(),
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

    testWidgets('41. no internal type names in UI', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _onePresetReadModel(),
          ),
        ),
      );
      expect(find.textContaining('ProjectSurfacePreset'), findsNothing);
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(find.textContaining('SurfaceStudioPresetReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });

    testWidgets('42. read model with diagnostics builds', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioPresetDetailView(
            readModel: _readModelWithDiagnosticsAndPreset(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Water Surface'), findsOneWidget);
    });

    testWidgets('43. no ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SurfaceStudioPresetDetailView(
            readModel: _emptyReadModel(),
          ),
        ),
      );
      expect(find.text('Presets Surface'), findsOneWidget);
    });

    testWidgets('44. accepts bounded width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: SurfaceStudioPresetDetailView(
                  readModel: _onePresetReadModel(),
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

SurfaceAnimationFrame _oneFrame() => SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(atlasId: 'w', column: 0, row: 0),
      durationMs: 10,
    );

SurfaceStudioReadModel _onePresetReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-loop',
    name: 'L',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    sortOrder: 42,
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _multipleRolesReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a1',
    name: 'A1',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final anim2 = ProjectSurfaceAnimation(
    id: 'a2',
    name: 'A2',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final anim3 = ProjectSurfaceAnimation(
    id: 'a3',
    name: 'A3',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.cross,
        animationId: 'a1',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'a2',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.horizontal,
        animationId: 'a3',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'm',
    name: 'M',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim, anim2, anim3],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _presetTwoAnimationsReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final fa = ProjectSurfaceAnimation(
    id: 'water-a',
    name: 'WA',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final fb = ProjectSurfaceAnimation(
    id: 'water-b',
    name: 'WB',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-b',
      ),
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.horizontal,
        animationId: 'water-a',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'p2',
    name: 'P2',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[fa, fb],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _presetWithCategoryReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-loop',
    name: 'L',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    categoryId: 'animated-surfaces',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _presetCompleteRolesReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  const loopId = 'std-loop';
  final anim = ProjectSurfaceAnimation(
    id: loopId,
    name: 'Std',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      for (final role in standardSurfaceVariantRoleOrder)
        SurfaceVariantAnimationRef(
          role: role,
          animationId: loopId,
        ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'full',
    name: 'Full',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}

SurfaceStudioReadModel _multiplePresetsReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'loop',
    name: 'L',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  ProjectSurfacePreset mk(String id, String name) {
    return ProjectSurfacePreset(
      id: id,
      name: name,
      variantAnimations: SurfaceVariantAnimationRefSet(
        refs: <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'loop',
          ),
        ],
      ),
    );
  }

  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[
        mk('water-surface', 'WS'),
        mk('lava-surface', 'LS'),
        mk('grass-surface', 'GS'),
      ],
    ),
  );
}

SurfaceStudioReadModel _presetSortOrderContradictionReadModel() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'loop',
    name: 'L',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  ProjectSurfacePreset p(String id, String name, int so) {
    return ProjectSurfacePreset(
      id: id,
      name: name,
      sortOrder: so,
      variantAnimations: SurfaceVariantAnimationRefSet(
        refs: <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'loop',
          ),
        ],
      ),
    );
  }

  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas],
      animations: <ProjectSurfaceAnimation>[anim],
      presets: <ProjectSurfacePreset>[
        p('a', 'first', 99),
        p('b', 'second', 1),
      ],
    ),
  );
}

SurfaceStudioReadModel _readModelWithDiagnosticsAndPreset() {
  final g = _g2x2();
  final atlas = ProjectSurfaceAtlas(
    id: 'w',
    name: 'W',
    tilesetId: 't',
    geometry: g,
  );
  final unusedAtlas = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'Orphan',
    tilesetId: 't',
    geometry: g,
  );
  final okAnim = ProjectSurfaceAnimation(
    id: 'ok',
    name: 'ok',
    timeline:
        SurfaceAnimationTimeline(frames: <SurfaceAnimationFrame>[_oneFrame()]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: <SurfaceVariantAnimationRef>[
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'ok',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'p',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return buildSurfaceStudioReadModelFromCatalog(
    ProjectSurfaceCatalog(
      atlases: <ProjectSurfaceAtlas>[atlas, unusedAtlas],
      animations: <ProjectSurfaceAnimation>[okAnim],
      presets: <ProjectSurfacePreset>[preset],
    ),
  );
}
