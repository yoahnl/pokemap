import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

const _retryCases = <_LighthouseRetryCase>[
  _LighthouseRetryCase(
    label: 'first lighthouse guardian',
    eventId: 'evt_019abcde-5000-7000-8000-000000000026',
    mapId: 'map_phare_interieur',
    triggerId: 'tr_phare_guardian_1',
    prerequisiteFacts: <String>{'fact_lighthouse_old_note_read'},
    expectedVictoryFacts: <String>{
      'fact_lighthouse_guardian_1_defeated',
    },
  ),
  _LighthouseRetryCase(
    label: 'second lighthouse guardian',
    eventId: 'evt_019abcde-5000-7000-8000-000000000027',
    mapId: 'map_phare_interieur',
    triggerId: 'tr_phare_guardian_2',
    prerequisiteFacts: <String>{
      'fact_lighthouse_old_note_read',
      'fact_lighthouse_guardian_1_defeated',
    },
    expectedVictoryFacts: <String>{
      'fact_lighthouse_guardian_2_defeated',
      'fact_lighthouse_top_unlocked',
    },
    expectedCompletedSteps: <String>{'step_climb_lighthouse'},
  ),
  _LighthouseRetryCase(
    label: 'lighthouse boss',
    eventId: 'evt_019abcde-5000-7000-8000-000000000028',
    mapId: 'map_sommet_phare',
    triggerId: 'tr_sommet_confrontation',
    prerequisiteFacts: <String>{
      'fact_lighthouse_top_unlocked',
      'fact_lighthouse_guardian_2_defeated',
    },
    expectedVictoryFacts: <String>{
      'fact_lighthouse_pokemon_appeased',
      'fact_mist_source_resolved',
    },
    expectedCompletedSteps: <String>{'step_final_confrontation'},
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Selbrume lighthouse defeat retry regression', () {
    late NarrativeEventRuntimeSnapshot snapshot;

    setUpAll(() async {
      snapshot = await _loadSelbrumeSnapshot();
    });

    for (final testCase in _retryCases) {
      test(
        '${testCase.label} supports defeat, reload, retry, victory, and reload',
        () async {
          var state = GameState(
            saveId: 'selbrume_retry_${testCase.eventId}',
            currentMapId: testCase.mapId,
            narrativeFactRuntimeState: NarrativeFactRuntimeState(
              overridesByFactId: <String, bool>{
                for (final factId in testCase.prerequisiteFacts) factId: true,
              },
            ),
          );
          var sequence = 0;
          var battleCalls = 0;

          Future<NarrativeSpatialProductionDispatchResult> dispatch(
            String battleOutcome,
          ) async {
            // A fresh transaction boundary mirrors leaving and re-entering the
            // trigger after a battle or a save reload. It also prevents this
            // regression test from accidentally relying on in-memory bridge
            // state that is not serialized by the real save contract.
            final transactions = NarrativeEventStateTransactions(state);
            final source = NarrativeEventSourceRef.triggerEnter(
              testCase.mapId,
              testCase.triggerId,
            );
            final bridge = NarrativeSpatialProductionDispatchBridge(
              stateTransactions: transactions,
              currentGameState: () => state,
              onGameStateCommitted: (next) => state = next,
              prepareAuthority: (_, occurrence) async {
                return NarrativeEventDispatchAuthority.prepare(
                  registryResult: snapshot.registryResult,
                  occurrence: occurrence,
                  factResolver: snapshot.factResolver,
                  legacyClaimIndex: snapshot.legacyClaimIndex,
                  projectCatalog: snapshot.projectCatalog,
                );
              },
              executeScene: (request) {
                return executeNarrativeEventScene(
                  request: request,
                  project: snapshot.project,
                  mapsById: snapshot.mapsById,
                  currentGameState: () => state,
                  callbacks: SceneRuntimeHostCallbacks(
                    evaluateCondition: (intent) => _resolveConditionOutput(
                      snapshot.project,
                      state,
                      intent,
                    ),
                    showDialogue: (_) => 'completed',
                    playCinematic: (_) => 'completed',
                    startBattle: (_) {
                      battleCalls++;
                      return battleOutcome;
                    },
                  ),
                );
              },
              legacyFallback: (_, __, ___) async {},
              activityPort: NoopNarrativeEventActivityPort(),
              isCurrentOccurrence: (_) => true,
              executionIdFactory: () => _runtimeId('evx', ++sequence),
              correlationIdFactory: () => _runtimeId('corr', ++sequence),
              deliveryIdFactory: () => _runtimeId('outd', ++sequence),
            );

            final result = await bridge.dispatch(
              occurrenceId: 'retry-${testCase.triggerId}-${++sequence}',
              occurrence: NarrativeEventOccurrence(source: source),
            );
            expect(await transactions.read(), state);
            return result;
          }

          final defeat = await dispatch('defeat');
          _expectHandled(defeat, testCase.eventId);
          expect(battleCalls, 1);
          for (final factId in testCase.expectedVictoryFacts) {
            expect(
              state.narrativeFactRuntimeState.overridesByFactId[factId],
              isNot(isTrue),
              reason: 'A defeat must not grant victory Fact $factId.',
            );
          }
          for (final stepId in testCase.expectedCompletedSteps) {
            expect(
              state.progression.completedStepIds,
              isNot(contains(stepId)),
              reason: 'A defeat must not complete victory step $stepId.',
            );
          }
          expect(
            state.narrativeEventProgress.consumedNarrativeEventIds,
            isNot(contains(testCase.eventId)),
            reason: 'A defeated lighthouse encounter must remain retryable.',
          );

          state = _roundTrip(state);
          expect(
            state.narrativeEventProgress.consumedNarrativeEventIds,
            isNot(contains(testCase.eventId)),
            reason: 'Retry eligibility must survive save/load after defeat.',
          );

          final victory = await dispatch('victory');
          _expectHandled(victory, testCase.eventId);
          expect(battleCalls, 2);
          for (final factId in testCase.expectedVictoryFacts) {
            expect(
              state.narrativeFactRuntimeState.overridesByFactId[factId],
              isTrue,
              reason: '$factId must be applied by the victory branch.',
            );
          }
          expect(
            state.progression.completedStepIds,
            containsAll(testCase.expectedCompletedSteps),
          );

          state = _roundTrip(state);
          final stateAfterVictoryReload = saveDataFromGameState(state).toJson();
          final battleCallsBeforeReentry = battleCalls;
          final postVictoryReentry = await dispatch('victory');

          expect(
            postVictoryReentry,
            isA<NarrativeSpatialProductionDispatchLegacyFallback>(),
            reason: 'The negative victory Fact prevents Event V2 replay; '
                'the reserved custom trigger then reaches its state-neutral '
                'legacy fallback.',
          );
          expect(battleCalls, battleCallsBeforeReentry);
          expect(
            saveDataFromGameState(state).toJson(),
            stateAfterVictoryReload,
            reason: 'Re-entering a completed encounter must be state-neutral.',
          );
        },
      );
    }
  });
}

void _expectHandled(
  NarrativeSpatialProductionDispatchResult result,
  String eventId,
) {
  if (result
      case NarrativeSpatialProductionDispatchFailed(
        :final failure,
        :final stackTrace,
      )) {
    fail('Lighthouse dispatch failed: $failure\n$stackTrace');
  }
  expect(result, isA<NarrativeSpatialProductionDispatchV2Handled>());
  expect(
    (result as NarrativeSpatialProductionDispatchV2Handled).execution.eventId,
    eventId,
  );
}

Future<NarrativeEventRuntimeSnapshot> _loadSelbrumeSnapshot() async {
  final root = _findRepositoryRoot();
  final projectPath = p.join(root.path, 'selbrume', 'project.json');
  final project = ProjectManifest.fromJson(
    _readJson(File(projectPath)),
  );
  return NarrativeEventRuntimeSnapshot.build(
    project: project,
    loadMap: (mapId) async {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: mapId,
      );
      return (project: bundle.manifest, map: bundle.map);
    },
  );
}

GameState _roundTrip(GameState state) {
  final serialized = jsonDecode(
    jsonEncode(saveDataFromGameState(state).toJson()),
  ) as Map<String, dynamic>;
  return gameStateFromSaveData(SaveData.fromJson(serialized));
}

String _resolveConditionOutput(
  ProjectManifest project,
  GameState state,
  SceneRuntimePlanIntent intent,
) {
  final source = intent.conditionSource;
  if (source == null) {
    throw StateError('Scene condition intent is missing a condition source.');
  }
  if (source.sourceKind == SceneConditionSourceKind.fact) {
    final matched = evaluateCanonicalNarrativeFactSceneCondition(
      source: source,
      gameState: state,
      resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
    );
    return matched ? 'true' : 'false';
  }
  throw UnsupportedError(
    'Condition source ${source.sourceKind.name} is outside this retry test.',
  );
}

String _runtimeId(String prefix, int sequence) {
  final suffix = sequence.toString().padLeft(12, '0');
  return '${prefix}_019abcde-7000-7000-8000-$suffix';
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

final class _LighthouseRetryCase {
  const _LighthouseRetryCase({
    required this.label,
    required this.eventId,
    required this.mapId,
    required this.triggerId,
    required this.prerequisiteFacts,
    required this.expectedVictoryFacts,
    this.expectedCompletedSteps = const <String>{},
  });

  final String label;
  final String eventId;
  final String mapId;
  final String triggerId;
  final Set<String> prerequisiteFacts;
  final Set<String> expectedVictoryFacts;
  final Set<String> expectedCompletedSteps;
}
