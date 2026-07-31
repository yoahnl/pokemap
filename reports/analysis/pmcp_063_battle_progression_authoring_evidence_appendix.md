# PMCP-063 — Created Dart files appendix

This appendix records the complete contents of every Dart file created by PMCP-063.

## `packages/map_battle/lib/src/battle_authoring_simulator.dart`

```dart
import 'dart:convert';

import 'battle_action.dart';
import 'battle_decision.dart';
import 'battle_resolution.dart';
import 'battle_rng.dart';
import 'battle_session.dart';
import 'battle_setup.dart';
import 'battle_state.dart';

enum BattleAuthoringChoiceKind {
  fight,
  switchPokemon,
  run,
  capture,
  continueBattle,
}

enum BattleAuthoringSetupKind { wild, trainer, staticEncounter }

final class BattleAuthoringSetupValidation {
  BattleAuthoringSetupValidation({
    required this.kind,
    required Iterable<String> diagnostics,
  }) : diagnostics = List<String>.unmodifiable(diagnostics);

  final BattleAuthoringSetupKind kind;
  final List<String> diagnostics;

  bool get isValid => diagnostics.isEmpty;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'isValid': isValid,
        'diagnostics': diagnostics,
      };
}

/// Small setup façade that preserves map_battle as the validation authority.
final class BattleAuthoringSetupFactory {
  const BattleAuthoringSetupFactory();

  BattleSetup wild({
    required BattleCombatantData playerPokemon,
    Iterable<BattleCombatantData> playerReservePokemon =
        const <BattleCombatantData>[],
    required BattleCombatantData enemyPokemon,
    Iterable<BattleCombatantData> enemyReservePokemon =
        const <BattleCombatantData>[],
    bool allowCapture = true,
    bool allowFlee = true,
  }) {
    return BattleSetup(
      playerPokemon: playerPokemon,
      playerReservePokemon:
          List<BattleCombatantData>.unmodifiable(playerReservePokemon),
      enemyPokemon: enemyPokemon,
      enemyReservePokemon:
          List<BattleCombatantData>.unmodifiable(enemyReservePokemon),
      isTrainerBattle: false,
      trainerId: null,
      allowCapture: allowCapture,
      allowFlee: allowFlee,
    );
  }

  BattleSetup trainer({
    required BattleCombatantData playerPokemon,
    Iterable<BattleCombatantData> playerReservePokemon =
        const <BattleCombatantData>[],
    required BattleCombatantData enemyPokemon,
    Iterable<BattleCombatantData> enemyReservePokemon =
        const <BattleCombatantData>[],
    required String trainerId,
  }) {
    final normalizedTrainerId = trainerId.trim();
    if (normalizedTrainerId.isEmpty) {
      throw ArgumentError.value(trainerId, 'trainerId', 'must not be empty');
    }
    return BattleSetup(
      playerPokemon: playerPokemon,
      playerReservePokemon:
          List<BattleCombatantData>.unmodifiable(playerReservePokemon),
      enemyPokemon: enemyPokemon,
      enemyReservePokemon:
          List<BattleCombatantData>.unmodifiable(enemyReservePokemon),
      isTrainerBattle: true,
      trainerId: normalizedTrainerId,
      allowCapture: false,
      allowFlee: false,
    );
  }

  BattleSetup staticEncounter({
    required BattleCombatantData playerPokemon,
    Iterable<BattleCombatantData> playerReservePokemon =
        const <BattleCombatantData>[],
    required BattleCombatantData enemyPokemon,
    Iterable<BattleCombatantData> enemyReservePokemon =
        const <BattleCombatantData>[],
  }) {
    return BattleSetup(
      playerPokemon: playerPokemon,
      playerReservePokemon:
          List<BattleCombatantData>.unmodifiable(playerReservePokemon),
      enemyPokemon: enemyPokemon,
      enemyReservePokemon:
          List<BattleCombatantData>.unmodifiable(enemyReservePokemon),
      isTrainerBattle: false,
      trainerId: null,
      allowCapture: false,
      allowFlee: false,
    );
  }

  BattleAuthoringSetupValidation validate(BattleSetup setup) {
    final diagnostics = <String>[];
    if (setup.isTrainerBattle &&
        (setup.trainerId == null || setup.trainerId!.trim().isEmpty)) {
      diagnostics.add('Trainer battle requires a non-empty trainerId.');
    }
    if (!setup.isTrainerBattle && setup.trainerId != null) {
      diagnostics.add('Non-trainer battle must not define trainerId.');
    }
    try {
      createBattleSession(setup);
    } on Object catch (error) {
      diagnostics.add('map_battle rejected setup: $error');
    }
    return BattleAuthoringSetupValidation(
      kind: setup.isTrainerBattle
          ? BattleAuthoringSetupKind.trainer
          : !setup.allowCapture && !setup.allowFlee
              ? BattleAuthoringSetupKind.staticEncounter
              : BattleAuthoringSetupKind.wild,
      diagnostics: diagnostics,
    );
  }
}

/// Stable, serializable choice used by authoring and future MCP adapters.
final class BattleAuthoringChoice {
  const BattleAuthoringChoice._({
    required this.kind,
    this.index,
  });

  const factory BattleAuthoringChoice.fight({required int moveIndex}) =
      _BattleAuthoringFightChoice;

  const factory BattleAuthoringChoice.switchPokemon({
    required int reserveIndex,
  }) = _BattleAuthoringSwitchChoice;

  const factory BattleAuthoringChoice.run() = _BattleAuthoringRunChoice;

  const factory BattleAuthoringChoice.capture() = _BattleAuthoringCaptureChoice;

  const factory BattleAuthoringChoice.continueBattle() =
      _BattleAuthoringContinueChoice;

  final BattleAuthoringChoiceKind kind;
  final int? index;

  PlayerBattleChoice toEngineChoice() => switch (kind) {
        BattleAuthoringChoiceKind.fight => PlayerBattleChoiceFight(index!),
        BattleAuthoringChoiceKind.switchPokemon =>
          PlayerBattleChoiceSwitch(index!),
        BattleAuthoringChoiceKind.run => const PlayerBattleChoiceRun(),
        BattleAuthoringChoiceKind.capture => const PlayerBattleChoiceCapture(),
        BattleAuthoringChoiceKind.continueBattle =>
          const PlayerBattleChoiceContinue(),
      };

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        if (index != null) 'index': index,
      };
}

final class _BattleAuthoringFightChoice extends BattleAuthoringChoice {
  const _BattleAuthoringFightChoice({required int moveIndex})
      : super._(
          kind: BattleAuthoringChoiceKind.fight,
          index: moveIndex,
        );
}

final class _BattleAuthoringSwitchChoice extends BattleAuthoringChoice {
  const _BattleAuthoringSwitchChoice({required int reserveIndex})
      : super._(
          kind: BattleAuthoringChoiceKind.switchPokemon,
          index: reserveIndex,
        );
}

final class _BattleAuthoringRunChoice extends BattleAuthoringChoice {
  const _BattleAuthoringRunChoice()
      : super._(kind: BattleAuthoringChoiceKind.run);
}

final class _BattleAuthoringCaptureChoice extends BattleAuthoringChoice {
  const _BattleAuthoringCaptureChoice()
      : super._(kind: BattleAuthoringChoiceKind.capture);
}

final class _BattleAuthoringContinueChoice extends BattleAuthoringChoice {
  const _BattleAuthoringContinueChoice()
      : super._(kind: BattleAuthoringChoiceKind.continueBattle);
}

final class BattleAuthoringSimulationRequest {
  BattleAuthoringSimulationRequest({
    required this.setup,
    this.seed = 0x00C0FFEE,
    Iterable<BattleAuthoringChoice> choices = const <BattleAuthoringChoice>[],
    this.maxSteps = 256,
  }) : choices = List<BattleAuthoringChoice>.unmodifiable(choices);

  final BattleSetup setup;
  final int seed;
  final List<BattleAuthoringChoice> choices;
  final int maxSteps;
}

final class BattleAuthoringChoiceRejectedException implements Exception {
  const BattleAuthoringChoiceRejectedException({
    required this.step,
    required this.requestKind,
    required this.choice,
  });

  final int step;
  final BattleDecisionRequestKind requestKind;
  final BattleAuthoringChoice choice;

  @override
  String toString() =>
      'Battle authoring choice ${choice.kind.name} is not legal at step '
      '$step for ${requestKind.name}.';
}

final class BattleAuthoringSimulationLimitException implements Exception {
  const BattleAuthoringSimulationLimitException(this.maxSteps);

  final int maxSteps;

  @override
  String toString() =>
      'Battle authoring simulation did not finish in $maxSteps steps.';
}

final class BattleAuthoringUnusedChoicesException implements Exception {
  const BattleAuthoringUnusedChoicesException(this.count);

  final int count;

  @override
  String toString() =>
      'Battle authoring simulation has $count unused scripted choices.';
}

final class BattleAuthoringStateSnapshot {
  const BattleAuthoringStateSnapshot({
    required this.phase,
    required this.playerSpeciesId,
    required this.playerCurrentHp,
    required this.playerMaxHp,
    required this.enemySpeciesId,
    required this.enemyCurrentHp,
    required this.enemyMaxHp,
    required this.outcome,
  });

  factory BattleAuthoringStateSnapshot.fromState(BattleState state) {
    return BattleAuthoringStateSnapshot(
      phase: state.phase.name,
      playerSpeciesId: state.player.speciesId,
      playerCurrentHp: state.player.currentHp,
      playerMaxHp: state.player.maxHp,
      enemySpeciesId: state.enemy.speciesId,
      enemyCurrentHp: state.enemy.currentHp,
      enemyMaxHp: state.enemy.maxHp,
      outcome: state.outcome?.type.name,
    );
  }

  final String phase;
  final String playerSpeciesId;
  final int playerCurrentHp;
  final int playerMaxHp;
  final String enemySpeciesId;
  final int enemyCurrentHp;
  final int enemyMaxHp;
  final String? outcome;

  Map<String, Object?> toJson() => {
        'phase': phase,
        'player': {
          'speciesId': playerSpeciesId,
          'currentHp': playerCurrentHp,
          'maxHp': playerMaxHp,
        },
        'enemy': {
          'speciesId': enemySpeciesId,
          'currentHp': enemyCurrentHp,
          'maxHp': enemyMaxHp,
        },
        if (outcome != null) 'outcome': outcome,
      };
}

final class BattleAuthoringExecutionTrace {
  const BattleAuthoringExecutionTrace({
    required this.attacker,
    required this.moveId,
    required this.target,
    required this.damage,
    required this.didHit,
    required this.didCrit,
  });

  factory BattleAuthoringExecutionTrace.fromExecution(
    BattleMoveExecution execution,
  ) {
    return BattleAuthoringExecutionTrace(
      attacker: execution.attacker,
      moveId: execution.move.id,
      target: execution.target,
      damage: execution.damage,
      didHit: execution.didHit,
      didCrit: execution.didCrit,
    );
  }

  final String attacker;
  final String moveId;
  final String target;
  final int damage;
  final bool didHit;
  final bool didCrit;

  Map<String, Object?> toJson() => {
        'attacker': attacker,
        'moveId': moveId,
        'target': target,
        'damage': damage,
        'didHit': didHit,
        'didCrit': didCrit,
      };
}

final class BattleAuthoringTraceEntry {
  BattleAuthoringTraceEntry({
    required this.step,
    required this.requestKind,
    required this.choice,
    required this.before,
    required this.after,
    required Iterable<BattleAuthoringExecutionTrace> executions,
    required this.timelineEventCount,
  }) : executions =
            List<BattleAuthoringExecutionTrace>.unmodifiable(executions);

  final int step;
  final BattleDecisionRequestKind requestKind;
  final BattleAuthoringChoice choice;
  final BattleAuthoringStateSnapshot before;
  final BattleAuthoringStateSnapshot after;
  final List<BattleAuthoringExecutionTrace> executions;
  final int timelineEventCount;

  Map<String, Object?> toJson() => {
        'step': step,
        'requestKind': requestKind.name,
        'choice': choice.toJson(),
        'before': before.toJson(),
        'after': after.toJson(),
        'executions': [for (final execution in executions) execution.toJson()],
        'timelineEventCount': timelineEventCount,
      };
}

final class BattleAuthoringCombatantWriteBack {
  BattleAuthoringCombatantWriteBack({
    required this.lineupIndex,
    required this.speciesId,
    required this.currentHp,
    required this.statusId,
    required Map<String, int> currentPpByMoveId,
  }) : currentPpByMoveId = Map<String, int>.unmodifiable(
          currentPpByMoveId,
        );

  factory BattleAuthoringCombatantWriteBack.fromCombatant(
    BattleCombatant combatant,
  ) {
    return BattleAuthoringCombatantWriteBack(
      lineupIndex: combatant.lineupIndex,
      speciesId: combatant.writeBackSpeciesId,
      currentHp: combatant.currentHp,
      statusId: combatant.majorStatus?.id.name,
      currentPpByMoveId: <String, int>{
        for (final move in combatant.writeBackMoves) move.id: move.currentPp,
      },
    );
  }

  final int lineupIndex;
  final String speciesId;
  final int currentHp;
  final String? statusId;
  final Map<String, int> currentPpByMoveId;

  Map<String, Object?> toJson() => {
        'lineupIndex': lineupIndex,
        'speciesId': speciesId,
        'currentHp': currentHp,
        if (statusId != null) 'statusId': statusId,
        'currentPpByMoveId': currentPpByMoveId,
      };
}

final class BattleAuthoringWriteBack {
  BattleAuthoringWriteBack({
    required Iterable<BattleAuthoringCombatantWriteBack> playerLineup,
    required Iterable<int> playerParticipantLineupIndexes,
  })  : playerLineup =
            List<BattleAuthoringCombatantWriteBack>.unmodifiable(playerLineup),
        playerParticipantLineupIndexes =
            Set<int>.unmodifiable(playerParticipantLineupIndexes);

  factory BattleAuthoringWriteBack.fromOutcome(BattleOutcome outcome) {
    return BattleAuthoringWriteBack(
      playerLineup: <BattleAuthoringCombatantWriteBack>[
        BattleAuthoringCombatantWriteBack.fromCombatant(
          outcome.finalState.player,
        ),
        for (final combatant in outcome.finalState.playerReserve)
          BattleAuthoringCombatantWriteBack.fromCombatant(combatant),
      ],
      playerParticipantLineupIndexes: outcome.playerParticipantLineupIndexes,
    );
  }

  final List<BattleAuthoringCombatantWriteBack> playerLineup;
  final Set<int> playerParticipantLineupIndexes;

  Map<String, Object?> toJson() => {
        'playerLineup': [
          for (final combatant in playerLineup) combatant.toJson(),
        ],
        'playerParticipantLineupIndexes':
            playerParticipantLineupIndexes.toList()..sort(),
      };
}

final class BattleAuthoringSimulationResult {
  BattleAuthoringSimulationResult({
    required this.seed,
    required this.outcome,
    required Iterable<BattleAuthoringTraceEntry> trace,
    required this.writeBack,
    required this.receipt,
  }) : trace = List<BattleAuthoringTraceEntry>.unmodifiable(trace);

  final int seed;
  final BattleOutcome outcome;
  final List<BattleAuthoringTraceEntry> trace;
  final BattleAuthoringWriteBack writeBack;
  final BattleAuthoringSimulationReceipt receipt;

  Map<String, Object?> toJson() => {
        'seed': seed,
        'outcome': {
          'kind': outcome.type.name,
          if (outcome.captureItemId != null)
            'captureItemId': outcome.captureItemId,
          if (outcome.captureAttemptId != null)
            'captureAttemptId': outcome.captureAttemptId,
        },
        'trace': [for (final entry in trace) entry.toJson()],
        'writeBack': writeBack.toJson(),
        'receipt': receipt.toJson(),
      };
}

final class BattleAuthoringSimulationReceipt {
  const BattleAuthoringSimulationReceipt({
    required this.id,
    required this.seed,
    required this.stepCount,
    required this.outcomeKind,
  });

  final String id;
  final int seed;
  final int stepCount;
  final BattleOutcomeType outcomeKind;

  Map<String, Object?> toJson() => {
        'id': id,
        'seed': seed,
        'stepCount': stepCount,
        'outcomeKind': outcomeKind.name,
      };
}

/// Runs the production legacy battle engine with an explicit deterministic
/// seed and records a protocol-neutral authoring trace.
final class BattleAuthoringSimulator {
  const BattleAuthoringSimulator();

  BattleAuthoringSimulationResult simulate(
    BattleAuthoringSimulationRequest request,
  ) {
    RangeError.checkValueInInterval(
      request.seed,
      0,
      0xFFFFFFFF,
      'seed',
    );
    RangeError.checkValueInInterval(
      request.maxSteps,
      1,
      10000,
      'maxSteps',
    );
    var session = createBattleSession(
      request.setup,
      rng: BattleSeededRng(state: request.seed),
    );
    var scriptedChoiceIndex = 0;
    final trace = <BattleAuthoringTraceEntry>[];

    while (!session.state.isFinished) {
      if (trace.length >= request.maxSteps) {
        throw BattleAuthoringSimulationLimitException(request.maxSteps);
      }
      final engineRequest = session.decisionRequest;
      final choice = scriptedChoiceIndex < request.choices.length
          ? request.choices[scriptedChoiceIndex++]
          : _firstLegalChoice(engineRequest);
      final engineChoice = choice.toEngineChoice();
      if (!engineRequest.allows(engineChoice)) {
        throw BattleAuthoringChoiceRejectedException(
          step: trace.length,
          requestKind: engineRequest.kind,
          choice: choice,
        );
      }
      final before = BattleAuthoringStateSnapshot.fromState(session.state);
      session = session.applyChoice(engineChoice);
      final turn = session.state.currentTurn;
      trace.add(
        BattleAuthoringTraceEntry(
          step: trace.length,
          requestKind: engineRequest.kind,
          choice: choice,
          before: before,
          after: BattleAuthoringStateSnapshot.fromState(session.state),
          executions: [
            for (final execution
                in turn?.executions ?? const <BattleMoveExecution>[])
              BattleAuthoringExecutionTrace.fromExecution(execution),
          ],
          timelineEventCount: turn?.timeline.length ?? 0,
        ),
      );
    }

    final unusedChoices = request.choices.length - scriptedChoiceIndex;
    if (unusedChoices > 0) {
      throw BattleAuthoringUnusedChoicesException(unusedChoices);
    }
    final outcome = session.state.outcome;
    if (outcome == null) {
      throw StateError('Finished battle authoring simulation has no outcome.');
    }
    final writeBack = BattleAuthoringWriteBack.fromOutcome(outcome);
    final receipt = _buildReceipt(
      seed: request.seed,
      outcome: outcome,
      trace: trace,
      writeBack: writeBack,
    );
    return BattleAuthoringSimulationResult(
      seed: request.seed,
      outcome: outcome,
      trace: trace,
      writeBack: writeBack,
      receipt: receipt,
    );
  }
}

BattleAuthoringSimulationReceipt _buildReceipt({
  required int seed,
  required BattleOutcome outcome,
  required List<BattleAuthoringTraceEntry> trace,
  required BattleAuthoringWriteBack writeBack,
}) {
  final payload = jsonEncode({
    'formatVersion': 1,
    'seed': seed,
    'outcome': outcome.type.name,
    'trace': [for (final entry in trace) entry.toJson()],
    'writeBack': writeBack.toJson(),
  });
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(payload)) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF;
  }
  return BattleAuthoringSimulationReceipt(
    id: 'battle-sim-v1-${hash.toRadixString(16).padLeft(16, '0')}',
    seed: seed,
    stepCount: trace.length,
    outcomeKind: outcome.type,
  );
}

BattleAuthoringChoice _firstLegalChoice(BattleDecisionRequest request) {
  final choices = request.allowedChoices;
  if (choices.isEmpty) {
    throw StateError(
      'Battle authoring simulation cannot advance ${request.kind.name}.',
    );
  }
  return _fromEngineChoice(choices.first);
}

BattleAuthoringChoice _fromEngineChoice(PlayerBattleChoice choice) {
  return switch (choice) {
    PlayerBattleChoiceFight() =>
      BattleAuthoringChoice.fight(moveIndex: choice.moveIndex),
    PlayerBattleChoiceSwitch() =>
      BattleAuthoringChoice.switchPokemon(reserveIndex: choice.reserveIndex),
    PlayerBattleChoiceRun() => const BattleAuthoringChoice.run(),
    PlayerBattleChoiceCapture() => const BattleAuthoringChoice.capture(),
    PlayerBattleChoiceContinue() =>
      const BattleAuthoringChoice.continueBattle(),
  };
}
```
## `packages/map_battle/test/battle_authoring_simulator_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _stats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

void main() {
  group('BattleAuthoringSimulator', () {
    test('replays the same seeded battle with the same trace and write-back',
        () {
      final request = BattleAuthoringSimulationRequest(
        setup: _oneHitSetup(),
        seed: 42,
        choices: const <BattleAuthoringChoice>[
          BattleAuthoringChoice.fight(moveIndex: 0),
        ],
      );

      final first = const BattleAuthoringSimulator().simulate(request);
      final second = const BattleAuthoringSimulator().simulate(request);

      expect(first.outcome.type, BattleOutcomeType.victory);
      expect(first.trace, hasLength(1));
      expect(first.trace.single.choice.kind, BattleAuthoringChoiceKind.fight);
      expect(first.trace.single.executions, hasLength(1));
      expect(first.writeBack.playerLineup.single.lineupIndex, 0);
      expect(first.writeBack.playerParticipantLineupIndexes, <int>{0});
      expect(first.receipt.id, second.receipt.id);
      expect(first.receipt.stepCount, 1);
      expect(first.toJson(), second.toJson());
    });

    test('builds and validates wild trainer and static setup identities', () {
      const factory = BattleAuthoringSetupFactory();
      final fixture = _oneHitSetup();
      final wild = factory.wild(
        playerPokemon: fixture.playerPokemon,
        enemyPokemon: fixture.enemyPokemon,
        allowCapture: false,
      );
      final trainer = factory.trainer(
        playerPokemon: fixture.playerPokemon,
        enemyPokemon: fixture.enemyPokemon,
        trainerId: ' rival ',
      );
      final staticEncounter = factory.staticEncounter(
        playerPokemon: fixture.playerPokemon,
        enemyPokemon: fixture.enemyPokemon,
      );

      expect(factory.validate(wild).kind, BattleAuthoringSetupKind.wild);
      expect(factory.validate(wild).isValid, isTrue);
      expect(factory.validate(trainer).kind, BattleAuthoringSetupKind.trainer);
      expect(trainer.trainerId, 'rival');
      expect(
        factory.validate(staticEncounter).kind,
        BattleAuthoringSetupKind.staticEncounter,
      );
      expect(staticEncounter.allowCapture, isFalse);
      expect(staticEncounter.allowFlee, isFalse);
    });

    test('rejects a scripted choice that is not legal for the current request',
        () {
      expect(
        () => const BattleAuthoringSimulator().simulate(
          BattleAuthoringSimulationRequest(
            setup: BattleSetup(
              playerPokemon: BattleCombatantData(
                speciesId: 'hero',
                level: 5,
                maxHp: 20,
                stats: _stats,
                moves: <BattleMoveData>[
                  BattleMoveData(id: 'tackle', name: 'Tackle', power: 10),
                ],
              ),
              enemyPokemon: BattleCombatantData(
                speciesId: 'rival',
                level: 5,
                maxHp: 20,
                stats: _stats,
                moves: <BattleMoveData>[
                  BattleMoveData(id: 'tackle', name: 'Tackle', power: 10),
                ],
              ),
              isTrainerBattle: true,
              trainerId: 'rival',
            ),
            choices: <BattleAuthoringChoice>[
              BattleAuthoringChoice.run(),
            ],
          ),
        ),
        throwsA(isA<BattleAuthoringChoiceRejectedException>()),
      );
    });

    test('fails explicitly instead of returning a partial max-step outcome',
        () {
      expect(
        () => const BattleAuthoringSimulator().simulate(
          BattleAuthoringSimulationRequest(
            setup: BattleSetup(
              playerPokemon: BattleCombatantData(
                speciesId: 'hero',
                level: 5,
                maxHp: 100,
                stats: _stats,
                moves: <BattleMoveData>[
                  BattleMoveData(id: 'tap', name: 'Tap', power: 1),
                ],
              ),
              enemyPokemon: BattleCombatantData(
                speciesId: 'wild',
                level: 5,
                maxHp: 100,
                stats: _stats,
                moves: <BattleMoveData>[
                  BattleMoveData(id: 'tap', name: 'Tap', power: 1),
                ],
              ),
              isTrainerBattle: false,
              trainerId: null,
              allowFlee: false,
            ),
            maxSteps: 1,
          ),
        ),
        throwsA(isA<BattleAuthoringSimulationLimitException>()),
      );
    });

    test('records a deterministic captured outcome and its attempt identity',
        () {
      final result = const BattleAuthoringSimulator().simulate(
        BattleAuthoringSimulationRequest(
          setup: const BattleSetup(
            playerPokemon: BattleCombatantData(
              speciesId: 'hero',
              level: 10,
              maxHp: 100,
              stats: _stats,
              moves: <BattleMoveData>[
                BattleMoveData(id: 'wait', name: 'Wait', power: 0),
              ],
            ),
            enemyPokemon: BattleCombatantData(
              speciesId: 'wild',
              level: 10,
              maxHp: 100,
              currentHp: 1,
              catchRate: 255,
              majorStatus: BattleMajorStatusState.slp(),
              stats: _stats,
              moves: <BattleMoveData>[
                BattleMoveData(id: 'tap', name: 'Tap', power: 1),
              ],
            ),
            isTrainerBattle: false,
            trainerId: null,
            allowCapture: true,
          ),
          seed: 47,
          choices: const <BattleAuthoringChoice>[
            BattleAuthoringChoice.capture(),
          ],
        ),
      );

      expect(result.outcome.type, BattleOutcomeType.captured);
      expect(result.outcome.captureItemId, canonicalPokeBallItemId);
      expect(result.outcome.captureAttemptId, 'capture-attempt-1');
      expect(
          result.trace.single.choice.kind, BattleAuthoringChoiceKind.capture);
    });
  });
}

BattleSetup _oneHitSetup() {
  return const BattleSetup(
    playerPokemon: BattleCombatantData(
      speciesId: 'hero',
      level: 5,
      maxHp: 20,
      stats: BattleStatsSnapshot(
        attack: 100,
        defense: 50,
        specialAttack: 50,
        specialDefense: 50,
        speed: 100,
      ),
      moves: <BattleMoveData>[
        BattleMoveData(id: 'finisher', name: 'Finisher', power: 100),
      ],
    ),
    enemyPokemon: BattleCombatantData(
      speciesId: 'wild',
      level: 5,
      maxHp: 5,
      stats: BattleStatsSnapshot(
        attack: 10,
        defense: 10,
        specialAttack: 10,
        specialDefense: 10,
        speed: 1,
      ),
      moves: <BattleMoveData>[
        BattleMoveData(id: 'tap', name: 'Tap', power: 1),
      ],
    ),
    isTrainerBattle: false,
    trainerId: null,
  );
}
```

## `packages/map_gameplay/lib/src/battle_progression_authoring_service.dart`

```dart
import 'package:map_core/map_core.dart';

import 'battle_progression_result.dart';
import 'battle_progression_service.dart';
import 'battle_reward.dart';
import 'player_storage_operations.dart';

enum BattleProgressionAuthoringDecisionKind {
  moveLearning,
  evolution,
}

enum BattleAuthoringCaptureDestinationKind {
  party,
  storageBox,
  unavailable,
}

final class BattleAuthoringCaptureDestinationPreview {
  const BattleAuthoringCaptureDestinationPreview({
    required this.kind,
    this.partyIndex,
    this.boxId,
    this.boxIndex,
    this.failure,
  });

  final BattleAuthoringCaptureDestinationKind kind;
  final int? partyIndex;
  final String? boxId;
  final int? boxIndex;
  final PlayerStorageFailure? failure;

  bool get isAvailable =>
      kind != BattleAuthoringCaptureDestinationKind.unavailable;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'isAvailable': isAvailable,
        if (partyIndex != null) 'partyIndex': partyIndex,
        if (boxId != null) 'boxId': boxId,
        if (boxIndex != null) 'boxIndex': boxIndex,
        if (failure != null) 'failure': failure!.name,
      };
}

sealed class BattleProgressionAuthoringDecision {
  const BattleProgressionAuthoringDecision(this.kind);

  const factory BattleProgressionAuthoringDecision.moveLearning(
    BattleMoveLearningDecision decision,
  ) = BattleProgressionAuthoringMoveLearningDecision;

  const factory BattleProgressionAuthoringDecision.evolution(
    BattleEvolutionDecision decision,
  ) = BattleProgressionAuthoringEvolutionDecision;

  final BattleProgressionAuthoringDecisionKind kind;

  Map<String, Object?> toJson();
}

final class BattleProgressionAuthoringMoveLearningDecision
    extends BattleProgressionAuthoringDecision {
  const BattleProgressionAuthoringMoveLearningDecision(this.decision)
      : super(BattleProgressionAuthoringDecisionKind.moveLearning);

  final BattleMoveLearningDecision decision;

  @override
  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'opportunityId': decision.opportunityId,
        'partySlot': decision.partySlot,
        'moveId': decision.moveId,
        'decision': switch (decision) {
          LearnBattleMoveLearningDecision() => 'learn',
          ReplaceBattleMoveLearningDecision() => 'replace',
          DeclineBattleMoveLearningDecision() => 'decline',
        },
        if (decision case ReplaceBattleMoveLearningDecision replacement) ...{
          'replaceMoveIndex': replacement.replaceMoveIndex,
          'expectedReplacedMoveId': replacement.expectedReplacedMoveId,
        },
      };
}

final class BattleProgressionAuthoringEvolutionDecision
    extends BattleProgressionAuthoringDecision {
  const BattleProgressionAuthoringEvolutionDecision(this.decision)
      : super(BattleProgressionAuthoringDecisionKind.evolution);

  final BattleEvolutionDecision decision;

  @override
  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'opportunityId': decision.opportunityId,
        'occurrenceId': decision.occurrenceId,
        'partySlot': decision.partySlot,
        'sourceSpeciesId': decision.sourceSpeciesId,
        'targetSpeciesId': decision.targetSpeciesId,
        'decision': switch (decision) {
          AcceptBattleEvolutionDecision() => 'accept',
          RefuseBattleEvolutionDecision() => 'refuse',
        },
      };
}

final class BattleProgressionAuthoringDecisionTrace {
  const BattleProgressionAuthoringDecisionTrace({
    required this.index,
    required this.kind,
    required this.decision,
    required this.pendingBefore,
    required this.pendingAfter,
  });

  final int index;
  final BattleProgressionAuthoringDecisionKind kind;
  final Map<String, Object?> decision;
  final String pendingBefore;
  final String pendingAfter;

  Map<String, Object?> toJson() => {
        'index': index,
        'kind': kind.name,
        'decision': decision,
        'pendingBefore': pendingBefore,
        'pendingAfter': pendingAfter,
      };
}

final class BattleProgressionAuthoringPolicy {
  const BattleProgressionAuthoringPolicy({
    required this.outcome,
    required this.requiresRuntimeBattleWriteBack,
    required this.requiresCaptureDestination,
    required this.appliesVictoryRewards,
  });

  factory BattleProgressionAuthoringPolicy.forOutcome(
    BattleProgressionOutcomeKind outcome,
  ) {
    return BattleProgressionAuthoringPolicy(
      outcome: outcome,
      requiresRuntimeBattleWriteBack: true,
      requiresCaptureDestination:
          outcome == BattleProgressionOutcomeKind.captured,
      appliesVictoryRewards: outcome == BattleProgressionOutcomeKind.victory,
    );
  }

  final BattleProgressionOutcomeKind outcome;
  final bool requiresRuntimeBattleWriteBack;
  final bool requiresCaptureDestination;
  final bool appliesVictoryRewards;

  Map<String, Object?> toJson() => {
        'outcome': outcome.name,
        'requiresRuntimeBattleWriteBack': requiresRuntimeBattleWriteBack,
        'requiresCaptureDestination': requiresCaptureDestination,
        'appliesVictoryRewards': appliesVictoryRewards,
      };
}

final class BattleProgressionAuthoringPreview {
  BattleProgressionAuthoringPreview({
    required this.sourceState,
    required this.result,
    required Iterable<BattleProgressionAuthoringDecisionTrace> decisionTrace,
    required this.policy,
    required this.captureDestination,
  }) : decisionTrace =
            List<BattleProgressionAuthoringDecisionTrace>.unmodifiable(
          decisionTrace,
        );

  final GameState sourceState;
  final BattleProgressionResult result;
  final List<BattleProgressionAuthoringDecisionTrace> decisionTrace;
  final BattleProgressionAuthoringPolicy policy;
  final BattleAuthoringCaptureDestinationPreview? captureDestination;

  bool get isDecisionComplete =>
      result.pendingMoveLearning == null && result.pendingEvolution == null;

  Map<String, Object?> toJson() => {
        'productionWriteAllowed': false,
        'policy': policy.toJson(),
        if (captureDestination != null)
          'captureDestination': captureDestination!.toJson(),
        'isDecisionComplete': isDecisionComplete,
        'sourceState': sourceState.toJson(),
        'resultState': result.state.toJson(),
        'appliedReward': _rewardToJson(result.appliedReward),
        'progressionChanges': [
          for (final change in result.changes)
            {
              'partySlot': change.partySlot,
              'experienceAwarded': change.experienceAwarded,
              'oldExperience': change.oldExperience,
              'newExperience': change.newExperience,
              'oldLevel': change.oldLevel,
              'newLevel': change.newLevel,
              'newCurrentHp': change.newCurrentHp,
            },
        ],
        'pendingMoveLearning': _pendingMoveLearningToJson(
          result.pendingMoveLearning,
        ),
        'pendingEvolution': _pendingEvolutionToJson(result.pendingEvolution),
        'decisionTrace': [for (final entry in decisionTrace) entry.toJson()],
      };
}

final class BattleProgressionAuthoringDecisionException implements Exception {
  const BattleProgressionAuthoringDecisionException({
    required this.index,
    required this.expected,
    required this.actual,
  });

  final int index;
  final String expected;
  final BattleProgressionAuthoringDecisionKind actual;

  @override
  String toString() =>
      'Battle progression authoring decision $index is ${actual.name}; '
      'expected $expected.';
}

/// Detached preview over the production gameplay progression service.
final class BattleProgressionAuthoringService {
  const BattleProgressionAuthoringService({
    this.progressionService = const BattleProgressionService(),
  });

  final BattleProgressionService progressionService;

  BattleAuthoringCaptureDestinationPreview previewCaptureDestination(
    GameState state,
  ) {
    if (state.party.members.length < maxPlayerPartySize) {
      return BattleAuthoringCaptureDestinationPreview(
        kind: BattleAuthoringCaptureDestinationKind.party,
        partyIndex: state.party.members.length,
      );
    }
    final slot = const PlayerStorageOperations().findFirstAvailableSlot(
      state.pokemonStorage,
    );
    if (slot == null) {
      return const BattleAuthoringCaptureDestinationPreview(
        kind: BattleAuthoringCaptureDestinationKind.unavailable,
        failure: PlayerStorageFailure.storageFull,
      );
    }
    return BattleAuthoringCaptureDestinationPreview(
      kind: BattleAuthoringCaptureDestinationKind.storageBox,
      boxId: slot.boxId,
      boxIndex: slot.boxIndex,
    );
  }

  BattleProgressionAuthoringPreview preview({
    required GameState state,
    required BattleProgressionContext context,
    required BattleReward reward,
    Iterable<BattleProgressionAuthoringDecision> decisions =
        const <BattleProgressionAuthoringDecision>[],
    bool applyAuthoredRewards = true,
  }) {
    final sourceState = _copyState(state);
    var result = progressionService.apply(
      state: _copyState(sourceState),
      context: context,
      reward: reward,
      applyAuthoredRewards: applyAuthoredRewards,
    );
    final trace = <BattleProgressionAuthoringDecisionTrace>[];
    var index = 0;
    for (final authoringDecision in decisions) {
      final before = _pendingKind(result);
      switch (authoringDecision) {
        case BattleProgressionAuthoringMoveLearningDecision():
          if (result.pendingMoveLearning == null) {
            throw BattleProgressionAuthoringDecisionException(
              index: index,
              expected: 'a pending move-learning decision',
              actual: authoringDecision.kind,
            );
          }
          result = result.resolvePendingMoveLearning(
            authoringDecision.decision,
          );
        case BattleProgressionAuthoringEvolutionDecision():
          if (result.pendingEvolution == null) {
            throw BattleProgressionAuthoringDecisionException(
              index: index,
              expected: 'a pending evolution decision',
              actual: authoringDecision.kind,
            );
          }
          result = result.resolvePendingEvolution(authoringDecision.decision);
      }
      trace.add(
        BattleProgressionAuthoringDecisionTrace(
          index: index,
          kind: authoringDecision.kind,
          decision: Map<String, Object?>.unmodifiable(
            authoringDecision.toJson(),
          ),
          pendingBefore: before,
          pendingAfter: _pendingKind(result),
        ),
      );
      index += 1;
    }

    return BattleProgressionAuthoringPreview(
      sourceState: sourceState,
      result: result,
      decisionTrace: trace,
      policy: BattleProgressionAuthoringPolicy.forOutcome(context.outcome),
      captureDestination:
          context.outcome == BattleProgressionOutcomeKind.captured
              ? previewCaptureDestination(sourceState)
              : null,
    );
  }
}

String _pendingKind(BattleProgressionResult result) {
  if (result.pendingMoveLearning != null) return 'moveLearning';
  if (result.pendingEvolution != null) return 'evolution';
  return 'none';
}

Map<String, Object?> _rewardToJson(BattleReward reward) => {
      'sourceKind': reward.sourceKind.name,
      if (reward.trainerId != null) 'trainerId': reward.trainerId,
      'experienceGrants': [
        for (final grant in reward.experienceGrants)
          {
            'partySlot': grant.partySlot,
            'experience': grant.experience,
          },
      ],
      'money': reward.money,
      'itemGrants': [
        for (final grant in reward.itemGrants)
          {
            'itemId': grant.itemId,
            'quantity': grant.quantity,
          },
      ],
      'flagIds': reward.flagIds,
      if (reward.badgeId != null) 'badgeId': reward.badgeId,
      if (reward.fieldAbilityUnlock != null)
        'fieldAbilityUnlock': reward.fieldAbilityUnlock!.name,
    };

Map<String, Object?>? _pendingMoveLearningToJson(
  PendingBattleMoveLearning? pending,
) {
  if (pending == null) return null;
  return {
    'opportunityId': pending.opportunityId,
    'partySlot': pending.partySlot,
    'moveId': pending.candidate.moveId,
    'phase': pending.phase.name,
  };
}

Map<String, Object?>? _pendingEvolutionToJson(
  PendingBattleEvolution? pending,
) {
  if (pending == null) return null;
  return {
    'opportunityId': pending.opportunityId,
    'occurrenceId': pending.occurrenceId,
    'partySlot': pending.partySlot,
    'sourceSpeciesId': pending.sourceSpeciesId,
    'targetSpeciesId': pending.targetSpeciesId,
  };
}

GameState _copyState(GameState state) =>
    GameState.fromJson(Map<String, dynamic>.from(state.toJson()));
```

## `packages/map_gameplay/test/battle_progression_authoring_service_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('BattleProgressionAuthoringService', () {
    test('previews rewards and progression on a detached player state', () {
      final source = _state();

      final preview = const BattleProgressionAuthoringService().preview(
        state: source,
        context: _context(),
        reward: BattleReward(
          sourceKind: BattleRewardSourceKind.wild,
          money: 120,
        ),
      );

      expect(source.party.members.single.level, 5);
      expect(source.trainerProfile.money, 0);
      expect(preview.result.state.party.members.single.level, 6);
      expect(preview.result.state.trainerProfile.money, 120);
      expect(preview.policy.requiresRuntimeBattleWriteBack, isTrue);
      expect(preview.policy.requiresCaptureDestination, isFalse);
      expect(preview.isDecisionComplete, isTrue);
    });

    test('records typed move-learning decisions in deterministic order', () {
      final preview = const BattleProgressionAuthoringService().preview(
        state: _state(
          knownMoveIds: const <String>['one', 'two', 'three', 'four'],
        ),
        context: _context(
          candidates: const <PokemonMoveLearningCandidate>[
            PokemonMoveLearningCandidate(
              opportunityId: 'hero:growl:6',
              moveId: 'growl',
              learnedAtLevel: 6,
              maxPp: 40,
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
        decisions: const <BattleProgressionAuthoringDecision>[
          BattleProgressionAuthoringDecision.moveLearning(
            BattleMoveLearningDecision.decline(
              opportunityId: 'hero:growl:6',
              partySlot: 0,
              moveId: 'growl',
            ),
          ),
        ],
      );

      expect(preview.isDecisionComplete, isTrue);
      expect(preview.decisionTrace, hasLength(1));
      expect(
        preview.decisionTrace.single.kind,
        BattleProgressionAuthoringDecisionKind.moveLearning,
      );
      expect(
        preview.result.moveLearningChanges.single.kind,
        BattleMoveLearningChangeKind.declined,
      );
    });

    test('resolves an exact evolution decision through the production queue',
        () {
      final preview = const BattleProgressionAuthoringService().preview(
        state: _state(),
        context: _context(
          evolutionCandidates: <PokemonEvolutionCandidate>[
            PokemonEvolutionCandidate(
              opportunityId: 'hero:0:6:hero2',
              sourceSpeciesId: 'hero',
              targetSpeciesId: 'hero2',
              minLevel: 6,
              targetBaseStats: PokemonBaseStats(
                hp: 60,
                attack: 65,
                defense: 60,
                specialAttack: 80,
                specialDefense: 70,
                speed: 60,
              ),
              targetPrimaryAbilityId: 'overgrow',
              targetAbilityIds: <String>['overgrow'],
            ),
          ],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
        decisions: const <BattleProgressionAuthoringDecision>[
          BattleProgressionAuthoringDecision.evolution(
            BattleEvolutionDecision.accept(
              opportunityId: 'hero:0:6:hero2',
              occurrenceId: 'hero:0:6:hero2:slot:0:levels:5->6',
              partySlot: 0,
              sourceSpeciesId: 'hero',
              targetSpeciesId: 'hero2',
            ),
          ),
        ],
      );

      expect(preview.isDecisionComplete, isTrue);
      expect(preview.result.state.party.members.single.speciesId, 'hero2');
      expect(
        preview.decisionTrace.single.kind,
        BattleProgressionAuthoringDecisionKind.evolution,
      );
    });

    test('surfaces captured outcomes as runtime-owned capture write-back', () {
      final source = _state();
      final preview = const BattleProgressionAuthoringService().preview(
        state: source,
        context: _context(
          outcome: BattleProgressionOutcomeKind.captured,
          participants: const <int>{},
          opponents: const <BattleProgressionDefeatedOpponent>[],
          metadata: const <BattleProgressionPartySlotMetadata>[],
        ),
        reward: BattleReward(sourceKind: BattleRewardSourceKind.wild),
      );

      expect(preview.result.state.toJson(), source.toJson());
      expect(preview.result.appliedReward.isEmpty, isTrue);
      expect(preview.policy.requiresCaptureDestination, isTrue);
      expect(preview.policy.appliesVictoryRewards, isFalse);
      expect(
        preview.captureDestination?.kind,
        BattleAuthoringCaptureDestinationKind.party,
      );
      expect(preview.captureDestination?.partyIndex, 1);
    });

    test('previews the first real box slot when the party is full', () {
      final fullParty = _state().copyWith(
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            maxPlayerPartySize,
            (index) => PlayerPokemon(
              speciesId: 'hero_$index',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 5,
              currentHp: 19,
            ),
          ),
        ),
      );

      final destination = const BattleProgressionAuthoringService()
          .previewCaptureDestination(fullParty);

      expect(
        destination.kind,
        BattleAuthoringCaptureDestinationKind.storageBox,
      );
      expect(destination.boxId, 'box-01');
      expect(destination.boxIndex, 0);
    });
  });
}

BattleProgressionContext _context({
  BattleProgressionOutcomeKind outcome = BattleProgressionOutcomeKind.victory,
  Set<int> participants = const <int>{0},
  List<BattleProgressionDefeatedOpponent> opponents =
      const <BattleProgressionDefeatedOpponent>[
    BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
  ],
  List<BattleProgressionPartySlotMetadata>? metadata,
  List<PokemonMoveLearningCandidate> candidates =
      const <PokemonMoveLearningCandidate>[],
  List<PokemonEvolutionCandidate> evolutionCandidates =
      const <PokemonEvolutionCandidate>[],
}) {
  return BattleProgressionContext(
    outcome: outcome,
    playerParticipantPartySlots: participants,
    defeatedOpponents: opponents,
    partySlotMetadata: metadata ??
        const <BattleProgressionPartySlotMetadata>[
          BattleProgressionPartySlotMetadata(
            partySlot: 0,
            growthRateId: 'medium',
            oldMaxHp: 19,
            baseStats: PokemonBaseStats(
              hp: 45,
              attack: 49,
              defense: 49,
              specialAttack: 65,
              specialDefense: 65,
              speed: 45,
            ),
          ),
        ],
    moveLearningCandidatesByPartySlot: <int,
        List<PokemonMoveLearningCandidate>>{0: candidates},
    evolutionCandidatesByPartySlot: <int, List<PokemonEvolutionCandidate>>{
      0: evolutionCandidates,
    },
  );
}

GameState _state({
  List<String> knownMoveIds = const <String>[],
}) {
  return GameState(
    saveId: 'authoring-progression',
    trainerProfile: const TrainerProfile(name: 'Player'),
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'hero',
          natureId: 'hardy',
          abilityId: 'overgrow',
          level: 5,
          experience: 125,
          knownMoveIds: knownMoveIds,
          currentPpByMoveId: const <String, int>{},
          currentHp: 19,
        ),
      ],
    ),
  );
}
```

## `packages/map_authoring/lib/src/domains/gameplay/battle_actions.dart`

```dart
import '../../contracts/action_descriptor.dart';

/// Protocol-neutral battle playtest surface.
///
/// Stateful pause/resume, arbitrary RNG probes, manual target selection and
/// production outcome application are intentionally not advertised.
abstract final class BattleActions {
  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('battle.setup_validate', 'Validate a map_battle setup'),
      ('battle.setup_build_wild', 'Build a wild battle setup'),
      ('battle.setup_build_trainer', 'Build a trainer battle setup'),
      ('battle.setup_build_static', 'Build a static encounter setup'),
      ('battle.inspect_state', 'Inspect one simulation state snapshot'),
      ('battle.inspect_timeline', 'Inspect the ordered simulation trace'),
      ('battle.choose_move', 'Script one exact move choice'),
      ('battle.switch', 'Script one exact reserve switch'),
      ('battle.capture', 'Script one capture attempt'),
      ('battle.run', 'Script one flee attempt'),
      ('battle.advance', 'Advance one forced continuation'),
      ('battle.resolve_all', 'Resolve until a terminal outcome'),
      ('battle.inject_seed', 'Select the deterministic simulation seed'),
      ('battle.apply_outcome_plan', 'Preview terminal write-back data'),
      ('battle.simulate', 'Run one seeded deterministic battle'),
      ('battle.receipt_get', 'Read the deterministic simulation receipt'),
    ])
      _descriptor(entry.$1, entry.$2),
  ]);
}

AuthoringActionDescriptor _descriptor(String id, String summary) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'pokemap.authoring/$id.input.v1',
    outputSchemaId: 'pokemap.authoring/$id.output.v1',
    riskLevel: AuthoringRiskLevel.readOnly,
    resourceKinds: const ['battleProgression'],
    capabilityIds: const ['authoring.battle.simulation'],
    requiredPermissions: const [AuthoringPermission.playtestControl],
    guarantees: const [AuthoringGuarantee.dryRun],
    extensions: const {
      'deterministic': true,
      'productionWriteAllowed': false,
    },
  );
}
```

## `packages/map_authoring/lib/src/domains/gameplay/progression_actions.dart`

```dart
import '../../contracts/action_descriptor.dart';

/// Detached post-battle progression surface.
///
/// Actions whose catalog names contain `apply` still operate only on the
/// sandbox copy returned by the gameplay preview service.
abstract final class ProgressionActions {
  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('progression.preview_xp', 'Preview battle XP grants'),
      ('progression.apply_xp', 'Apply XP to detached player state'),
      ('progression.preview_level_up', 'Preview level and stat changes'),
      ('progression.apply_level_up', 'Apply levels to detached player state'),
      (
        'progression.preview_move_learning',
        'Inspect pending move-learning decisions',
      ),
      (
        'progression.accept_move_learning',
        'Resolve an exact move-learning acceptance',
      ),
      (
        'progression.refuse_move_learning',
        'Resolve an exact move-learning refusal',
      ),
      ('progression.preview_evolution', 'Inspect pending evolution decisions'),
      ('progression.accept_evolution', 'Resolve an exact evolution acceptance'),
      ('progression.refuse_evolution', 'Resolve an exact evolution refusal'),
      ('progression.preview_rewards', 'Preview authored battle rewards'),
      ('progression.apply_rewards', 'Apply rewards to detached player state'),
      (
        'progression.apply_capture_destination',
        'Preview runtime-owned party or box capture destination',
      ),
      ('progression.apply_badge', 'Apply a badge to detached player state'),
      (
        'progression.apply_trainer_defeated',
        'Apply trainer-defeated facts to detached player state',
      ),
    ])
      _descriptor(entry.$1, entry.$2),
  ]);
}

AuthoringActionDescriptor _descriptor(String id, String summary) {
  return AuthoringActionDescriptor(
    id: id,
    version: 1,
    summary: summary,
    inputSchemaId: 'pokemap.authoring/$id.input.v1',
    outputSchemaId: 'pokemap.authoring/$id.output.v1',
    riskLevel: id.startsWith('progression.preview_')
        ? AuthoringRiskLevel.readOnly
        : AuthoringRiskLevel.low,
    resourceKinds: const ['battleProgression', 'sandboxPlayerState'],
    capabilityIds: const ['authoring.battle.progression'],
    requiredPermissions: const [AuthoringPermission.playtestControl],
    guarantees: const [AuthoringGuarantee.dryRun],
    extensions: const {
      'productionWriteAllowed': false,
      'sandboxOnly': true,
    },
  );
}
```

## `packages/map_authoring/test/domains/gameplay/battle_simulation_contract_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('battle and progression actions are playtest-only and non-mutating', () {
    final descriptors = <AuthoringActionDescriptor>[
      ...BattleActions.descriptors,
      ...ProgressionActions.descriptors,
    ];

    expect(
      descriptors.map((entry) => entry.id),
      containsAll(<String>{
        'battle.setup_build_wild',
        'battle.setup_build_trainer',
        'battle.setup_build_static',
        'battle.simulate',
        'battle.inspect_timeline',
        'battle.apply_outcome_plan',
        'battle.receipt_get',
        'progression.preview_xp',
        'progression.preview_move_learning',
        'progression.accept_move_learning',
        'progression.preview_evolution',
        'progression.accept_evolution',
        'progression.preview_rewards',
        'progression.apply_capture_destination',
      }),
    );
    expect(
      descriptors.every(
        (entry) =>
            entry.requiredPermissions
                .contains(AuthoringPermission.playtestControl) &&
            !entry.requiredPermissions
                .contains(AuthoringPermission.projectWrite) &&
            entry.extensions['productionWriteAllowed'] == false,
      ),
      isTrue,
    );
    final battleActionIds =
        BattleActions.descriptors.map((entry) => entry.id).toSet();
    for (final unsupported in const <String>[
      'battle.choose_target',
      'battle.pause',
      'battle.resume',
      'battle.inject_rng_probe_only',
      'battle.apply_outcome_apply',
    ]) {
      expect(battleActionIds, isNot(contains(unsupported)));
    }
    expect(
      AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((entry) => entry.id),
      isNot(contains('battle.simulate')),
    );
  });
}
```

## `packages/map_runtime/lib/src/application/runtime_battle_authoring_capability_truth.dart`

```dart
enum RuntimeBattleAuthoringSupportStatus {
  supported,
  partial,
  unsupported,
}

final class RuntimeBattleAuthoringCapability {
  RuntimeBattleAuthoringCapability({
    required this.id,
    required this.status,
    required this.runtimeAuthority,
    Iterable<String> limitations = const <String>[],
  }) : limitations = List<String>.unmodifiable(limitations);

  final String id;
  final RuntimeBattleAuthoringSupportStatus status;
  final String runtimeAuthority;
  final List<String> limitations;

  Map<String, Object?> toJson() => {
        'id': id,
        'status': status.name,
        'runtimeAuthority': runtimeAuthority,
        'limitations': limitations,
      };
}

/// Capability truth sourced from the concrete runtime post-battle consumers.
///
/// Catalog presence is never treated as proof that an effect executes.
final class RuntimeBattleAuthoringCapabilityTruth {
  RuntimeBattleAuthoringCapabilityTruth()
      : capabilities = List<RuntimeBattleAuthoringCapability>.unmodifiable(
          _canonicalCapabilities,
        ),
        _byId = Map<String, RuntimeBattleAuthoringCapability>.unmodifiable({
          for (final capability in _canonicalCapabilities)
            capability.id: capability,
        });

  final List<RuntimeBattleAuthoringCapability> capabilities;
  final Map<String, RuntimeBattleAuthoringCapability> _byId;

  RuntimeBattleAuthoringCapability require(String id) {
    final capability = _byId[id];
    if (capability == null) {
      throw ArgumentError.value(id, 'id', 'is not a known capability');
    }
    return capability;
  }

  Map<String, Object?> toJson() => {
        'formatVersion': 1,
        'capabilities': [
          for (final capability in capabilities) capability.toJson(),
        ],
      };
}

final List<RuntimeBattleAuthoringCapability> _canonicalCapabilities = [
  RuntimeBattleAuthoringCapability(
    id: 'writeBack.playerHp',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'writePlayerBattleLineupBackToPartySlots',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'writeBack.movePp',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'writePlayerBattleLineupBackToPartySlots',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'writeBack.majorStatus',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'writePlayerBattleLineupBackToPartySlots',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'writeBack.heldItem',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'writePlayerPsdkHeldItemsBackToPartySlots',
    limitations: const <String>[
      'Requires a PSDK battle result; the legacy authoring simulator does not '
          'project held items.',
    ],
  ),
  RuntimeBattleAuthoringCapability(
    id: 'progression.experience',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimeBattleRewardResolver + BattleProgressionService',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'progression.level',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'BattleProgressionService',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'progression.moves',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimePostBattleDecisionCoordinator',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'progression.evolution',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimePostBattleDecisionCoordinator',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'capture.destination',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'applyRuntimeBattleOutcomeTransactionBase',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'reward.money',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'BattleProgressionService + GameStateMutations',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'reward.items',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'BattleProgressionService + GameStateMutations',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'reward.facts',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimePostBattleDecisionCoordinator',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'reward.badges',
    status: RuntimeBattleAuthoringSupportStatus.supported,
    runtimeAuthority: 'RuntimeBattleRewardResolver + GameStateMutations',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'battle.registeredEffects',
    status: RuntimeBattleAuthoringSupportStatus.partial,
    runtimeAuthority:
        'RuntimeBattleCombatantSeedBuilder + map_battle registries',
    limitations: const <String>[
      'Only registered move, ability and item effects execute.',
    ],
  ),
  RuntimeBattleAuthoringCapability(
    id: 'battle.unregisteredEffects',
    status: RuntimeBattleAuthoringSupportStatus.unsupported,
    runtimeAuthority: 'RuntimeBattleCombatantSeedBuilder diagnostics',
    limitations: const <String>[
      'Catalog presence is not runtime support.',
    ],
  ),
  RuntimeBattleAuthoringCapability(
    id: 'battle.manualTargetChoice',
    status: RuntimeBattleAuthoringSupportStatus.unsupported,
    runtimeAuthority: 'Singles battle decision contract',
  ),
  RuntimeBattleAuthoringCapability(
    id: 'battle.arbitraryRngProbe',
    status: RuntimeBattleAuthoringSupportStatus.unsupported,
    runtimeAuthority: 'BattleSeededRng',
  ),
];
```

## `packages/map_runtime/test/battle_authoring_simulation_runtime_consumption_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_authoring_capability_truth.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

void main() {
  test('runtime write-back consumes an authoring simulation outcome', () {
    final simulation = const BattleAuthoringSimulator().simulate(
      BattleAuthoringSimulationRequest(
        setup: const BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'hero',
            level: 5,
            maxHp: 20,
            stats: BattleStatsSnapshot(
              attack: 100,
              defense: 50,
              specialAttack: 50,
              specialDefense: 50,
              speed: 100,
            ),
            moves: <BattleMoveData>[
              BattleMoveData(id: 'finisher', name: 'Finisher', power: 100),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'wild',
            level: 5,
            maxHp: 5,
            stats: BattleStatsSnapshot(
              attack: 10,
              defense: 10,
              specialAttack: 10,
              specialDefense: 10,
              speed: 1,
            ),
            moves: <BattleMoveData>[
              BattleMoveData(id: 'tap', name: 'Tap', power: 1),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
        seed: 42,
      ),
    );
    const initialState = GameState(
      saveId: 'runtime-authoring-proof',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'hero',
            natureId: 'hardy',
            abilityId: 'overgrow',
            level: 5,
            knownMoveIds: <String>['finisher'],
            currentPpByMoveId: <String, int>{'finisher': 35},
            currentHp: 20,
          ),
        ],
      ),
    );

    final updated = applyRuntimeBattleOutcomeToGameState(
      gameState: initialState,
      context: RuntimeActiveBattleContext(
        request: _wildRequest(),
        playerPartyIndex: 0,
      ),
      outcome: simulation.outcome,
    );

    expect(
      updated.party.members.single.currentHp,
      simulation.outcome.finalState.player.currentHp,
    );
    expect(
      updated.party.members.single.currentPpByMoveId!['finisher'],
      simulation.outcome.finalState.player.moves.single.currentPp,
    );
    expect(
        initialState.party.members.single.currentPpByMoveId!['finisher'], 35);
  });

  test('runtime capability truth never promotes unsupported effects', () {
    final truth = RuntimeBattleAuthoringCapabilityTruth();

    for (final id in const <String>[
      'writeBack.playerHp',
      'writeBack.movePp',
      'writeBack.majorStatus',
      'writeBack.heldItem',
      'progression.experience',
      'progression.level',
      'progression.moves',
      'progression.evolution',
      'capture.destination',
      'reward.money',
      'reward.items',
      'reward.facts',
      'reward.badges',
    ]) {
      expect(
        truth.require(id).status,
        RuntimeBattleAuthoringSupportStatus.supported,
        reason: id,
      );
    }
    expect(
      truth.require('battle.registeredEffects').status,
      RuntimeBattleAuthoringSupportStatus.partial,
    );
    expect(
      truth.require('battle.unregisteredEffects').status,
      RuntimeBattleAuthoringSupportStatus.unsupported,
    );
  });
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'authoring-proof',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field',
    zoneId: 'grass',
    tableId: 'grass-table',
    encounterKind: EncounterKind.walk,
    speciesId: 'wild',
    level: 5,
    minLevel: 5,
    maxLevel: 5,
    weight: 1,
    playerPos: GridPos(x: 1, y: 1),
  );
}
```
