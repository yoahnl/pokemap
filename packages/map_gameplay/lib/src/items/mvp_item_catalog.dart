import 'package:map_core/map_core.dart';

final ProjectItemCatalog mvpItemCatalog = ProjectItemCatalog(
  schemaVersion: 1,
  entries: [
    _hpHealingItem('potion', 'Potion', 20),
    _hpHealingItem('super-potion', 'Super Potion', 50),
    _hpHealingItem('hyper-potion', 'Hyper Potion', 120),
    _hpHealingItem('max-potion', 'Max Potion', null),
    _statusCureItem(
      'antidote',
      'Antidote',
      const {'poison', 'badly-poisoned'},
    ),
    _statusCureItem('awakening', 'Awakening', const {'sleep'}),
    _statusCureItem(
      'paralyze-heal',
      'Paralyze Heal',
      const {'paralysis', 'paralyzed'},
    ),
    _statusCureItem('burn-heal', 'Burn Heal', const {'burn'}),
    _statusCureItem('ice-heal', 'Ice Heal', const {'freeze', 'frozen'}),
    _statusCureItem('full-heal', 'Full Heal', null),
    ProjectItemDefinition(
      id: 'revive',
      displayName: 'Revive',
      pocketId: 'medicine',
      tags: const {'healing', 'revive'},
      uses: const [
        ProjectItemUseDefinition(
          contexts: {
            ProjectItemUseContext.overworld,
            ProjectItemUseContext.battle,
          },
          target: ProjectItemTargetKind.partyMember,
          consumption: ProjectItemConsumptionPolicy.onApplied,
          effect: ProjectItemEffectDefinition.revive(
            rateNumerator: 1,
            rateDenominator: 2,
          ),
        ),
      ],
    ),
    _ppRestoringItem('ether', 'Ether', 10),
    _ppRestoringItem('max-ether', 'Max Ether', null),
    ProjectItemDefinition(
      id: 'poke-ball',
      displayName: 'Poké Ball',
      pocketId: 'balls',
      tags: const {'capture'},
      capture: const ProjectCaptureItemDefinition(
        rateNumerator: 1,
        rateDenominator: 1,
        allowedEncounterKinds: {
          EncounterKind.walk,
          EncounterKind.surf,
          EncounterKind.headbutt,
          EncounterKind.oldRod,
          EncounterKind.goodRod,
          EncounterKind.superRod,
          EncounterKind.special,
        },
      ),
    ),
    ProjectItemDefinition(
      id: 'key-item',
      displayName: 'Key Item',
      pocketId: 'key-items',
      tags: const {'key-item', 'passive'},
    ),
  ],
).normalized();

ProjectItemDefinition _hpHealingItem(
  String id,
  String displayName,
  int? amount,
) {
  return ProjectItemDefinition(
    id: id,
    displayName: displayName,
    pocketId: 'medicine',
    tags: const {'healing'},
    uses: [
      ProjectItemUseDefinition(
        contexts: const {
          ProjectItemUseContext.overworld,
          ProjectItemUseContext.battle,
        },
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: ProjectItemEffectDefinition.healHp(
          mode: amount == null
              ? ProjectItemAmountMode.full
              : ProjectItemAmountMode.flat,
          amount: amount,
        ),
      ),
    ],
  );
}

ProjectItemDefinition _statusCureItem(
  String id,
  String displayName,
  Set<String>? statusIds,
) {
  return ProjectItemDefinition(
    id: id,
    displayName: displayName,
    pocketId: 'medicine',
    tags: const {'status-cure'},
    uses: [
      ProjectItemUseDefinition(
        contexts: const {
          ProjectItemUseContext.overworld,
          ProjectItemUseContext.battle,
        },
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: ProjectItemEffectDefinition.cureStatus(
          mode: statusIds == null
              ? ProjectItemStatusCureMode.all
              : ProjectItemStatusCureMode.listed,
          statusIds: statusIds ?? const {},
        ),
      ),
    ],
  );
}

ProjectItemDefinition _ppRestoringItem(
  String id,
  String displayName,
  int? amount,
) {
  return ProjectItemDefinition(
    id: id,
    displayName: displayName,
    pocketId: 'medicine',
    tags: const {'pp-restore'},
    uses: [
      ProjectItemUseDefinition(
        contexts: const {
          ProjectItemUseContext.overworld,
          ProjectItemUseContext.battle,
        },
        target: ProjectItemTargetKind.partyMove,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: ProjectItemEffectDefinition.restorePp(
          mode: amount == null
              ? ProjectItemAmountMode.full
              : ProjectItemAmountMode.flat,
          amount: amount,
        ),
      ),
    ],
  );
}
