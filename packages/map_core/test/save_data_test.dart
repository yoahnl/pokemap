import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PokemonStatSpread', () {
    test('serialization round-trip', () {
      const stats = PokemonStatSpread(
        hp: 31,
        attack: 30,
        defense: 29,
        specialAttack: 28,
        specialDefense: 27,
        speed: 26,
      );

      final json = stats.toJson();
      final restored = PokemonStatSpread.fromJson(json);

      expect(restored, stats);
    });
  });

  group('PlayerPokemon', () {
    test('serialization round-trip', () {
      const pokemon = PlayerPokemon(
        speciesId: 'lapras',
        natureId: 'modest',
        abilityId: 'water-absorb',
        level: 30,
        ivs: PokemonStatSpread(
          hp: 31,
          attack: 12,
          defense: 22,
          specialAttack: 31,
          specialDefense: 25,
          speed: 18,
        ),
        evs: PokemonStatSpread(
          hp: 0,
          attack: 0,
          defense: 4,
          specialAttack: 252,
          specialDefense: 0,
          speed: 252,
        ),
        knownMoveIds: ['surf', 'ice_beam'],
        currentHp: 99,
        statusId: 'poison',
        isShiny: true,
        heldItemId: 'mystic-water',
      );
      final json = pokemon.toJson();
      final restored = PlayerPokemon.fromJson(json);
      expect(restored, pokemon);
    });

    test('defaults are coherent', () {
      const pokemon = PlayerPokemon(
        speciesId: 'magikarp',
        natureId: 'hardy',
        abilityId: 'swift-swim',
      );
      expect(pokemon.level, 1);
      expect(pokemon.knownMoveIds, isEmpty);
      expect(pokemon.currentHp, 1);
      expect(pokemon.isFainted, false);
    });

    test('JSON keys match expected structure', () {
      const pokemon = PlayerPokemon(
        speciesId: 'pikachu',
        natureId: 'jolly',
        abilityId: 'static',
        knownMoveIds: ['thunderbolt'],
      );
      final json = pokemon.toJson();
      expect(json['speciesId'], 'pikachu');
      expect(json['natureId'], 'jolly');
      expect(json['abilityId'], 'static');
      expect(json['knownMoveIds'], ['thunderbolt']);
      expect(json['currentHp'], 1);
    });

    test('normalized rejects more than four moves', () {
      const pokemon = PlayerPokemon(
        speciesId: 'pikachu',
        natureId: 'jolly',
        abilityId: 'static',
        knownMoveIds: ['tackle', 'growl', 'quick_attack', 'slam', 'surf'],
      );

      expect(() => pokemon.normalized(), throwsStateError);
    });

    test('legacy JSON migrates missing phase 9 fields', () {
      final restored = PlayerPokemon.fromJson({
        'id': 'party_1',
        'speciesId': 'lapras',
        'nickname': 'Ferry',
        'level': 30,
        'knownMoveIds': ['surf', 'ice_beam'],
        'isFainted': true,
      });

      expect(restored.speciesId, 'lapras');
      expect(restored.natureId, 'hardy');
      expect(restored.abilityId, 'unknown');
      expect(restored.currentHp, 0);
      expect(restored.knownMoveIds, ['surf', 'ice_beam']);
    });

    test('non legacy JSON missing phase 9 fields still fails', () {
      expect(
        () => PlayerPokemon.fromJson({
          'speciesId': 'lapras',
          'knownMoveIds': ['surf'],
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('PlayerParty', () {
    test('serialization round-trip', () {
      const party = PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'lapras',
          natureId: 'modest',
          abilityId: 'water-absorb',
          knownMoveIds: ['surf'],
        ),
        PlayerPokemon(
          speciesId: 'pikachu',
          natureId: 'timid',
          abilityId: 'static',
        ),
      ]);
      final json = party.toJson();
      final restored = PlayerParty.fromJson(json);
      expect(restored.members.length, 2);
      expect(restored.members[0].speciesId, 'lapras');
    });

    test('default is empty party', () {
      const party = PlayerParty();
      expect(party.members, isEmpty);
    });
  });

  group('PlayerProgression', () {
    test('serialization round-trip', () {
      const progression = PlayerProgression(
        unlockedFieldAbilities: [FieldAbility.surf],
        storyFlags: ['badge_cascade', 'rescued_bill'],
        completedStepIds: ['step_intro', 'step_2_1'],
      );
      final json = progression.toJson();
      final restored = PlayerProgression.fromJson(json);
      expect(restored.unlockedFieldAbilities, [FieldAbility.surf]);
      expect(restored.storyFlags, ['badge_cascade', 'rescued_bill']);
      expect(restored.completedStepIds, ['step_intro', 'step_2_1']);
    });

    test('defaults are empty', () {
      const progression = PlayerProgression();
      expect(progression.unlockedFieldAbilities, isEmpty);
      expect(progression.storyFlags, isEmpty);
      expect(progression.completedStepIds, isEmpty);
    });
  });

  group('TrainerProfile', () {
    test('serialization round-trip', () {
      const profile = TrainerProfile(
        name: 'Red',
        badgeIds: ['boulder', 'cascade'],
        money: 4200,
        playtimeSeconds: 3600,
      );

      final json = profile.toJson();
      final restored = TrainerProfile.fromJson(json);

      expect(restored, profile);
    });

    test('normalized badges are stable', () {
      const profile = TrainerProfile(
        name: ' Red ',
        badgeIds: ['cascade', 'boulder', 'cascade'],
      );

      final normalized = profile.normalized();

      expect(normalized.name, 'Red');
      expect(normalized.badgeIds, ['boulder', 'cascade']);
    });

    test('normalized rejects empty names', () {
      const profile = TrainerProfile(name: '   ');

      expect(() => profile.normalized(), throwsStateError);
    });
  });

  group('Bag', () {
    test('serialization round-trip', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 10),
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
        ],
      );

      final json = bag.toJson();
      final restored = Bag.fromJson(json);

      expect(restored, bag);
    });

    test('normalized entries merge duplicates deterministically', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
          BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
        ],
      );

      final normalized = bag.normalized();

      expect(normalized.entries, [
        const BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
        const BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 5),
      ]);
    });

    test('normalized rejects non-positive quantities', () {
      const bag = Bag(
        entries: [
          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 0),
        ],
      );

      expect(() => bag.normalized(), throwsStateError);
    });
  });

  group('SaveData', () {
    test('serialization round-trip', () {
      const save = SaveData(
        saveId: 'save_001',
        currentMapId: 'pallet_town',
        playerPosition: GridPos(x: 5, y: 3),
        playerFacing: EntityFacing.north,
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'squirtle',
            natureId: 'bold',
            abilityId: 'torrent',
            level: 12,
            knownMoveIds: ['surf', 'water_gun'],
          ),
        ]),
        trainerProfile: TrainerProfile(
          name: 'Leaf',
          badgeIds: ['cascade'],
          money: 1200,
          playtimeSeconds: 180,
        ),
        bag: Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
          ],
        ),
        progression: PlayerProgression(
          unlockedFieldAbilities: [FieldAbility.surf],
          storyFlags: ['intro_done'],
        ),
        properties: {'lastHealLocation': 'pokemon_center_1'},
      );

      final json = save.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = SaveData.fromJson(decoded);

      expect(restored.saveId, 'save_001');
      expect(restored.currentMapId, 'pallet_town');
      expect(restored.playerPosition, const GridPos(x: 5, y: 3));
      expect(restored.playerFacing, EntityFacing.north);
      expect(restored.party.members.length, 1);
      expect(restored.party.members.first.speciesId, 'squirtle');
      expect(restored.trainerProfile.name, 'Leaf');
      expect(restored.bag.entries.single.itemId, 'poke-ball');
      expect(restored.progression.unlockedFieldAbilities, [FieldAbility.surf]);
      expect(restored.properties['lastHealLocation'], 'pokemon_center_1');
    });

    test('defaults are coherent', () {
      const save = SaveData(saveId: 'test');
      expect(save.currentMapId, '');
      expect(save.playerPosition, const GridPos(x: 0, y: 0));
      expect(save.playerFacing, EntityFacing.south);
      expect(save.party.members, isEmpty);
      expect(save.trainerProfile.name, 'Player');
      expect(save.bag.entries, isEmpty);
      expect(save.progression.unlockedFieldAbilities, isEmpty);
      expect(save.progression.storyFlags, isEmpty);
      expect(save.progression.completedStepIds, isEmpty);
      expect(save.properties, isEmpty);
    });

    test('copyWith preserves unmodified fields', () {
      const save = SaveData(
        saveId: 'test',
        currentMapId: 'route_1',
        party: PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'bulbasaur',
            natureId: 'hardy',
            abilityId: 'overgrow',
          ),
        ]),
      );
      final updated = save.copyWith(currentMapId: 'route_2');
      expect(updated.saveId, 'test');
      expect(updated.currentMapId, 'route_2');
      expect(updated.party.members.length, 1);
    });
  });

  group('FieldAbility', () {
    test('JSON values match expected strings', () {
      const save = SaveData(
        saveId: 'test',
        progression: PlayerProgression(
          unlockedFieldAbilities: [
            FieldAbility.surf,
            FieldAbility.cut,
            FieldAbility.strength,
          ],
        ),
      );
      final json = save.toJson();
      final abilities = (json['progression']
          as Map<String, dynamic>)['unlockedFieldAbilities'] as List;
      expect(abilities, ['surf', 'cut', 'strength']);
    });
  });
}
