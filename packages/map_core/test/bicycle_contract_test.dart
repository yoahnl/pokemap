import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('bicycle has a typed reusable world capability and saved mode', () {
    final use = ProjectItemUseDefinition.fromJson({
      'contexts': ['overworld'],
      'target': 'world',
      'consumption': 'never',
      'effect': {'kind': 'bicycle'},
    });
    expect(use.toJson()['effect'], {'kind': 'bicycle'});
    final state = GameState.fromJson(
      const GameState(saveId: 'save', currentMapId: 'route').toJson()
        ..['playerMovementMode'] = 'bicycle',
    );
    expect(state.toJson()['playerMovementMode'], 'bicycle');
  });

  test(
    'bicycle definition rejects consumable, battle, party and non-key uses',
    () {
      const valid = ProjectItemUseDefinition(
        contexts: {ProjectItemUseContext.overworld},
        target: ProjectItemTargetKind.world,
        consumption: ProjectItemConsumptionPolicy.never,
        effect: ProjectItemEffectDefinition.bicycle(),
      );
      for (final use in [
        valid,
        valid.copyWith(consumption: ProjectItemConsumptionPolicy.onApplied),
        valid.copyWith(contexts: {ProjectItemUseContext.battle}),
        valid.copyWith(target: ProjectItemTargetKind.partyMember),
      ]) {
        final report = validateProjectItemCatalog(
          ProjectItemCatalog(
            schemaVersion: 1,
            entries: [
              ProjectItemDefinition(
                id: 'cycle',
                displayName: 'Vélo',
                pocketId: 'key-items',
                tags: const {'key-item'},
                uses: [use],
              ),
            ],
          ),
          capabilityTruth: itemSystemV1CapabilityTruth,
        );
        expect(report.hasBlockingDiagnostics, use != valid);
      }
      final notKey = validateProjectItemCatalog(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: [
            ProjectItemDefinition(
              id: 'cycle',
              displayName: 'Vélo',
              pocketId: 'items',
              uses: [valid],
            ),
          ],
        ),
        capabilityTruth: itemSystemV1CapabilityTruth,
      );
      expect(notKey.hasBlockingDiagnostics, isTrue);
    },
  );

  test('map bicycle restriction survives serialization', () {
    final metadata = MapMetadata.fromJson({'allowBicycle': false});
    expect(metadata.toJson()['allowBicycle'], isFalse);
    expect(const MapMetadata().toJson()['allowBicycle'], isTrue);
  });
}
