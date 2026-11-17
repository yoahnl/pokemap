import 'package:map_core/map_core.dart';

import 'game_package_format_exception.dart';
import 'game_package_manifest.dart';
import 'game_package_security_policy.dart';
import 'game_package_spatial_project_validator.dart';

void validateGamePackageDialogueLocalization({
  required ProjectManifest project,
  required GamePackageManifest manifest,
  required GamePackageSecurityPolicy policy,
  required GamePackagePayloadReader readPayload,
}) {
  final localized =
      project.dialogues.where((entry) => entry.localization != null);
  if (localized.isEmpty) return;
  if (!manifest.compatibility.requiredCapabilities
      .contains(dialogueLocalizationCapability)) {
    throw GamePackageFormatException(
      code: 'dialogueLocalizationCapabilityMissing',
      path: r'$.compatibility.requiredCapabilities',
      message: 'Localized dialogues require project.dialogue-localization@1.',
    );
  }
  final locales = ProjectLocalePolicy(
      supportedLocales: manifest.locales.supported,
      fallbackLocale: manifest.locales.defaultLocale);
  final policies = dialogueLinePoliciesByDocument(project.scenes);
  final factIds = project.facts.map((fact) => fact.id).toSet();
  for (final entry in localized) {
    final path = 'project/${entry.relativePath.replaceAll(r'\', '/')}';
    try {
      if (!path.toLowerCase().endsWith('.json')) {
        throw const FormatException(
            'Localized Player dialogues must be compiled JSON.');
      }
      final bytes = readPayload(path);
      if (bytes == null || bytes.length > policy.maxJsonBytes) {
        throw const FormatException(
            'Localized dialogue is missing or exceeds its size limit.');
      }
      final document = const RuntimeDialogueDocumentCodec().decodeUtf8(bytes);
      validateRuntimeDialogueLocalizationVariants(document, entry.localization!,
          locales: locales,
          factIds: factIds,
          linePolicySets: policies[entry.id] ?? const []);
    } on Object catch (error) {
      throw GamePackageFormatException(
          code: 'invalidDialogueLocalization',
          path: path,
          message: 'Localized dialogue cannot be loaded: $error');
    }
  }
}
