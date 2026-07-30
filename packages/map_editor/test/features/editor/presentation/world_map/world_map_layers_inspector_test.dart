import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_layer_deletion_impact.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layer_mutation_dialogs.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layers_inspector.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('shows one canonical top-first list and activates a layer',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.byType(ListView), findsOneWidget);
    final top = tester.getTopLeft(
      find.byKey(const ValueKey<String>('world-map-layer-row-top')),
    );
    final middle = tester.getTopLeft(
      find.byKey(const ValueKey<String>('world-map-layer-row-middle')),
    );
    final bottom = tester.getTopLeft(
      find.byKey(const ValueKey<String>('world-map-layer-row-bottom')),
    );
    expect(top.dy, lessThan(middle.dy));
    expect(middle.dy, lessThan(bottom.dy));
    expect(
      find.byKey(const ValueKey<String>('world-map-layer-active-middle')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-activate-top')),
    );
    await tester.pump();
    expect(harness.notifier.state.activeLayerId, 'top');
  });

  testWidgets('edits visibility opacity rename and group order',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onRenameRequested: ({
        required context,
        required layerId,
        required currentName,
      }) async {
        expect(layerId, 'middle');
        expect(currentName, 'Middle');
        return '  Milieu  ';
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-visibility-middle')),
    );
    await tester.pump();
    expect(_layer(harness, 'middle').isVisible, isFalse);

    final slider = tester.widget<PokeMapGuidedSlider>(
      find.byKey(const ValueKey<String>('world-map-layer-opacity-middle')),
    );
    slider.onChanged(40);
    await tester.pump();
    expect(_layer(harness, 'middle').opacity, 0.4);

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-rename-middle')),
    );
    await tester.pumpAndSettle();
    expect(_layer(harness, 'middle').name, 'Milieu');

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-move-up-middle')),
    );
    await tester.pump();
    expect(
      harness.notifier.state.activeMap!.layers.map((layer) => layer.id),
      const ['middle', 'top', 'bottom'],
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-move-down-middle')),
    );
    await tester.pump();
    expect(
      harness.notifier.state.activeMap!.layers.map((layer) => layer.id),
      const ['top', 'middle', 'bottom'],
    );
  });

  testWidgets('dispatches all eight creation kinds with real layer types',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final add = tester.widget<PokeMapSplitButton<WorldMapLayerCreationKind>>(
      find.byKey(const ValueKey<String>('world-map-layer-add')),
    );
    expect(
        add.items.map((item) => item.value), WorldMapLayerCreationKind.values);
    for (final kind in WorldMapLayerCreationKind.values) {
      add.onSelected(kind);
      await tester.pump();
    }

    final created = harness.notifier.state.activeMap!.layers;
    expect(created.whereType<TileLayer>(), isNotEmpty);
    expect(created.whereType<CollisionLayer>(), hasLength(1));
    expect(created.whereType<TerrainLayer>(), isNotEmpty);
    expect(created.whereType<PathLayer>(), hasLength(1));
    expect(created.whereType<ObjectLayer>(), hasLength(1));
    expect(created.whereType<EnvironmentLayer>(), hasLength(1));
    expect(created.whereType<BorderLayer>(), hasLength(1));
    expect(created.whereType<SurfaceLayer>(), hasLength(1));
    expect(
      find.text(
        'Zone auteur pour environnements organiques : forêts, bosquets, '
        'prairies, côtes rocheuses.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rename cancellation leaves map and history untouched',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    final before = harness.notifier.state.activeMap;
    await harness.pump(
      tester,
      onRenameRequested: ({
        required context,
        required layerId,
        required currentName,
      }) async =>
          null,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-rename-middle')),
    );
    await tester.pumpAndSettle();

    expect(harness.notifier.state.activeMap, same(before));
    expect(harness.notifier.state.canUndoMap, isFalse);
  });

  testWidgets('delete cancellation reports impact without losing placements',
      (tester) async {
    MapLayerDeletionImpact? receivedImpact;
    final map = _threeLayerMap().copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'tree',
          layerId: 'middle',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        receivedImpact = impact;
        return false;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(receivedImpact?.placedElementCount, 1);
    expect(harness.notifier.state.activeMap!.placedElements, hasLength(1));
    expect(harness.notifier.state.activeMap!.layers, hasLength(3));
    expect(harness.notifier.state.canUndoMap, isFalse);
  });

  testWidgets('confirmed deletion removes the layer and its placements',
      (tester) async {
    final map = _threeLayerMap().copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'tree',
          layerId: 'middle',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async =>
          true,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.notifier.state.activeMap!.layers
          .where((layer) => layer.id == 'middle'),
      isEmpty,
    );
    expect(harness.notifier.state.activeMap!.placedElements, isEmpty);
  });

  testWidgets('rechecks impact after confirmation and rejects stale deletion',
      (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        final current = harness.notifier.state.activeMap!;
        harness.notifier.state = harness.notifier.state.copyWith(
          activeMap: current.copyWith(
            events: const [
              MapEventDefinition(
                id: 'event_after_confirmation',
                pages: [MapEventPage(pageNumber: 0)],
                position: EventPosition(layerId: 'middle', x: 0, y: 0),
              ),
            ],
          ),
        );
        return true;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-layer-delete-middle')),
    );
    await tester.pumpAndSettle();

    expect(
      harness.notifier.state.activeMap!.layers
          .any((layer) => layer.id == 'middle'),
      isTrue,
    );
    expect(harness.notifier.state.activeMap!.events, hasLength(1));
  });

  testWidgets('dependency blockers disable delete with their current reason',
      (tester) async {
    var deleteRequests = 0;
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 1, height: 1),
      layers: [
        _tile('decor', 'Décor'),
        MapLayer.environment(
          id: 'forest',
          name: 'Forêt',
          content: EnvironmentLayerContent(targetTileLayerId: 'decor'),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'decor');
    addTearDown(harness.dispose);
    await harness.pump(
      tester,
      onDeleteRequested: ({
        required context,
        required impact,
      }) async {
        deleteRequests += 1;
        return true;
      },
    );

    final delete = tester.widget<PokeMapIconButton>(
      find.byKey(const ValueKey<String>('world-map-layer-delete-decor')),
    );
    expect(delete.onPressed, isNull);
    expect(
      delete.tooltip,
      'Impossible de supprimer ce layer : un environnement lui est attaché.',
    );
    expect(deleteRequests, 0);
  });

  testWidgets('MapEvent and generated dependencies expose disabled reasons',
      (tester) async {
    final map = MapData(
      id: 'map',
      name: 'Map',
      size: const GridSize(width: 1, height: 1),
      layers: [
        _tile('decor', 'Décor'),
        MapLayer.environment(
          id: 'orphan_forest',
          name: 'Forêt orpheline',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'missing',
            areas: [
              EnvironmentArea(
                id: 'forest_area',
                name: 'Forêt',
                presetId: 'forest',
                mask: EnvironmentAreaMask(
                  width: 1,
                  height: 1,
                  cells: [true],
                ),
                seed: 1,
                generatedPlacementIds: const ['generated_tree'],
              ),
            ],
          ),
        ),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'generated_tree',
          layerId: 'decor',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
      events: const [
        MapEventDefinition(
          id: 'event_gate',
          pages: [MapEventPage(pageNumber: 0)],
          position: EventPosition(layerId: 'decor', x: 0, y: 0),
        ),
      ],
    );
    final harness = _Harness(map, activeLayerId: 'decor');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final eventDelete = tester.widget<PokeMapIconButton>(
      find.byKey(const ValueKey<String>('world-map-layer-delete-decor')),
    );
    expect(eventDelete.onPressed, isNull);
    expect(eventDelete.tooltip, contains('1 événement de map'));

    final generatedDelete = tester.widget<PokeMapIconButton>(
      find.byKey(
        const ValueKey<String>('world-map-layer-delete-orphan_forest'),
      ),
    );
    expect(generatedDelete.onPressed, isNull);
    expect(generatedDelete.tooltip, contains('1 élément généré'));
  });

  testWidgets('does not fabricate lock or duplicate controls', (tester) async {
    final harness = _Harness(_threeLayerMap(), activeLayerId: 'middle');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.textContaining('Verrou'), findsNothing);
    expect(find.textContaining('Dupliquer'), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
    expect(find.byIcon(Icons.copy), findsNothing);
  });
}

final class _Harness {
  _Harness(
    MapData map, {
    required String activeLayerId,
  }) : container = ProviderContainer() {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = EditorState(
      projectRootPath: '/virtual/project',
      project: const ProjectManifest(
        name: 'Project',
        maps: [],
        tilesets: [],
      ),
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: map,
      activeLayerId: activeLayerId,
    );
  }

  final ProviderContainer container;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> pump(
    WidgetTester tester, {
    WorldMapLayerRenameRequested onRenameRequested =
        showWorldMapLayerRenameDialog,
    WorldMapLayerDeleteRequested onDeleteRequested =
        showWorldMapLayerDeleteDialog,
  }) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 760,
              child: WorldMapLayersInspector(
                onRenameRequested: onRenameRequested,
                onDeleteRequested: onDeleteRequested,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

MapLayer _layer(_Harness harness, String id) {
  return harness.notifier.state.activeMap!.layers
      .firstWhere((layer) => layer.id == id);
}

MapData _threeLayerMap() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 1, height: 1),
    layers: [
      _tile('top', 'Top'),
      _tile('middle', 'Middle'),
      _tile('bottom', 'Bottom'),
    ],
  );
}

TileLayer _tile(String id, String name) {
  return TileLayer(
    id: id,
    name: name,
    tiles: const [0],
  );
}
