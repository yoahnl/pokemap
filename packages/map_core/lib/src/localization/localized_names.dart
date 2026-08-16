/// Résout un nom localisé depuis une map de traductions.
///
/// La sémantique reprend celle déjà retenue par `SceneLocalizedText.resolve` :
/// correspondance exacte, puis code langue, puis repli. Une traduction vide est
/// traitée comme absente afin qu'une entrée mal renseignée n'efface jamais un
/// libellé affichable.
String resolveLocalizedName({
  required Map<String, String> names,
  required String locale,
  required String fallback,
}) {
  final normalized = locale.trim().replaceAll('_', '-').toLowerCase();
  if (normalized.isEmpty) {
    return fallback;
  }

  final exact = names[normalized];
  if (exact != null && exact.trim().isNotEmpty) {
    return exact;
  }

  final separator = normalized.indexOf('-');
  if (separator > 0) {
    final language = names[normalized.substring(0, separator)];
    if (language != null && language.trim().isNotEmpty) {
      return language;
    }
  }

  return fallback;
}
