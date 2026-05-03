import 'package:map_core/map_core.dart';

/// Libellés FR stables pour l’UI auteur (Lot Environment-11).
String environmentDiagnosticKindLabel(EnvironmentAuthoringDiagnosticKind kind) {
  return switch (kind) {
    EnvironmentAuthoringDiagnosticKind.duplicatePresetId => 'Preset dupliqué',
    EnvironmentAuthoringDiagnosticKind.missingPaletteElement =>
      'Élément introuvable',
    EnvironmentAuthoringDiagnosticKind.unknownTemplateId => 'Template inconnu',
    EnvironmentAuthoringDiagnosticKind.forcedCollisionWithoutProfile =>
      'Collision forcée sans profil',
    EnvironmentAuthoringDiagnosticKind.missingAreaPreset =>
      'Preset de zone introuvable',
    EnvironmentAuthoringDiagnosticKind.missingTargetTileLayerId =>
      'Layer cible manquant',
    EnvironmentAuthoringDiagnosticKind.unknownTargetTileLayer =>
      'Layer cible introuvable',
    EnvironmentAuthoringDiagnosticKind.targetLayerIsNotTileLayer =>
      'Layer cible invalide',
    EnvironmentAuthoringDiagnosticKind.areaMaskSizeMismatch =>
      'Taille de zone incohérente',
    EnvironmentAuthoringDiagnosticKind.emptyAreaMask => 'Zone vide',
    EnvironmentAuthoringDiagnosticKind.missingGeneratedPlacement =>
      'Placement généré introuvable',
  };
}

String environmentDiagnosticSeverityLabel(
  EnvironmentAuthoringDiagnosticSeverity severity,
) {
  return switch (severity) {
    EnvironmentAuthoringDiagnosticSeverity.error => 'Erreur',
    EnvironmentAuthoringDiagnosticSeverity.warning => 'Avertissement',
  };
}
