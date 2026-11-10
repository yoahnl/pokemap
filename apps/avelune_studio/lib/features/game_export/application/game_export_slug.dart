String gameExportSlug(String value) {
  final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final result = normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  return result.isEmpty ? 'jeu' : result;
}
