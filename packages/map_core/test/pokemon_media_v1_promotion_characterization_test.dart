import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('a v1 extension becomes active after a version-only promotion', () {
    const legacyFields = {
      'frontAnimated': 'assets/legacy/front.gif',
      'backAnimated': 'assets/legacy/back.gif',
      'frontShinyAnimated': 'assets/legacy/front-shiny.gif',
      'backShinyAnimated': 'assets/legacy/back-shiny.gif',
      'frontFemaleAnimated': 'assets/legacy/front-female.gif',
      'backFemaleAnimated': 'assets/legacy/back-female.gif',
      'frontShinyFemaleAnimated': 'assets/legacy/front-shiny-female.gif',
      'backShinyFemaleAnimated': 'assets/legacy/back-shiny-female.gif',
    };
    final original = PokemonMediaFile.fromJson({
      'schemaVersion': 1,
      'speciesId': 'cyndaquil',
      'defaultFormId': 'base',
      'variants': {
        'base': {
          'frontStatic': 'assets/cyndaquil/front.png',
          'cry': 'assets/cyndaquil/cry.wav',
          ...legacyFields,
          'otherExtension': {'owner': 'legacy'},
        },
      },
    });

    Map<String, String?> animatedPaths(PokemonMediaVariant variant) => {
      'frontAnimated': variant.frontAnimated,
      'backAnimated': variant.backAnimated,
      'frontShinyAnimated': variant.frontShinyAnimated,
      'backShinyAnimated': variant.backShinyAnimated,
      'frontFemaleAnimated': variant.frontFemaleAnimated,
      'backFemaleAnimated': variant.backFemaleAnimated,
      'frontShinyFemaleAnimated': variant.frontShinyFemaleAnimated,
      'backShinyFemaleAnimated': variant.backShinyFemaleAnimated,
    };

    expect(
      animatedPaths(original.variants['base']!).values,
      everyElement(isNull),
    );
    final retained = original.toJson();
    final variant = (retained['variants'] as Map)['base'] as Map;
    for (final entry in legacyFields.entries) {
      expect(variant[entry.key], entry.value);
    }
    expect(variant['frontStatic'], 'assets/cyndaquil/front.png');
    expect(variant['cry'], 'assets/cyndaquil/cry.wav');
    expect(variant['otherExtension'], {'owner': 'legacy'});

    final promoted = PokemonMediaFile.fromJson({
      ...retained,
      'schemaVersion': 2,
    });
    expect(animatedPaths(promoted.variants['base']!), legacyFields);
  });

  test('a v1 non-string extension makes a version-only promotion fail', () {
    final original = PokemonMediaFile.fromJson({
      'schemaVersion': 1,
      'speciesId': 'cyndaquil',
      'defaultFormId': 'base',
      'variants': {
        'base': {
          'frontAnimated': {'legacyAnimation': 'idle'},
        },
      },
    });

    expect(original.variants['base']!.frontAnimated, isNull);
    final retained = original.toJson();
    expect(((retained['variants'] as Map)['base'] as Map)['frontAnimated'], {
      'legacyAnimation': 'idle',
    });
    expect(
      () => PokemonMediaFile.fromJson({...retained, 'schemaVersion': 2}),
      throwsA(isA<TypeError>()),
    );
  });
}
