import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'offline builtin reconstructs its admitted reference inventory and fresh shards',
      () {
    final catalog = NativePsdkCatalogManifest.builtin();
    expect(canonicalHashOf(catalog.toJson()).value,
        NativePsdkCatalogManifest.builtinManifestHash);
    final index =
        NativePsdkCatalogManifest.builtinReferenceAdmission(catalog: catalog);
    final definitions = (index.document['definitions'] as List).cast<Map>();
    final admitted =
        definitions.where((row) => row['status'] == 'admitted').toList();
    final ids = {
      for (final row in admitted)
        ...(row['nativeSpeciesIds'] as List).cast<String>()
    };
    expect(catalog.speciesById.keys.toSet(), ids);
    expect(catalog.evidence['catalogRequests'], hasLength(admitted.length));
    expect(catalog.shards.length, inInclusiveRange(1, 128));
    expect(catalog.movesById.length, inInclusiveRange(1, 4096));
    expect(catalog.speciesById['poochyena']!.names['fr'], 'Medhyèna');
    expect(catalog.speciesById['mightyena']!.names['en'], 'Mightyena');
    expect(index.summary['refusedFamilies'], isNotEmpty);
    expect(() => (index.document['counts'] as Map)['admittedBases'] = 0,
        throwsUnsupportedError);
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
        NativePsdkCatalogManifest.builtinManifestHash);
  });

  final catalog = NativePsdkCatalogManifest.builtin();
  final index =
      NativePsdkCatalogManifest.builtinReferenceAdmission(catalog: catalog);
  for (final mutation in [
    'hash',
    'manifest',
    'counts',
    'family',
    'forms',
    'catalogClosure'
  ]) {
    test('reference admission rejects $mutation disagreement', () {
      final document = (jsonDecode(jsonEncode(index.document)) as Map)
          .cast<String, Object?>();
      final definitions = (document['definitions'] as List).cast<Map>();
      switch (mutation) {
        case 'hash':
          document['referenceSnapshotHash'] = '0' * 64;
        case 'manifest':
          document['catalogManifestHash'] = '0' * 64;
        case 'counts':
          (document['counts'] as Map)['admittedBases'] = 0;
        case 'family':
          definitions.first['familyId'] = 'other_family';
        case 'forms':
          (definitions.first['nativeSpeciesIds'] as List).removeLast();
        case 'catalogClosure':
          break;
      }
      expect(
          () => NativePsdkReferenceIndex.fromJson(document,
              expectedHash: mutation == 'hash'
                  ? index.canonicalHash
                  : canonicalHashOf(document,
                      limits: const ContractLimits(
                          maxNodes: 2000000, maxTextCodeUnits: 16777216)),
              catalogManifestHash:
                  Sha256Hash(NativePsdkCatalogManifest.builtinManifestHash),
              catalogSpeciesIds: mutation == 'catalogClosure'
                  ? ['missing_native_identity']
                  : catalog.speciesById.keys),
          throwsA(isA<ContractError>()));
    });
  }
}
