import 'dart:convert';

import 'package:map_core/map_core.dart';

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
  const BattleAuthoringSetupFactory({required this.ruleset});

  const BattleAuthoringSetupFactory.pokeMapBetaV1ForTest()
      : ruleset = PokemonRulesetProfile.pokeMapBetaV1;

  final PokemonRulesetProfile ruleset;

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
      ruleset: ruleset,
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
      ruleset: ruleset,
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
      ruleset: ruleset,
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

/// Reçu d'une simulation, destiné à rendre un run rejouable et auditable.
///
/// BETA-BAT-008 exige que « seed ET ruleset » y figurent. Le seed y était,
/// le ruleset non : deux simulations conduites sous des profils de règles
/// différents produisaient des reçus indiscernables, alors que c'est
/// précisément ce qui change le résultat.
final class BattleAuthoringSimulationReceipt {
  const BattleAuthoringSimulationReceipt({
    required this.id,
    required this.seed,
    required this.rulesetProfileId,
    required this.rulesetSchemaVersion,
    required this.stepCount,
    required this.outcomeKind,
  });

  final String id;
  final int seed;

  /// Profil de règles sous lequel ce run a été résolu.
  final String rulesetProfileId;
  final int rulesetSchemaVersion;

  final int stepCount;
  final BattleOutcomeType outcomeKind;

  Map<String, Object?> toJson() => {
        'id': id,
        'seed': seed,
        'rulesetProfileId': rulesetProfileId,
        'rulesetSchemaVersion': rulesetSchemaVersion,
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
      ruleset: request.setup.ruleset,
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
  required PokemonRulesetProfile ruleset,
  required BattleOutcome outcome,
  required List<BattleAuthoringTraceEntry> trace,
  required BattleAuthoringWriteBack writeBack,
}) {
  // Le ruleset entre dans le PAYLOAD, donc dans le hash de l'identifiant. Le
  // porter seulement en champ lisible aurait laissé deux runs sous des règles
  // différentes partager un même identifiant de reçu.
  final payload = jsonEncode({
    'formatVersion': 1,
    'seed': seed,
    'ruleset': ruleset.toJson(),
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
    rulesetProfileId: ruleset.profileId,
    rulesetSchemaVersion: ruleset.schemaVersion,
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
