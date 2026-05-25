import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 ScenarioAsset runtime golden path', () {
    test('loads a disk project and executes its embedded ScenarioAsset',
        () async {
      final projectFilePath = p.join(
        Directory.current.path,
        'test',
        'fixtures',
        'p3_scenario_runtime_golden_path',
        'project.json',
      );

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'p3_test_map',
      );

      expect(bundle.map.id, 'p3_test_map');
      expect(bundle.manifest.scenarios, hasLength(1));

      final scenario = bundle.manifest.scenarios.single;
      expect(scenario.id, 'p3_test_scenario');
      expect(scenario.entryNodeId, 'p3_start');
      expect(scenario.declaredOutcomes, contains('p3.outcome.done'));

      var state = const GameState(saveId: 'p3-scenario-runtime-golden-path');
      final result = const ScenarioRuntimeExecutor().dispatch(
        scenarios: bundle.manifest.scenarios,
        sourceEvent: ScenarioRuntimeSourceEvent.mapEnter(mapId: 'p3_test_map'),
        context: ScenarioRuntimeExecutionContext(
          gameState: state,
          onGameStateUpdated: (next) => state = next,
          openDialogue: (_, {startNode, runtimeSourceId}) => false,
          runScript: (_, {startNode, runtimeSourceId}) => false,
          showMessage: (_) {},
        ),
      );

      expect(result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(result.scenarioId, 'p3_test_scenario');
      expect(result.sourceNodeId, 'p3_test_source');
      expect(result.stopNodeId, 'p3_end');

      expect(state.storyFlags.activeFlags, contains('p3.flag.executed'));
      expect(
        state.progression.completedStepIds,
        contains('p3.step.completed'),
      );
      expect(
        state.storyFlags.activeFlags,
        contains(scenarioOutcomeFlagName('p3.outcome.done')),
      );
    });
  });
}
