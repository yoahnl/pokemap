import 'dart:ui' show Offset, Rect;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('PostBattleProgressionOverlayComponent', () {
    test('presents every ordered message then completes exactly once',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _automaticResolution,
      );
      final started = await _begin(coordinator);
      var completionCount = 0;
      final overlay = PostBattleProgressionOverlayComponent(
        initialResult: started,
        viewportSize: Vector2(800, 600),
        onMoveLearningDecision: (_) => throw StateError('not expected'),
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () => completionCount += 1,
      );
      final game = FlameGame();
      await game.add(overlay);
      await game.ready();

      expect(overlay.messageSemanticKey, 'post-battle-message');
      expect(overlay.currentMessageText, 'Victoire !');
      expect(overlay.decisionLabels, isEmpty);
      expect(overlay.currentPresentationSnapshot?.message, 'Victoire !');
      expect(
        overlay.currentPresentationSnapshot?.messageKind,
        RuntimePostBattleMessageKind.victory,
      );

      while (!overlay.isCompleted) {
        expect(overlay.validateSelectedChoice(), isTrue);
      }
      await overlay.completionFuture;

      expect(completionCount, 1);
      expect(overlay.validateSelectedChoice(), isFalse);
      expect(completionCount, 1);
    });

    test('publishes state without mounting Flame chrome in player mode',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _automaticResolution,
      );
      final overlay = PostBattleProgressionOverlayComponent(
        initialResult: await _begin(coordinator),
        viewportSize: Vector2(800, 600),
        renderInFlame: false,
        onMoveLearningDecision: (_) => throw StateError('not expected'),
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () {},
      );
      final game = FlameGame();
      await game.add(overlay);
      await game.ready();

      expect(overlay.currentPresentationSnapshot?.message, 'Victoire !');
      expect(overlay.children, isEmpty);
      expect(overlay.containsLocalPoint(Vector2(20, 20)), isFalse);
    });

    test('uses exact move decisions and exposes four replacement labels',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _pendingMoveResolution,
      );
      final started = await _begin(
        coordinator,
        knownMoves: const <String>[
          'tackle',
          'growl',
          'tail_whip',
          'focus_energy',
        ],
      );
      BattleMoveLearningDecision? submitted;
      late final PostBattleProgressionOverlayComponent overlay;
      overlay = PostBattleProgressionOverlayComponent(
        initialResult: started,
        viewportSize: Vector2(800, 600),
        onMoveLearningDecision: (decision) {
          submitted = decision;
          return coordinator.resolveMoveLearning(
            transaction: overlay.currentTransaction!,
            decision: decision,
          );
        },
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () {},
      );
      final game = FlameGame();
      await game.add(overlay);
      await game.ready();

      while (overlay.decisionLabels.isEmpty) {
        expect(overlay.validateSelectedChoice(), isTrue);
      }
      expect(overlay.decisionSemanticKeys,
          <String>['post-battle-choice-learn', 'post-battle-choice-decline']);
      expect(overlay.decisionLabels, <String>['Apprendre', 'Ne pas apprendre']);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(submitted, isA<LearnBattleMoveLearningDecision>());

      expect(
        overlay.decisionLabels,
        <String>[
          'Tackle',
          'Growl',
          'Tail whip',
          'Focus energy',
          'Ne pas apprendre',
        ],
      );
      expect(overlay.selectDecision(1), isTrue);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(submitted, isA<ReplaceBattleMoveLearningDecision>());
      final replacement = submitted! as ReplaceBattleMoveLearningDecision;
      expect(replacement.replaceMoveIndex, 1);
      expect(replacement.expectedReplacedMoveId, 'growl');
      expect(
        overlay
            .currentTransaction!.finalState!.party.members.single.knownMoveIds,
        <String>['tackle', 'quick_attack', 'tail_whip', 'focus_energy'],
      );
    });

    test('offers exact accept and refusal decisions for evolution', () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _pendingEvolutionResolution,
      );
      final started = await _begin(coordinator);
      BattleEvolutionDecision? submitted;
      late final PostBattleProgressionOverlayComponent overlay;
      overlay = PostBattleProgressionOverlayComponent(
        initialResult: started,
        viewportSize: Vector2(800, 600),
        onMoveLearningDecision: (_) => throw StateError('not expected'),
        onEvolutionDecision: (decision) {
          submitted = decision;
          return coordinator.resolveEvolution(
            transaction: overlay.currentTransaction!,
            decision: decision,
          );
        },
        onCompleted: () {},
      );
      final game = FlameGame();
      await game.add(overlay);
      await game.ready();

      while (overlay.decisionLabels.isEmpty) {
        overlay.validateSelectedChoice();
      }
      expect(overlay.decisionLabels, <String>['Évoluer', 'Refuser']);
      expect(overlay.selectDecision(1), isTrue);
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(submitted, isA<RefuseBattleEvolutionDecision>());
      expect(
          overlay
              .currentTransaction!.finalState!.party.members.single.speciesId,
          'hero');
    });

    test('renders a typed error and waits for acknowledgement', () async {
      final original = _state();
      var completed = false;
      final overlay = PostBattleProgressionOverlayComponent(
        initialResult: RuntimePostBattleCoordinatorResult.failure(
          failure: RuntimePostBattleCoordinatorFailure(
            code: RuntimePostBattleCoordinatorFailureCode.rewardResolution,
            message: 'Données de progression manquantes.',
            originalState: original,
          ),
        ),
        viewportSize: Vector2(800, 600),
        onMoveLearningDecision: (_) => throw StateError('not expected'),
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () => completed = true,
      );
      final game = FlameGame();
      await game.add(overlay);
      await game.ready();

      expect(overlay.currentMessageText, 'Données de progression manquantes.');
      expect(overlay.currentMessageKind, RuntimePostBattleMessageKind.error);
      expect(completed, isFalse);
      expect(overlay.validateSelectedChoice(), isTrue);
      await overlay.completionFuture;
      expect(completed, isTrue);
    });

    test('turns a decision callback exception into an acknowledgeable failure',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _pendingMoveResolution,
      );
      final started = await _begin(
        coordinator,
        knownMoves: const <String>[
          'tackle',
          'growl',
          'tail_whip',
          'focus_energy',
        ],
      );
      var completed = false;
      final overlay = PostBattleProgressionOverlayComponent(
        initialResult: started,
        viewportSize: Vector2(800, 600),
        onMoveLearningDecision: (_) => throw StateError('decision failed'),
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () => completed = true,
      );
      final game = FlameGame();
      await game.add(overlay);
      await game.ready();

      while (overlay.decisionLabels.isEmpty) {
        expect(overlay.validateSelectedChoice(), isTrue);
      }
      expect(overlay.validateSelectedChoice(), isTrue);
      expect(overlay.currentFailure, isNotNull);
      expect(overlay.currentMessageKind, RuntimePostBattleMessageKind.error);
      expect(overlay.validateSelectedChoice(), isTrue);
      await overlay.completionFuture;
      expect(completed, isTrue);
    });

    test('completes with error when the completion callback throws', () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _automaticResolution,
      );
      final overlay = PostBattleProgressionOverlayComponent(
        initialResult: await _begin(coordinator),
        viewportSize: Vector2(800, 600),
        onMoveLearningDecision: (_) => throw StateError('not expected'),
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () => throw StateError('commit failed'),
      );
      final game = FlameGame();
      await game.add(overlay);
      await game.ready();
      final completion = expectLater(
        overlay.completionFuture,
        throwsA(isA<StateError>()),
      );

      while (overlay.currentTransaction?.isReadyToCommit != true ||
          overlay.currentMessageText !=
              overlay.currentTransaction!.messages.last.text) {
        expect(overlay.validateSelectedChoice(), isTrue);
      }
      expect(
        overlay.validateSelectedChoice,
        throwsA(isA<StateError>()),
      );
      await completion;
      expect(overlay.isCompleted, isTrue);
      expect(overlay.validateSelectedChoice(), isFalse);
    });

    test('keeps five replacement choices inside a 640x360 viewport and panel',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _pendingMoveResolution,
      );
      late final PostBattleProgressionOverlayComponent overlay;
      overlay = PostBattleProgressionOverlayComponent(
        initialResult: await _begin(
          coordinator,
          knownMoves: const <String>[
            'tackle',
            'growl',
            'tail_whip',
            'focus_energy',
          ],
        ),
        viewportSize: Vector2(640, 360),
        onMoveLearningDecision: (decision) {
          return coordinator.resolveMoveLearning(
            transaction: overlay.currentTransaction!,
            decision: decision,
          );
        },
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () {},
      );
      final game = FlameGame();
      game.onGameResize(Vector2(640, 360));
      await game.add(overlay);
      await game.ready();

      while (overlay.decisionLabels.length != 5) {
        expect(overlay.validateSelectedChoice(), isTrue);
      }

      const viewport = Rect.fromLTWH(0, 0, 640, 360);
      final panel = overlay.debugPanelRect;
      expect(viewport.contains(panel.topLeft), isTrue);
      expect(viewport.contains(panel.bottomRight), isTrue);
      expect(overlay.debugDecisionHitBoxes, hasLength(5));
      for (final hitBox in overlay.debugDecisionHitBoxes) {
        expect(panel.contains(hitBox.topLeft), isTrue);
        expect(panel.contains(hitBox.bottomRight), isTrue);
        expect(viewport.contains(hitBox.topLeft), isTrue);
        expect(viewport.contains(hitBox.bottomRight), isTrue);
      }
    });

    test('fits the exact replacement prompt above five choices at 640x360',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _pendingMoveResolution,
      );
      late final PostBattleProgressionOverlayComponent overlay;
      overlay = PostBattleProgressionOverlayComponent(
        initialResult: await _begin(
          coordinator,
          knownMoves: const <String>[
            'tackle',
            'growl',
            'tail_whip',
            'focus_energy',
          ],
        ),
        viewportSize: Vector2(640, 360),
        onMoveLearningDecision: (decision) {
          return coordinator.resolveMoveLearning(
            transaction: overlay.currentTransaction!,
            decision: decision,
          );
        },
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () {},
      );
      final game = FlameGame();
      game.onGameResize(Vector2(640, 360));
      await game.add(overlay);
      await game.ready();

      while (overlay.decisionLabels.length != 5) {
        expect(overlay.validateSelectedChoice(), isTrue);
      }
      expect(
        overlay.currentMessageText,
        'Choisissez une capacité à remplacer pour apprendre Quick attack.',
      );
      final message = overlay.debugMessageComponent!;
      await message.redraw();
      final renderedTextHeight = message.lineHeight * message.lines.length;

      expect(message.lines.length, greaterThan(1));
      expect(
        renderedTextHeight,
        lessThanOrEqualTo(overlay.debugMessageRect.height),
        reason: 'messageSize=${message.size}, box=${overlay.debugMessageRect}, '
            'maxWidth=${message.boxConfig.maxWidth}, '
            'textWidth=${message.textRenderer.getLineMetrics(message.text).width}, '
            'lineWidths=${message.lines.map((line) => message.textRenderer.getLineMetrics(line).width).toList()}, '
            'wrapped lines: ${message.lines}',
      );
      expect(overlay.debugDecisionHitBoxes, hasLength(5));
    });

    test('ignores taps outside decision rows even at the same vertical offset',
        () async {
      final coordinator = RuntimePostBattleDecisionCoordinator(
        resolveReward: _pendingMoveResolution,
      );
      var submissionCount = 0;
      late final PostBattleProgressionOverlayComponent overlay;
      overlay = PostBattleProgressionOverlayComponent(
        initialResult: await _begin(
          coordinator,
          knownMoves: const <String>[
            'tackle',
            'growl',
            'tail_whip',
            'focus_energy',
          ],
        ),
        viewportSize: Vector2(640, 360),
        onMoveLearningDecision: (decision) {
          submissionCount += 1;
          return coordinator.resolveMoveLearning(
            transaction: overlay.currentTransaction!,
            decision: decision,
          );
        },
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () {},
      );
      final game = FlameGame();
      game.onGameResize(Vector2(640, 360));
      await game.add(overlay);
      await game.ready();

      while (overlay.decisionLabels.length != 5) {
        expect(overlay.validateSelectedChoice(), isTrue);
      }
      final submissionCountBeforeTap = submissionCount;
      final firstRow = overlay.debugDecisionHitBoxes.first;
      final outsidePanel = Offset(
        overlay.debugPanelRect.left - 4,
        firstRow.center.dy,
      );

      expect(overlay.debugTapAt(outsidePanel), isFalse);

      expect(submissionCount, submissionCountBeforeTap);
      expect(overlay.decisionLabels, hasLength(5));
      expect(overlay.selectedDecisionIndex, 0);
    });

    test('wraps a long message inside the panel at 640x360', () async {
      final overlay = PostBattleProgressionOverlayComponent(
        initialResult: RuntimePostBattleCoordinatorResult.failure(
          failure: RuntimePostBattleCoordinatorFailure(
            code: RuntimePostBattleCoordinatorFailureCode.rewardResolution,
            message:
                'Cette récompense post-combat contient une explication assez '
                'longue pour nécessiter plusieurs lignes dans une petite '
                'fenêtre sans jamais sortir du panneau.',
            originalState: _state(),
          ),
        ),
        viewportSize: Vector2(640, 360),
        onMoveLearningDecision: (_) => throw StateError('not expected'),
        onEvolutionDecision: (_) => throw StateError('not expected'),
        onCompleted: () {},
      );
      final game = FlameGame();
      game.onGameResize(Vector2(640, 360));
      await game.add(overlay);
      await game.ready();

      const viewport = Rect.fromLTWH(0, 0, 640, 360);
      final panel = overlay.debugPanelRect;
      final message = overlay.debugMessageRect;
      expect(overlay.debugMessageComponent!.lines.length, greaterThan(1));
      expect(panel.contains(message.topLeft), isTrue);
      expect(panel.contains(message.bottomRight), isTrue);
      expect(viewport.contains(message.topLeft), isTrue);
      expect(viewport.contains(message.bottomRight), isTrue);
    });
  });
}

Future<RuntimePostBattleCoordinatorResult> _begin(
  RuntimePostBattleDecisionCoordinator coordinator, {
  List<String> knownMoves = const <String>['tackle'],
}) {
  return coordinator.begin(
    transactionBaseState: _state(knownMoves: knownMoves),
    bundle: _bundle(),
    runtimeContext: _context(),
    outcome: _outcome(),
    itemCatalog: ItemCatalogSnapshot.empty(),
  );
}

Future<RuntimeBattleRewardResolution> _automaticResolution({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
}) async {
  return _resolution(
    state: postWriteBackState,
    moveCandidates: const <PokemonMoveLearningCandidate>[
      PokemonMoveLearningCandidate(
        opportunityId: 'hero:6:quick_attack',
        moveId: 'quick_attack',
        learnedAtLevel: 6,
        maxPp: 30,
      ),
    ],
  );
}

Future<RuntimeBattleRewardResolution> _pendingMoveResolution({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
}) async {
  return _resolution(
    state: postWriteBackState,
    moveCandidates: const <PokemonMoveLearningCandidate>[
      PokemonMoveLearningCandidate(
        opportunityId: 'hero:6:quick_attack',
        moveId: 'quick_attack',
        learnedAtLevel: 6,
        maxPp: 30,
      ),
    ],
  );
}

Future<RuntimeBattleRewardResolution> _pendingEvolutionResolution({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
}) async {
  return _resolution(
    state: postWriteBackState,
    evolutionCandidates: <PokemonEvolutionCandidate>[
      _evolutionCandidate(),
    ],
  );
}

RuntimeBattleRewardResolution _resolution({
  required GameState state,
  List<PokemonMoveLearningCandidate> moveCandidates =
      const <PokemonMoveLearningCandidate>[],
  List<PokemonEvolutionCandidate> evolutionCandidates =
      const <PokemonEvolutionCandidate>[],
}) {
  final reward = BattleReward(
    sourceKind: BattleRewardSourceKind.trainer,
    trainerId: 'trainer_iris',
    money: 100,
  );
  final context = BattleProgressionContext(
    outcome: BattleProgressionOutcomeKind.victory,
    playerParticipantPartySlots: const <int>{0},
    defeatedOpponents: const <BattleProgressionDefeatedOpponent>[
      BattleProgressionDefeatedOpponent(level: 14, baseExperience: 70),
    ],
    partySlotMetadata: const <BattleProgressionPartySlotMetadata>[
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
        Iterable<PokemonMoveLearningCandidate>>{0: moveCandidates},
    evolutionCandidatesByPartySlot: <int, Iterable<PokemonEvolutionCandidate>>{
      0: evolutionCandidates
    },
  );
  return RuntimeBattleRewardResolution(
    baseState: state,
    reward: reward,
    progressionContext: context,
    progression: const BattleProgressionService().apply(
      state: state,
      context: context,
      reward: reward,
      applyAuthoredRewards: false,
    ),
  );
}

PokemonEvolutionCandidate _evolutionCandidate() {
  return PokemonEvolutionCandidate(
    opportunityId: 'hero:6:hero_evolved',
    sourceSpeciesId: 'hero',
    targetSpeciesId: 'hero_evolved',
    minLevel: 6,
    targetBaseStats: const PokemonBaseStats(
      hp: 60,
      attack: 62,
      defense: 63,
      specialAttack: 80,
      specialDefense: 80,
      speed: 60,
    ),
    targetPrimaryAbilityId: 'hero_power',
    targetAbilityIds: const <String>['hero_power'],
  );
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: const ProjectManifest(
      name: 'Overlay fixture',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(id: 'route', name: 'Route', relativePath: 'route.json'),
      ],
      tilesets: <ProjectTilesetEntry>[],
      trainers: <ProjectTrainerEntry>[
        ProjectTrainerEntry(
          id: 'trainer_iris',
          name: 'Iris',
          trainerClass: 'Rivale',
        ),
      ],
    ),
    map: const MapData(
      id: 'route',
      name: 'Route',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[],
    ),
    projectRootDirectory: '/tmp/overlay-fixture',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

GameState _state({List<String> knownMoves = const <String>['tackle']}) {
  return GameState(
    saveId: 'overlay',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'hero',
          natureId: 'hardy',
          abilityId: 'hero_power',
          level: 5,
          knownMoveIds: knownMoves,
          currentPpByMoveId: <String, int>{
            for (final move in knownMoves) move: 35,
          },
          experience: 125,
          currentHp: 15,
        ),
      ],
    ),
  );
}

RuntimeActiveBattleContext _context() {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: const TrainerBattleStartRequest(
      requestId: 'trainer',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'route',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      mapId: 'route',
      trainerId: 'trainer_iris',
      npcEntityId: 'npc_iris',
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: const <int>[0],
  );
}

BattleOutcome _outcome() {
  return BattleOutcome(
    type: BattleOutcomeType.victory,
    finalState: BattleState(
      phase: BattlePhase.finished,
      player: _combatant('hero', level: 5, currentHp: 7),
      enemy: _combatant('foe', level: 14, currentHp: 0),
      playerParticipantLineupIndexes: const <int>{0},
    ),
  );
}

BattleCombatant _combatant(
  String speciesId, {
  required int level,
  required int currentHp,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    lineupIndex: 0,
    level: level,
    currentHp: currentHp,
    maxHp: 19,
    stats: const BattleStatsSnapshot(
      attack: 10,
      defense: 10,
      specialAttack: 10,
      specialDefense: 10,
      speed: 10,
    ),
    moves: const <BattleMove>[
      BattleMove(id: 'tackle', name: 'Charge', power: 40, currentPp: 30),
    ],
  );
}
