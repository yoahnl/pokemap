import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

List<PsdkBattleAiItemOption> resolveRuntimeTrainerBattleItems({
  required ProjectTrainerEntry trainer,
  required ItemCatalogSnapshot? itemCatalog,
}) {
  ProjectValidator.validateTrainerBattleItemReferences(
    [trainer],
    itemCatalog: itemCatalog?.catalog,
  );
  if (trainer.battleItems.isEmpty) {
    return const [];
  }
  final resolver = ItemCapabilityResolver(itemCatalog!);
  final itemIds = trainer.battleItems.keys.toList()..sort();
  return List.unmodifiable([
    for (final itemId in itemIds)
      PsdkBattleAiItemOption(
        itemId: itemId,
        quantity: trainer.battleItems[itemId]!,
        effect: _battleEffect(
          resolver.resolveUse(
            itemId: itemId,
            context: ProjectItemUseContext.battle,
          ).use!.effect,
        ),
      ),
  ]);
}

PsdkBattleItemActionEffect _battleEffect(ProjectItemEffectDefinition effect) {
  return switch (effect) {
    ProjectItemFullRestoreEffectDefinition() =>
      const PsdkBattleFullRestoreItemEffect(),
    ProjectItemHealHpEffectDefinition() =>
      effect.mode == ProjectItemAmountMode.full
          ? const PsdkBattleHpHealItemEffect.full()
          : PsdkBattleHpHealItemEffect.flat(effect.amount!),
    ProjectItemCureStatusEffectDefinition() =>
      effect.mode == ProjectItemStatusCureMode.all
          ? const PsdkBattleStatusCureItemEffect.any()
          : PsdkBattleStatusCureItemEffect.only({
              for (final statusId in effect.statusIds) _statusFor(statusId),
            }),
    _ => throw StateError('Unsupported trainer battle item effect.'),
  };
}

PsdkBattleMajorStatus _statusFor(String statusId) => switch (statusId) {
  'paralysis' || 'paralyzed' => PsdkBattleMajorStatus.paralysis,
  'burn' => PsdkBattleMajorStatus.burn,
  'poison' => PsdkBattleMajorStatus.poison,
  'badly-poisoned' => PsdkBattleMajorStatus.toxic,
  'sleep' => PsdkBattleMajorStatus.sleep,
  'freeze' || 'frozen' => PsdkBattleMajorStatus.freeze,
  _ => throw StateError('Unsupported trainer medicine status: $statusId'),
};
