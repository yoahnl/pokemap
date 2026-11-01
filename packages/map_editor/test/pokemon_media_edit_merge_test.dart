import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_media_use_case.dart';

void main() {
  test('preserves animated and unknown fields while applying legacy edits', () {
    final before = PokemonMediaFile.fromJson({
      'schemaVersion': 2,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'extension': {'source': 'kept'},
      'variants': {
        'base': {
          'frontStatic': 'old.png',
          'frontAnimated': 'front.gif',
          'backAnimated': 'back.gif',
          'frontShinyAnimated': 'front-shiny.gif',
          'backShinyAnimated': 'back-shiny.gif',
          'frontFemaleAnimated': 'front-female.gif',
          'backFemaleAnimated': 'back-female.gif',
          'frontShinyFemaleAnimated': 'front-shiny-female.gif',
          'backShinyFemaleAnimated': 'back-shiny-female.gif',
          'variantExtension': {'value': 7},
          'animations': {
            'idle': {
              'sheet': 'old-sheet.png',
              'animationId': 'old-id',
              'animationExtension': true,
            },
            'removed': {'sheet': 'removed.png', 'animationId': 'removed'},
          },
        },
        'removed': {'frontAnimated': 'removed.gif'},
      },
    });
    final beforeJson = jsonEncode(before.toJson());
    final result = mergePokemonMediaLegacyDraft(
      before: before,
      edited: const PokemonMediaFile(
        speciesId: 'oshawott',
        defaultFormId: 'base',
        variants: {
          'base': PokemonMediaVariant(
            frontStatic: 'new.png',
            animations: {
              'idle': PokemonMediaAnimationRef(
                sheet: 'new-sheet.png',
                animationId: 'new-id',
              ),
            },
          ),
          'new': PokemonMediaVariant(frontStatic: 'new-form.png'),
        },
      ),
    );

    final json = result.toJson();
    final variants = json['variants'] as Map;
    final base = variants['base'] as Map;
    final animations = base['animations'] as Map;
    expect(json['schemaVersion'], 2);
    expect(json['extension'], {'source': 'kept'});
    expect(variants.keys, unorderedEquals(['base', 'new']));
    expect(base['frontStatic'], 'new.png');
    expect(base['variantExtension'], {'value': 7});
    for (final field in [
      'frontAnimated',
      'backAnimated',
      'frontShinyAnimated',
      'backShinyAnimated',
      'frontFemaleAnimated',
      'backFemaleAnimated',
      'frontShinyFemaleAnimated',
      'backShinyFemaleAnimated',
    ]) {
      expect(base[field], (before.toJson()['variants'] as Map)['base'][field]);
    }
    expect(animations.keys, ['idle']);
    expect(animations['idle']['sheet'], 'new-sheet.png');
    expect(animations['idle']['animationId'], 'new-id');
    expect(animations['idle']['animationExtension'], true);
    expect(jsonEncode(before.toJson()), beforeJson);
    (json['extension'] as Map)['source'] = 'changed';
    expect((before.toJson()['extension'] as Map)['source'], 'kept');
  });

  test('keeps v1 extension fields opaque when an old document is edited', () {
    final before = PokemonMediaFile.fromJson({
      'schemaVersion': 1,
      'speciesId': 'oshawott',
      'defaultFormId': 'base',
      'variants': {
        'base': {'frontAnimated': 'legacy-extension', 'other': 4},
      },
    });
    final result = mergePokemonMediaLegacyDraft(
      before: before,
      edited: const PokemonMediaFile(
        speciesId: 'oshawott',
        defaultFormId: 'base',
        variants: {'base': PokemonMediaVariant(frontStatic: 'new.png')},
      ),
    );
    expect(result.schemaVersion, 1);
    expect(result.variants['base']!.frontAnimated, isNull);
    final base = (result.toJson()['variants'] as Map)['base'] as Map;
    expect(base['frontAnimated'], 'legacy-extension');
    expect(base['other'], 4);
    expect(base['frontStatic'], 'new.png');
  });

  test('accepts a new document and rejects a different media identity', () {
    const edited = PokemonMediaFile(
      speciesId: 'oshawott',
      defaultFormId: 'base',
      variants: {'base': PokemonMediaVariant(frontStatic: 'new.png')},
    );
    expect(
      mergePokemonMediaLegacyDraft(edited: edited).toJson(),
      edited.toJson(),
    );
    const other = PokemonMediaFile(speciesId: 'other', defaultFormId: 'base');
    expect(
      () => mergePokemonMediaLegacyDraft(before: other, edited: edited),
      throwsArgumentError,
    );
  });

  test('does not silently upgrade a legacy draft to another schema', () {
    const edited = PokemonMediaFile(
      schemaVersion: 2,
      speciesId: 'oshawott',
      defaultFormId: 'base',
    );
    expect(
      () => mergePokemonMediaLegacyDraft(edited: edited),
      throwsArgumentError,
    );
  });
}
