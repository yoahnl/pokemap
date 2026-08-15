import 'package:map_core/map_core.dart';

final class PokemonCatalogGenerationSanitizer {
  const PokemonCatalogGenerationSanitizer();

  PokemonSpeciesForms sanitizeForms(
    PokemonSpeciesForms forms, {
    required Set<String> availableFormIds,
  }) {
    final otherForms =
        forms.otherForms
            .where(availableFormIds.contains)
            .toSet()
            .toList(growable: false)
          ..sort();
    return PokemonSpeciesForms(
      baseFormId: forms.baseFormId,
      isBaseForm: forms.isBaseForm,
      formId: forms.formId,
      formName: forms.formName,
      otherForms: otherForms,
    );
  }

  PokemonMediaFile sanitizeMedia(
    PokemonMediaFile media, {
    required Set<String> availableFormIds,
  }) {
    final variants = Map<String, PokemonMediaVariant>.fromEntries(
      media.variants.entries.where(
        (entry) => availableFormIds.contains(entry.key),
      ),
    );
    final sortedFormIds = variants.keys.toList(growable: false)..sort();
    final defaultFormId = variants.containsKey(media.defaultFormId)
        ? media.defaultFormId
        : sortedFormIds.firstOrNull ?? media.defaultFormId;
    return PokemonMediaFile(
      schemaVersion: media.schemaVersion,
      speciesId: media.speciesId,
      defaultFormId: defaultFormId,
      variants: variants,
    );
  }

  List<PokemonEvolutionEntry> sanitizeEvolutions(
    Iterable<PokemonEvolutionEntry> entries, {
    required Set<String> availableSpeciesIds,
  }) {
    final result = <PokemonEvolutionEntry>[];
    for (final entry in entries) {
      if (!availableSpeciesIds.contains(entry.targetSpeciesId)) {
        continue;
      }
      final normalized = _normalizeEvolution(entry);
      if (normalized != null) {
        final existingIndex = result.indexWhere(
          (existing) => _sameEvolutionFamily(existing, normalized),
        );
        if (existingIndex < 0) {
          result.add(normalized);
        } else if (normalized.method == 'level_up' &&
            normalized.minLevel! < result[existingIndex].minLevel!) {
          result[existingIndex] = normalized;
        }
      }
    }
    return List<PokemonEvolutionEntry>.unmodifiable(result);
  }

  PokemonEvolutionEntry? _normalizeEvolution(PokemonEvolutionEntry entry) {
    final method = entry.method.trim();
    if (method == 'level_up') {
      if (entry.minFriendship != null) {
        return _copy(entry, method: 'friendship', minLevel: null);
      }
      if (entry.requiredMoveId != null && entry.requiredMoveId!.isNotEmpty) {
        return _copy(entry, method: 'known_move', minLevel: null);
      }
      return _copy(
        entry,
        method: 'level_up',
        minLevel: (entry.minLevel ?? 1).clamp(1, 100),
      );
    }
    if (!PokemonCatalogCoherenceValidator.supportedEvolutionMethods.contains(
      method,
    )) {
      return null;
    }
    if (method == 'friendship' && entry.minFriendship == null) {
      return null;
    }
    if (method == 'known_move' &&
        (entry.requiredMoveId == null || entry.requiredMoveId!.isEmpty)) {
      return null;
    }
    return entry;
  }

  bool _sameEvolutionFamily(
    PokemonEvolutionEntry left,
    PokemonEvolutionEntry right,
  ) {
    return left.targetSpeciesId == right.targetSpeciesId &&
        left.method == right.method &&
        left.itemId == right.itemId &&
        left.requiredMoveId == right.requiredMoveId &&
        left.minFriendship == right.minFriendship;
  }

  PokemonEvolutionEntry _copy(
    PokemonEvolutionEntry entry, {
    required String method,
    required int? minLevel,
  }) {
    return PokemonEvolutionEntry(
      targetSpeciesId: entry.targetSpeciesId,
      method: method,
      minLevel: minLevel,
      minFriendship: entry.minFriendship,
      itemId: entry.itemId,
      requiredMoveId: entry.requiredMoveId,
      conditionText: entry.conditionText,
    );
  }
}
