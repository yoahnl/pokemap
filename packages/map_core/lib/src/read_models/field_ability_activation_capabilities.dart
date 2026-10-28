import '../models/project_manifest.dart';

abstract final class FieldAbilityActivationCapabilities {
  static const capabilityId = 'gameplay.field-ability-activation@1';
  static const extendedCapabilityId = 'gameplay.field-ability-activation@2';
  static const _extendedIds = {'rock_climb', 'defog'};

  static bool requiresCapability(ProjectManifest project) =>
      project.settings.fieldAbilities?.isEmpty == false;

  static bool requiresExtendedCapability(ProjectManifest project) =>
      project.settings.fieldAbilities?.disabledAbilityIds.any(
        _extendedIds.contains,
      ) ??
      false;
}
