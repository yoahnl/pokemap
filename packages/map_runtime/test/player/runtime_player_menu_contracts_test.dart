import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('menu-contracts-');
  });

  tearDown(() async => root.delete(recursive: true));

  test('projects current profile, catalog identities and public dex data',
      () async {
    final species = Directory('${root.path}/data/pokemon/species');
    await species.create(recursive: true);
    for (final id in ['emberling', 'waterling', 'unseen', 'disabled']) {
      await File('${species.path}/$id.json').writeAsString(jsonEncode({
        'id': id,
        'nationalDex':
            ['emberling', 'waterling', 'unseen', 'disabled'].indexOf(id) + 1,
        'names': {'fr': 'Espèce $id'},
        'typing': {
          'types': ['fire'],
        },
        'forms': {'formId': '$id-default'},
        'refs': {'media': '$id-media'},
        'classification': {'isEnabledInProject': id != 'disabled'},
      }));
    }
    final state = GameState(
      saveId: 'current-session',
      currentMapId: 'route',
      trainerProfile: const TrainerProfile(
        name: 'Yoahn',
        avatarCharacterId: 'hero',
        pronounSet: PlayerPronounSet.masculine,
        money: 3200,
        playtimeSeconds: 7,
        badgeIds: ['forest'],
      ),
      party: const PlayerParty(members: [
        PlayerPokemon(
          individualId: 'party-identity',
          speciesId: 'emberling',
          formId: 'alternate',
          gender: 'female',
          isShiny: true,
          natureId: 'hardy',
          abilityId: 'blaze',
          statusId: 'burn',
          level: 8,
          currentHp: 18,
        ),
      ]),
      bag: const Bag(entries: [BagEntry(itemId: 'potion', quantity: 3)]),
      progression: const PlayerProgression(
        seenSpeciesIds: ['waterling', 'disabled', 'outside-catalog'],
        caughtSpeciesIds: ['disabled', 'outside-catalog'],
      ),
    );
    final before = jsonEncode(state.toJson());
    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: state,
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
      locale: 'fr',
      playtimeSeconds: 3661,
      projectMaps: const [
        ProjectMapEntry(
            id: 'route', name: 'Route des Brumes', relativePath: 'r'),
      ],
      projectBadges: const [
        BadgeDefinition(id: 'forest', label: 'Forêt'),
        BadgeDefinition(id: 'sea', label: 'Mer'),
      ],
      projectCharacters: const [
        ProjectCharacterEntry(
          id: 'other',
          name: 'Autre',
          tilesetId: 'other',
          portraits: [
            CharacterPortraitVariant(
                portraitStateId: 'neutral', assetId: 'wrong'),
          ],
        ),
        ProjectCharacterEntry(
          id: 'hero',
          name: 'Héros',
          tilesetId: 'hero',
          portraits: [
            CharacterPortraitVariant(
                portraitStateId: 'neutral', assetId: 'hero-face'),
          ],
        ),
      ],
      itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog.copyWith(
        entries: [
          for (final item in mvpItemCatalog.entries)
            item.id == 'potion'
                ? item.copyWith(description: 'Rend vingt PV.')
                : item,
        ],
      )),
    );

    final profileDetail = details[RuntimePlayerPauseSection.profile]!;
    final profile = profileDetail.profile!;
    expect(profile.playerName, 'Yoahn');
    expect(profile.money, 3200);
    expect(profile.playtimeSeconds, 3661);
    expect(profile.currentMapId, 'route');
    expect(profile.locationName, 'Route des Brumes');
    expect(profile.avatarCharacterId, 'hero');
    expect(profile.portraits.single.assetId, 'hero-face');
    expect(profile.pronounSet, PlayerPronounSet.masculine);
    expect(profile.badgeIds, ['forest']);
    expect(profile.badgeTotal, isNull);
    expect(profile.badges.map((badge) => badge.id), ['forest']);
    expect(profile.pokedex?.seen, 2);
    expect(profile.pokedex?.caught, 1);
    expect(profile.pokedex?.total, 3);
    expect(profile.currencyLabel, isNull);
    expect(profileDetail.withMessage('Updated').profile, same(profile));

    final summary = details[RuntimePlayerPauseSection.party]!
        .entries
        .single
        .pokemonSummary!;
    expect(summary.individualId, 'party-identity');
    expect(summary.identity?.speciesId, 'emberling');
    expect(summary.identity?.formId, 'alternate');
    expect(summary.identity?.defaultFormId, 'emberling-default');
    expect(summary.identity?.mediaRef, 'emberling-media');
    expect(summary.identity?.gender, 'female');
    expect(summary.identity?.isShiny, isTrue);
    expect(summary.typeIds, ['fire']);
    expect(summary.abilityId, 'blaze');
    expect(summary.statusId, 'burn');

    final bag = details[RuntimePlayerPauseSection.bag]!.entries.single;
    expect(bag.bagItem?.itemId, 'potion');
    expect(bag.bagItem?.quantity, 3);
    expect(bag.bagItem?.sortOrder, 0);
    expect(
        bag.bagItem?.pocketId,
        mvpItemCatalog.entries
            .singleWhere((item) => item.id == 'potion')
            .pocketId);
    expect(bag.bagItem?.description, 'Rend vingt PV.');
    expect(bag.bagAction?.isEnabled, isTrue);

    final dex = details[RuntimePlayerPauseSection.pokedex]!;
    final unknown = dex.entries.singleWhere((entry) => entry.id == 'unseen');
    expect(unknown.title, '???');
    expect(
        unknown.pokedexEntry?.knowledge, RuntimePlayerPokedexKnowledge.unknown);
    expect(unknown.pokedexEntry?.identity, isNull);
    expect(unknown.pokedexEntry?.typeIds, isEmpty);
    final seen = dex.entries.singleWhere((entry) => entry.id == 'waterling');
    expect(seen.pokedexEntry?.knowledge, RuntimePlayerPokedexKnowledge.seen);
    expect(seen.pokedexEntry?.identity?.mediaRef, 'waterling-media');
    expect(seen.pokedexEntry?.identity?.formId, 'waterling-default');
    expect(details, isNot(contains(RuntimePlayerPauseSection.quests)));
    expect(jsonEncode(state.toJson()), before);
  });

  test('missing optional sources stay absent without hiding the profile',
      () async {
    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: const GameState(
        saveId: 'no-pokemon',
        trainerProfile: TrainerProfile(name: 'Current', playtimeSeconds: 999),
      ),
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
        enabled: false,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
      locale: 'en',
    );
    final profile = details[RuntimePlayerPauseSection.profile]!.profile!;
    expect(profile.playerName, 'Current');
    expect(profile.playtimeSeconds, isNull);
    expect(profile.badgeTotal, isNull);
    expect(profile.locationName, isNull);
    expect(profile.avatarCharacterId, isNull);
    expect(profile.portraits, isEmpty);
    expect(profile.pokedex, isNull);
    expect(details, isNot(contains(RuntimePlayerPauseSection.pokedex)));
    expect(details, isNot(contains(RuntimePlayerPauseSection.quests)));
  });

  test('profile is immutable, preserved by navigation and cleared with details',
      () {
    final badges = ['forest'];
    final profile = RuntimePlayerProfileSnapshot(
      playerName: 'Current',
      currentMapId: 'route',
      money: 1,
      badgeIds: badges,
    );
    final snapshot = RuntimePlayerSnapshot(
      revision: 1,
      phase: RuntimePlayerPhase.paused,
      gameTitle: 'Game',
      pauseDetails: {
        RuntimePlayerPauseSection.profile: RuntimePlayerPauseDetailSnapshot(
          section: RuntimePlayerPauseSection.profile,
          title: 'Profil',
          profile: profile,
        ),
      },
    );
    badges.clear();
    expect(profile.badgeIds, ['forest']);
    expect(() => profile.badgeIds.clear(), throwsUnsupportedError);
    expect(() => profile.portraits.clear(), throwsUnsupportedError);
    expect(snapshot.playerProfile, same(profile));
    expect(
        snapshot
            .next(pauseSection: RuntimePlayerPauseSection.bag)
            .playerProfile,
        same(profile));
    expect(snapshot.next(clearPauseDetails: true).playerProfile, isNull);
    expect(
        () => RuntimePlayerPokedexEntrySnapshot(
              knowledge: RuntimePlayerPokedexKnowledge.unknown,
              identity: const RuntimePokemonMediaIdentity(speciesId: 'secret'),
            ),
        throwsArgumentError);
  });
}
