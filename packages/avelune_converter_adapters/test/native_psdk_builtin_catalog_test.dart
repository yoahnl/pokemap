import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'offline builtin reconstructs the frozen world manifest and fresh shards',
      () {
    final catalog = NativePsdkCatalogManifest.builtin();
    expect(canonicalHashOf(catalog.toJson()).value,
        '496de1dd732814068173cec7da27264561b151bb04984b322ebd1cf514d2f214');
    expect(catalog.shards, hasLength(10));
    expect(catalog.speciesById, hasLength(300));
    expect(catalog.movesById, hasLength(562));
    expect(catalog.catalogs['abilities']!.entries, hasLength(142));
    expect(catalog.evidence['catalogRequests'], hasLength(2349));
    expect(catalog.evidence.containsKey('sourceTrainerKeys'), isFalse);
    final trainerBundle = NativePsdkTrainerBundle.builtin();
    expect(trainerBundle.evidence['sourceTrainerKeys'], hasLength(11));
    final rosters = trainerBundle.evidence['sourceTrainerRosters'] as Map;
    for (final roster in rosters.values.cast<List>()) {
      for (final member in roster.cast<Map>()) {
        final id = (member['sourceSpeciesSymbol'] as String).toLowerCase();
        expect(catalog.speciesById[id]!.abilities.primary,
            trainerBundle.speciesById[id]!.abilities.primary);
        expect(
            nativeTrainerDefaultMoveIds(
                catalog.learnsetsBySpeciesId[id]!, member['level'] as int),
            nativeTrainerDefaultMoveIds(trainerBundle.learnsetsBySpeciesId[id]!,
                member['level'] as int));
      }
    }
    for (final shard in catalog.shards.entries) {
      expect(
          canonicalHashOf(shard.value.toJson(),
                  limits: nativePsdkCatalogShardJsonLimits)
              .value,
          shard.key);
    }
    final original = catalog.speciesById['rattata']!.names['en'];
    catalog.speciesById['rattata']!.names['en'] = 'mutated caller';
    expect(catalog.toJson, throwsA(isA<ContractError>()));
    final fresh = NativePsdkCatalogManifest.builtin();
    expect(fresh.speciesById['rattata']!.names['en'], original);
    expect(canonicalHashOf(fresh.toJson()).value,
        '496de1dd732814068173cec7da27264561b151bb04984b322ebd1cf514d2f214');
  });
}
