import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

// Recette du 2026-08-24 — le feedback manquant, côté traduction PSDK.
//
// L'adaptateur ne traduisait que trois événements de la timeline PSDK
// (dégât, soin d'objet, capture) : un move de statut comme Doux Baiser, une
// attaque ratée ou une immunité ne produisaient RIEN côté présentation — le
// joueur regardait un écran muet. Ces tests verrouillent chaque traduction de
// bout en bout : la décision entre dans le moteur PSDK réel, et on lit ce que
// la session d'affichage legacy en retire.

void main() {
  group('recette 2026-08-24 — la traduction du feedback PSDK', () {
    test('Doux Baiser se traduit : un usage unique et la confusion appliquée',
        () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'sweet_kiss',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              statuses: <PsdkBattleMoveStatus>[
                PsdkBattleMoveStatus.volatile(
                  status: PsdkBattleVolatileStatus.confusion,
                  chance: 100,
                ),
              ],
            ),
          ],
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: false)
          .state
          .currentTurn!;

      final sweetKissExecutions = turn.timeline
          .whereType<BattleTurnExecutionEvent>()
          .where((event) => event.execution.move.id == 'sweet_kiss')
          .toList();
      expect(
        sweetKissExecutions,
        hasLength(1),
        reason: 'la déclaration sans dégât se traduit une fois, pas zéro, '
            'pas deux',
      );
      expect(sweetKissExecutions.single.execution.didHit, isTrue);
      expect(sweetKissExecutions.single.execution.damage, 0);
      expect(
        turn.timeline
            .whereType<BattleTurnVolatileEvent>()
            .map((event) => event.event.kind),
        contains(BattleVolatileEventKind.confusionApplied),
        reason: 'le moteur émet désormais l’application de la confusion et '
            'l’adaptateur la traduit',
      );
    });

    test('une immunité se traduit en exécution à multiplicateur nul', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'lick', power: 30, type: 'ghost', accuracy: 0),
          ],
        ),
      );

      final result =
          session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      expect(
        result.timeline.events.whereType<BattleMoveImmuneTimelineEvent>(),
        isNotEmpty,
        reason: 'spectre contre normal doit être une immunité moteur',
      );

      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: false)
          .state
          .currentTurn!;
      final lickExecutions = turn.timeline
          .whereType<BattleTurnExecutionEvent>()
          .where((event) => event.execution.move.id == 'lick')
          .toList();
      expect(lickExecutions, hasLength(1));
      expect(lickExecutions.single.execution.didHit, isTrue);
      expect(
        lickExecutions.single.execution.typeEffectivenessMultiplier,
        0.0,
      );
    });

    test('une attaque ratée se traduit en exécution didHit=false', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'pound', power: 40, accuracy: 1),
          ],
        ),
      );

      final result =
          session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      expect(
        result.timeline.events.whereType<BattleMoveMissedTimelineEvent>(),
        isNotEmpty,
        reason: 'précision 1 % : le jet seedé doit rater — sinon changer le '
            'seed moveAccuracy du harnais',
      );

      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: false)
          .state
          .currentTurn!;
      final poundExecutions = turn.timeline
          .whereType<BattleTurnExecutionEvent>()
          .where((event) => event.execution.move.id == 'pound')
          .toList();
      expect(poundExecutions, hasLength(1));
      expect(poundExecutions.single.execution.didHit, isFalse);
    });

    test('un move à dégâts ne traduit PAS sa déclaration en doublon', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'tackle', power: 40, accuracy: 0),
          ],
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: false)
          .state
          .currentTurn!;

      final tackleExecutions = turn.timeline
          .whereType<BattleTurnExecutionEvent>()
          .where((event) =>
              event.execution.move.id == 'tackle' &&
              event.execution.attackerSide == BattleSideId.player)
          .toList();
      expect(
        tackleExecutions,
        hasLength(1),
        reason: 'le dégât couvre la déclaration : un seul message d’usage',
      );
      expect(tackleExecutions.single.execution.damage, greaterThan(0));
    });

    test('un statut majeur appliqué se traduit en événement de statut', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(
        _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'poison_powder',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              statuses: <PsdkBattleMoveStatus>[
                PsdkBattleMoveStatus(
                  status: PsdkBattleMajorStatus.poison,
                  chance: 100,
                ),
              ],
            ),
          ],
        ),
      );

      session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final turn = session
          .createLegacyDisplaySession(isTrainerBattle: false)
          .state
          .currentTurn!;

      final statusEvents =
          turn.timeline.whereType<BattleTurnStatusEvent>().toList();
      expect(statusEvents, isNotEmpty);
      expect(statusEvents.first.event.kind, BattleStatusEventKind.applied);
      expect(statusEvents.first.event.status, BattleMajorStatusId.psn);
      expect(statusEvents.first.event.targetSide, BattleSideId.enemy);
    });
  });
}

PsdkBattleSetup _setup({required List<PsdkBattleMoveData> playerMoves}) {
  return PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(id: 'player', moves: playerMoves),
    opponent: _combatant(
      id: 'wild',
      moves: <PsdkBattleMoveData>[
        _move(id: 'tackle', power: 40, accuracy: 0),
      ],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 7,
      generic: 47,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 120,
    currentHp: 120,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  int accuracy = 100,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 15,
    currentPp: 15,
    priority: 0,
    battleEngineMethod:
        category == PsdkBattleMoveCategory.status ? 's_status' : 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    statuses: statuses,
  );
}
