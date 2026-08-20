import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

/// Réordonnancement et lead depuis le menu pause — BETA-PTY-002.
///
/// Les opérations pures existaient (swapPartyMembers, setLead, et leurs
/// variantes par individualId) SANS AUCUN APPELANT : le joueur ne pouvait ni
/// réordonner son équipe ni changer de Pokémon de tête. Ces cas certifient le
/// branchement : validation des cibles, opération par identifiant d'individu,
/// commit-et-sauvegarde, et ciblage stable après réordonnancement.
PlayerPokemon _member(String individualId, String speciesId) {
  return PlayerPokemon(
    individualId: individualId,
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'steadfast',
    level: 7,
    currentHp: 20,
  );
}

GameState _threeMemberState() {
  return GameState(
    saveId: 'party-reorder',
    party: PlayerParty(
      members: <PlayerPokemon>[
        _member('pkm_alpha', 'alpha'),
        _member('pkm_bravo', 'bravo'),
        _member('pkm_charlie', 'charlie'),
      ],
    ),
  );
}

typedef _Harness = ({
  PlayerServiceRuntimeController controller,
  List<GameState> commits,
  GameState Function() state,
});

_Harness _harness({GameState? initial, bool failCommit = false}) {
  var state = initial ?? _threeMemberState();
  final commits = <GameState>[];
  final controller = PlayerServiceRuntimeController.contextual(
    currentGameState: () => state,
    commitAndSave: (next) async {
      if (failCommit) {
        throw StateError('storage unavailable');
      }
      commits.add(next);
      state = next;
    },
    setInputLocked: (_) {},
    loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
      maxHpByPartyIndex: <int, int>{},
    ),
    itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
  );
  addTearDown(controller.dispose);
  return (controller: controller, commits: commits, state: () => state);
}

void main() {
  group('BETA-PTY-002 reorder and lead reach the player at last', () {
    test('a swap reorders the party and saves exactly once', () async {
      final harness = _harness();

      final result = await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.reorderPartyMember(
          partyTargetId: 'pokemon.pkm_alpha',
          secondPartyTargetId: 'pokemon.pkm_charlie',
        ),
      );

      expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(harness.commits, hasLength(1));
      expect(
        harness.state().party.members.map((member) => member.individualId),
        <String>['pkm_charlie', 'pkm_bravo', 'pkm_alpha'],
      );
    });

    test('set lead moves the member to the front and saves', () async {
      final harness = _harness();

      final result = await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.setPartyLead(
          partyTargetId: 'pokemon.pkm_charlie',
        ),
      );

      expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(
        harness.state().party.members.map((member) => member.individualId),
        <String>['pkm_charlie', 'pkm_alpha', 'pkm_bravo'],
      );
    });

    test('targets stay stable across a previous reorder', () async {
      // LE critère « stable selection ». La cible est l'INDIVIDU, pas la
      // position : après un premier échange, viser pkm_alpha doit toucher
      // pkm_alpha même s'il a changé d'index. Un ciblage par position
      // (party.<index>) déplacerait le mauvais Pokémon en silence.
      final harness = _harness();
      await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.reorderPartyMember(
          partyTargetId: 'pokemon.pkm_alpha',
          secondPartyTargetId: 'pokemon.pkm_charlie',
        ),
      );

      final result = await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.setPartyLead(
          partyTargetId: 'pokemon.pkm_alpha',
        ),
      );

      expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(
        harness.state().party.members.first.individualId,
        'pkm_alpha',
        reason: 'the selection follows the individual, not its slot',
      );
    });

    test('a vanished target is refused without mutating anything', () async {
      // Le critère « stale selection » : l'individu visé n'existe plus (relâché,
      // déposé au PC entre l'affichage et le clic). Aucune mutation, aucun
      // commit, un message stable.
      final harness = _harness();

      final result = await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.reorderPartyMember(
          partyTargetId: 'pokemon.pkm_ghost',
          secondPartyTargetId: 'pokemon.pkm_bravo',
        ),
      );

      expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
      expect(harness.commits, isEmpty);
      expect(
        harness.state().party.members.map((member) => member.individualId),
        <String>['pkm_alpha', 'pkm_bravo', 'pkm_charlie'],
      );
    });

    test('the reordered party survives a save and reload round trip', () async {
      // Le critère « save/reload » : ce que le commit a persisté se recharge à
      // l'identique — l'ordre est bien dans l'état sauvegardé, pas dans une
      // projection d'affichage.
      final harness = _harness();
      await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.setPartyLead(
          partyTargetId: 'pokemon.pkm_bravo',
        ),
      );

      final reloaded = gameStateFromSaveData(
        saveDataFromGameState(harness.commits.single),
      );

      expect(
        reloaded.party.members.map((member) => member.individualId),
        <String>['pkm_bravo', 'pkm_alpha', 'pkm_charlie'],
      );
    });

    test('a failed save reports failed and leaves the state visible', () async {
      final harness = _harness(failCommit: true);

      final result = await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.setPartyLead(
          partyTargetId: 'pokemon.pkm_bravo',
        ),
      );

      expect(result.status, RuntimePlayerPauseCommandStatus.failed);
      expect(harness.commits, isEmpty);
    });

    test('a bag command aimed at the party channel is refused', () async {
      // Les canaux ne se mélangent pas : la méthode équipe refuse les genres
      // sac, comme la méthode sac ignorera les genres équipe.
      final harness = _harness();

      final result = await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.useBagItem(
          itemTargetId: 'potion',
          partyTargetId: 'pokemon.pkm_alpha',
        ),
      );

      expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
      expect(harness.commits, isEmpty);
    });

    test('swapping a member with itself commits nothing', () async {
      // L'opération pure rend l'état inchangé ; le contrôleur sauvegarde quand
      // même — un commit sans diff est inutile mais pas faux. Ce cas épingle le
      // comportement réel pour que le jour où on veut l'optimiser, on le fasse
      // exprès.
      final harness = _harness();

      final result = await harness.controller.reorderPartyOutsideBattle(
        const RuntimePlayerPauseCommand.reorderPartyMember(
          partyTargetId: 'pokemon.pkm_alpha',
          secondPartyTargetId: 'pokemon.pkm_alpha',
        ),
      );

      expect(result.status, RuntimePlayerPauseCommandStatus.accepted);
      expect(
        harness.state().party.members.map((member) => member.individualId),
        <String>['pkm_alpha', 'pkm_bravo', 'pkm_charlie'],
      );
    });
  });
}
