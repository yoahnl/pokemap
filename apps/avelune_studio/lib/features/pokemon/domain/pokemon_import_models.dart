import 'pokemon_workspace_models.dart';

final class PokemonLocalImportItem {
  const PokemonLocalImportItem({
    required this.family,
    required this.sourcePath,
    required this.relativePath,
    required this.sourceBytes,
    required this.beforeBytes,
    required this.document,
  });

  final PokemonDocumentFamily family;
  final String sourcePath;
  final String relativePath;
  final List<int> sourceBytes;
  final List<int>? beforeBytes;
  final Map<String, dynamic> document;
  bool get conflicts => beforeBytes != null;
}

final class PokemonLocalImportPreview {
  const PokemonLocalImportPreview({
    required this.speciesId,
    required this.name,
    required this.items,
    required this.fingerprint,
  });

  final String speciesId;
  final String name;
  final List<PokemonLocalImportItem> items;
  final String fingerprint;
  bool get hasConflicts => items.any((item) => item.conflicts);
}
