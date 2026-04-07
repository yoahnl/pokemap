import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../lib/src/application/step_studio_completion_runtime.dart';
import '../lib/src/application/step_studio_world_presence_runtime.dart';

MapData _mapWithEmma({required String mapId}) {
  return MapData(
    id: mapId,
    name: 'Test',
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
  );
}

void main() {
  group('buildStepStudioWorldPresenceRuleList', () {
    test('reads worldChanges nested under steps', () {
      const doc = '''
{"schemaVersion":1,"steps":[
  {"id":"step_2_1","worldChanges":[
    {"mapId":"bourivka_center","entityId":"emma","presenceRule":"hiddenAfterStepCompletion"}
  ]}
]}''';
      final scenarios = [
        ScenarioAsset(
          id: 'g',
          name: 'g',
          entryNodeId: 'start',
          scope: ScenarioScope.globalStory,
          nodes: const [],
          edges: const [],
          metadata: {kStepStudioDocumentMetadataKey: doc},
        ),
      ];
      final rules = buildStepStudioWorldPresenceRuleList(scenarios);
      expect(rules, hasLength(1));
      expect(rules.single.sourceStepId, 'step_2_1');
      expect(rules.single.mapId, 'bourivka_center');
      expect(rules.single.entityId, 'emma');
      expect(rules.single.presenceRule, StepStudioWorldPresenceRuleKind.hiddenAfterStepCompletion);
    });
  });

  group('entityPassesStepStudioWorldPresence', () {
    final rules = [
      const StepStudioWorldPresenceRule(
        mapId: 'bourivka_center',
        entityId: 'emma',
        sourceStepId: 'step_2_1',
        presenceRule: StepStudioWorldPresenceRuleKind.hiddenAfterStepCompletion,
      ),
    ];
    final emma = _mapWithEmma(mapId: 'bourivka_center').entities.first;

    test('Emma visible tant que la step n’est pas complétée', () {
      expect(
        entityPassesStepStudioWorldPresence(
          mapId: 'bourivka_center',
          entity: emma,
          completedStepIds: const <String>[],
          rules: rules,
        ),
        isTrue,
      );
    });

    test('Emma disparaît après completion de la step (cas produit)', () {
      expect(
        entityPassesStepStudioWorldPresence(
          mapId: 'bourivka_center',
          entity: emma,
          completedStepIds: const <String>['step_2_1'],
          rules: rules,
        ),
        isFalse,
      );
    });

    test('autre mapId : règle ignorée', () {
      expect(
        entityPassesStepStudioWorldPresence(
          mapId: 'other_map',
          entity: emma,
          completedStepIds: const <String>['step_2_1'],
          rules: rules,
        ),
        isTrue,
      );
    });
  });

  group('GameplayWorldState + prédicat (collision / entityAt)', () {
    test('PNJ exclu des caches quand world change masque après step', () {
      final map = _mapWithEmma(mapId: 'm1');
      final rules = [
        const StepStudioWorldPresenceRule(
          mapId: 'm1',
          entityId: 'emma',
          sourceStepId: 's_done',
          presenceRule: StepStudioWorldPresenceRuleKind.hiddenAfterStepCompletion,
        ),
      ];
      NpcMapPresencePredicate pred(Iterable<String> completed) {
        return (String mapId, MapEntity e) {
          return entityPassesStepStudioWorldPresence(
            mapId: mapId,
            entity: e,
            completedStepIds: completed,
            rules: rules,
          );
        };
      }

      final before = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
        npcMapPresencePredicate: pred(const []),
      );
      expect(before.entityAt(3, 3)?.id, 'emma');

      final after = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
        npcMapPresencePredicate: pred(const ['s_done']),
      );
      expect(after.entityAt(3, 3), isNull);
      expect(after.isBlocked(3, 3), isFalse);
    });

    test('visibleAfterStepCompletion : absent puis présent après step', () {
      final map = _mapWithEmma(mapId: 'm2');
      final rules = [
        const StepStudioWorldPresenceRule(
          mapId: 'm2',
          entityId: 'emma',
          sourceStepId: 's1',
          presenceRule: StepStudioWorldPresenceRuleKind.visibleAfterStepCompletion,
        ),
      ];
      NpcMapPresencePredicate pred(Iterable<String> completed) {
        return (String mapId, MapEntity e) {
          return entityPassesStepStudioWorldPresence(
            mapId: mapId,
            entity: e,
            completedStepIds: completed,
            rules: rules,
          );
        };
      }

      final hidden = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
        npcMapPresencePredicate: pred(const []),
      );
      expect(hidden.entityAt(3, 3), isNull);

      final shown = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
        npcMapPresencePredicate: pred(const ['s1']),
      );
      expect(shown.entityAt(3, 3)?.id, 'emma');
    });
  });

  group('presenceAllowedForStepStudioWorldRule', () {
    test('hiddenAfterStepCompletion == visibleBeforeStepCompletion pour le booléen', () {
      expect(
        presenceAllowedForStepStudioWorldRule(
          sourceStepCompleted: false,
          kind: StepStudioWorldPresenceRuleKind.hiddenAfterStepCompletion,
        ),
        presenceAllowedForStepStudioWorldRule(
          sourceStepCompleted: false,
          kind: StepStudioWorldPresenceRuleKind.visibleBeforeStepCompletion,
        ),
      );
      expect(
        presenceAllowedForStepStudioWorldRule(
          sourceStepCompleted: true,
          kind: StepStudioWorldPresenceRuleKind.hiddenAfterStepCompletion,
        ),
        false,
      );
    });
  });
}
