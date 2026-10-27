import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'egg identity survives save parsing while legacy Pokemon stay hatched',
    () {
      final legacy = <String, dynamic>{
        'speciesId': 'clockbird',
        'natureId': 'hardy',
        'abilityId': 'clockwork',
        'currentHp': 12,
      };
      final egg = PlayerPokemon.fromJson({
        ...legacy,
        'isEgg': true,
      }).normalized();
      expect(egg.toJson()['isEgg'], isTrue);
      expect(PlayerPokemon.fromJson(egg.toJson()), egg);
      expect(PlayerPokemon.fromJson(legacy).isEgg, isFalse);
      expect(
        PlayerPokemon.fromJson(legacy).toJson().containsKey('isEgg'),
        isFalse,
      );
    },
  );

  test(
    'catalog egg gift is explicit and rejects nickname or dex disclosure',
    () {
      final json = <String, dynamic>{
        'kind': 'receivePokemonFromCatalog',
        'speciesId': 'clockbird',
        'formId': 'bronze',
        'level': 1,
        'nicknamePolicy': 'disabled',
        'nicknameMaxGraphemes': 10,
        'pokedexPresentationPolicy': 'never',
        'isEgg': true,
      };
      final command = SceneInteractiveCommand.fromJson(json);
      expect(command.toJson()['isEgg'], isTrue);
      expect(SceneInteractiveCommand.fromJson(command.toJson()), command);
      expect(
        () => SceneInteractiveCommand.fromJson({
          ...json,
          'nicknamePolicy': 'offer',
        }),
        throwsFormatException,
      );
      expect(
        () => SceneInteractiveCommand.fromJson({
          ...json,
          'pokedexPresentationPolicy': 'whenNewAndPokedexVisible',
        }),
        throwsFormatException,
      );
      expect(
        () => SceneInteractiveCommand.fromJson({...json, 'isEgg': 'true'}),
        throwsFormatException,
      );
    },
  );
}
