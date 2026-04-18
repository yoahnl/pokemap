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

    test(
        'adds only bootstrap entries that are already honestly supported by the bridge and battle engine',
        () {
      expect(
        movesById['scratch']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['tail_whip']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['ember']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['water_gun']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['quick_attack']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['spikes']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );

      // On verrouille quelques détails métier pour éviter un faux lift :
      // - `quick_attack` doit rester un vrai move de priorité ;
      // - `tail_whip` doit rester une vraie baisse déterministe de Défense ;
      // - `ember` ne doit pas perdre sa petite chance de brûlure.
      expect(movesById['quick_attack']!.priority, equals(1));
      expect(
        movesById['tail_whip']!.effects.single.map(
              fixedDamage: (_) => null,
              multiHit: (_) => null,
              applyStatus: (_) => null,
              applyVolatileStatus: (_) => null,
              modifyStats: (effect) => effect.stageChanges.single.stages,
              heal: (_) => null,
              drain: (_) => null,
              recoil: (_) => null,
              requireRecharge: (_) => null,
              chargeThenStrike: (_) => null,
              breakProtect: (_) => null,
              setWeather: (_) => null,
              setTerrain: (_) => null,
              setSideCondition: (_) => null,
              setSlotCondition: (_) => null,
              setPseudoWeather: (_) => null,
              forceSwitch: (_) => null,
              selfSwitch: (_) => null,
            ),
        equals(-1),
      );
      expect(
        movesById['ember']!.effects.single.map(
              fixedDamage: (_) => null,
              multiHit: (_) => null,
              applyStatus: (effect) => effect.chance,
              applyVolatileStatus: (_) => null,
              modifyStats: (_) => null,
              heal: (_) => null,
              drain: (_) => null,
              recoil: (_) => null,
              requireRecharge: (_) => null,
              chargeThenStrike: (_) => null,
              breakProtect: (_) => null,
              setWeather: (_) => null,
              setTerrain: (_) => null,
              setSideCondition: (_) => null,
              setSlotCondition: (_) => null,
              setPseudoWeather: (_) => null,
              forceSwitch: (_) => null,
              selfSwitch: (_) => null,
            ),
        equals(10),
      );
      expect(
        movesById['spikes']!.effects.single.map(
              fixedDamage: (_) => null,
              multiHit: (_) => null,
              applyStatus: (_) => null,
              applyVolatileStatus: (_) => null,
              modifyStats: (_) => null,
              heal: (_) => null,
              drain: (_) => null,
              recoil: (_) => null,
              requireRecharge: (_) => null,
              chargeThenStrike: (_) => null,
              breakProtect: (_) => null,
              setWeather: (_) => null,
              setTerrain: (_) => null,
              setSideCondition: (effect) => effect.conditionId,
              setSlotCondition: (_) => null,
              setPseudoWeather: (_) => null,
              forceSwitch: (_) => null,
              selfSwitch: (_) => null,
            ),
        equals('spikes'),
      );
    });
  });
}
