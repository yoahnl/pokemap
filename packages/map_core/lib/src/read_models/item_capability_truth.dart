import '../models/pokemon_trade_evolution.dart';
import '../models/items/project_item_capabilities.dart';
import '../models/items/project_item_effect_definition.dart';

enum ProjectItemEffectCapability {
  healHp,
  fullRestore,
  cureStatus,
  revive,
  restorePp,
  repel,
  escapeRope,
  bicycle,
  fishing,
  semanticAction,
}

enum ItemCapabilityReadiness { runtimeReady, passive, unsupported }

final class ItemUseCapability {
  const ItemUseCapability({required this.context, required this.effect});

  final ProjectItemUseContext context;
  final ProjectItemEffectCapability effect;

  @override
  bool operator ==(Object other) =>
      other is ItemUseCapability &&
      other.context == context &&
      other.effect == effect;

  @override
  int get hashCode => Object.hash(context, effect);
}

final class ItemCapabilityTruth {
  ItemCapabilityTruth({
    Set<ItemUseCapability> supportedUses = const <ItemUseCapability>{},
    Set<String> supportedSemanticActionIds = const <String>{},
    Set<String> supportedHeldEffectIds = const <String>{},
    this.supportsCapture = false,
    this.supportsMoveMachines = false,
    String presentationPocketFallback = 'items',
  }) : supportedUses = Set<ItemUseCapability>.unmodifiable(supportedUses),
       supportedSemanticActionIds = Set<String>.unmodifiable(
         supportedSemanticActionIds
             .map((actionId) => actionId.trim())
             .where((actionId) => actionId.isNotEmpty),
       ),
       supportedHeldEffectIds = Set<String>.unmodifiable(
         supportedHeldEffectIds
             .map(
               (effectId) => effectId.trim().toLowerCase().replaceAll('-', '_'),
             )
             .where((effectId) => effectId.isNotEmpty),
       ),
       presentationPocketFallback = _requiredFallback(
         presentationPocketFallback,
       );

  final Set<ItemUseCapability> supportedUses;
  final Set<String> supportedSemanticActionIds;
  final Set<String> supportedHeldEffectIds;
  final bool supportsCapture;
  final bool supportsMoveMachines;
  final String presentationPocketFallback;

  bool supportsUse(
    ProjectItemUseContext context,
    ProjectItemEffectCapability effect,
  ) => supportedUses.contains(
    ItemUseCapability(context: context, effect: effect),
  );

  bool supportsSemanticAction(String actionId) =>
      supportedSemanticActionIds.contains(actionId.trim());

  bool supportsHeldEffect(String heldEffectId) {
    final normalized = heldEffectId.trim().toLowerCase().replaceAll('-', '_');
    if (PokemonPassiveHeldEffect.fromId(normalized) != null &&
        normalized != heldEffectId) {
      return false;
    }
    return supportedHeldEffectIds.contains(normalized);
  }
}

final ItemCapabilityTruth itemSystemV1CapabilityTruth = ItemCapabilityTruth(
  supportedUses: <ItemUseCapability>{
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.healHp,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.fullRestore,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.cureStatus,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.revive,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.restorePp,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.repel,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.escapeRope,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.bicycle,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.overworld,
      effect: ProjectItemEffectCapability.fishing,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.battle,
      effect: ProjectItemEffectCapability.healHp,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.battle,
      effect: ProjectItemEffectCapability.fullRestore,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.battle,
      effect: ProjectItemEffectCapability.cureStatus,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.battle,
      effect: ProjectItemEffectCapability.revive,
    ),
    ItemUseCapability(
      context: ProjectItemUseContext.battle,
      effect: ProjectItemEffectCapability.restorePp,
    ),
  },
  supportedHeldEffectIds: <String>{
    'black_sludge',
    'king_s_rock',
    'leftovers',
    'lum_berry',
    'metal_coat',
    'prevent_evolution',
    'sitrus_berry',
    'smoke_ball',
  },
  supportsCapture: true,
  supportsMoveMachines: true,
);

final class ItemCapabilityAssessment {
  const ItemCapabilityAssessment({
    required this.itemId,
    required this.readiness,
    required this.presentationPocketId,
  });

  final String itemId;
  final ItemCapabilityReadiness readiness;
  final String presentationPocketId;
}

ProjectItemEffectCapability projectItemEffectCapabilityOf(
  ProjectItemEffectDefinition effect,
) {
  return switch (effect) {
    ProjectItemHealHpEffectDefinition() => ProjectItemEffectCapability.healHp,
    ProjectItemFullRestoreEffectDefinition() =>
      ProjectItemEffectCapability.fullRestore,
    ProjectItemCureStatusEffectDefinition() =>
      ProjectItemEffectCapability.cureStatus,
    ProjectItemReviveEffectDefinition() => ProjectItemEffectCapability.revive,
    ProjectItemRestorePpEffectDefinition() =>
      ProjectItemEffectCapability.restorePp,
    ProjectItemRepelEffectDefinition() => ProjectItemEffectCapability.repel,
    ProjectItemBicycleEffectDefinition() => ProjectItemEffectCapability.bicycle,
    ProjectItemFishingEffectDefinition() => ProjectItemEffectCapability.fishing,
    ProjectItemEscapeRopeEffectDefinition() =>
      ProjectItemEffectCapability.escapeRope,
    ProjectItemSemanticActionEffectDefinition() =>
      ProjectItemEffectCapability.semanticAction,
    _ => throw StateError('Unknown project item effect definition'),
  };
}

String _requiredFallback(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(
      value,
      'presentationPocketFallback',
      'must not be empty',
    );
  }
  return normalized;
}
