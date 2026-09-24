import 'dart:convert';

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
    required this.inventorySignature,
    required this.documents,
    required this.warnings,
  });

  final String speciesId;
  final String name;
  final String projectRevision;
  final String inventorySignature;
  final List<PokemonExternalDocument> documents;
  final List<String> warnings;
  bool get hasConflicts => documents.any((item) => item.conflict);

  PokemonExternalImportPlan plan(PokemonExternalConflictPolicy policy) {
    final species = documents.firstWhere(
      (item) => item.family == PokemonDocumentFamily.species,
    );
    final keptSpecies =
        species.conflict &&
        policy == PokemonExternalConflictPolicy.skipExisting;
    final retained = keptSpecies
        ? (jsonDecode(utf8.decode(species.beforeBytes!)) as Map)['refs'] as Map?
        : species.document['refs'] as Map?;
    final selected = <PokemonExternalDocument>[];
    final excluded = <String>[];
    for (final item in documents) {
      if (item.conflict &&
          policy == PokemonExternalConflictPolicy.skipExisting) {
        continue;
      }
      if (keptSpecies && item.family != PokemonDocumentFamily.species) {
        final key = item.family.name;
        final reference = item.relativePath
            .split('/')
            .last
            .replaceAll(RegExp(r'\.json$'), '');
        if (retained?[key] != reference) {
          excluded.add(item.relativePath);
          continue;
        }
      }
      if (item.conflict && item.family != PokemonDocumentFamily.species) {
        final previous = jsonDecode(utf8.decode(item.beforeBytes!)) as Map;
        selected.add(
          PokemonExternalDocument(
            family: item.family,
            relativePath: item.relativePath,
            beforeBytes: item.beforeBytes,
            document: {...item.document, 'speciesId': previous['speciesId']},
          ),
        );
      } else {
        selected.add(item);
      }
    }
    return PokemonExternalImportPlan(
      selected: List.unmodifiable(selected),
      excluded: List.unmodifiable(excluded),
      kept: documents.length - selected.length - excluded.length,
    );
  }
}

final class PokemonExternalImportPlan {
  const PokemonExternalImportPlan({
    required this.selected,
    required this.excluded,
    required this.kept,
  });

  final List<PokemonExternalDocument> selected;
  final List<String> excluded;
  final int kept;
  int get created => selected.where((item) => !item.conflict).length;
  int get overwritten => selected.where((item) => item.conflict).length;
}

final class PokemonExternalImportResult {
  const PokemonExternalImportResult({
    required this.speciesId,
    required this.created,
    required this.overwritten,
    required this.skipped,
    this.excluded = 0,
    required this.warnings,
  });

  final String speciesId;
  final int created;
  final int overwritten;
  final int skipped;
  final int excluded;
  final List<String> warnings;
  bool get noChange => created == 0 && overwritten == 0;
}
