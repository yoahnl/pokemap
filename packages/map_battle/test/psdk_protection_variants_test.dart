import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

/// Cycle de vie des variantes de protection et de leur punition de contact.
///
/// HISTORIQUE, parce qu'il explique la forme de ces tests. L'inventaire de
/// BETA-BAT-005 a mesuré que trois membres de la famille protection étaient
/// atteignables sans qu'aucun test ne les nomme. En écrivant leur cycle de vie,
/// un écart est apparu : AUCUNE variante ne punissait le contact DANS LE FLUX
/// RÉEL D'UNE CAPACITÉ. Six variantes s'y comportaient comme un simple
/// `protect`.
///
/// La nuance compte, et un premier diagnostic de ma part était trop large. La
/// punition FONCTIONNAIT déjà pour des dégâts appliqués directement à un
/// combattant protégé, ce que `protection_redirection_effects_test` couvre en
/// passant par `BattleDamageHandler.applyDamage`. Ce qui manquait, c'était la
/// seule entrée que le jeu emprunte vraiment.
///
/// La cause, diagnostiquée avec le Ruby pour oracle : PSDK joue la punition
/// depuis `on_move_prevention_target` (`001 Protect.rb`, `play_protect_effect`),
/// alors que `_applyContactPunishment` n'était accrochée qu'à
/// `onDamagePrevention` — jamais atteint quand la prévention arrête la capacité
/// en amont.
///
/// Corrigé par un hook mutateur dédié, `BattleEffect.onMovePrevented`, appelé
/// sur le seul effet qui a prévenu. Le contrat de `onMovePreventionTarget` n'a
/// pas bougé — dix fichiers l'implémentent ou le dispatchent — et la décision de
/// prévenir reste pure. Les deux entrées coexistent sans se cumuler : voir le
/// commentaire de `onDamagePrevention` dans `protect_effect.dart`.
///
/// Punitions de référence, lues dans le Ruby :
///   spiky_shield     -> dégâts de maxHp / 8
///   king_s_shield    -> Attaque -1
///   baneful_bunker   -> poison
///   obstruct         -> Défense -2
///   silk_trap        -> Vitesse -1
///   burning_bulwark  -> brûlure

const int _maxHp = 400;

void main() {
  group('BETA-BAT-005 protection variants block and punish contact', () {
    test('spiky_shield deals a fraction of the attacker maximum HP', () {
      final result = _protectThenContact(protectMoveId: 'spiky_shield');

      expect(_damageToDefender(result), 0);
      expect(
        result.state.battlerAt(psdkPlayerSlot).currentHp,
        _maxHp - (_maxHp / 8).floor(),
      );
    });

    test('king_s_shield drops the attacker Attack by one stage', () {
      final attacker = _punished('king_s_shield');

      expect(attacker.statStages.valueOf('attack'), -1);
      expect(attacker.currentHp, _maxHp, reason: 'no damage, only a drop');
    });

    test('obstruct drops the attacker Defense by two stages', () {
      // Deux crans, pas un : c'est ce qui distingue Obstruct de King's Shield.
      final attacker = _punished('obstruct');

      expect(attacker.statStages.valueOf('defense'), -2);
      expect(attacker.statStages.valueOf('attack'), 0);
      expect(attacker.statStages.valueOf('speed'), 0);
    });

    test('silk_trap drops the attacker Speed by one stage', () {
      final attacker = _punished('silk_trap');

      expect(attacker.statStages.valueOf('speed'), -1);
      expect(attacker.statStages.valueOf('defense'), 0);
    });

    test('baneful_bunker poisons the attacker', () {
      expect(
        _punished('baneful_bunker').majorStatus,
        PsdkBattleMajorStatus.poison,
      );
    });

    test('burning_bulwark burns the attacker', () {
      expect(
        _punished('burning_bulwark').majorStatus,
        PsdkBattleMajorStatus.burn,
      );
    });

    test('every variant blocks the hit it punishes', () {
      for (final variant in <String>[
        'obstruct',
        'silk_trap',
        'burning_bulwark',
        'spiky_shield',
        'king_s_shield',
        'baneful_bunker',
      ]) {
        final result = _protectThenContact(protectMoveId: variant);

        expect(_damageToDefender(result), 0, reason: variant);
        expect(
          result.timeline.psdkTimeline.events.map((event) => event.kind),
          contains('move_failed'),
          reason: variant,
        );
      }
    });

    test('plain protect blocks without punishing anything', () {
      // Contre-exemple : sans lui, une punition appliquée à toute la famille
      // passerait pour correcte.
      final attacker = _punished('protect');

      expect(attacker.currentHp, _maxHp);
      expect(attacker.majorStatus, isNull);
      expect(attacker.statStages.valueOf('attack'), 0);
      expect(attacker.statStages.valueOf('defense'), 0);
      expect(attacker.statStages.valueOf('speed'), 0);
    });

    test('a non-contact hit is blocked without any punishment', () {
      // La punition est conditionnée au contact, comme le `made_contact?` du
      // Ruby. Sans ce cas, un effet qui punirait tout le monde passerait pour
      // correct.
      final result = _protectThenContact(
        protectMoveId: 'obstruct',
        contact: false,
      );

      expect(_damageToDefender(result), 0);
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
        0,
      );
    });

    test('the protection does not outlive the turn that raised it', () {
      // Nettoyage en fin de tour, l'un des trois chemins que l'inventaire
      // documente. Au tour suivant le même coup doit passer.
      final engine = _engine(protectMoveId: 'obstruct');
      engine.submit(const BattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(
        _damageToDefender(second),
        greaterThan(0),
        reason: 'a protection that survived its turn would block forever',
      );
    });
  });
}

int _damageToDefender(BattleEngineTurnResult result) {
  return _maxHp - result.state.battlerAt(psdkOpponentSlot).currentHp;
}

/// Attaquant après avoir frappé la protection : c'est lui qui encaisse.
PsdkBattleCombatant _punished(String protectMoveId) {
  return _protectThenContact(protectMoveId: protectMoveId)
      .state
      .battlerAt(psdkPlayerSlot);
}

BattleEngine _engine({required String protectMoveId, bool contact = true}) {
  return BattleEngine(
    setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
      // L'attaquant est le joueur : la punition de contact doit atterrir sur
      // lui, ce qui rend les paliers du joueur lisibles.
      player: _attacker(contact: contact),
      opponent: _protector(protectMoveId),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

BattleEngineTurnResult _protectThenContact({
  required String protectMoveId,
  bool contact = true,
}) {
  return _engine(protectMoveId: protectMoveId, contact: contact)
      .submit(const BattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _attacker({required bool contact}) {
  return PsdkBattleCombatantSetup(
    id: 'attacker',
    speciesId: 'attacker',
    displayName: 'Attacker',
    level: 20,
    maxHp: _maxHp,
    currentHp: _maxHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 80,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      // Plus lent que le protecteur, pour que la protection soit posée avant le
      // coup sans dépendre de la priorité.
      speed: 10,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: contact ? 'tackle' : 'swift',
        dbSymbol: contact ? 'tackle' : 'swift',
        name: contact ? 'Tackle' : 'Swift',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 35,
        priority: 0,
        contact: contact,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}

PsdkBattleCombatantSetup _protector(String protectMoveId) {
  return PsdkBattleCombatantSetup(
    id: 'protector',
    speciesId: 'protector',
    displayName: 'Protector',
    level: 20,
    maxHp: _maxHp,
    currentHp: _maxHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 200,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: protectMoveId,
        dbSymbol: protectMoveId,
        name: protectMoveId,
        type: 'normal',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 100,
        pp: 10,
        priority: 4,
        battleEngineMethod: 's_protect',
        target: PsdkBattleMoveTarget.self,
      ),
    ],
  );
}
