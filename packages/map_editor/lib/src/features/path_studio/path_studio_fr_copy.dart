// Helpers de formulation FR pour Path Studio (Lot PathPattern-42).
// Pas d’i18n global : copies locales uniquement.

/// `count <= 1` → singulier ; `>= 2` → pluriel (usage français courant : « 0 blocage »).
String pluralizeFr(int count, String singular, String plural) {
  if (count <= 1) {
    return '$count $singular';
  }
  return '$count $plural';
}

/// Résumé diagnostic du type « 2 blocages · 1 warning · 3 infos » (segments omis si 0).
String formatDiagnosticsSeveritySummary({
  required int blocking,
  required int warning,
  required int info,
}) {
  final parts = <String>[];
  if (blocking > 0) {
    parts.add(pluralizeFr(blocking, 'blocage', 'blocages'));
  }
  if (warning > 0) {
    parts.add(pluralizeFr(warning, 'warning', 'warnings'));
  }
  if (info > 0) {
    parts.add(pluralizeFr(info, 'info', 'infos'));
  }
  return parts.join(' · ');
}
