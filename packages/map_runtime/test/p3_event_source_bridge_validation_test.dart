import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 event source bridge validation', () {
    test('dispatches each runtime source to only its matching disk scenario',
        () async {
      final bundle = await _loadBundle();

      expect(bundle.map.id, _mapId);
      expect(
        bundle.manifest.scenarios.map((scenario) => scenario.id),
        containsAll(_allScenarioIds),
      );

      for (final bridgeCase in _positiveCases) {
        final result = _dispatch(bundle, bridgeCase.sourceEvent);

        expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
        expect(result.scenarioId, bridgeCase.scenarioId);
        expect(result.sourceNodeId, bridgeCase.sourceNodeId);
        expect(result.state.storyFlags.activeFlags, contains(bridgeCase.flag));

        for (final otherFlag
            in _allFlags.where((flag) => flag != bridgeCase.flag)) {
          expect(
              result.state.storyFlags.activeFlags, isNot(contains(otherFlag)));
        }
      }
    });

    test('does not dispatch runtime sources with mismatched identifiers',
        () async {
      final bundle = await _loadBundle();

      final negativeSources = <ScenarioRuntimeSourceEvent>[
        ScenarioRuntimeSourceEvent.mapEnter(mapId: 'p3_wrong_map'),
        ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: _mapId,
          triggerId: 'p3_wrong_trigger',
        ),
        ScenarioRuntimeSourceEvent.entityInteract(
          mapId: _mapId,
          entityId: 'p3_wrong_npc',
        ),
        ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'p3.source.wrong_outcome',
        ),
      ];

      for (final sourceEvent in negativeSources) {
        final result = _dispatch(bundle, sourceEvent);

        expect(result.status, ScenarioRuntimeExecutionStatus.noMatchingSource);
        expect(result.scenarioId, isNull);
        expect(result.state.storyFlags.activeFlags, isEmpty);
      }
    });
  });
}

const _mapId = 'p3_event_source_map';

const _allFlags = <String>[
  'p3.source.map_enter.executed',
  'p3.source.trigger_enter.executed',
  'p3.source.entity_interact.executed',
  'p3.source.outcome_received.executed',
];

const _allScenarioIds = <String>[
  'p3_source_map_enter_scenario',
  'p3_source_trigger_enter_scenario',
  'p3_source_entity_interact_scenario',
  'p3_source_outcome_received_scenario',
];

final _positiveCases = <_BridgeCase>[
  _BridgeCase(
    sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: _mapId),
    scenarioId: 'p3_source_map_enter_scenario',
    sourceNodeId: 'p3_map_enter_source',
    flag: 'p3.source.map_enter.executed',
  ),
  _BridgeCase(
    sourceEvent: ScenarioRuntimeSourceEvent.triggerEnter(
      mapId: _mapId,
      triggerId: 'p3_test_trigger',
    ),
    scenarioId: 'p3_source_trigger_enter_scenario',
    sourceNodeId: 'p3_trigger_enter_source',
    flag: 'p3.source.trigger_enter.executed',
  ),
  _BridgeCase(
    sourceEvent: ScenarioRuntimeSourceEvent.entityInteract(
      mapId: _mapId,
      entityId: 'p3_test_npc',
    ),
    scenarioId: 'p3_source_entity_interact_scenario',
    sourceNodeId: 'p3_entity_interact_source',
    flag: 'p3.source.entity_interact.executed',
  ),
  _BridgeCase(
    sourceEvent: ScenarioRuntimeSourceEvent.outcomeReceived(
      outcomeId: 'p3.source.previous_outcome',
    ),
    scenarioId: 'p3_source_outcome_received_scenario',
    sourceNodeId: 'p3_outcome_received_source',
    flag: 'p3.source.outcome_received.executed',
  ),
];

Future<RuntimeMapBundle> _loadBundle() {
  final projectFilePath = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'p3_event_source_bridge',
    'project.json',
  );

  return loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: _mapId,
  );
}

_DispatchResult _dispatch(
  RuntimeMapBundle bundle,
  ScenarioRuntimeSourceEvent sourceEvent,
) {
  var state = const GameState(saveId: 'p3-event-source-bridge');
  final result = const ScenarioRuntimeExecutor().dispatch(
    scenarios: bundle.manifest.scenarios,
    sourceEvent: sourceEvent,
    context: ScenarioRuntimeExecutionContext(
      gameState: state,
      onGameStateUpdated: (next) => state = next,
      openDialogue: (_, {startNode, runtimeSourceId}) => false,
      runScript: (_, {startNode, runtimeSourceId}) => false,
      showMessage: (_) {},
    ),
  );

  return _DispatchResult(result: result, state: state);
}

class _BridgeCase {
  const _BridgeCase({
    required this.sourceEvent,
    required this.scenarioId,
    required this.sourceNodeId,
    required this.flag,
  });

  final ScenarioRuntimeSourceEvent sourceEvent;
  final String scenarioId;
  final String sourceNodeId;
  final String flag;
}

class _DispatchResult {
  const _DispatchResult({
    required this.result,
    required this.state,
  });

  final ScenarioRuntimeExecutionResult result;
  final GameState state;

  ScenarioRuntimeExecutionStatus get status => result.status;
  String? get scenarioId => result.scenarioId;
  String? get sourceNodeId => result.sourceNodeId;
}
