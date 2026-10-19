import '../models/items/project_item_capabilities.dart';
import '../models/items/project_item_catalog.dart';
import '../models/items/project_item_definition.dart';
import '../models/items/project_item_effect_definition.dart';
import '../validation/project_item_catalog_validator.dart';
import 'item_capability_truth.dart';

const _trainerMedicineStatusIds = {
  'paralysis',
  'paralyzed',
  'burn',
  'poison',
  'badly-poisoned',
  'sleep',
  'freeze',
  'frozen',
};

ProjectItemUseDefinition? resolveTrainerBattleItemUse(
  ProjectItemDefinition item,
) {
  if (item.id.isEmpty || item.id != item.id.trim()) {
    return null;
  }
  try {
    item.normalized();
  } on StateError {
    return null;
  }
  final report = validateProjectItemCatalog(
    ProjectItemCatalog(schemaVersion: 1, entries: [item]),
    capabilityTruth: itemSystemV1CapabilityTruth,
  );
  if (report.hasBlockingDiagnostics) {
    return null;
  }
  for (final use in item.uses) {
    final effect = use.effect;
    if (effect is ProjectItemCureStatusEffectDefinition &&
        effect.mode == ProjectItemStatusCureMode.listed &&
        !effect.statusIds.every(_trainerMedicineStatusIds.contains)) {
      continue;
    }
    if (use.contexts.contains(ProjectItemUseContext.battle) &&
        use.target == ProjectItemTargetKind.partyMember &&
        use.consumption == ProjectItemConsumptionPolicy.onApplied &&
        (use.effect is ProjectItemHealHpEffectDefinition ||
            use.effect is ProjectItemCureStatusEffectDefinition)) {
      return use;
    }
  }
  return null;
}

bool isEligibleTrainerBattleItem(ProjectItemDefinition item) =>
    resolveTrainerBattleItemUse(item) != null;

List<ProjectItemDefinition> eligibleTrainerBattleItems(
  ProjectItemCatalog? catalog,
) {
  if (catalog == null || catalog.schemaVersion != 1) {
    return const [];
  }
  final counts = <String, int>{};
  for (final item in catalog.entries) {
    counts[item.id] = (counts[item.id] ?? 0) + 1;
  }
  final eligible = catalog.entries
      .where((item) => counts[item.id] == 1 && isEligibleTrainerBattleItem(item))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return List.unmodifiable(eligible);
}
