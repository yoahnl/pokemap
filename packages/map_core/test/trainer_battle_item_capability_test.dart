import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('trainer medicine refuses cures outside the supported major statuses', () {
    final item = _item('confusion_cure').copyWith(
      uses: [
        _use.copyWith(
          effect: const ProjectItemEffectDefinition.cureStatus(
            mode: ProjectItemStatusCureMode.listed,
            statusIds: {'confusion'},
          ),
        ),
      ],
    );

    expect(isEligibleTrainerBattleItem(item), isFalse);
    expect(
      eligibleTrainerBattleItems(ProjectItemCatalog(schemaVersion: 1, entries: [item])),
      isEmpty,
    );
  });

  test('trainer picker offers exact unique eligible definitions in ID order', () {
    final catalog = ProjectItemCatalog(
      schemaVersion: 1,
      entries: [
        _item('z_tonic'),
        _item('duplicate'),
        _item('duplicate'),
        _item('a_tonic'),
        _item(' invalid '),
        _item('reusable').copyWith(
          uses: [_use.copyWith(consumption: ProjectItemConsumptionPolicy.never)],
        ),
      ],
    );

    expect(
      eligibleTrainerBattleItems(catalog).map((item) => item.id),
      ['a_tonic', 'z_tonic'],
    );
    expect(eligibleTrainerBattleItems(null), isEmpty);
  });
}

ProjectItemDefinition _item(String id) => ProjectItemDefinition(
  id: id,
  displayName: id,
  pocketId: 'medicine',
  uses: [_use],
);

const _use = ProjectItemUseDefinition(
  contexts: {ProjectItemUseContext.battle},
  target: ProjectItemTargetKind.partyMember,
  consumption: ProjectItemConsumptionPolicy.onApplied,
  effect: ProjectItemEffectDefinition.healHp(
    mode: ProjectItemAmountMode.flat,
    amount: 20,
  ),
);
