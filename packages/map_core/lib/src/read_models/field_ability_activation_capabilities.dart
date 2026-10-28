import '../models/project_manifest.dart';

abstract final class FieldAbilityActivationCapabilities {
  static const capabilityId = 'gameplay.field-ability-activation@1';

  static bool requiresCapability(ProjectManifest project) =>
      project.settings.fieldAbilities?.isEmpty == false;
}
