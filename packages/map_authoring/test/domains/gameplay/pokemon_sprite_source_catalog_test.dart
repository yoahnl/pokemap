import 'package:map_authoring/src/domains/gameplay/pokemon_sprite_source_catalog.dart';
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';

void main() {
  Map<String, Object?> entry(int dex, int form, String name) => {
        'sid': 's${dex * 32 + form}',
        'num': dex,
        'formeNum': form,
        'forme': name,
      };

  test('default is semantic rather than numeric form zero', () {
    final catalog = PokemonSpriteSourceCatalog.fromJson({
      's21312': entry(666, 0, 'Icy Snow'),
      's21318': entry(666, 6, ''),
      's22912': entry(716, 0, 'Neutral'),
      's22913': entry(716, 1, ''),
      's24768': entry(774, 0, 'Meteor'),
      's24775': entry(774, 7, ''),
    });
    for (final value in [(666, 's21318'), (716, 's22913'), (774, 's24775')]) {
      expect(
          catalog
              .match(nationalDex: value.$1, formId: 'base', baseFormId: 'base')
              ?.identity
              .id,
          value.$2);
    }
  });

  test('ambiguous forms require explicit mappings and never first-match', () {
    final catalog = PokemonSpriteSourceCatalog.fromJson({
      's22976': entry(718, 0, ''),
      's22977': entry(718, 1, '10%'),
      's22980': entry(718, 4, 'Complete'),
      's22978': entry(718, 2, '10%'),
      's22979': entry(718, 3, ''),
      's24768': entry(774, 0, 'Meteor'),
      's24769': entry(774, 1, 'Meteor'),
    });
    expect(
        catalog
            .match(nationalDex: 718, formId: 'base', baseFormId: 'base')
            ?.identity
            .id,
        's22976');
    expect(
        catalog
            .match(nationalDex: 718, formId: '10', baseFormId: 'base')
            ?.identity
            .id,
        's22977');
    expect(
        catalog
            .match(nationalDex: 774, formId: 'meteor', baseFormId: 'base')
            ?.identity
            .id,
        's24768');
    expect(catalog.match(nationalDex: 718, formId: '10%', baseFormId: 'base'),
        isNull);
    expect(catalog.match(nationalDex: 999, formId: 'base', baseFormId: 'base'),
        isNull);
  });

  test('identity formula is verified and non-national records excluded', () {
    final catalog = PokemonSpriteSourceCatalog.fromJson({
      's32': entry(1, 0, ''),
      'negative': {'num': -1},
    });
    expect(catalog.identities.map((entry) => entry.id), ['s32']);
    expect(() => PokemonSpriteSourceCatalog.fromJson({'s33': entry(1, 0, '')}),
        throwsFormatException);
    expect(() => PokemonSpriteSourceCatalog.fromJson({'s64': entry(1, 32, '')}),
        throwsFormatException);
  });

  test('a selected regional default retains its own source form', () {
    final catalog = PokemonSpriteSourceCatalog.fromJson({
      's1216': entry(38, 0, ''),
      's1217': entry(38, 1, 'Alola'),
      's22977': entry(718, 1, '10%'),
    });
    expect(
        catalog
            .match(nationalDex: 38, formId: 'alola', baseFormId: 'alola')
            ?.identity
            .id,
        's1217');
    expect(
        catalog
            .match(nationalDex: 718, formId: '10', baseFormId: '10')
            ?.identity
            .id,
        's22977');
  });

  test('media defaults cannot replace the species base identity', () {
    final catalog = PokemonSpriteSourceCatalog.fromJson({
      's1216': entry(38, 0, ''),
      's1217': entry(38, 1, 'Alola'),
    });
    final species = PokemonSpeciesFile.fromJson({
      'schemaVersion': currentPokemonDataSchemaVersion,
      'id': 'ninetales',
      'nationalDex': 38,
      'forms': {
        'formId': 'base',
        'otherForms': ['alola', 'custom'],
      },
    });
    for (final selected in ['alola', 'custom']) {
      final qualified = catalog.qualify(species: [
        species
      ], media: {
        species.id: PokemonMediaFile(
          speciesId: species.id,
          defaultFormId: selected,
        ),
      });
      final byForm = {
        for (final form in qualified) form['formId']: form['sourceId'],
      };
      expect(byForm['base'], 's1216');
      expect(byForm['alola'], 's1217');
      expect(byForm['custom'], isNull);
      expect(
          qualified.singleWhere((form) => form['isDefault'] == true)['formId'],
          selected);
    }
  });

  test('media aliases do not change source or gameplay form identity', () {
    expect(PokemonSpriteSourceCatalog.homeMediaIdentity('s22978'), 's22977');
    expect(PokemonSpriteSourceCatalog.homeMediaIdentity('s24774'), 's24768');
    expect(PokemonSpriteSourceCatalog.homeMediaIdentity('s24775'), 's24775');
  });

  test('named Zygarde default takes precedence over the base exception', () {
    final catalog = PokemonSpriteSourceCatalog.fromJson({
      's22976': entry(718, 0, ''),
      's22980': entry(718, 4, 'Complete'),
    });
    expect(
        catalog
            .match(nationalDex: 718, formId: 'complete', baseFormId: 'complete')
            ?.identity
            .id,
        's22980');
  });
}
