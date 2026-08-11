import '../models/items/project_item_capabilities.dart';
import '../models/items/project_item_effect_definition.dart';

enum ProjectItemEffectCapability {
  healHp,
  cureStatus,
  revive,
  restorePp,
  repel,
  semanticAction,
}

enum ItemCapabilityReadiness { runtimeReady, passive, unsupported }

final class ItemCapabilityTruth {
  ItemCapabilityTruth({
    Set<ProjectItemUseContext> supportedUseContexts = const {},
    Set<ProjectItemEffectCapability> supportedEffects = const {},
    Set<String> supportedSemanticActionIds = const {},
    Set<String> supportedHeldEffectIds = const {},
    this.supportsCapture = false,
    this.supportsMoveMachines = false,
    String presentationPocketFallback = 'items',
  }) : supportedUseContexts = Set.unmodifiable(supportedUseContexts),
       supportedEffects = Set.unmodifiable(supportedEffects),
       supportedSemanticActionIds = Set.unmodifiable(
         supportedSemanticActionIds
             .map((actionId) => actionId.trim())
             .where((actionId) => actionId.isNotEmpty),
       ),
       supportedHeldEffectIds = Set.unmodifiable(
         supportedHeldEffectIds
             .map((effectId) => effectId.trim())
             .where((effectId) => effectId.isNotEmpty),
       ),
       presentationPocketFallback = _requiredFallback(
         presentationPocketFallback,
       );

  final Set<ProjectItemUseContext> supportedUseContexts;
  final Set<ProjectItemEffectCapability> supportedEffects;
  final Set<String> supportedSemanticActionIds;
  final Set<String> supportedHeldEffectIds;
  final bool supportsCapture;
  final bool supportsMoveMachines;
  final String presentationPocketFallback;
}

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
    ProjectItemCureStatusEffectDefinition() =>
      ProjectItemEffectCapability.cureStatus,
    ProjectItemReviveEffectDefinition() => ProjectItemEffectCapability.revive,
    ProjectItemRestorePpEffectDefinition() =>
      ProjectItemEffectCapability.restorePp,
    ProjectItemRepelEffectDefinition() => ProjectItemEffectCapability.repel,
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
