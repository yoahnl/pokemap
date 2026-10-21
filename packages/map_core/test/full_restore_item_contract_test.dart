import 'package:map_core/map_core.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:test/test.dart';

void main() {
  test('full restore is one strict typed effect with stable roundtrip', () {
    final effect = ProjectItemEffectDefinition.fromJson({
      'kind': 'full_restore',
    });
    expect(effect.toJson(), {'kind': 'full_restore'});
    expect(ProjectItemEffectDefinition.fromJson(effect.toJson()), effect);
    expect(
      () => ProjectItemEffectDefinition.fromJson({
        'kind': 'full_restore',
        'amount': 50,
      }),
      throwsA(isA<UnrecognizedKeysException>()),
    );
  });

  test(
    'full restore is usable by player and trainer from canonical catalog',
    () {
      final catalog = decodeProjectItemCatalog(_catalog());
      expect(
        decodeProjectItemCatalog(encodeProjectItemCatalog(catalog)),
        catalog,
      );
      final item = catalog.entries.single;
      expect(
        validateProjectItemCatalog(
          catalog,
          capabilityTruth: itemSystemV1CapabilityTruth,
        ).hasBlockingDiagnostics,
        isFalse,
      );
      expect(isEligibleTrainerBattleItem(item), isTrue);
      for (final context in [
        ProjectItemUseContext.overworld,
        ProjectItemUseContext.battle,
      ]) {
        expect(
          itemSystemV1CapabilityTruth.supportsUse(
            context,
            projectItemEffectCapabilityOf(item.uses.single.effect),
          ),
          isTrue,
        );
      }
    },
  );

  test('full restore rejects extra codec fields and incompatible target', () {
    expect(
      () => decodeProjectItemCatalog(_catalog(extra: {'mode': 'full'})),
      throwsA(isA<ProjectItemCatalogCodecException>()),
    );
    final catalog = decodeProjectItemCatalog(_catalog(target: 'world'));
    expect(
      validateProjectItemCatalog(
        catalog,
        capabilityTruth: itemSystemV1CapabilityTruth,
      ).hasBlockingDiagnostics,
      isTrue,
    );
    expect(isEligibleTrainerBattleItem(catalog.entries.single), isFalse);
  });
}

Map<String, Object?> _catalog({
  String target = 'party_member',
  Map<String, Object?> extra = const {},
}) => {
  'schemaVersion': 1,
  'entries': [
    {
      'id': 'full-restore',
      'displayName': 'Soin Total',
      'pocketId': 'medicine',
      'uses': [
        {
          'contexts': ['overworld', 'battle'],
          'target': target,
          'consumption': 'on_applied',
          'effect': {'kind': 'full_restore', ...extra},
        },
      ],
    },
  ],
};
