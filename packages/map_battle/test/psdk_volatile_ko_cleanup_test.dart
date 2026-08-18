import 'package:map_battle/map_battle.dart';
// TauntEffect n'est pas exporte : c'est un compteur de duree sans garde propre
// sur isFainted, donc le seul moyen d'observer le filtre du dispatch.
import 'package:map_battle/src/domain/effect/move/taunt_effect.dart';
import 'package:test/test.dart';

/// Nettoyage des volatiles au KO, troisième chemin de BETA-BAT-005.
///
/// CONTRAT MESURÉ LE 2026-08-18, et il n'est pas celui qu'on imaginerait. Au
/// moment du KO, les volatiles de portée combattant RESTENT ATTACHÉS : rien ne
/// les retire là. Ce qui les retire, c'est la sortie de terrain, qui suit
/// toujours un KO dans un combat qui continue.
///
/// Ce serait un défaut si un effet pouvait encore agir dans cet intervalle. Il
/// ne peut pas, et la protection est DOUBLE — ce qui a demandé deux essais pour
/// être mesuré correctement :
///  1. `tickEndTurnEffects` filtre le dispatch d'un porteur KO sur les seules
///     portées terrain (`!ownerIsFainted || effect.scope is
///     FieldBattleEffectScope`) ;
///  2. treize des vingt-deux effets de fin de tour se gardent EN PLUS eux-mêmes
///     sur `isFainted`, dont Aqua Ring et Leech Seed.
///
/// Cette redondance a d'abord masqué ma mesure. Un premier test prétendait
/// prouver le filtre du handler avec Leech Seed : retirer le filtre ne changeait
/// rien, parce qu'un porteur à zéro PV n'a de toute façon rien à drainer. Il
/// faut un effet SANS garde propre pour voir le filtre agir — Taunt, un simple
/// compteur de durée, dont le décrément est observable.
///
/// Et si le combat se termine au lieu de continuer, le write-back ne persiste
/// aucun volatile — vérifié par BETA-BAT-004.
///
/// Ces tests figent les trois maillons. Le deuxième est celui qui porte tout :
/// sans lui, « ils restent attachés » serait une fuite plutôt qu'un contrat.
const int _seededHp = 12;
const int _sourceHp = 100;
const int _tauntDuration = 3;

int _tauntTurns(PsdkBattleState state) {
  final taunt = state
      .battlerAt(psdkPlayerSlot)
      .effects
      .effects
      .firstWhere((effect) => effect.id == 'taunt');
  return taunt.remainingTurns ?? -1;
}

void main() {
  group('BETA-BAT-005 volatiles across a knock out', () {
    test('a fainted battler still carries the volatiles it had', () {
      final engine = _engine();
      final knockedOut = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final victim = knockedOut.state.battlerAt(psdkPlayerSlot);

      expect(victim.isFainted, isTrue, reason: 'the vector needs a real KO');
      expect(
        victim.effects.values,
        containsAll(<String>['confusion', 'leech_seed']),
      );
    });

    test('the replacement arrives without the volatiles of the one it replaces',
        () {
      final engine = _engine();
      engine.submit(const BattleDecision.fight(moveSlot: 0));
      final switched =
          engine.submit(const BattleDecision.switchPokemon(partyIndex: 1));

      expect(switched.state.battlerAt(psdkPlayerSlot).effects.values, isEmpty);
      final benched = switched.state.psdkState
          .partyForBank(0)
          .firstWhere((battler) => battler.id == 'victim');
      expect(
        benched.effects.values,
        isEmpty,
        reason: 'the switch-out snapshot is what actually clears them',
      );
    });

    test('a volatile on a fainted battler does not even tick', () {
      // Le maillon porteur, mesuré sur un effet SANS garde propre : Taunt est un
      // compteur de durée, donc son décrément dit si le dispatch l'a atteint.
      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        _endTurnContext(ownerIsFainted: true),
      );

      expect(_tauntTurns(result.state), _tauntDuration,
          reason: 'a fainted owner must not progress its volatiles at all');
    });

    test('the same volatile on a living battler does tick', () {
      // Contraste indispensable : sans lui, le cas précédent passerait aussi
      // avec un Taunt qui ne compte jamais.
      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        _endTurnContext(ownerIsFainted: false),
      );

      expect(_tauntTurns(result.state), lessThan(_tauntDuration));
    });

    test('leech seed feeds nobody from a fainted host', () {
      // Vrai aussi, mais garanti par le garde propre de l'effet plutôt que par
      // le filtre du dispatch : un porteur à zéro PV n'a rien à donner.
      final result = const BattleEndTurnHandler().tickEndTurnEffects(
        _endTurnContext(ownerIsFainted: true),
      );

      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, _sourceHp);
    });
  });
}

BattleHandlerContext _endTurnContext({required bool ownerIsFainted}) {
  return BattleHandlerContext(
    state: PsdkBattleState.pokeMapBetaV1ForTest(
      combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
        psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
          _combatant(
            'seeded',
            maxHp: 200,
            currentHp: ownerIsFainted ? 0 : 200,
            effects: _seededVolatiles(),
          ),
        ),
        psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
          _combatant('source', maxHp: 200, currentHp: _sourceHp),
        ),
      },
    ),
    rng: BattleRngStreams.fromSeeds(
      moveDamageSeed: 1,
      moveCriticalSeed: 2,
      moveAccuracySeed: 3,
      genericSeed: 4,
    ),
    turn: 3,
    user: psdkPlayerSlot,
  );
}

BattleEngine _engine() {
  return BattleEngine(
    setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant(
        'victim',
        maxHp: _seededHp,
        currentHp: _seededHp,
        effects: _seededVolatiles(),
      ),
      playerReserves: <PsdkBattleCombatantSetup>[
        _combatant('reserve', maxHp: 200, currentHp: 200),
      ],
      opponent: _combatant(
        'killer',
        maxHp: 200,
        currentHp: 200,
        attack: 200,
        speed: 200,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

PsdkBattleEffectStack _seededVolatiles() {
  return const PsdkBattleEffectStack.empty()
      .addEffect(
        ConfusionEffect(
          scope: BattlerBattleEffectScope(psdkPlayerSlot),
          remainingConfusionTurns: 4,
        ),
      )
      .addEffect(
        LeechSeedEffect(
          scope: BattlerBattleEffectScope(psdkPlayerSlot),
          source: psdkOpponentSlot,
        ),
      )
      .addEffect(
        TauntEffect(
          scope: BattlerBattleEffectScope(psdkPlayerSlot),
          remainingTurns: _tauntDuration,
        ),
      );
}

PsdkBattleCombatantSetup _combatant(
  String id, {
  required int maxHp,
  required int currentHp,
  int attack = 20,
  int speed = 10,
  PsdkBattleEffectStack? effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: maxHp,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: attack,
      defense: 20,
      specialAttack: attack,
      specialDefense: 20,
      speed: speed,
    ),
    effects: effects,
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 60,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}
