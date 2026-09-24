final class PokemonMovesSyncPreview {
  const PokemonMovesSyncPreview({
    required this.relativePath,
    required this.projectRevision,
    required this.beforeBytes,
    required this.document,
    required this.externalCount,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
  });

  final String relativePath;
  final String projectRevision;
  final List<int>? beforeBytes;
  final Map<String, dynamic> document;
  final int externalCount;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
}
