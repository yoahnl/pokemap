import 'package:avelune_studio/features/pokemon/data/pokemon_moves_snapshot_source.dart';

class PokemonMovesSourceFixture implements PokemonMovesSnapshotSource {
  const PokemonMovesSourceFixture();

  @override
  Future<Map<String, dynamic>> fetch() async => {
    'thunderbolt': {
      'name': 'Thunderbolt',
      'type': 'Electric',
      'category': 'Special',
      'basePower': 90,
      'accuracy': 100,
      'pp': 15,
      'priority': 0,
      'target': 'normal',
      'shortDesc': 'May paralyze the target.',
      'desc': 'A strong electric blast crashes down on the target.',
      'gen': 1,
    },
  };
}
