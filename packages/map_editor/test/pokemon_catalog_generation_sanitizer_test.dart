import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/pokemon_catalog_generation_sanitizer.dart';

void main() {
  const sanitizer = PokemonCatalogGenerationSanitizer();

  test('keeps only form ids that are actually present', () {
    const forms = PokemonSpeciesForms(
      baseFormId: 'base',
      isBaseForm: true,
      formId: 'base',
      otherForms: <String>['mega', 'hisui'],
    );

    final result = sanitizer.sanitizeForms(
      forms,
      availableFormIds: const <String>{'base', 'mega'},
    );

    expect(result.otherForms, <String>['mega']);
  });

  test('normalizes representable evolution conditions and removes others', () {
    const entries = <PokemonEvolutionEntry>[
      PokemonEvolutionEntry(
        targetSpeciesId: 'friend',
        method: 'level_up',
        minFriendship: 220,
      ),
      PokemonEvolutionEntry(
        targetSpeciesId: 'move',
        method: 'level_up',
        requiredMoveId: 'ancient_power',
      ),
      PokemonEvolutionEntry(targetSpeciesId: 'conditional', method: 'level_up'),
      PokemonEvolutionEntry(targetSpeciesId: 'trade_target', method: 'trade'),
      PokemonEvolutionEntry(
        targetSpeciesId: 'future_target',
        method: 'level_up',
        minLevel: 40,
      ),
    ];

    final result = sanitizer.sanitizeEvolutions(
      entries,
      availableSpeciesIds: const <String>{
        'friend',
        'move',
        'conditional',
        'trade_target',
      },
    );

    expect(result, hasLength(3));
    expect(result[0].method, 'friendship');
    expect(result[0].minFriendship, 220);
    expect(result[1].method, 'known_move');
    expect(result[1].requiredMoveId, 'ancient_power');
    expect(result[2].method, 'level_up');
    expect(result[2].minLevel, 1);
  });

  test('keeps only media variants for available forms', () {
    const media = PokemonMediaFile(
      speciesId: 'greninja',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{
        'base': PokemonMediaVariant(frontStatic: 'base.png'),
        'ash': PokemonMediaVariant(frontStatic: 'ash.png'),
      },
    );

    final result = sanitizer.sanitizeMedia(
      media,
      availableFormIds: const <String>{'base'},
    );

    expect(result.defaultFormId, 'base');
    expect(result.variants.keys, <String>['base']);
  });

  test('deduplicates level evolutions and keeps the lowest level', () {
    const entries = <PokemonEvolutionEntry>[
      PokemonEvolutionEntry(
        targetSpeciesId: 'quilava',
        method: 'level_up',
        minLevel: 17,
      ),
      PokemonEvolutionEntry(
        targetSpeciesId: 'quilava',
        method: 'level_up',
        minLevel: 14,
      ),
    ];

    final result = sanitizer.sanitizeEvolutions(
      entries,
      availableSpeciesIds: const <String>{'quilava'},
    );

    expect(result, hasLength(1));
    expect(result.single.minLevel, 14);
  });
}
