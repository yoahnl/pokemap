import 'package:map_core/map_core.dart';

enum ProjectItemEffectRuntimeSupport { supported, unsupported }

ProjectItemEffectRuntimeSupport projectItemEffectRuntimeSupport(
  ProjectItemEffectDefinition effect,
) => switch (effect) {
  ProjectItemHealHpEffectDefinition() ||
  ProjectItemCureStatusEffectDefinition() ||
  ProjectItemReviveEffectDefinition() ||
  ProjectItemRestorePpEffectDefinition() ||
  ProjectItemRepelEffectDefinition() ||
  ProjectItemBicycleEffectDefinition() ||
  ProjectItemEscapeRopeEffectDefinition() =>
    ProjectItemEffectRuntimeSupport.supported,
  _ => ProjectItemEffectRuntimeSupport.unsupported,
};

String? projectItemEffectUnsupportedReason(
  ProjectItemEffectDefinition effect,
) =>
    projectItemEffectRuntimeSupport(effect) ==
            ProjectItemEffectRuntimeSupport.supported
        ? null
        : 'Cette action sémantique n’est pas résolue par le moteur : l’objet restera sans effet en jeu.';
