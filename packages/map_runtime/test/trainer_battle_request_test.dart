import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/trainer_battle_request.dart';

void main() {
  group('buildTrainerBattleRequestFromNpc', () {
    final _testEntity = MapEntity(
      id: 'npc_trainer_1',
      name: 'Dresseur Test',
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 5, y: 5),
      size: const GridSize(width: 1, height: 1),
      npc: const MapEntityNpcData(
        displayName: 'Dresseur Test',
        trainerId: 'trainer_001',
      ),
    );

    final _testEntityNoTrainer = MapEntity(
      id: 'npc_civilian',
      name: 'Civilian',
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 6, y: 5),
      size: const GridSize(width: 1, height: 1),
      npc: const MapEntityNpcData(
        displayName: 'Civilian',
        trainerId: null,
      ),
    );

    final _testEntityEmptyTrainerId = MapEntity(
      id: 'npc_empty',
      name: 'Empty',
      kind: MapEntityKind.npc,
      pos: const GridPos(x: 7, y: 5),
      size: const GridSize(width: 1, height: 1),
      npc: const MapEntityNpcData(
        displayName: 'Empty',
        trainerId: '',
      ),
    );

    final _testManifest = ProjectManifest(
      name: 'Test',
      maps: [],
      tilesets: [],
      elements: [],
      trainers: [
      surfaceCatalog: ProjectSurfaceCatalog(),
        ProjectTrainerEntry(
          id: 'trainer_001',
          name: 'Dresseur 1',
          trainerClass: 'Dresseur',
          team: [],
        ),
      ],
    );

    final _testWorld = GameplayWorldState.initial(
      map: MapData(
        id: 'test_map',
        name: 'Test Map',
        size: const GridSize(width: 10, height: 10),
      ),
      playerPos: const GridPos(x: 4, y: 5),
    );

    test('returns TrainerBattleStartRequest for valid trainerId', () {
      final request = buildTrainerBattleRequestFromNpc(
        entity: _testEntity,
        manifest: _testManifest,
        world: _testWorld,
        createdAtEpochMs: 1234567890,
      );

      expect(request, isNotNull);
      expect(request!.trainerId, equals('trainer_001'));
      expect(request.npcEntityId, equals('npc_trainer_1'));
      expect(request.mapId, equals('test_map'));
      expect(request.kind, equals(RuntimeBattleKind.trainer));
      expect(request.source, equals(RuntimeBattleSourceKind.trainerInteraction));
    });

    test('returns null for NPC without trainerId', () {
      final request = buildTrainerBattleRequestFromNpc(
        entity: _testEntityNoTrainer,
        manifest: _testManifest,
        world: _testWorld,
      );

      expect(request, isNull);
    });

    test('returns null for NPC with empty trainerId', () {
      final request = buildTrainerBattleRequestFromNpc(
        entity: _testEntityEmptyTrainerId,
        manifest: _testManifest,
        world: _testWorld,
      );

      expect(request, isNull);
    });

    test('returns null for invalid trainerId not in manifest', () {
      final entityWithInvalidTrainer = MapEntity(
        id: 'npc_invalid',
        name: 'Invalid Trainer',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 8, y: 5),
        size: const GridSize(width: 1, height: 1),
        npc: const MapEntityNpcData(
          displayName: 'Invalid',
          trainerId: 'nonexistent_trainer',
        ),
      );

      final request = buildTrainerBattleRequestFromNpc(
        entity: entityWithInvalidTrainer,
        manifest: _testManifest,
        world: _testWorld,
      );

      expect(request, isNull);
    });

    test('request contains correct returnContext', () {
      final request = buildTrainerBattleRequestFromNpc(
        entity: _testEntity,
        manifest: _testManifest,
        world: _testWorld,
        createdAtEpochMs: 1234567890,
      );

      expect(request, isNotNull);
      expect(request!.returnContext.mapId, equals('test_map'));
      expect(request.returnContext.playerPos, equals(const GridPos(x: 4, y: 5)));
      expect(request.returnContext.playerFacing, equals(Direction.south));
    });

    test('request ID is deterministic with fixed createdAtEpochMs', () {
      final request1 = buildTrainerBattleRequestFromNpc(
        entity: _testEntity,
        manifest: _testManifest,
        world: _testWorld,
        createdAtEpochMs: 1234567890,
      );

      final request2 = buildTrainerBattleRequestFromNpc(
        entity: _testEntity,
        manifest: _testManifest,
        world: _testWorld,
        createdAtEpochMs: 1234567890,
      );

      expect(request1!.requestId, equals(request2!.requestId));
    });

    test('request ID changes with different createdAtEpochMs', () {
      final request1 = buildTrainerBattleRequestFromNpc(
        entity: _testEntity,
        manifest: _testManifest,
        world: _testWorld,
        createdAtEpochMs: 1234567890,
      );

      final request2 = buildTrainerBattleRequestFromNpc(
        entity: _testEntity,
        manifest: _testManifest,
        world: _testWorld,
        createdAtEpochMs: 1234567891,
      );

      expect(request1!.requestId, isNot(equals(request2!.requestId)));
    });
  });
}
