import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/native_encounter_qualification_fixture.dart';

void main() {
  test(
      'selected source scopes qualify independently without fixed map species or tuple identities',
      () async {
    for (final mapId in [7, 91]) {
      final row = await nativeEncounterQualificationFixture(
          mapId: mapId,
          namespace: 'world-$mapId',
          symbol: 'SOURCE_$mapId',
          firstLevel: mapId == 7 ? 3 : 6,
          lastLevel: mapId == 7 ? 5 : 7);
      final result = await const NativeEncounterCatalogBindings().bind(
          snapshot: row.fixture.snapshot,
          source: row.pbs,
          files: row.fixture.files,
          nativeMapIds: {mapId: 'native-$mapId'},
          qualification: row.qualification,
          ratePolicy: NativeEncounterRatePolicy
              .adaptSourceBasePercentToNativeConstantChance);
      expect(result.tables, hasLength(1));
      expect(result.tables.single.entries.single.speciesId, 'rattata');
      expect(row.qualification.wildCases, hasLength(mapId == 7 ? 3 : 2));
      expect(row.qualification.admitsAutomaticSource(row.fixture.snapshot),
          isTrue);
      expect(
          row.qualification.admitsSourceScope(row.fixture.snapshot, [mapId],
              source: row.pbs),
          isTrue);
      expect(
          row.qualification.admitsSourceScope(row.fixture.snapshot, [mapId + 1],
              source: row.pbs),
          isFalse);
      final foreign = await nativeEncounterQualificationFixture(
          mapId: mapId, namespace: 'foreign-$mapId');
      await expectLater(
          const NativeEncounterCatalogBindings().bind(
              snapshot: foreign.fixture.snapshot,
              source: foreign.pbs,
              files: foreign.fixture.files,
              nativeMapIds: {mapId: 'native'},
              qualification: row.qualification,
              ratePolicy: NativeEncounterRatePolicy
                  .adaptSourceBasePercentToNativeConstantChance),
          throwsA(isA<ContractError>().having(
              (e) => e.code, 'code', 'native_encounter.source_binding')));
    }
  });
  test(
      'qualifications round trip only through current typed portable artifacts',
      () async {
    final row = await nativeEncounterQualificationFixture();
    final release = row.qualification.artifacts();
    final restored = NativeEncounterCatalogQualification.fromArtifacts(
        evidence: release.evidence, artifacts: release.artifacts);
    expect(restored.evidenceHash, row.qualification.evidenceHash);
    expect(restored.wildCases, row.qualification.wildCases);
    for (final kind in [
      'unknownRelease',
      'nativeEncounterGenericQualification'
    ]) {
      expect(
          () => NativeEncounterCatalogQualification.fromArtifacts(
              evidence: {...release.evidence, 'kind': kind},
              artifacts: release.artifacts),
          throwsA(isA<ContractError>()));
    }
    expect(
        () => NativeEncounterCatalogQualification.fromArtifacts(
            evidence: release.evidence, artifacts: []),
        throwsA(isA<ContractError>()));
  });
  test('source base percentage adaptation remains explicit', () async {
    final row = await nativeEncounterQualificationFixture();
    await expectLater(
        const NativeEncounterCatalogBindings().bind(
            snapshot: row.fixture.snapshot,
            source: row.pbs,
            files: row.fixture.files,
            nativeMapIds: {7: 'native'},
            qualification: row.qualification,
            ratePolicy: NativeEncounterRatePolicy.unresolved),
        throwsA(isA<ContractError>().having(
            (e) => e.code, 'code', 'native_encounter.rate_policy_required')));
  });
}
