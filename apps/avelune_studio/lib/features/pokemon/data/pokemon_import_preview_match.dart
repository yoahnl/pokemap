import '../domain/pokemon_import_models.dart';

bool samePokemonImportPreviewTargets(
  PokemonLocalImportPreview a,
  PokemonLocalImportPreview b,
) {
  if (a.items.length != b.items.length) return false;
  for (var i = 0; i < a.items.length; i++) {
    final left = a.items[i];
    final right = b.items[i];
    if (left.relativePath != right.relativePath ||
        left.family != right.family ||
        !_sameBytes(left.beforeBytes, right.beforeBytes) ||
        !_sameBytes(left.sourceBytes, right.sourceBytes)) {
      return false;
    }
  }
  return true;
}

bool _sameBytes(List<int>? a, List<int>? b) {
  if (a == null || b == null) return a == null && b == null;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
