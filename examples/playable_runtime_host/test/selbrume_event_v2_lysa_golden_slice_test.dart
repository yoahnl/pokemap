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
const _victoryFollowupEventId = 'evt_019abcde-5000-7000-8000-000000000033';
const _defeatFollowupEventId = 'evt_019abcde-5000-7000-8000-000000000034';
const _defeatRetryEventId = 'evt_019abcde-5000-7000-8000-000000000041';
const _canonicalVictoryFactId = 'fact_rival_port_defeated';
const _canonicalDefeatFactId = 'fact_rival_port_lost_once';

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
              narrativeFactRuntimeState: promoted
                  ? NarrativeFactRuntimeState(
                      overridesByFactId: const <String, bool>{
                        'fact_port_alert_seen': true,
                      },
                    )
                  : const NarrativeFactRuntimeState.empty(),
            );
            final transactions = NarrativeEventStateTransactions(state);
            final source = NarrativeEventSourceRef.entityInteract(
              _portMapId,
              _lysaEntityId,
            );
            final occurrence = NarrativeEventOccurrence(source: source);
            final dialogueNodes = <String>[];
            final cinematicIds = <String>[];
            var battleCalls = 0;
            var legacyCalls = 0;
            var sequence = 0;
            final activityPort = NoopNarrativeEventActivityPort();

            Future<NarrativeSceneExecutionResult> executeScene(
              NarrativeSceneExecutionRequest request,
            ) async {
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
                    expect(intent.dialogueId, _lysaDialogueId);
                    dialogueNodes.add(intent.yarnNodeName!);
                    return promoted && intent.yarnNodeName == 'LysaPort'
                        ? 'confident'
                        : 'completed';
                  },
                  playCinematic: (intent) {
                    cinematicIds.add(intent.cinematicId!);
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
            }

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
              executeScene: executeScene,
              legacyFallback: (_, __, ___) async => legacyCalls++,
              activityPort: activityPort,
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
            expect(dialogueNodes, <String>['LysaPort']);
            expect(
              cinematicIds,
              <String>[
                promoted ? 'cinematic_rival_smiles' : _lysaCinematicId,
              ],
            );
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

            final pendingDeliveryIds = state
                .narrativeEventProgress.pendingNarrativeOutcomeDeliveries
                .map((delivery) => delivery.deliveryId)
                .toList(growable: false);
            final dispatchedOutcomeRefs = <NarrativeOutcomeRef>[];
            final followupEventIds = <String>[];
            if (promoted) {
              final processor = NarrativeOutcomeOutboxProcessor(
                stateTransactions: transactions,
                activityPort: activityPort,
                deliveryIdFactory: () => _runtimeId('outd', ++sequence),
                dispatcher: (request) async {
                  dispatchedOutcomeRefs.add(request.delivery.outcome);
                  final preparation = NarrativeEventDispatchAuthority.prepare(
                    registryResult: fixture.snapshot.registryResult,
                    occurrence: request.occurrence,
                    factResolver: fixture.snapshot.factResolver,
                    legacyClaimIndex: fixture.snapshot.legacyClaimIndex,
                    projectCatalog: fixture.snapshot.projectCatalog,
                  );
                  if (preparation is NarrativeEventDispatchAuthorityBlocked) {
                    return NarrativeOutcomeDispatchResult
                        .infrastructureFailureBeforePlanning(
                      StateError(
                        'Outcome authority blocked: '
                        '${preparation.reason.name}.',
                      ),
                    );
                  }
                  final coordinator = NarrativeEventExecutionCoordinator(
                    stateTransactions: transactions,
                    planner: NarrativeEventDispatchPlanner(),
                    executeScene: executeScene,
                    activityPort: activityPort,
                    executionIdFactory: () => _runtimeId('evx', ++sequence),
                    correlationIdFactory: () => _runtimeId('corr', ++sequence),
                    deliveryIdFactory: () => _runtimeId('outd', ++sequence),
                  );
                  final execution = await coordinator.execute(
                    authority:
                        preparation as NarrativeEventDispatchAuthorityReady,
                  );
                  if (execution is NarrativeEventExecutionSucceeded) {
                    followupEventIds.add(execution.eventId);
                    return NarrativeOutcomeDispatchResult.delivered(
                      updatedGameState: execution.updatedGameState,
                      causationExecutionId: execution.executionId,
                    );
                  }
                  if (execution
                          is NarrativeEventExecutionClaimedButIneligible ||
                      execution is NarrativeEventExecutionNoMatch) {
                    return NarrativeOutcomeDispatchResult.delivered(
                      updatedGameState: request.gameState,
                    );
                  }
                  if (execution is NarrativeEventExecutionFailed) {
                    return NarrativeOutcomeDispatchResult.terminalFailure(
                      execution.failure,
                    );
                  }
                  final cancelled =
                      execution as NarrativeEventExecutionCancelled;
                  return NarrativeOutcomeDispatchResult.terminalFailure(
                    cancelled.reason ??
                        StateError('Outcome Scene was cancelled.'),
                  );
                },
              );

              while (true) {
                final result = await processor.processNext();
                if (result is NarrativeOutcomeOutboxEmpty) {
                  break;
                }
                expect(result, isA<NarrativeOutcomeOutboxDelivered>());
                if (result is! NarrativeOutcomeOutboxDelivered) {
                  fail('Promoted outcome outbox did not deliver: $result');
                }
                state = result.updatedGameState;
              }
              state = await transactions.read();

              expect(
                dispatchedOutcomeRefs,
                <NarrativeOutcomeRef>[
                  NarrativeOutcomeRef(
                    producerKind: NarrativeOutcomeProducerKind.battle,
                    producerId: 'trainer:$_lysaTrainerId',
                    outcomeId: battleOutcome,
                  ),
                  NarrativeOutcomeRef(
                    producerKind: NarrativeOutcomeProducerKind.scene,
                    producerId: _lysaSceneId,
                    outcomeId: battleOutcome == 'victory'
                        ? _victoryOutcomeId
                        : _defeatOutcomeId,
                  ),
                ],
              );
              expect(
                followupEventIds,
                <String>[
                  battleOutcome == 'victory'
                      ? _victoryFollowupEventId
                      : _defeatFollowupEventId,
                ],
              );
              expect(
                state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
                isEmpty,
              );
              expect(
                state.narrativeEventProgress
                    .deliveredNarrativeOutcomeDeliveryIds,
                pendingDeliveryIds.toSet(),
              );
              expect(
                state.narrativeEventProgress.consumedNarrativeEventIds,
                contains(followupEventIds.single),
              );
            }

            final factValue =
                state.narrativeFactRuntimeState.overridesByFactId[_lysaFactId];
            final projection = const RuntimeWorldRuleProjectionHook().resolve(
              project: fixture.snapshot.project,
              gameState: state,
              map: fixture.portBundle.map,
            );
            if (promoted) {
              expect(
                dialogueNodes,
                <String>[
                  'LysaPort',
                  battleOutcome == 'victory'
                      ? 'RivalAfterWin'
                      : 'RivalAfterLoss',
                ],
              );
              expect(
                cinematicIds,
                battleOutcome == 'victory'
                    ? <String>[
                        'cinematic_rival_smiles',
                        'cinematic_rival_smiles',
                        'cinematic_rival_depart_win',
                      ]
                    : <String>[
                        'cinematic_rival_smiles',
                        'cinematic_rival_teases',
                        'cinematic_rival_depart_loss',
                      ],
              );
              expect(
                state.narrativeFactRuntimeState
                    .overridesByFactId['fact_lysa_tone_confident'],
                isTrue,
              );
              expect(
                state.narrativeFactRuntimeState
                    .overridesByFactId['fact_lysa_goes_ahead'],
                isTrue,
              );
              expect(factValue, isNot(true));
              expect(
                state.progression.completedStepIds,
                contains(_lysaStepId),
              );
              expect(
                fixture.snapshot.project.worldRules.map((rule) => rule.id),
                contains(_lysaWorldRuleId),
              );
              if (battleOutcome == 'victory') {
                expect(
                  state.narrativeFactRuntimeState
                      .overridesByFactId[_canonicalVictoryFactId],
                  isTrue,
                );
                expect(
                  state.narrativeFactRuntimeState
                      .overridesByFactId['fact_lysa_respects_player'],
                  isTrue,
                );
                expect(
                  state.narrativeFactRuntimeState
                      .overridesByFactId[_canonicalDefeatFactId],
                  isNot(true),
                );
                expect(projection.hiddenEntityIds, contains(_lysaEntityId));
              } else {
                expect(
                  state.narrativeFactRuntimeState
                      .overridesByFactId[_canonicalDefeatFactId],
                  isTrue,
                );
                expect(
                  state.narrativeFactRuntimeState
                      .overridesByFactId[_canonicalVictoryFactId],
                  isNot(true),
                );
                expect(
                  state.narrativeFactRuntimeState
                      .overridesByFactId['fact_lysa_respects_player'],
                  isNot(true),
                );
                expect(
                  projection.hiddenEntityIds,
                  isNot(contains(_lysaEntityId)),
                );
                expect(
                  projection.dialogueOverrideForEntity(_lysaEntityId),
                  'dialogue_lysa_after_loss',
                );
              }
            } else if (battleOutcome == 'victory') {
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
                dialogueNodes.length + cinematicIds.length + battleCalls;
            final second = await bridge.dispatch(
              occurrenceId: 'phase-j-lysa-$battleOutcome-2',
              occurrence: occurrence,
            );
            if (promoted && battleOutcome == 'defeat') {
              expect(
                second,
                isA<NarrativeSpatialProductionDispatchV2Handled>(),
              );
              expect(
                (second as NarrativeSpatialProductionDispatchV2Handled)
                    .execution
                    .eventId,
                _defeatRetryEventId,
              );
              expect(
                dialogueNodes.length + cinematicIds.length + battleCalls,
                callsBeforeReinteraction + 3,
                reason: 'The reusable retry Event must replay the Lysa Scene.',
              );
              expect(legacyCalls, 0);
            } else {
              expect(
                second,
                isA<NarrativeSpatialProductionDispatchLegacyFallback>(),
                reason:
                    'dualRead keeps the unrelated historical fallback path.',
              );
              expect(
                dialogueNodes.length + cinematicIds.length + battleCalls,
                callsBeforeReinteraction,
                reason: 'The one-shot Event must not replay its Scene.',
              );
              expect(legacyCalls, 1);
            }

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
              reloaded.narrativeEventProgress,
              state.narrativeEventProgress,
            );
            expect(
              reloaded.narrativeFactRuntimeState,
              state.narrativeFactRuntimeState,
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
