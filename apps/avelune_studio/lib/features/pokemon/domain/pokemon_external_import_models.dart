import 'pokemon_workspace_models.dart';

enum PokemonExternalConflictPolicy {
  failOnConflict,
  skipExisting,
  overwriteExisting,
}

final class PokemonExternalSuggestion {
  const PokemonExternalSuggestion({
    required this.id,
    required this.name,
    required this.nationalDex,
    required this.generation,
  });

  final String id;
  final String name;
  final int nationalDex;
  final int? generation;
}

final class PokemonExternalSearch {
  const PokemonExternalSearch({required this.suggestions, this.message});
  final List<PokemonExternalSuggestion> suggestions;
  final String? message;
}

final class PokemonExternalDocument {
  const PokemonExternalDocument({
    required this.family,
    required this.relativePath,
    required this.beforeBytes,
    required this.document,
  });

  final PokemonDocumentFamily family;
  final String relativePath;
  final List<int>? beforeBytes;
  final Map<String, dynamic> document;
  bool get conflict => beforeBytes != null;
}

final class PokemonExternalImportPreview {
  const PokemonExternalImportPreview({
    required this.speciesId,
    required this.name,
    required this.projectRevision,
    required this.documents,
    required this.warnings,
  });

  final String speciesId;
  final String name;
  final String projectRevision;
  final List<PokemonExternalDocument> documents;
  final List<String> warnings;
  bool get hasConflicts => documents.any((item) => item.conflict);
}

final class PokemonExternalImportResult {
  const PokemonExternalImportResult({
    required this.speciesId,
    required this.created,
    required this.overwritten,
    required this.skipped,
    required this.warnings,
  });

  final String speciesId;
  final int created;
  final int overwritten;
  final int skipped;
  final List<String> warnings;
}
