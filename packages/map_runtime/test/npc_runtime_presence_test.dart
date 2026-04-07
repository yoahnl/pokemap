import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../lib/src/application/npc_runtime_presence.dart';
import '../lib/src/application/step_studio_completion_runtime.dart';
import '../lib/src/application/step_studio_world_presence_runtime.dart';

const _stepStudioDoc = '''
{"schemaVersion":1,"steps":[
  {"id":"step_2_1","worldChanges":[
    {"mapId":"bourivka_center","entityId":"emma","presenceRule":"hiddenAfterStepCompletion"}
  ]}
]}''';

ProjectManifest _manifestWithGlobalStory() {
  return ProjectManifest(
    name: 't',
    maps: const [],
    tilesets: const [],
    scenarios: [
      ScenarioAsset(
        id: 'g',
        name: 'g',
        entryNodeId: 'start',
        scope: ScenarioScope.globalStory,
        nodes: const [],
        edges: const [],
        metadata: {kStepStudioDocumentMetadataKey: _stepStudioDoc},
      ),
    ],
  );
}

MapEntity _emmaOnBourivka() {
  return MapData(
    id: 'bourivka_center',
    name: 'Bourivka',
    size: const GridSize(width: 8, height: 8),
    layers: const <MapLayer>[
      MapLayer.collision(
        id: 'c',
        name: 'C',
        collisions: <bool>[],
      ),
    ],
    entities: const <MapEntity>[
      MapEntity(
        id: 'emma',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 3, y: 3),
        size: GridSize(width: 1, height: 1),
        npc: MapEntityNpcData(),
      ),
    ],
  ).entities.first;
}

void main() {
  group('isNpcRuntimePresentOnMap', () {
    final manifest = _manifestWithGlobalStory();
    final rules = buildStepStudioWorldPresenceRuleList(manifest.scenarios);
    final emma = _emmaOnBourivka();

    test('Emma présente avant complétion de la step (hiddenAfterStepCompletion)', () {
      final gs = const GameState(
        saveId: 's',
        progression: PlayerProgression(completedStepIds: []),
      );
      expect(
        isNpcRuntimePresentOnMap(
          gameState: gs,
          manifest: manifest,
          stepStudioWorldRules: rules,
          mapId: 'bourivka_center',
          entity: emma,
        ),
        isTrue,
      );
    });

    test('Emma absente après complétion — cas produit (Bourivka / emma)', () {
      final gs = const GameState(
        saveId: 's',
        progression: PlayerProgression(
          completedStepIds: <String>['step_2_1'],
        ),
      );
      expect(
        isNpcRuntimePresentOnMap(
          gameState: gs,
          manifest: manifest,
          stepStudioWorldRules: rules,
          mapId: 'bourivka_center',
          entity: emma,
        ),
        isFalse,
      );
    });

    test('GameplayWorldState reconstruit : toujours absent avec même prédicat', () {
      final map = MapData(
        id: 'bourivka_center',
        name: 'Bourivka',
        size: const GridSize(width: 8, height: 8),
        layers: const <MapLayer>[
          MapLayer.collision(
            id: 'c',
            name: 'C',
            collisions: <bool>[],
          ),
        ],
        entities: <MapEntity>[emma],
      );
      final gs = const GameState(
        saveId: 's',
        progression: PlayerProgression(
          completedStepIds: <String>['step_2_1'],
        ),
      );
      bool pred(String mapId, MapEntity e) => isNpcRuntimePresentOnMap(
            gameState: gs,
            manifest: manifest,
            stepStudioWorldRules: rules,
            mapId: mapId,
            entity: e,
          );

      final w1 = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
        project: manifest,
        npcMapPresencePredicate: pred,
      );
      expect(w1.entityAt(3, 3), isNull);
      expect(w1.isBlocked(3, 3), isFalse);

      final w2 = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 1, y: 0),
        project: manifest,
        npcMapPresencePredicate: pred,
      );
      expect(w2.entityAt(3, 3), isNull);
    });

    test('après sérialisation GameState : completedStepIds conservés → absent', () {
      final gs = const GameState(
        saveId: 's',
        progression: PlayerProgression(
          completedStepIds: <String>['step_2_1'],
        ),
      );
      final roundTrip = GameState.fromJson(gs.toJson());
      expect(
        isNpcRuntimePresentOnMap(
          gameState: roundTrip,
          manifest: manifest,
          stepStudioWorldRules: rules,
          mapId: 'bourivka_center',
          entity: emma,
        ),
        isFalse,
      );
    });

    test('visibilité de base false : absent sans évaluer Step Studio', () {
      final hiddenWhen = MapEntity(
        id: 'emma',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 3, y: 3),
        size: const GridSize(width: 1, height: 1),
        npc: MapEntityNpcData(
          visibilityRule: MapEntityNpcVisibilityRule(
            mode: MapEntityNpcVisibilityMode.visibleWhen,
            predicate: const MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'never_set',
            ),
          ),
        ),
      );
      final gs = const GameState(
        saveId: 's',
        progression: PlayerProgression(
          completedStepIds: <String>[],
        ),
      );
      expect(
        isNpcRuntimePresentOnMap(
          gameState: gs,
          manifest: manifest,
          stepStudioWorldRules: rules,
          mapId: 'bourivka_center',
          entity: hiddenWhen,
        ),
        isFalse,
      );
    });
  });
}
