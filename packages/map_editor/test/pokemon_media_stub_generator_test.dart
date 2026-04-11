import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/services/pokemon_media_stub_generator.dart';

void main() {
  const generator = PokemonMediaStubGenerator();

  group('PokemonMediaStubGenerator', () {
    test('generates a base media stub with default animation refs', () {
      final media = generator.createStub(_baseSpecies);

      expect(media.speciesId, 'bulbasaur');
      expect(media.defaultFormId, 'base');
      expect(media.variants.keys, contains('base'));
      expect(
        media.variants['base']?.frontStatic,
        'assets/pokemon/sprites/bulbasaur/front.png',
      );
      expect(
        media.variants['base']?.animations['battleFront']?.animationId,
        'battle_front',
      );
    });

    test('generates extra variants for declared forms', () {
      final media = generator.createStub(_speciesWithForms);

      expect(media.defaultFormId, 'base');
      expect(media.variants.keys, containsAll(<String>['base', 'mega']));
      expect(
        media.variants['mega']?.frontStatic,
        'assets/pokemon/sprites/venusaur/mega/front.png',
      );
    });

    test('uses the species formId as defaultFormId for non-base forms', () {
      final media = generator.createStub(_formSpecies);

      expect(media.defaultFormId, 'dusk');
      expect(
        media.variants['dusk']?.frontStatic,
        'assets/pokemon/sprites/lycanrocdusk/front.png',
      );
    });

    test('fails clearly when species id is empty', () {
      expect(
        () => generator.createStub(
          const PokemonSpeciesFile(
            id: ' ',
            slug: '',
            nationalDex: 0,
            names: <String, String>{},
            speciesName: <String, String>{},
            genIntroduced: 0,
            typing: PokemonSpeciesTyping(),
            baseStats: PokemonSpeciesBaseStats(
              hp: 0,
              atk: 0,
              def: 0,
              spa: 0,
              spd: 0,
              spe: 0,
              bst: 0,
            ),
            abilities: PokemonSpeciesAbilities(primary: ''),
            breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
            progression: PokemonSpeciesProgression(
              growthRateId: '',
              baseExp: 0,
              catchRate: 0,
              baseFriendship: 0,
            ),
            refs: PokemonSpeciesRefs(
              learnset: '',
              evolution: '',
              media: '',
            ),
            dexContent: PokemonSpeciesDexContent(),
            gameplayFlags: PokemonSpeciesGameplayFlags(),
            sourceMeta: PokemonSpeciesSourceMeta(),
          ),
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon media stub speciesId cannot be empty',
          ),
        ),
      );
    });
  });
}

const PokemonSpeciesFile _baseSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{'en': 'Bulbasaur'},
  speciesName: <String, String>{},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 45,
    atk: 49,
    def: 49,
    spa: 65,
    spd: 65,
    spe: 45,
    bst: 318,
  ),
  abilities: PokemonSpeciesAbilities(primary: 'overgrow'),
  breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
  progression: PokemonSpeciesProgression(
    growthRateId: '',
    baseExp: 0,
    catchRate: 0,
    baseFriendship: 0,
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'bulbasaur',
    evolution: 'bulbasaur',
    media: 'bulbasaur',
  ),
  dexContent: PokemonSpeciesDexContent(),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(),
);

const PokemonSpeciesFile _speciesWithForms = PokemonSpeciesFile(
  id: 'venusaur',
  slug: 'venusaur',
  nationalDex: 3,
  names: <String, String>{'en': 'Venusaur'},
  speciesName: <String, String>{},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 80,
    atk: 82,
    def: 83,
    spa: 100,
    spd: 100,
    spe: 80,
    bst: 525,
  ),
  abilities: PokemonSpeciesAbilities(primary: 'overgrow'),
  breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
  progression: PokemonSpeciesProgression(
    growthRateId: '',
    baseExp: 0,
    catchRate: 0,
    baseFriendship: 0,
  ),
  forms: PokemonSpeciesForms(
    baseFormId: '',
    isBaseForm: true,
    otherForms: <String>['mega'],
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'venusaur',
    evolution: 'venusaur',
    media: 'venusaur',
  ),
  dexContent: PokemonSpeciesDexContent(),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(),
);

const PokemonSpeciesFile _formSpecies = PokemonSpeciesFile(
  id: 'lycanrocdusk',
  slug: 'lycanrocdusk',
  nationalDex: 745,
  names: <String, String>{'en': 'Lycanroc-Dusk'},
  speciesName: <String, String>{},
  genIntroduced: 7,
  typing: PokemonSpeciesTyping(types: <String>['rock']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 75,
    atk: 117,
    def: 65,
    spa: 55,
    spd: 65,
    spe: 110,
    bst: 487,
  ),
  abilities: PokemonSpeciesAbilities(primary: 'tough-claws'),
  breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
  progression: PokemonSpeciesProgression(
    growthRateId: '',
    baseExp: 0,
    catchRate: 0,
    baseFriendship: 0,
  ),
  forms: PokemonSpeciesForms(
    baseFormId: 'lycanroc',
    isBaseForm: false,
    formId: 'dusk',
    formName: 'Dusk',
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'lycanrocdusk',
    evolution: 'lycanrocdusk',
    media: 'lycanrocdusk',
  ),
  dexContent: PokemonSpeciesDexContent(),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(),
);
