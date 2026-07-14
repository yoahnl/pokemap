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

      expect(result.map.version, ProjectVersion.v2);
      expect(result.layer, isA<BorderLayer>());
      expect(result.layer.id, 'l_border_coast_1');
      expect((result.layer as BorderLayer).content, BorderLayerContent());
      expect(result.map.layers.first, same(source.layers.first));
      expect(source.version, ProjectVersion.v1);
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

    testWidgets('LayersPanel gives Border its own icon and label',
        (tester) async {
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v2,
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
