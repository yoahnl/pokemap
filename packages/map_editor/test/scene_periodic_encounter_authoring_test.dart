import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/scene_periodic_encounter_authoring_gateway.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/periodic_encounter_authoring_panel.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets(
    'guided periodic encounter requires a label and consuming outcome',
    (tester) async {
      PeriodicEncounterDefinition? updated;
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: PeriodicEncounterAuthoringPanel(
              nodeId: 'battle',
              payload: SceneBattlePayload(battleKind: 'wild'),
              onUpdate:
                  ({
                    required nodeId,
                    required enabled,
                    required label,
                    required consumeOnOutcomes,
                  }) async {
                    updated = enabled
                        ? PeriodicEncounterDefinition(
                            rewardId: 'derived',
                            label: label,
                            consumeOnOutcomes: consumeOnOutcomes,
                          )
                        : null;
                    return true;
                  },
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('periodic-encounter-enabled')),
      );
      await tester.pump();
      for (final outcome in PeriodicEncounterOutcome.values) {
        expect(
          tester
              .widget<CheckboxListTile>(
                find.byKey(ValueKey('periodic-encounter-${outcome.name}')),
              )
              .value,
          isTrue,
        );
      }
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('periodic-encounter-apply')),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField), 'Visiteur du vendredi');
      for (final outcome in PeriodicEncounterOutcome.values) {
        final checkbox = tester.widget<CheckboxListTile>(
          find.byKey(ValueKey('periodic-encounter-${outcome.name}')),
        );
        checkbox.onChanged!(false);
        await tester.pump();
      }
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('periodic-encounter-apply')),
            )
            .onPressed,
        isNull,
      );
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('periodic-encounter-fled')),
          )
          .onChanged!(true);
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('periodic-encounter-apply')));
      await tester.pump();
      expect(updated?.label, 'Visiteur du vendredi');
      expect(updated?.consumeOnOutcomes, {PeriodicEncounterOutcome.fled});
      expect(find.textContaining('Défaite'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('periodic-encounter-defeat')),
        findsNothing,
      );
    },
  );

  for (final payload in [
    SceneBattlePayload(battleKind: 'trainer'),
    SceneBattlePayload(
      battleKind: 'wild',
      demonstration: SceneBattleDemonstration(
        playerTrainerId: 'guide',
        bagItems: [],
        choices: [SceneBattleDemonstrationChoice.fight(0)],
      ),
    ),
  ]) {
    testWidgets(
      'non-player wild battle has no periodic toggle ${payload.battleKind} demo=${payload.demonstration != null}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: PeriodicEncounterAuthoringPanel(
              nodeId: 'battle',
              payload: payload,
              onUpdate: null,
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('periodic-encounter-enabled')),
          findsNothing,
        );
      },
    );
  }

  for (final foreign in [0, 240]) {
    test(
      'canonical draft gateway preserves policy identity and graph with $foreign foreign scenes',
      () async {
        final battle = SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'wild',
            battleTemplateId: 'fixed',
          ),
        );
        final scene = SceneAsset(
          id: 'source',
          name: 'Source',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              battle,
              SceneNode(id: 'end', kind: SceneNodeKind.end),
              if (foreign > 0)
                SceneNode(
                  id: 'unrelated-item',
                  kind: SceneNodeKind.action,
                  payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.claimPeriodicReward(
                      definition: PeriodicItemRewardDefinition(
                        rewardId: 'fruit',
                        label: 'Fruit',
                        itemId: 'fruit',
                        quantity: 1,
                      ),
                    ),
                  ),
                ),
            ],
            edges: [
              SceneEdge(
                id: 'enter',
                fromNodeId: 'start',
                fromPortId: 'completed',
                toNodeId: 'battle',
                kind: SceneEdgeKind.defaultFlow,
              ),
              for (final port in ['victory', 'defeat'])
                SceneEdge(
                  id: port,
                  fromNodeId: 'battle',
                  fromPortId: port,
                  toNodeId: 'end',
                  kind: port == 'victory'
                      ? SceneEdgeKind.battleVictory
                      : SceneEdgeKind.battleDefeat,
                ),
            ],
          ),
        );
        final project = ProjectManifest(
          name: 'Periodic',
          maps: [],
          tilesets: [],
          scenes: [
            scene,
            for (var index = 0; index < foreign; index++)
              SceneAsset(
                id: 'foreign-$index',
                name: 'Foreign',
                graph: scene.graph,
              ),
          ],
          encounterTables: const [
            ProjectEncounterTable(
              id: 'fixed',
              name: 'Fixed',
              encounterKind: EncounterKind.walk,
              entries: [
                ProjectEncounterEntry(
                  speciesId: 'target',
                  minLevel: 2,
                  maxLevel: 2,
                ),
              ],
            ),
          ],
        );
        const gateway = ScenePeriodicEncounterAuthoringGateway();
        final updated = await gateway.updateDraft(
          project: project,
          sceneId: 'source',
          nodeId: 'battle',
          enabled: true,
          label: 'Rencontre',
          consumeOnOutcomes: {PeriodicEncounterOutcome.captured},
        );
        final first =
            updated.scenes.first.graph.nodes[1].payload as SceneBattlePayload;
        expect(first.periodicEncounter?.rewardId, isNotEmpty);
        final relabeled = await gateway.updateDraft(
          project: updated,
          sceneId: 'source',
          nodeId: 'battle',
          enabled: true,
          label: 'Autre nom',
          consumeOnOutcomes: {PeriodicEncounterOutcome.victory},
        );
        final second =
            relabeled.scenes.first.graph.nodes[1].payload as SceneBattlePayload;
        expect(
          second.periodicEncounter?.rewardId,
          first.periodicEncounter?.rewardId,
        );
        expect(second.battleTemplateId, first.battleTemplateId);
        final normalEdit = updateSceneBattlePayload(
          relabeled.scenes.first,
          nodeId: 'battle',
          battleKind: 'wild',
          battleTemplateId: 'fixed',
          defeatRecovery: SceneBattleDefeatRecovery.returnToRecoveryPoint,
        );
        expect(
          normalEdit.updatedPayload.periodicEncounter,
          second.periodicEncounter,
        );
        expect(updated.scenes.first.graph.edges, scene.graph.edges);
        expect(updated.scenes.skip(1), project.scenes.skip(1));
        expect(
          () => ProjectManifest.fromJson(updated.toJson()),
          returnsNormally,
        );
        await expectLater(
          gateway.updateDraft(
            project: updated,
            sceneId: 'source',
            nodeId: 'battle',
            enabled: true,
            label: 'Vide',
            consumeOnOutcomes: {},
          ),
          throwsArgumentError,
        );
        expect(project.scenes.first.graph.nodes[1].payload, battle.payload);
        final disabled = await gateway.updateDraft(
          project: updated,
          sceneId: 'source',
          nodeId: 'battle',
          enabled: false,
          label: '',
          consumeOnOutcomes: {},
        );
        expect(
          (disabled.scenes.first.graph.nodes[1].payload as SceneBattlePayload)
              .periodicEncounter,
          isNull,
        );
      },
    );
  }
}
