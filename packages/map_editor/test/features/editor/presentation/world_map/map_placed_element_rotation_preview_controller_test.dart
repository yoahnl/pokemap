import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_placed_element_rotation_planner.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/map_placed_element_rotation_preview_controller.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('MapPlacedElementRotationPreviewController', () {
    test('stores a pure plan without changing map data or history', () {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);
      final sourceJson = fixture.map.toJson();

      fixture.controller.preview(
        map: fixture.map,
        project: _project,
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      final preview =
          fixture.container.read(mapPlacedElementRotationPreviewProvider);
      expect(preview?.instanceId, 'placed');
      expect(preview?.targetQuarterTurns, 1);
      expect(preview?.plan.canCommit, isTrue);
      expect(
        preview?.plan.previewFootprint?.destinationSize,
        const GridSize(width: 2, height: 3),
      );
      expect(fixture.notifier.state.activeMap, same(fixture.map));
      expect(fixture.notifier.state.activeMap!.toJson(), sourceJson);
      expect(fixture.notifier.state.mapUndoStack, isEmpty);
    });

    test('apply delegates one absolute transaction and clears success', () {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);
      fixture.controller.preview(
        map: fixture.map,
        project: _project,
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      final committed = fixture.controller.apply();

      expect(committed, isTrue);
      expect(
        fixture.notifier.state.activeMap!.placedElements.single.quarterTurns,
        1,
      );
      expect(fixture.notifier.state.mapUndoStack, hasLength(1));
      expect(
        fixture.container.read(mapPlacedElementRotationPreviewProvider),
        isNull,
      );
    });

    test('cancel clears without mutation or history', () {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);
      fixture.controller.preview(
        map: fixture.map,
        project: _project,
        instanceId: 'placed',
        targetQuarterTurns: 1,
      );

      fixture.controller.cancel();

      expect(
        fixture.container.read(mapPlacedElementRotationPreviewProvider),
        isNull,
      );
      expect(fixture.notifier.state.activeMap, same(fixture.map));
      expect(fixture.notifier.state.mapUndoStack, isEmpty);
    });

    test('does not apply a rejected plan', () {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);
      fixture.controller.preview(
        map: fixture.map,
        project: _project,
        instanceId: 'placed',
        targetQuarterTurns: 4,
      );

      expect(fixture.controller.apply(), isFalse);
      expect(fixture.notifier.state.activeMap, same(fixture.map));
      expect(fixture.notifier.state.mapUndoStack, isEmpty);
      expect(
        fixture.container
            .read(mapPlacedElementRotationPreviewProvider)
            ?.plan
            .rejection,
        MapPlacedElementRotationRejection.targetQuarterTurnsOutOfRange,
      );
    });

    test('map, selection, and tool changes clear transient preview', () {
      final fixture = _fixture();
      addTearDown(fixture.container.dispose);

      void preview() {
        fixture.controller.preview(
          map: fixture.notifier.state.activeMap,
          project: _project,
          instanceId: 'placed',
          targetQuarterTurns: 1,
        );
        expect(
          fixture.container.read(mapPlacedElementRotationPreviewProvider),
          isNotNull,
        );
      }

      preview();
      fixture.notifier.state = fixture.notifier.state.copyWith(
        selectedPlacedElementInstanceId: null,
      );
      expect(
        fixture.container.read(mapPlacedElementRotationPreviewProvider),
        isNull,
      );

      fixture.notifier.state = fixture.notifier.state.copyWith(
        selectedPlacedElementInstanceId: 'placed',
      );
      preview();
      fixture.notifier.state = fixture.notifier.state.copyWith(
        activeTool: EditorToolType.eraser,
      );
      expect(
        fixture.container.read(mapPlacedElementRotationPreviewProvider),
        isNull,
      );

      fixture.notifier.state = fixture.notifier.state.copyWith(
        activeTool: EditorToolType.selection,
      );
      preview();
      fixture.notifier.state = fixture.notifier.state.copyWith(
        activeMap: fixture.map.copyWith(name: 'Changed'),
      );
      expect(
        fixture.container.read(mapPlacedElementRotationPreviewProvider),
        isNull,
      );
    });
  });
}

({
  ProviderContainer container,
  EditorNotifier notifier,
  MapPlacedElementRotationPreviewController controller,
  MapData map,
}) _fixture() {
  final container = ProviderContainer();
  final notifier = container.read(editorNotifierProvider.notifier);
  const map = _map;
  notifier.state = const EditorState(
    project: _project,
    activeMap: map,
    activeLayerId: 'decor',
    selectedPlacedElementInstanceId: 'placed',
    savedMapSnapshot: map,
  );
  final controller =
      container.read(mapPlacedElementRotationPreviewProvider.notifier);
  return (
    container: container,
    notifier: notifier,
    controller: controller,
    map: map,
  );
}

const _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: GridSize(width: 5, height: 5),
  layers: <MapLayer>[
    TileLayer(
      id: 'decor',
      name: 'Decor',
      cells: <int>[
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ],
    ),
  ],
  placedElements: <MapPlacedElement>[
    MapPlacedElement(
      id: 'placed',
      layerId: 'decor',
      elementId: 'element-3x2',
      pos: GridPos(x: 1, y: 1),
    ),
  ],
);

const _project = ProjectManifest(
  name: 'Rotation preview',
  version: ProjectVersion.v6,
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'assets/tiles.png',
    ),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'element-3x2',
      name: 'Element 3x2',
      tilesetId: 'tiles',
      categoryId: 'decor',
      frames: <TilesetVisualFrame>[
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 2),
        ),
      ],
    ),
  ],
);
