import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> rodJson(String kind) => {
  'id': 'custom_tool',
  'displayName': 'Outil de rivière',
  'pocketId': 'custom',
  'tags': ['key-item'],
  'uses': [
    {
      'contexts': ['overworld'],
      'target': 'world',
      'consumption': 'never',
      'effect': {'kind': 'fishing', 'rodKind': kind},
    },
  ],
};

void main() {
  for (final kind in ['old_rod', 'good_rod', 'super_rod']) {
    test('$kind is a reusable typed capability independent of item names', () {
      final catalog = decodeProjectItemCatalog({
        'schemaVersion': 1,
        'entries': [rodJson(kind)],
      });
      final use = catalog.entries.single.uses.single;
      expect(use.toJson()['effect'], {'kind': 'fishing', 'rodKind': kind});
      expect(
        validateProjectItemCatalog(
          catalog,
          capabilityTruth: itemSystemV1CapabilityTruth,
        ).hasBlockingDiagnostics,
        isFalse,
      );
      expect(encodeProjectItemCatalog(catalog)['entries'], [
        catalog.entries.single.toJson(),
      ]);
    });
  }

  test('fishing rejects unknown rods and extra effect fields', () {
    for (final effect in [
      {'kind': 'fishing', 'rodKind': 'walk'},
      {'kind': 'fishing', 'rodKind': 'old_rod', 'chance': 0.5},
    ]) {
      final json = rodJson('old_rod');
      (json['uses'] as List).single['effect'] = effect;
      expect(
        () => decodeProjectItemCatalog({
          'schemaVersion': 1,
          'entries': [json],
        }),
        throwsA(isA<ProjectItemCatalogCodecException>()),
      );
    }
  });

  test(
    'fishing rejects battle, consumption, party targets and non-key items',
    () {
      final valid = ProjectItemDefinition.fromJson(rodJson('old_rod'));
      final use = valid.uses.single;
      for (final invalid in [
        valid.copyWith(
          uses: [
            use.copyWith(contexts: {ProjectItemUseContext.battle}),
          ],
        ),
        valid.copyWith(
          uses: [
            use.copyWith(consumption: ProjectItemConsumptionPolicy.onApplied),
          ],
        ),
        valid.copyWith(
          uses: [use.copyWith(target: ProjectItemTargetKind.partyMember)],
        ),
        valid.copyWith(tags: {}),
      ]) {
        expect(
          validateProjectItemCatalog(
            ProjectItemCatalog(schemaVersion: 1, entries: [invalid]),
            capabilityTruth: itemSystemV1CapabilityTruth,
          ).hasBlockingDiagnostics,
          isTrue,
        );
      }
    },
  );
}
