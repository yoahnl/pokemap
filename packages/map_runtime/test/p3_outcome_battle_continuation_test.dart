import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P3 outcome and battle outcome continuation', () {
    test('emits a scenario outcome and reaches a sourceOutcome continuation',
        () async {
      final bundle = await _loadBundle();

      expect(
        bundle.manifest.scenarios.map((scenario) => scenario.id),
        containsAll(<String>[
          _outcomeEmitterScenarioId,
          _outcomeReceiverScenarioId,
        ]),
      );

      final dispatch = _dispatch(
        bundle,
        ScenarioRuntimeSourceEvent.mapEnter(mapId: _mapId),
      );

      expect(dispatch.result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(dispatch.result.emittedOutcomeId, _outcomeId);
      expect(dispatch.result.scenarioId, _outcomeReceiverScenarioId);
      expect(dispatch.result.sourceNodeId, 'p3_outcome_receiver_source');
      expect(
        dispatch.state.storyFlags.activeFlags,
        contains(scenarioOutcomeFlagName(_outcomeId)),
      );
      expect(
        dispatch.state.storyFlags.activeFlags,
        contains('p3.outcome.emitted'),
      );
      expect(
        dispatch.state.storyFlags.activeFlags,
        contains('p3.outcome.received'),
      );
    });

    test('dispatches explicit outcomeReceived and ignores unknown outcomes',
        () async {
      final bundle = await _loadBundle();

      final explicit = _dispatch(
        bundle,
        ScenarioRuntimeSourceEvent.outcomeReceived(outcomeId: _outcomeId),
      );

      expect(explicit.result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(explicit.result.scenarioId, _outcomeReceiverScenarioId);
      expect(
        explicit.state.storyFlags.activeFlags,
        contains('p3.outcome.received'),
      );
      expect(
        explicit.state.storyFlags.activeFlags,
        isNot(contains(scenarioOutcomeFlagName(_outcomeId))),
      );

      final unknown = _dispatch(
        bundle,
        ScenarioRuntimeSourceEvent.outcomeReceived(
          outcomeId: 'p3.outcome.unknown',
        ),
      );

      expect(unknown.result.status,
          ScenarioRuntimeExecutionStatus.noMatchingSource);
      expect(unknown.state.storyFlags.activeFlags, isEmpty);
    });

    test('starts a trainer battle and exposes battle handoff data', () async {
      final bundle = await _loadBundle();

      final dispatch = _dispatch(
        bundle,
        ScenarioRuntimeSourceEvent.entityInteract(
          mapId: _mapId,
          entityId: _npcEntityId,
        ),
      );

      expect(dispatch.result.status,
          ScenarioRuntimeExecutionStatus.executedEffect);
      expect(dispatch.result.scenarioId, _battleScenarioId);
      expect(dispatch.result.sourceNodeId, 'p3_battle_source');
      expect(dispatch.result.stopNodeId, 'p3_battle_node');
      expect(dispatch.result.effect.type, ScenarioRuntimeEffectType.battle);
      expect(dispatch.result.effect.battleId, _battleId);
      expect(dispatch.result.effect.trainerId, _trainerId);
      expect(dispatch.result.effect.npcEntityId, _npcEntityId);
    });

    test('keeps battle outcome flags separate and resumes victory or defeat',
        () async {
      final bundle = await _loadBundle();
      final victoryFlag = scenarioBattleOutcomeFlagName(
        _battleId,
        kBattleOutcomeSuffixVictory,
      );
      final defeatFlag = scenarioBattleOutcomeFlagName(
        _battleId,
        kBattleOutcomeSuffixDefeat,
      );

      expect(victoryFlag, 'battle:p3_battle_test:victory');
      expect(defeatFlag, 'battle:p3_battle_test:defeat');
      expect(victoryFlag, isNot(startsWith('scenario.outcome.')));
      expect(defeatFlag, isNot(startsWith('scenario.outcome.')));
      expect(
        scenarioOutcomeFlagName(_outcomeId),
        isNot(anyOf(victoryFlag, defeatFlag)),
      );

      final victory =
          _continueAfterBattle(bundle, activeBattleFlag: victoryFlag);
      expect(victory.result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(
        victory.state.storyFlags.activeFlags,
        contains('p3.battle.victory.continued'),
      );
      expect(
        victory.state.storyFlags.activeFlags,
        isNot(contains('p3.battle.defeat.continued')),
      );

      final defeat = _continueAfterBattle(bundle, activeBattleFlag: defeatFlag);
      expect(defeat.result.status, ScenarioRuntimeExecutionStatus.reachedEnd);
      expect(
        defeat.state.storyFlags.activeFlags,
        contains('p3.battle.defeat.continued'),
      );
      expect(
        defeat.state.storyFlags.activeFlags,
        isNot(contains('p3.battle.victory.continued')),
      );
    });
  });
}

const _mapId = 'p3_outcome_battle_map';
const _npcEntityId = 'p3_battle_npc';
const _trainerId = 'p3_trainer_test';
const _battleId = 'p3_battle_test';
const _outcomeId = 'p3.outcome.continuation';
const _outcomeEmitterScenarioId = 'p3_scenario_outcome_emitter';
const _outcomeReceiverScenarioId = 'p3_scenario_outcome_receiver';
const _battleScenarioId = 'p3_battle_starter_scenario';

Future<RuntimeMapBundle> _loadBundle() {
  final projectFilePath = p.join(
    Directory.current.path,
    'test',
    'fixtures',
    'p3_outcome_battle_continuation',
    'project.json',
  );

  return loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: _mapId,
  );
}

_DispatchProbe _dispatch(
  RuntimeMapBundle bundle,
  ScenarioRuntimeSourceEvent sourceEvent,
) {
  var state = const GameState(saveId: 'p3-outcome-battle-continuation');
  final result = const ScenarioRuntimeExecutor().dispatch(
    scenarios: bundle.manifest.scenarios,
    sourceEvent: sourceEvent,
    context: _context(
      state: state,
      onUpdate: (next) => state = next,
    ),
  );

  return _DispatchProbe(result: result, state: state);
}

_DispatchProbe _continueAfterBattle(
  RuntimeMapBundle bundle, {
  required String activeBattleFlag,
}) {
  var state = const StoryFlagsManager().set(
    const GameState(saveId: 'p3-outcome-battle-continuation'),
    activeBattleFlag,
  );
  final result = const ScenarioRuntimeExecutor().dispatchContinuation(
    scenarios: bundle.manifest.scenarios,
    scenarioId: _battleScenarioId,
    sourceNodeId: 'p3_battle_source',
    resumeAfterNodeId: 'p3_battle_node',
    context: _context(
      state: state,
      onUpdate: (next) => state = next,
    ),
  );

  return _DispatchProbe(result: result, state: state);
}

ScenarioRuntimeExecutionContext _context({
  required GameState state,
  required void Function(GameState) onUpdate,
}) {
  return ScenarioRuntimeExecutionContext(
    gameState: state,
    onGameStateUpdated: onUpdate,
    openDialogue: (_, {startNode, runtimeSourceId}) => false,
    runScript: (_, {startNode, runtimeSourceId}) => false,
    showMessage: (_) {},
  );
}

class _DispatchProbe {
  const _DispatchProbe({
    required this.result,
    required this.state,
  });

  final ScenarioRuntimeExecutionResult result;
  final GameState state;
}
