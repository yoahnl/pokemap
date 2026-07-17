import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

const _portMapId = 'map_port_brisants';
const _marshMapId = 'map_marais_salants';
const _lysaEntityId = 'npc_lysa';
const _lysaEventId = 'evt_019abcde-4000-7000-8000-000000000001';
const _lysaSceneId = 'scene_lysa_port';
const _lysaDialogueId = 'dialogue_lysa_port';
const _lysaCinematicId = 'cinematic_lysa_port';
const _lysaTrainerId = 'trainer_lysa_port';
const _lysaFactId = 'fact_lysa_port_resolved';
const _lysaStepId = 'step_rival_battle';
const _lysaWorldRuleId = 'world_rule_lysa_port_resolved';
const _victoryOutcomeId = 'lysa.victory';
const _defeatOutcomeId = 'lysa.defeat';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('J4 Selbrume Lysa Golden Slice', () {
    for (final promoted in const <bool>[false, true]) {
      for (final battleOutcome in const <String>['victory', 'defeat']) {
        test(
          '${promoted ? 'promoted Selbrume' : 'versioned fixture'} $battleOutcome '
          'crosses Yarn, Cinematic, Battle, outcome and save/load',
          () async {
            final fixture = await _loadFixture(promoted: promoted);
            final dialogueText = await File(
              p.join(fixture.root.path, 'dialogues', 'lysa_port.yarn'),
            ).readAsString();
            expect(dialogueText, contains('title: LysaPort'));
            expect(dialogueText, contains('Port des Brisants'));

            var state = GameState(
              saveId: 'phase_j_lysa_$battleOutcome',
              currentMapId: _portMapId,
              playerPosition: const GridPos(x: 26, y: 17),
            );
            final transactions = NarrativeEventStateTransactions(state);
            final source = NarrativeEventSourceRef.entityInteract(
              _portMapId,
              _lysaEntityId,
            );
            final occurrence = NarrativeEventOccurrence(source: source);
            var dialogueCalls = 0;
            var cinematicCalls = 0;
            var battleCalls = 0;
            var legacyCalls = 0;
            var sequence = 0;
            final bridge = NarrativeSpatialProductionDispatchBridge(
              stateTransactions: transactions,
              currentGameState: () => state,
              onGameStateCommitted: (next) => state = next,
              prepareAuthority: (_, currentOccurrence) async {
                return NarrativeEventDispatchAuthority.prepare(
                  registryResult: fixture.snapshot.registryResult,
                  occurrence: currentOccurrence,
                  factResolver: fixture.snapshot.factResolver,
                  legacyClaimIndex: fixture.snapshot.legacyClaimIndex,
                  projectCatalog: fixture.snapshot.projectCatalog,
                );
              },
              executeScene: (request) async {
                final hostedBattleOutcomes = <NarrativeOutcomeRef>[];
                return executeNarrativeEventScene(
                  request: request,
                  project: fixture.snapshot.project,
                  mapsById: fixture.snapshot.mapsById,
                  currentGameState: () => state,
                  hostedBattleOutcomes: hostedBattleOutcomes,
                  callbacks: SceneRuntimeHostCallbacks(
                    evaluateCondition: (_) =>
                        throw StateError('No condition is expected.'),
                    showDialogue: (intent) {
                      dialogueCalls++;
                      expect(intent.dialogueId, _lysaDialogueId);
                      expect(intent.yarnNodeName, 'LysaPort');
                      return 'completed';
                    },
                    playCinematic: (intent) {
                      cinematicCalls++;
                      expect(intent.cinematicId, _lysaCinematicId);
                      return 'completed';
                    },
                    startBattle: (intent) {
                      battleCalls++;
                      expect(intent.battleKind, 'trainer');
                      expect(intent.trainerId, _lysaTrainerId);
                      hostedBattleOutcomes.add(
                        NarrativeOutcomeRef(
                          producerKind: NarrativeOutcomeProducerKind.battle,
                          producerId: 'trainer:$_lysaTrainerId',
                          outcomeId: battleOutcome,
                        ),
                      );
                      return battleOutcome;
                    },
                  ),
                );
              },
              legacyFallback: (_, __, ___) async => legacyCalls++,
              activityPort: NoopNarrativeEventActivityPort(),
              isCurrentOccurrence: (_) => true,
              executionIdFactory: () => _runtimeId('evx', ++sequence),
              correlationIdFactory: () => _runtimeId('corr', ++sequence),
              deliveryIdFactory: () => _runtimeId('outd', ++sequence),
            );

            final first = await bridge.dispatch(
              occurrenceId: 'phase-j-lysa-$battleOutcome-1',
              occurrence: occurrence,
            );
            expect(
              first,
              isA<NarrativeSpatialProductionDispatchV2Handled>(),
              reason: first is NarrativeSpatialProductionDispatchFailed
                  ? first.failure.toString()
                  : null,
            );
            expect(
              (first as NarrativeSpatialProductionDispatchV2Handled)
                  .execution
                  .eventId,
              _lysaEventId,
            );
            expect(dialogueCalls, 1);
            expect(cinematicCalls, 1);
            expect(battleCalls, 1);
            expect(legacyCalls, 0);
            expect(
              state.narrativeEventProgress.consumedNarrativeEventIds,
              contains(_lysaEventId),
            );

            final pendingOutcomes = state
                .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
                .map((delivery) => delivery.outcome)
                .toSet();
            expect(
              pendingOutcomes,
              contains(
                NarrativeOutcomeRef(
                  producerKind: NarrativeOutcomeProducerKind.battle,
                  producerId: 'trainer:$_lysaTrainerId',
                  outcomeId: battleOutcome,
                ),
              ),
            );
            expect(
              pendingOutcomes,
              contains(
                NarrativeOutcomeRef(
                  producerKind: NarrativeOutcomeProducerKind.scene,
                  producerId: _lysaSceneId,
                  outcomeId: battleOutcome == 'victory'
                      ? _victoryOutcomeId
                      : _defeatOutcomeId,
                ),
              ),
            );

            final factValue =
                state.narrativeFactRuntimeState.overridesByFactId[_lysaFactId];
            final projection = const RuntimeWorldRuleProjectionHook().resolve(
              project: fixture.snapshot.project,
              gameState: state,
              map: fixture.portBundle.map,
            );
            if (battleOutcome == 'victory') {
              expect(factValue, isTrue);
              expect(state.progression.completedStepIds, contains(_lysaStepId));
              expect(projection.hiddenEntityIds, contains(_lysaEntityId));
              expect(
                fixture.snapshot.project.worldRules.map((rule) => rule.id),
                contains(_lysaWorldRuleId),
              );
            } else {
              expect(factValue, isNot(true));
              expect(
                state.progression.completedStepIds,
                isNot(contains(_lysaStepId)),
              );
              expect(
                projection.hiddenEntityIds,
                isNot(contains(_lysaEntityId)),
              );
            }

            final callsBeforeReinteraction =
                dialogueCalls + cinematicCalls + battleCalls;
            final second = await bridge.dispatch(
              occurrenceId: 'phase-j-lysa-$battleOutcome-2',
              occurrence: occurrence,
            );
            expect(
              second,
              isA<NarrativeSpatialProductionDispatchLegacyFallback>(),
              reason: 'dualRead keeps the unrelated historical fallback path.',
            );
            expect(
              dialogueCalls + cinematicCalls + battleCalls,
              callsBeforeReinteraction,
              reason: 'The one-shot Event must not replay its Scene.',
            );
            expect(legacyCalls, 1);

            final encodedSave = jsonDecode(
              jsonEncode(saveDataFromGameState(state).toJson()),
            ) as Map<String, dynamic>;
            final reloaded = gameStateFromSaveData(
              SaveData.fromJson(encodedSave),
            );
            expect(
              reloaded.narrativeEventProgress.consumedNarrativeEventIds,
              contains(_lysaEventId),
            );
            expect(
              reloaded.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
              state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
            );
            expect(
              reloaded.narrativeFactRuntimeState.overridesByFactId[_lysaFactId],
              factValue,
            );
            expect(
              reloaded.progression.completedStepIds,
              state.progression.completedStepIds,
            );
          },
        );
      }
    }
  });
}

String _runtimeId(String prefix, int sequence) {
  final suffix = sequence.toString().padLeft(12, '0');
  return '${prefix}_019abcde-5000-7000-8000-$suffix';
}

Future<_GoldenFixture> _loadFixture({required bool promoted}) async {
  final root = promoted
      ? Directory(p.join(Directory.current.path, '..', '..', 'selbrume'))
      : Directory(
          p.join(
            Directory.current.path,
            'event_builder_v2_selbrume_slice',
          ),
        );
  final projectPath = p.join(root.path, 'project.json');
  final bundles = <String, RuntimeMapBundle>{};
  Future<RuntimeMapBundle> load(String mapId) async {
    return bundles[mapId] ??= await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: mapId,
    );
  }

  final portBundle = await load(_portMapId);
  await load(_marshMapId);
  final snapshot = await NarrativeEventRuntimeSnapshot.build(
    project: portBundle.manifest,
    loadMap: (mapId) async {
      final bundle = await load(mapId);
      return (project: bundle.manifest, map: bundle.map);
    },
  );
  return _GoldenFixture(
    root: root,
    portBundle: portBundle,
    snapshot: snapshot,
  );
}

final class _GoldenFixture {
  const _GoldenFixture({
    required this.root,
    required this.portBundle,
    required this.snapshot,
  });

  final Directory root;
  final RuntimeMapBundle portBundle;
  final NarrativeEventRuntimeSnapshot snapshot;
}
