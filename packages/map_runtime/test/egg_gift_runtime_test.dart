import 'dart:convert';

import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

import 'scene_interactive_pokemon_gift_test.dart' show giftCatalog;

PlayerPokemon member(String id, {bool egg = false}) => PlayerPokemon.fromJson({
  'individualId': id,
  'speciesId': 'clockbird',
  'formId': 'bronze',
  'natureId': 'hardy',
  'abilityId': 'clockwork',
  'currentHp': 14,
  'isEgg': egg,
});
SceneReceivePokemonFromCatalogInteractiveCommand command() =>
    SceneInteractiveCommand.fromJson({
      'kind': 'receivePokemonFromCatalog',
      'speciesId': 'clockbird',
      'formId': 'bronze',
      'level': 1,
      'nicknamePolicy': 'disabled',
      'nicknameMaxGraphemes': 10,
      'pokedexPresentationPolicy': 'never',
      'isEgg': true,
    }) as SceneReceivePokemonFromCatalogInteractiveCommand;

void main() {
  const project = ProjectManifest(name: 'Gift', maps: [], tilesets: []);
  test(
    'egg occupies party slot once, remains unknown in dex and survives reload',
    () async {
      final initial = GameState(
        saveId: 'egg',
        currentMapId: 'lab',
        party: const PlayerParty(),
      );
      final catalog = giftCatalog();
      final prepared = await receiveScenePokemonFromCatalog(
        command: command(),
        operationId: 'egg-gift',
        project: project,
        readProjectedState: () => initial,
        catalog: catalog,
        present: (request) async {
          expect(request.pokemon.toJson()['isEgg'], isTrue);
          expect(request.isNewPokedexEntry, isFalse);
          final prompt = request.interaction;
          return SceneInteractionResult.acknowledged(
            requestId: prompt.requestId,
            revision: prompt.revision,
          );
        },
      );
      final given = prepared.prepared!.commit(
        initial,
        catalog: catalog,
        project: project,
      );
      expect(given.party.members.length, 1);
      expect(given.party.members.last.toJson()['isEgg'], isTrue);
      expect(given.progression.caughtSpeciesIds, isEmpty);
      expect(given.progression.seenSpeciesIds, isEmpty);
      final loaded = GameState.fromJson(jsonDecode(jsonEncode(given.toJson())));
      expect(loaded.party.members.last.toJson()['isEgg'], isTrue);
      expect(
        prepared.prepared!.commit(loaded, catalog: catalog, project: project),
        loaded,
      );
    },
  );
  test(
    'full party refuses egg even with empty storage without consuming grant',
    () async {
      final initial = GameState(
        saveId: 'egg',
        currentMapId: 'lab',
        party: PlayerParty(members: List.generate(6, (i) => member('p$i'))),
      );
      final prepared = await receiveScenePokemonFromCatalog(
        command: command(),
        operationId: 'egg-gift',
        project: project,
        readProjectedState: () => initial,
        catalog: giftCatalog(),
        present: (_) async => throw StateError('Must not present'),
      );
      expect(prepared.outputPortId, 'noCapacity');
      expect(prepared.prepared, isNull);
      expect(initial.appliedPokemonGrantOperationIds, isEmpty);
    },
  );
  test('eggs cannot lead, replace or contribute to usable battle party', () {
    final party = PlayerParty(
      members: [
        member('egg', egg: true),
        member('hatched'),
        member('egg2', egg: true),
      ],
    );
    final mapper = RuntimeBattleSetupMapper();
    final lineup = mapper.selectPlayerBattleLineup(party);
    expect(lineup.activeIndex, 1);
    expect(lineup.reserveIndices, isEmpty);
    expect(usablePartyMemberCount(party), 1);
    expect(
      () => mapper.selectPlayerBattleLineup(party, playerPartyIndex: 0),
      throwsA(isA<RuntimeBattleSetupException>()),
    );
    expect(
      () => mapper.selectPlayerBattleLineup(party, activeCount: 2),
      throwsA(isA<RuntimeBattleSetupException>()),
    );
  });
}
