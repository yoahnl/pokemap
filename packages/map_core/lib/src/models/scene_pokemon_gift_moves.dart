List<String>? readScenePokemonGiftMoveIds(Object? value) {
  if (value == null) return null;
  if (value is! List || value.isEmpty || value.length > 4) {
    throw const FormatException(
      'Catalog gift requires one to four imposed move ids.',
    );
  }
  final moveIds = <String>[];
  for (final moveId in value) {
    if (moveId is! String ||
        moveId.isEmpty ||
        RegExp(r'\s', unicode: true).hasMatch(moveId) ||
        moveIds.contains(moveId)) {
      throw const FormatException(
        'Catalog gift move ids must be distinct, nonblank and exact.',
      );
    }
    moveIds.add(moveId);
  }
  return List<String>.unmodifiable(moveIds);
}

bool scenePokemonGiftMoveIdsEqual(List<String>? left, List<String>? right) {
  if (identical(left, right)) return true;
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
