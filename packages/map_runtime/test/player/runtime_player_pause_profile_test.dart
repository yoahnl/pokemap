import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pause-profile-projection-');
  });
  tearDown(() => root.delete(recursive: true));

  test('projects the current player and resolves the exact authored portrait',
      () async {
    final state = _state();
    final before = jsonEncode(state.toJson());
    final requests = <({String characterId, String portraitStateId})>[];
    final portraitFile = '${root.path}/assets/.pokemap-store/avatar.blob';
    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: state,
      projectRootDirectory: root.path,
      pokemonConfig: _pokemonConfig,
      locale: 'fr',
      itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
      playtimeSeconds: 12 * 3600 + 5 * 60 + 49,
      projectMaps: const [
        ProjectMapEntry(id: 'other', name: 'Autre lieu', relativePath: 'other'),
        ProjectMapEntry(
            id: 'port', name: ' Port des brumes ', relativePath: 'port'),
      ],
      projectCharacters: _characters,
      projectBadges: const [
        BadgeDefinition(id: 'tide', label: 'Marée'),
        BadgeDefinition(id: 'mist', label: 'Brume'),
        BadgeDefinition(id: 'mountain', label: 'Montagne'),
      ],
      portraitLookup: ({required characterId, required portraitStateId}) {
        requests
            .add((characterId: characterId, portraitStateId: portraitStateId));
        return ResolvedDialoguePortrait(
          characterId: characterId,
          characterName: 'Nom auteur du personnage',
          portraitStateId: portraitStateId,
          portraitStateName: 'En voyage',
          assetId: 'catalogue.hero.travel',
          absoluteFilePath: portraitFile,
          fitMode: CharacterPortraitFitMode.contain,
        );
      },
    );
    final profile = details[RuntimePlayerPauseSection.profile]!.profile!;
    expect(profile.playerName, 'Camille');
    expect(profile.currentMapId, 'port');
    expect(profile.locationName, 'Port des brumes');
    expect(profile.money, 350);
    expect(profile.playtimeSeconds, 43549);
    expect(profile.avatarCharacterId, 'hero');
    expect(profile.pronounSet, PlayerPronounSet.feminine);
    expect(profile.badgeIds, ['tide', 'mist']);
    expect(profile.badgeTotal, 3);
    expect(profile.portraits, _characters.last.portraits);
    expect(profile.portraitFilePath, portraitFile);
    expect(requests, [(characterId: 'hero', portraitStateId: 'travel')]);
    expect(profile.pokedex, isNull);
    expect(jsonEncode(state.toJson()), before);
  });

  test(
      'portrait without a lookup stays unresolved instead of exposing asset ids',
      () async {
    final profile =
        await _buildProfile(root, state: _state(), characters: _characters);
    expect(profile.playerName, 'Camille');
    expect(profile.avatarCharacterId, 'hero');
    expect(profile.portraits.first.assetId, 'catalogue.hero.travel');
    expect(profile.portraitFilePath, isNull);
  });

  test('unknown avatar never resolves a different canonical character',
      () async {
    var lookupCalls = 0;
    final profile = await _buildProfile(
      root,
      state: _state(avatarCharacterId: 'unknown-avatar'),
      characters: _characters,
      portraitLookup: ({required characterId, required portraitStateId}) {
        lookupCalls++;
        return null;
      },
    );
    expect(profile.playerName, 'Camille');
    expect(profile.avatarCharacterId, 'unknown-avatar');
    expect(profile.portraits, isEmpty);
    expect(profile.portraitFilePath, isNull);
    expect(lookupCalls, 0);
  });

  test('character without portraits does not invent a default portrait state',
      () async {
    var lookupCalls = 0;
    final profile = await _buildProfile(
      root,
      state: _state(),
      characters: const [
        ProjectCharacterEntry(id: 'hero', name: 'Héroïne', tilesetId: 'hero'),
      ],
      portraitLookup: ({required characterId, required portraitStateId}) {
        lookupCalls++;
        return null;
      },
    );
    expect(profile.portraits, isEmpty);
    expect(profile.portraitFilePath, isNull);
    expect(lookupCalls, 0);
  });

  test('unresolved catalogue portrait stays null without a path fallback',
      () async {
    final requests = <({String characterId, String portraitStateId})>[];
    final profile = await _buildProfile(
      root,
      state: _state(),
      characters: _characters,
      portraitLookup: ({required characterId, required portraitStateId}) {
        requests
            .add((characterId: characterId, portraitStateId: portraitStateId));
        return null;
      },
    );
    expect(requests, [(characterId: 'hero', portraitStateId: 'travel')]);
    expect(profile.portraits, _characters.last.portraits);
    expect(profile.portraitFilePath, isNull);
  });

  test('missing optional sources remain absent in the live summary', () async {
    final profile = await _buildProfile(
      root,
      state: const GameState(
        saveId: 'optional-absent',
        currentMapId: 'map.internal.unresolved',
        trainerProfile: TrainerProfile(name: 'Alex', playtimeSeconds: 999),
      ),
    );
    expect(profile.playerName, 'Alex');
    expect(profile.currentMapId, 'map.internal.unresolved');
    expect(profile.locationName, isNull);
    expect(profile.playtimeSeconds, isNull);
    expect(profile.badgeIds, isEmpty);
    expect(profile.badgeTotal, isNull);
    expect(profile.avatarCharacterId, isNull);
    expect(profile.portraits, isEmpty);
    expect(profile.portraitFilePath, isNull);
    expect(profile.pokedex, isNull);
  });
}

const _pokemonConfig = ProjectPokemonConfig(
  enabled: false,
  ruleset: PokemonRulesetProfile.pokeMapBetaV1,
);

const _characters = [
  ProjectCharacterEntry(
    id: 'other',
    name: 'Autre personnage',
    tilesetId: 'other',
    portraits: [
      CharacterPortraitVariant(
          portraitStateId: 'neutral', assetId: 'catalogue.other.neutral')
    ],
  ),
  ProjectCharacterEntry(
    id: 'hero',
    name: 'Nom auteur du personnage',
    tilesetId: 'hero',
    portraits: [
      CharacterPortraitVariant(
          portraitStateId: 'travel', assetId: 'catalogue.hero.travel'),
      CharacterPortraitVariant(
          portraitStateId: 'neutral', assetId: 'catalogue.hero.neutral'),
    ],
  ),
];

GameState _state({String avatarCharacterId = 'hero'}) => GameState(
      saveId: 'live-session',
      currentMapId: 'port',
      trainerProfile: TrainerProfile(
        name: 'Camille',
        avatarCharacterId: avatarCharacterId,
        pronounSet: PlayerPronounSet.feminine,
        money: 350,
        badgeIds: ['tide', 'mist'],
        playtimeSeconds: 17,
      ),
    );

Future<RuntimePlayerProfileSnapshot> _buildProfile(
  Directory root, {
  required GameState state,
  List<ProjectCharacterEntry> characters = const [],
  DialoguePortraitLookup? portraitLookup,
}) async {
  final details = await const RuntimePlayerPauseDataBuilder().build(
    gameState: state,
    projectRootDirectory: root.path,
    pokemonConfig: _pokemonConfig,
    locale: 'fr',
    itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
    projectCharacters: characters,
    portraitLookup: portraitLookup,
  );
  return details[RuntimePlayerPauseSection.profile]!.profile!;
}
