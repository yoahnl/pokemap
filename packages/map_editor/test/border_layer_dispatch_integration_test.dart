import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/layer_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/layers_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

void main() {
  group('Border layer editor dispatch integration', () {
    test('AddMapLayerUseCase creates a unique empty Border layer in V2', () {
      const source = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.object(id: 'l_border_coast', name: 'Reserved ID'),
        ],
      );
      final before = source.toJson();

      final result = AddMapLayerUseCase().execute(
        source,
        kind: MapLayerKind.border,
        name: 'Coast',
      );

      expect(result.map.version, ProjectVersion.v6);
      expect(result.layer, isA<BorderLayer>());
      expect(result.layer.id, 'l_border_coast_1');
      expect((result.layer as BorderLayer).content, BorderLayerContent());
      expect(result.map.layers.first, same(source.layers.first));
      expect(source.version, ProjectVersion.v6);
      expect(source.toJson(), before);
    });

    test('EditorNotifier appends a Border layer above the authored stack', () {
      const tile = MapLayer.tile(
        id: 'tile',
        name: 'Décor',
        tiles: <int>[0, 0, 0, 0],
      );
      const collision = MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: <bool>[false, false, false, false],
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[tile, collision],
      );
      final collisionJson = collision.toJson();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = const EditorState(
        activeMap: map,
        activeLayerId: 'tile',
      );

      notifier.addMapLayer(
        kind: MapLayerKind.border,
        name: 'Bordures',
      );

      final updated = notifier.state.activeMap!;
      expect(updated.layers.map((layer) => layer.id), <String>[
        'tile',
        'collision',
        'l_border_bordures',
      ]);
      expect(updated.layers.last, isA<BorderLayer>());
      expect(
        updated.layers.whereType<CollisionLayer>().single.toJson(),
        collisionJson,
      );
    });

    test('generic reorder, visibility and opacity preserve Border save/reload',
        () {
      const source = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'tile',
            name: 'Décor',
            tiles: <int>[0, 0, 0, 0],
          ),
          MapLayer.border(id: 'border', name: 'Bordures'),
        ],
      );

      var updated = SetMapLayerVisibilityUseCase().execute(
        source,
        layerId: 'border',
        isVisible: false,
      );
      updated = SetMapLayerOpacityUseCase().execute(
        updated,
        layerId: 'border',
        opacity: 0.42,
      );
      updated = ReorderMapLayersUseCase().execute(
        updated,
        oldIndex: 1,
        newIndex: 0,
      );

      final border = updated.layers.first as BorderLayer;
      expect(border.id, 'border');
      expect(border.isVisible, isFalse);
      expect(border.opacity, 0.42);
      final reloaded = MapData.fromJson(updated.toJson());
      expect(reloaded.toJson(), updated.toJson());
      expect(reloaded.layers.first, isA<BorderLayer>());
    });

    testWidgets(
        'add-layer dialog offers Couche de bordures and appends it at the end',
        (tester) async {
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.tile(
            id: 'tile',
            name: 'Décor',
            tiles: <int>[0, 0, 0, 0],
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: map,
        activeLayerId: 'tile',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 420,
                  height: 600,
                  child: LayersPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();
      final dropdownFinder =
          find.byKey(const ValueKey<String>('layers-panel-add-type-dropdown'));
      expect(dropdownFinder, findsOneWidget);
      final dynamic dropdown = tester.widget(dropdownFinder);
      final dynamic borderItem = (dropdown.items as List<dynamic>)
          .singleWhere((dynamic item) => item.label == 'Couche de bordures');
      expect(borderItem.label, 'Couche de bordures');
      dropdown.onChanged(borderItem.value);
      await tester.pump();
      await tester.enterText(find.byType(MacosTextField), 'Rivage');
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      final updated = container.read(editorNotifierProvider).activeMap!;
      expect(updated.layers.last, isA<BorderLayer>());
      expect(updated.layers.last.name, 'Rivage');
      expect(container.read(editorNotifierProvider).activeLayerId,
          updated.layers.last.id);
    });

    testWidgets('LayersPanel gives Border its own icon and label',
        (tester) async {
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.border(id: 'border', name: 'Côte'),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        activeMap: map,
        activeLayerId: 'border',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 420,
                  height: 600,
                  child: LayersPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('bordure · 0 tracé(s) • border'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.waveform_path), findsOneWidget);
      expect(find.textContaining('collision • border'), findsNothing);
      expect(find.textContaining('surface • border'), findsNothing);
    });
  });
}
