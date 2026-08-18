import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

/// Cycle de vie des variantes de protection, et l'écart qu'il a révélé.
///
/// L'inventaire de BETA-BAT-005 a mesuré que trois membres de la famille
/// protection étaient atteignables depuis `static_basic_move_registry` sans
/// qu'aucun test ne les nomme : `obstruct`, `silk_trap` et `burning_bulwark`.
/// En écrivant leur cycle de vie, un écart plus large est apparu.
///
/// ÉCART CONSIGNÉ, 2026-08-18 : AUCUNE variante n'applique sa punition de
/// contact, y compris les trois qui avaient déjà des tests. Six variantes sont
/// donc fonctionnellement identiques à `protect`.
///
///   spiky_shield     devrait infliger des dégâts     -> rien
///   king_s_shield    devrait baisser l'Attaque       -> rien
///   baneful_bunker   devrait empoisonner             -> rien
///   obstruct         devrait baisser la Défense      -> rien
///   silk_trap        devrait baisser la Vitesse      -> rien
///   burning_bulwark  devrait brûler                  -> rien
///
/// DIAGNOSTIC, avec le Ruby pour oracle. Dans PSDK
/// (`06 Effects/02 Move Effects/001 Protect.rb`), la punition est jouée par
/// `play_protect_effect`, appelée depuis `on_move_prevention_target`. Côté Dart,
/// `_applyContactPunishment` est accrochée à `onDamagePrevention`, un chemin
/// jamais atteint : `onMovePreventionTarget` renvoie `protected` et la capacité
/// s'arrête là. Le timeline le montre, `move_declared` puis `move_failed`, sans
/// aucun événement de dégât ni de statut.
///
/// POURQUOI CE N'EST PAS CORRIGÉ ICI : `onMovePreventionTarget` ne renvoie
/// qu'une `BattleMoveFailureReason?` et ne peut donc pas muter l'état. Déplacer
/// la punition demande soit de changer le contrat de ce hook, soit d'en ajouter
/// un nouveau — et dix fichiers l'implémentent ou le dispatchent, dont les
/// immunités de type, Soundproof, Safety Goggles et les gardes de doubles.
/// C'est un choix de conception, pas une ligne à déplacer.
///
/// Ces tests figent donc le comportement RÉEL. Le jour où la punition sera
/// branchée, ils échoueront, et c'est exactement ce qu'on veut d'eux.

void main() {
  group('BETA-BAT-005 protection variants block but never punish', () {
    for (final variant in <String>[
      'obstruct',
      'silk_trap',
      'burning_bulwark',
      'spiky_shield',
      'king_s_shield',
      'baneful_bunker',
    ]) {
      test('$variant blocks a contact hit', () {
        final result = _protectThenContact(protectMoveId: variant);

        expect(
          _damageToDefender(result),
          0,
          reason: 'the block is the half that works',
        );
        expect(
          result.timeline.psdkTimeline.events.map((event) => event.kind),
          contains('move_failed'),
        );
      });

      test('$variant does not punish the contact it blocked', () {
        // Écart consigné, voir l'en-tête. Le jour où la punition sera branchée,
        // ce cas échouera : c'est sa raison d'être.
        final result = _protectThenContact(protectMoveId: variant);
        final attacker = result.state.battlerAt(psdkPlayerSlot);

        expect(attacker.currentHp, 400, reason: 'no spiky damage');
        expect(attacker.majorStatus, isNull, reason: 'no burn, no poison');
        expect(attacker.statStages.valueOf('attack'), 0);
        expect(attacker.statStages.valueOf('defense'), 0);
        expect(attacker.statStages.valueOf('speed'), 0);
      });
    }

    test('a non-contact hit is blocked without any punishment', () {
      // La punition est conditionnée au contact. Sans ce cas, un effet qui
      // punirait tout le monde passerait pour correct.
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
  return 400 - result.state.battlerAt(psdkOpponentSlot).currentHp;
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
    maxHp: 400,
    currentHp: 400,
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
    maxHp: 400,
    currentHp: 400,
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
