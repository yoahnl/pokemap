import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/surface_painter/surface_catalog_availability.dart';
import 'package:map_editor/src/features/surface_painter/surface_palette_panel.dart';

void main() {
  group('SurfacePalettePanel', () {
    testWidgets('empty palette shows catalog counts and next actions',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfacePalettePanel(
            availability: SurfaceCatalogAvailability.fromCatalog(
              const ProjectSurfaceCatalog.empty(),
            ),
            presets: const [],
            selectedSurfacePresetId: null,
            onPresetSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Surfaces'), findsOneWidget);
      expect(find.text('Catalogue Surface :'), findsOneWidget);
      expect(find.text('Atlas : 0'), findsOneWidget);
      expect(find.text('Animations : 0'), findsOneWidget);
      expect(find.text('Presets : 0'), findsOneWidget);
      expect(find.text('Aucun preset Surface disponible'), findsOneWidget);
      expect(
        find.text(
          'Ajoutez au catalogue un atlas, des animations et un preset Surface.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('animations without presets explain the real paint blocker',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfacePalettePanel(
            availability: SurfaceCatalogAvailability.fromCatalog(
              ProjectSurfaceCatalog(
                atlases: [_atlas('water')],
                animations: List.generate(
                  20,
                  (index) => _animation('water-$index'),
                ),
              ),
            ),
            presets: const [],
            selectedSurfacePresetId: null,
            onPresetSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Atlas : 1'), findsOneWidget);
      expect(find.text('Animations : 20'), findsOneWidget);
      expect(find.text('Presets : 0'), findsOneWidget);
      expect(
        find.text('Animations Surface trouvées, mais aucun preset peignable.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Ajoutez un preset Surface au catalogue du projet pour rendre ces animations peignables.',
        ),
        findsOneWidget,
      );
      expect(find.text('ProjectSurfacePreset'), findsNothing);
      expect(find.text('ProjectSurfaceCatalog'), findsNothing);
      expect(find.text('SurfaceVariantAnimationRef'), findsNothing);
      expect(find.text('SurfaceAnimationFrame'), findsNothing);
      expect(find.text('manifest'), findsNothing);
      expect(find.text('callback'), findsNothing);
      expect(find.text('copyWith'), findsNothing);
    });

    testWidgets('lists presets and reports selected surface ids',
        (tester) async {
      final selectedIds = <String>[];

      await tester.pumpWidget(
        _wrap(
          SurfacePalettePanel(
            availability: SurfaceCatalogAvailability.fromCatalog(
              ProjectSurfaceCatalog(
                presets: [
                  _preset(id: 'water', name: 'Water'),
                  _preset(id: 'lava', name: 'Lava'),
                ],
              ),
            ),
            presets: [
              _preset(id: 'water', name: 'Water'),
              _preset(id: 'lava', name: 'Lava'),
            ],
            selectedSurfacePresetId: 'lava',
            onPresetSelected: selectedIds.add,
          ),
        ),
      );

      expect(find.text('Presets : 2'), findsOneWidget);
      expect(find.text('Sélectionnez une surface à peindre.'), findsOneWidget);
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Lava'), findsOneWidget);
      expect(find.text('ID : water'), findsOneWidget);
      expect(find.text('ID : lava'), findsOneWidget);
      expect(find.text('Surface sélectionnée'), findsOneWidget);

      await tester.tap(find.byKey(const Key('surface-palette-preset-water')));
      expect(selectedIds, ['water']);
    });
  });

  group('SurfacePainterPanel', () {
    testWidgets('surface layer plus zero presets explains nothing is paintable',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: ProjectManifest(
          name: 'Demo',
          maps: const [],
          tilesets: const [],
          surfaceCatalog: ProjectSurfaceCatalog(
            atlases: [_atlas('water')],
            animations: List.generate(
              20,
              (index) => _animation('water-$index'),
            ),
          ),
        ),
        activeMap: const MapData(
          id: 'map_1',
          name: 'Map 1',
          size: GridSize(width: 3, height: 3),
          layers: [
            SurfaceLayer(id: 'surface-main', name: 'Eau'),
          ],
        ),
        activeLayerId: 'surface-main',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SurfacePainterPanel(embedded: true),
            ),
          ),
        ),
      );

      expect(find.text('Eau — 0 placement(s)'), findsOneWidget);
      expect(find.text('Atlas : 1'), findsOneWidget);
      expect(find.text('Animations : 20'), findsOneWidget);
      expect(find.text('Presets : 0'), findsOneWidget);
      expect(
        find.text(
          'Un calque Surface existe, mais aucune surface n’est encore peignable.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}

Widget _wrap(Widget child) {
  return CupertinoApp(
    home: CupertinoPageScaffold(child: child),
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required String name,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: '$id-isolated',
        ),
      ],
    ),
  );
}

SurfaceAtlasGeometry _geometry() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas(String id) {
  return ProjectSurfaceAtlas(
    id: id,
    name: 'Atlas $id',
    tilesetId: 'tileset-$id',
    geometry: _geometry(),
  );
}

SurfaceAnimationTimeline _timeline() {
  return SurfaceAnimationTimeline(
    frames: [
      SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      ),
    ],
  );
}

ProjectSurfaceAnimation _animation(String id) {
  return ProjectSurfaceAnimation(
    id: id,
    name: 'Animation $id',
    timeline: _timeline(),
  );
}
