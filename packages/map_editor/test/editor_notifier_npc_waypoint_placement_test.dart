import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

MapEntity _npcEntity({
  required String id,
  required GridPos pos,
  required MapEntityNpcMovementMode mode,
  List<GridPos> waypoints = const <GridPos>[],
}) {
  return MapEntity(
    id: id,
    kind: MapEntityKind.npc,
    pos: pos,
    npc: MapEntityNpcData(
      movement: MapEntityNpcMovementConfig(
        mode: mode,
        waypoints: waypoints,
      ),
    ),
  );
}

MapData _mapWithEntities(List<MapEntity> entities) {
  return MapData(
    id: 'map_test',
    name: 'Map Test',
    size: const GridSize(width: 20, height: 20),
    entities: entities,
  );
}

void main() {
  group('NPC waypoint placement mode', () {
    test('can activate and cancel placement mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithEntities(<MapEntity>[
        _npcEntity(
          id: 'npc_1',
          pos: const GridPos(x: 2, y: 2),
          mode: MapEntityNpcMovementMode.patrol,
        ),
      ]);
      notifier.state = EditorState(
        activeMap: map,
        selectedEntityId: 'npc_1',
      );

      expect(notifier.startNpcWaypointPlacementForSelectedEntity(), isTrue);
      expect(
        container.read(editorNotifierProvider).npcWaypointPlacementEntityId,
        'npc_1',
      );

      notifier.cancelNpcWaypointPlacement();
      expect(
        container.read(editorNotifierProvider).npcWaypointPlacementEntityId,
        isNull,
      );
    });

    test('map tap appends waypoint on targeted NPC', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithEntities(<MapEntity>[
        _npcEntity(
          id: 'npc_1',
          pos: const GridPos(x: 1, y: 1),
          mode: MapEntityNpcMovementMode.patrol,
        ),
        _npcEntity(
          id: 'npc_2',
          pos: const GridPos(x: 7, y: 7),
          mode: MapEntityNpcMovementMode.patrol,
        ),
      ]);
      notifier.state = EditorState(
        activeMap: map,
        selectedEntityId: 'npc_1',
      );
      expect(notifier.startNpcWaypointPlacementForSelectedEntity(), isTrue);

      expect(notifier.addNpcWaypointAt(const GridPos(x: 5, y: 6)), isTrue);

      final updatedMap = container.read(editorNotifierProvider).activeMap!;
      final npc1 = updatedMap.entities.firstWhere((e) => e.id == 'npc_1');
      final npc2 = updatedMap.entities.firstWhere((e) => e.id == 'npc_2');
      expect(
        npc1.npc!.movement.waypoints,
        contains(const GridPos(x: 5, y: 6)),
      );
      expect(npc2.npc!.movement.waypoints, isEmpty);
    });

    test('invalid placement context exits mode safely', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithEntities(<MapEntity>[
        _npcEntity(
          id: 'npc_1',
          pos: const GridPos(x: 2, y: 2),
          mode: MapEntityNpcMovementMode.patrol,
        ),
      ]);
      notifier.state = EditorState(
        activeMap: map,
        selectedEntityId: 'npc_1',
      );
      expect(notifier.startNpcWaypointPlacementForSelectedEntity(), isTrue);

      // Simule suppression/changement de contexte: entité ciblée introuvable.
      notifier.state = notifier.state.copyWith(
        activeMap: map.copyWith(entities: const <MapEntity>[]),
      );

      expect(notifier.addNpcWaypointAt(const GridPos(x: 3, y: 3)), isFalse);
      expect(
        container.read(editorNotifierProvider).npcWaypointPlacementEntityId,
        isNull,
      );
    });
  });
}
