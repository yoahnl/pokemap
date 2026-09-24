String normalizePokemonMoveLocalId(String rawValue) {
  final lowerCase = rawValue.trim().toLowerCase();
  if (lowerCase.isEmpty) {
    return '';
  }

  final separated = lowerCase.replaceAll(RegExp(r'[\s-]+'), '_');
  final asciiSafe = separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  final collapsed = asciiSafe.replaceAll(RegExp(r'_+'), '_');
  return collapsed.replaceAll(RegExp(r'^_|_$'), '');
}
