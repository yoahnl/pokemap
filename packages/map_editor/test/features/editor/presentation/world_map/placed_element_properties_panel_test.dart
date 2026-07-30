import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/placed_element_properties_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  testWidgets(
    'public panel reuses placed-element forms and existing notifier commands',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier)
        ..state = const EditorState(
          project: _project,
          activeMap: _map,
          activeLayerId: 'ground',
          savedMapSnapshot: _map,
        );

      await tester.binding.setSurfaceSize(const Size(700, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 520,
                    child: PlacedElementPropertiesPanel(
                      instanceId: 'placed-lamp',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
          find.text("Propriétés de l'instance sélectionnée"), findsOneWidget);
      expect(find.text('Lamp (lamp)'), findsOneWidget);
      expect(find.text('Collision'), findsOneWidget);
      expect(find.text('Opacité'), findsOneWidget);
      expect(find.text('Ombre de cette instance'), findsOneWidget);
      expect(find.text('Animation'), findsOneWidget);
      expect(
          find.text('Aperçu indisponible pour le tileset actuellement chargé.'),
          findsOneWidget);
      expect(find.textContaining('Rotation'), findsNothing);
      expect(find.textContaining('Dupliquer'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('placed-element-collision-switch')),
      );
      await tester.pump();
      expect(
        notifier.state.activeMap!.placedElements.single.applyCollision,
        isFalse,
      );

      final slider = tester.widget<MacosSlider>(
        find.byKey(const ValueKey('placed-instance-opacity-slider')),
      );
      slider.onChanged(0.45);
      await tester.pump();
      expect(
        notifier.state.activeMap!.placedElements.single.opacity,
        0.45,
      );
    },
  );

  testWidgets('missing instance is read-only guidance', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    addTearDown(keepAlive.close);
    final notifier = container.read(editorNotifierProvider.notifier)
      ..state = const EditorState(
        project: _project,
        activeMap: _map,
        activeLayerId: 'ground',
        savedMapSnapshot: _map,
      );
    final before = notifier.state;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 520,
                height: 400,
                child: PlacedElementPropertiesPanel(
                  instanceId: 'missing',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Instance introuvable'), findsOneWidget);
    expect(notifier.state, same(before));
  });
}

const _project = ProjectManifest(
  name: 'Placed properties',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'decor', name: 'Décor'),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'lamp',
      name: 'Lamp',
      tilesetId: 'world',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 2),
        ),
      ],
    ),
  ],
  settings: ProjectSettings(tileWidth: 16, tileHeight: 16),
  surfaceCatalog: ProjectSurfaceCatalog.empty(),
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    TileLayer(
      id: 'ground',
      name: 'Ground',
      tilesetId: 'world',
      tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
  ],
  placedElements: <MapPlacedElement>[
    MapPlacedElement(
      id: 'placed-lamp',
      layerId: 'ground',
      elementId: 'lamp',
      pos: GridPos(x: 1, y: 2),
      applyCollision: true,
      opacity: 0.75,
    ),
  ],
);
