import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerPokemon', () {
    test('serialization round-trip', () {
      const pokemon = PlayerPokemon(
        id: 'poke_1',
        speciesId: 'lapras',
        nickname: 'Nessie',
        level: 30,
        knownMoveIds: ['surf', 'ice_beam'],
        isFainted: false,
      );
      final json = pokemon.toJson();
      final restored = PlayerPokemon.fromJson(json);
      expect(restored, pokemon);
    });

    test('defaults are coherent', () {
      const pokemon = PlayerPokemon(id: 'p1', speciesId: 'magikarp');
      expect(pokemon.nickname, '');
      expect(pokemon.level, 1);
      expect(pokemon.knownMoveIds, isEmpty);
      expect(pokemon.isFainted, false);
    });

    test('JSON keys match expected structure', () {
      const pokemon = PlayerPokemon(
        id: 'p1',
        speciesId: 'pikachu',
        knownMoveIds: ['thunderbolt'],
      );
      final json = pokemon.toJson();
      expect(json['id'], 'p1');
      expect(json['speciesId'], 'pikachu');
      expect(json['knownMoveIds'], ['thunderbolt']);
      expect(json['isFainted'], false);
    });
  });

  group('PlayerParty', () {
    test('serialization round-trip', () {
      const party = PlayerParty(members: [
        PlayerPokemon(id: 'p1', speciesId: 'lapras', knownMoveIds: ['surf']),
        PlayerPokemon(id: 'p2', speciesId: 'pikachu'),
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
      );
      final json = progression.toJson();
      final restored = PlayerProgression.fromJson(json);
      expect(restored.unlockedFieldAbilities, [FieldAbility.surf]);
      expect(restored.storyFlags, ['badge_cascade', 'rescued_bill']);
    });

    test('defaults are empty', () {
      const progression = PlayerProgression();
      expect(progression.unlockedFieldAbilities, isEmpty);
      expect(progression.storyFlags, isEmpty);
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
            id: 'p1',
            speciesId: 'squirtle',
            level: 12,
            knownMoveIds: ['surf', 'water_gun'],
          ),
        ]),
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
      expect(restored.progression.unlockedFieldAbilities,
          [FieldAbility.surf]);
      expect(restored.properties['lastHealLocation'], 'pokemon_center_1');
    });

    test('defaults are coherent', () {
      const save = SaveData(saveId: 'test');
      expect(save.currentMapId, '');
      expect(save.playerPosition, const GridPos(x: 0, y: 0));
      expect(save.playerFacing, EntityFacing.south);
      expect(save.party.members, isEmpty);
      expect(save.progression.unlockedFieldAbilities, isEmpty);
      expect(save.progression.storyFlags, isEmpty);
      expect(save.properties, isEmpty);
    });

    test('copyWith preserves unmodified fields', () {
      const save = SaveData(
        saveId: 'test',
        currentMapId: 'route_1',
        party: PlayerParty(members: [
          PlayerPokemon(id: 'p1', speciesId: 'bulbasaur'),
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
