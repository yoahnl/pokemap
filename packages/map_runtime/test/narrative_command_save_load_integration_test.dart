import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final sourceCommand in <SceneInteractiveCommand>[
    SceneInteractiveCommand.warp(
      destinationMapId: 'map.lighthouse',
      warpId: 'warp.door',
    ),
    SceneInteractiveCommand.openShop(shopId: 'shop.lighthouse'),
    SceneInteractiveCommand.openPc(storageId: 'pc.main'),
  ]) {
    test('${sourceCommand.kind.name} survives save/load and resumes once',
        () async {
      final encoded = jsonEncode(_scene(sourceCommand).toJson());
      final loaded = SceneAsset.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      var executions = 0;
      Future<String> complete(SceneInteractiveCommand _) async {
        executions += 1;
        return 'completed';
      }

      final interactive = SceneInteractiveCommandRuntimeExecutor(
        warp: complete,
        openShop: complete,
        openPc: complete,
      );
      final plan = buildSceneRuntimePlan(loaded).plan!;

      final result = await SceneRuntimeExecutor(
        callbacks: SceneRuntimeExecutionCallbacks(
          evaluateCondition: (_) => 'false',
          showDialogue: (_) => 'completed',
          startBattle: (_) => 'victory',
          playCinematic: (_) => 'completed',
          applyConsequence: (_) => 'completed',
          executeInteractiveCommand: interactive.execute,
        ),
      ).execute(plan);

      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(executions, 1);
      final resumed = await SceneRuntimeExecutor(
        callbacks: SceneRuntimeExecutionCallbacks(
          evaluateCondition: (_) => 'false',
          showDialogue: (_) => 'completed',
          startBattle: (_) => 'victory',
          playCinematic: (_) => 'completed',
          applyConsequence: (_) => 'completed',
          executeInteractiveCommand: interactive.execute,
        ),
      ).execute(plan, context: result.context);
      expect(resumed.status, SceneRuntimeExecutionStatus.completed);
      expect(executions, 1,
          reason: 'The durable command receipt prevents replay.');
      final loadedCommand =
          (loaded.graph.nodes[1].payload as SceneActionPayload)
              .interactiveCommand;
      expect(loadedCommand, sourceCommand);
    });
  }

  test('canonical gameplay consequences survive GameState save/load', () {
    const state = GameState(
      saveId: 'canonical-consequences',
      trainerProfile: TrainerProfile(name: 'Leaf'),
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            currentHp: 2,
          ),
        ],
      ),
    );
    const writer = SceneConsequenceRuntimeWriter(
      project: ProjectManifest(
        name: 'Canonical consequences',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        badges: <BadgeDefinition>[
          BadgeDefinition(id: 'badge_tide', label: 'Badge Marée'),
        ],
      ),
      maxHpByPartyIndex: <int, int>{0: 24},
    );
    final consequences = <SceneConsequence>[
      SceneConsequence.healParty(),
      SceneConsequence.awardBadge(badgeId: 'badge_tide'),
      SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
    ];

    final applied = writer.applyAll(state, consequences);
    final restored = gameStateFromSaveData(
      SaveData.fromJson(
        jsonDecode(
                jsonEncode(saveDataFromGameState(applied.gameState).toJson()))
            as Map<String, dynamic>,
      ),
    );
    final replayed = writer.applyAll(restored, consequences);

    expect(restored.party.members.single.currentHp, 24);
    expect(restored.trainerProfile.badgeIds, <String>['badge_tide']);
    expect(
      restored.progression.unlockedFieldAbilities,
      <FieldAbility>[FieldAbility.surf],
    );
    expect(replayed.gameState, restored);
  });
}

SceneAsset _scene(SceneInteractiveCommand command) => SceneAsset(
      id: 'scene.lighthouse',
      name: 'Entrée du phare',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'warp',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.interactive(
              command,
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start-warp',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'warp',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'warp-end',
            fromNodeId: 'warp',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );
