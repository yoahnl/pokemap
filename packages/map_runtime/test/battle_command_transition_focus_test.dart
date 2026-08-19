import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';

/// Cohérence du focus du menu de combat à travers une transition.
///
/// Critère d'acceptation de BETA-BAT-007 : « le focus revient sur un choix
/// valide après chaque transition ». Le composant garde son mode et son index
/// entre deux images ; c'est le modèle qui doit refuser de les honorer quand la
/// session a changé sous eux.
///
/// CE QUE CE CRITÈRE NE VEUT PAS DIRE, et je m'y suis trompé le 2026-08-18. Le
/// menu racine autorise DÉLIBÉRÉMENT le curseur à se poser sur une entrée
/// grisée : `battle_command_menu_component_test` l'affirme explicitement, puis
/// vérifie que valider ne produit rien. C'est la forme que prend ici le « feedback
/// sûr » du critère voisin. J'avais d'abord déplacé le focus hors des entrées
/// désactivées, prenant ce choix de conception pour un défaut — deux tests
/// existants m'ont arrêté, dont celui de la navigation en grille 2x2, que
/// déplacer le curseur cassait pour de bon.
///
/// La garantie réelle est donc plus étroite et vit dans le modèle : un mode de
/// sous-menu périmé et un index périmé ne survivent pas à la transition.
void main() {
  group('BETA-BAT-007 a transition does not leave a stale focus behind', () {
    test('a stale submenu mode is dropped when a replacement is forced', () {
      final battle = _knockOutTheActive();

      // Le composant redemande le mode qu'il avait AVANT le K.O. Le modèle doit
      // le refuser : présenter un choix de move alors que le moteur exige un
      // remplaçant enverrait une commande impossible.
      final model = buildBattleCommandMenuModel(
        session: battle,
        mode: BattleCommandMenuMode.fight,
        selectedRootIndex: 0,
        selectedChoiceIndex: 0,
      );

      expect(
        battle.decisionRequest.kind,
        BattleDecisionRequestKind.forcedReplacement,
        reason: 'the vector needs the transition it claims to test',
      );
      expect(model.mode, isNot(BattleCommandMenuMode.fight));
      expect(model.mode, BattleCommandMenuMode.root);
    });

    test('a stale choice index does not survive a shorter list', () {
      final battle = _knockOutTheActive();

      final model = buildBattleCommandMenuModel(
        session: battle,
        mode: BattleCommandMenuMode.fight,
        selectedRootIndex: 0,
        selectedChoiceIndex: 3,
      );

      // Un index hors liste laisserait le composant lire une entrée inexistante.
      expect(model.selectedChoiceIndex, lessThan(1));
      expect(model.selectedChoiceIndex, 0);
    });

    test('the selected root index stays inside the entries it indexes', () {
      // Balayage large plutôt qu'un cas : c'est l'invariant qui compte.
      final battle = _knockOutTheActive();

      for (var requested = -3; requested < 9; requested += 1) {
        final model = buildBattleCommandMenuModel(
          session: battle,
          mode: BattleCommandMenuMode.root,
          selectedRootIndex: requested,
          selectedChoiceIndex: 0,
        );

        expect(model.selectedRootIndex, greaterThanOrEqualTo(0));
        expect(
          model.selectedRootIndex,
          lessThan(model.rootEntries.length),
          reason: 'asked $requested',
        );
      }
    });

    test('a free turn keeps the submenu the player actually opened', () {
      // Contraste indispensable : sans lui, un modèle qui ramènerait TOUJOURS au
      // menu racine passerait les cas précédents.
      final model = buildBattleCommandMenuModel(
        session: _freshBattle(),
        mode: BattleCommandMenuMode.fight,
        selectedRootIndex: 0,
        selectedChoiceIndex: 0,
      );

      expect(model.mode, BattleCommandMenuMode.fight);
      expect(model.choiceEntries, isNotEmpty);
    });
  });
}

/// Session dont l'actif vient de tomber, avec un remplaçant disponible.
///
/// Poison résiduel sur un actif à 1 PV : c'est la façon la plus simple de
/// provoquer la transition sans dépendre des dégâts adverses.
BattleSession _knockOutTheActive() {
  final battle = _freshBattle(activeHp: 1, poisoned: true);
  return battle.applyChoice(const PlayerBattleChoiceFight(0));
}

BattleSession _freshBattle({int? activeHp, bool poisoned = false}) {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: _combatant(
        'charmander',
        0,
        currentHp: activeHp,
        poisoned: poisoned,
      ),
      playerReservePokemon: <BattleCombatantData>[_combatant('ivysaur', 1)],
      enemyPokemon: _combatant('squirtle', 0),
      enemyReservePokemon: <BattleCombatantData>[_combatant('wartortle', 1)],
      isTrainerBattle: true,
      trainerId: 'trainer',
    ),
  );
}

BattleCombatantData _combatant(
  String speciesId,
  int lineupIndex, {
  int? currentHp,
  bool poisoned = false,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 20,
    maxHp: 40,
    currentHp: currentHp,
    majorStatus: poisoned ? const BattleMajorStatusState.psn() : null,
    stats: const BattleStatsSnapshot(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: const <BattleMoveData>[
      BattleMoveData(
        id: 'scratch',
        name: 'Scratch',
        power: 40,
        category: BattleMoveCategory.physical,
        target: BattleMoveTarget.opponent,
        accuracy: BattleMoveAccuracy.alwaysHits(),
      ),
    ],
  );
}
