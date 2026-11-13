
import 'package:avelune_studio/features/pokemon/data/pokemon_moves_projection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';


void main() {
  const catalog = PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(description: ''),
    entries: [
      {
        'id': 'growl',
        'name': 'Growl',
        'source': 'golden_item_system',
        'type': 'normal',
        'category': 'status',
      },
      {
        'id': 'custom-growl',
        'name': 'My Growl',
        'names': {'fr': 'Mon Cri'},
        'source': 'project_custom',
        'type': 'grass',
        'category': 'special',
        'power': 100,
      },
    ],
  );

  test(
    'project locale selects official and authored names without changing IDs',
    () {
      final french = projectPokemonMoves(catalog, 'moves.json', 'fr-FR');
      final english = projectPokemonMoves(catalog, 'moves.json', 'en');
      expect(french.entries.first.id, 'custom-growl');
      expect(french.entries.first.name, 'Mon Cri');
      expect(french.entries.first.userCreated, isTrue);
      expect(french.entries.last.id, 'growl');
      expect(french.entries.last.name, 'Rugissement');
      expect(french.entries.last.userCreated, isFalse);
      expect(english.entries.first.name, 'Growl');
      expect(english.entries.last.name, 'My Growl');
    },
  );

}
