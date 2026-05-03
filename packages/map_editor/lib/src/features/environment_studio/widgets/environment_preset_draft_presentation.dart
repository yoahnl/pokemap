import '../authoring/environment_preset_draft.dart';

/// Libellés FR pour l’affichage des issues de brouillon (Lot Environment-13).
String environmentPresetDraftIssueKindLabel(
    EnvironmentPresetDraftIssueKind kind) {
  return switch (kind) {
    EnvironmentPresetDraftIssueKind.emptyId => 'Id vide',
    EnvironmentPresetDraftIssueKind.duplicateId => 'Id déjà utilisé',
    EnvironmentPresetDraftIssueKind.emptyName => 'Nom vide',
    EnvironmentPresetDraftIssueKind.emptyTemplateId => 'Template vide',
    EnvironmentPresetDraftIssueKind.unknownTemplateId => 'Template inconnu',
    EnvironmentPresetDraftIssueKind.emptyPalette => 'Palette vide',
    EnvironmentPresetDraftIssueKind.emptyPaletteElementId =>
      'Élément de palette vide',
    EnvironmentPresetDraftIssueKind.duplicatePaletteElementId =>
      'Élément dupliqué',
    EnvironmentPresetDraftIssueKind.missingPaletteElement =>
      'Élément introuvable',
    EnvironmentPresetDraftIssueKind.invalidPaletteWeight => 'Poids invalide',
    EnvironmentPresetDraftIssueKind.emptyPaletteTag => 'Tag vide',
    EnvironmentPresetDraftIssueKind.invalidDensity => 'Densité invalide',
    EnvironmentPresetDraftIssueKind.invalidVariation => 'Variation invalide',
    EnvironmentPresetDraftIssueKind.invalidEdgeDensity =>
      'Densité des bords invalide',
    EnvironmentPresetDraftIssueKind.invalidMinSpacingCells =>
      'Espacement invalide',
    EnvironmentPresetDraftIssueKind.emptyCategoryId => 'Catégorie vide',
  };
}

String environmentPresetDraftIssueSeverityLabel(
  EnvironmentPresetDraftIssueSeverity severity,
) {
  return switch (severity) {
    EnvironmentPresetDraftIssueSeverity.error => 'Erreur',
    EnvironmentPresetDraftIssueSeverity.warning => 'Avertissement',
  };
}
