import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('native trade requirements round trip without source variables', () {
    const requirements = PokemonTradeEvolutionRequirements(
      requiredHeldItemId: 'native-coat',
      requiredPartnerSpeciesId: 'shelmet',
    );
    final decoded = PokemonTradeEvolutionRequirements.fromJson(
      requirements.toJson(),
    );
    expect(decoded.requiredHeldItemId, 'native-coat');
    expect(decoded.requiredPartnerSpeciesId, 'shelmet');
  });
  test(
    'native requirement reader rejects unknown and malformed constraints',
    () {
      for (final json in <Map<String, dynamic>>[
        {'unknown': true},
        {'requiredHeldItemId': 1},
        {'requiredPartnerSpeciesId': '../shelmet'},
        {'requiredHeldItemId': ''},
      ]) {
        expect(
          () => PokemonTradeEvolutionRequirements.fromJson(json),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'trade catalog entry preserves typed requirements through canonical JSON',
    () {
      final entry = PokemonEvolutionEntry.fromJson({
        'targetSpeciesId': 'steelix',
        'method': 'trade',
        'tradeRequirements': {'requiredHeldItemId': 'native-coat'},
      });
      expect(entry.tradeRequirements!.requiredHeldItemId, 'native-coat');
      expect(entry.toJson()['tradeRequirements'], {
        'requiredHeldItemId': 'native-coat',
      });
    },
  );
  test('trade catalog rejects an unknown top-level eligibility constraint', () {
    expect(
      () => PokemonEvolutionEntry.fromJson({
        'targetSpeciesId': 'machamp',
        'method': 'trade',
        'tradeRequirements': <String, dynamic>{},
        'timeOfDay': 'night',
      }),
      throwsFormatException,
    );
  });

  test('trade catalog cannot omit its closed requirements object', () {
    expect(
      () => PokemonEvolutionEntry.fromJson({
        'targetSpeciesId': 'alakazam',
        'method': 'trade',
      }),
      throwsFormatException,
    );
  });
  test(
    'nontrade catalog cannot smuggle a trade constraint into level rules',
    () {
      expect(
        () => PokemonEvolutionEntry.fromJson({
          'targetSpeciesId': 'alakazam',
          'method': 'level_up',
          'minLevel': 20,
          'tradeRequirements': {'requiredHeldItemId': 'native-coat'},
        }),
        throwsFormatException,
      );
    },
  );
  test('ordinary native evolution JSON keeps its established shape', () {
    const entry = PokemonEvolutionEntry(
      targetSpeciesId: 'ivysaur',
      method: 'level_up',
      minLevel: 16,
    );
    expect(entry.toJson().containsKey('tradeRequirements'), false);
  });
  test(
    'the native held capability validates its exact id and rejects aliases',
    () {
      expect(
        itemSystemV1CapabilityTruth.supportsHeldEffect('prevent_evolution'),
        true,
      );
      for (final effect in [
        'prevent-evolution',
        'PREVENT_EVOLUTION',
        'unknown_effect',
      ]) {
        expect(itemSystemV1CapabilityTruth.supportsHeldEffect(effect), false);
      }
      final report = validateProjectItemCatalog(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'native-stone',
              displayName: 'Evolution Guard',
              pocketId: 'held-items',
              heldEffectId: 'prevent_evolution',
            ),
          ],
        ),
        capabilityTruth: itemSystemV1CapabilityTruth,
      );
      expect(report.hasBlockingDiagnostics, false);
    },
  );

  test('native passive held effects reject arbitrary ids', () {
    expect(
      PokemonPassiveHeldEffect.fromId('prevent_evolution'),
      PokemonPassiveHeldEffect.preventEvolution,
    );
    expect(PokemonPassiveHeldEffect.fromId('unknown-effect'), isNull);
    expect(PokemonPassiveHeldEffect.fromId('everstone'), isNull);
  });
}
