import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/seeds/pokemon_moves_bootstrap_seed.dart';

void main() {
  group('buildEmbeddedPokemonMovesBootstrapSeed', () {
    late Map<String, PokemonMove> movesById;

    setUp(() {
      final catalog = buildEmbeddedPokemonMovesBootstrapSeed();
      movesById = <String, PokemonMove>{
        for (final entry in catalog.entries)
          PokemonMove.fromJson(entry).id: PokemonMove.fromJson(entry),
      };
    });

    test(
        'keeps obviously unsupported switch and multi-hit seams out of supported bootstrap claims',
        () {
      expect(
        movesById['absorb']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['double_slap']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['u_turn']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['whirlwind']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
    });

    test('reflects the real BE8 and BE9 support that now exists locally', () {
      expect(
        movesById['solar_beam']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['trick_room']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredPartial),
      );
    });
  });
}
