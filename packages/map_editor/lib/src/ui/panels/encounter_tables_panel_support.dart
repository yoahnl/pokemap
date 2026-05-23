part of 'encounter_tables_panel.dart';

// ---------------------------------------------------------------------------
// Local encounter references and draft validation
// ---------------------------------------------------------------------------

class _EncounterReferenceData {
  const _EncounterReferenceData({
    required this.speciesEntries,
    required this.isSpeciesAvailable,
    required this.speciesMessage,
  });

  const _EncounterReferenceData.loading()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Chargement des données locales d’espèces… Les IDs d’espèces bruts restent autorisés pendant le chargement.';

  const _EncounterReferenceData.unavailable()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Aucun espace de travail Pokémon utilisable détecté. Les IDs d’espèces bruts restent autorisés, mais sans assistance locale.';

  final List<PokemonDatabaseIndexEntry> speciesEntries;
  final bool isSpeciesAvailable;
  final String speciesMessage;
}

class _EncounterEntryDraftValidation {
  const _EncounterEntryDraftValidation({
    this.speciesMessage,
    this.minLevelMessage,
    this.maxLevelMessage,
    this.weightMessage,
  });

  final String? speciesMessage;
  final String? minLevelMessage;
  final String? maxLevelMessage;
  final String? weightMessage;

  String? get firstMessage =>
      speciesMessage ?? minLevelMessage ?? maxLevelMessage ?? weightMessage;
}

class _EncounterSpeciesStatus {
  const _EncounterSpeciesStatus({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;
}

// ---------------------------------------------------------------------------
// Pure helpers
// ---------------------------------------------------------------------------
//
// These stay outside the state class on purpose:
// - they do not mutate draft state;
// - they are reused by both the main orchestrator and the extracted widgets;
// - keeping them local to this library avoids creating any new encounter
//   service or shared abstraction layer.

String? _validateEncounterTableName(String rawName) {
  if (rawName.trim().isEmpty) {
    return 'Le nom de la table ne peut pas être vide.';
  }
  return null;
}

PokemonDatabaseIndexEntry? _resolveEncounterSpecies(
  _EncounterReferenceData references,
  String rawSpeciesId,
) {
  if (!references.isSpeciesAvailable) {
    return null;
  }
  return _encounterSpeciesLookupService.findById(
    references.speciesEntries,
    rawSpeciesId,
  );
}

_EncounterSpeciesStatus _resolveEncounterSpeciesStatus({
  required _EncounterReferenceData references,
  required String rawSpeciesId,
}) {
  final speciesId = rawSpeciesId.trim();
  if (speciesId.isEmpty) {
    return const _EncounterSpeciesStatus(
      message:
          'Recherchez par ID d’espèce, nom local ou numéro de Pokédex lorsque les données locales sont disponibles.',
      isError: false,
    );
  }

  if (!references.isSpeciesAvailable) {
    return const _EncounterSpeciesStatus(
      message:
          'Impossible de vérifier par rapport aux données locales d’espèces. Les IDs bruts restent autorisés.',
      isError: false,
    );
  }

  final resolved = _resolveEncounterSpecies(references, speciesId);
  if (resolved == null) {
    return const _EncounterSpeciesStatus(
      message: 'Espèce non présente dans le Pokédex local.',
      isError: true,
    );
  }

  final dexLabel = resolved.nationalDex > 0
      ? '#${resolved.nationalDex.toString().padLeft(4, '0')}'
      : 'Aucun numéro de Pokédex';
  return _EncounterSpeciesStatus(
    message:
        'Correspondance d’espèce locale : ${resolved.primaryName} • $dexLabel • ${resolved.id}',
    isError: false,
  );
}

List<PokemonDatabaseIndexEntry> _buildEncounterSpeciesSuggestions({
  required _EncounterReferenceData references,
  required String rawQuery,
}) {
  if (!references.isSpeciesAvailable) {
    return const <PokemonDatabaseIndexEntry>[];
  }
  final query = rawQuery.trim();
  if (query.isEmpty) {
    return const <PokemonDatabaseIndexEntry>[];
  }
  return _encounterSpeciesLookupService.search(
    references.speciesEntries,
    query,
    limit: 8,
  );
}

int _tableTotalWeight(ProjectEncounterTable table) {
  return table.entries.fold<int>(
    0,
    (sum, entry) => sum + (entry.weight > 0 ? entry.weight : 0),
  );
}

double? _entryChance({
  required ProjectEncounterTable table,
  required int weight,
}) {
  final totalWeight = _tableTotalWeight(table);
  if (weight <= 0 || totalWeight <= 0) {
    return null;
  }
  return weight / totalWeight;
}

String? _formatEncounterShare(double? share) {
  if (share == null) {
    return null;
  }
  return '${(share * 100).toStringAsFixed(1)}%';
}

String _kindLabel(EncounterKind kind) {
  return switch (kind) {
    EncounterKind.walk => 'Marcher',
    EncounterKind.surf => 'Surfer',
    EncounterKind.headbutt => 'Coup de tête',
    EncounterKind.oldRod => 'Canne',
    EncounterKind.goodRod => 'Super Canne',
    EncounterKind.superRod => 'Méga Canne',
    EncounterKind.gift => 'Cadeau',
    EncounterKind.special => 'Spécial',
  };
}

extension _EncounterTablesPanelSupport on _EncounterTablesPanelState {
  _EncounterEntryDraftValidation _validateEntryDraft({
    required _EncounterReferenceData references,
  }) {
    final speciesId = _entrySpeciesController.text.trim();
    final minLevel = int.tryParse(_entryMinLevelController.text.trim());
    final maxLevel = int.tryParse(_entryMaxLevelController.text.trim());
    final weight = int.tryParse(_entryWeightController.text.trim());

    String? speciesMessage;
    if (speciesId.isEmpty) {
      speciesMessage = 'L\'ID de l\'espèce ne peut pas être vide.';
    } else if (references.isSpeciesAvailable &&
        _resolveEncounterSpecies(references, speciesId) == null) {
      speciesMessage =
          'L\'espèce "$speciesId" n\'est pas présente dans le Pokédex local.';
    }

    String? minLevelMessage;
    if (minLevel == null || minLevel <= 0) {
      minLevelMessage = 'Le niveau min doit être un entier positif.';
    }

    String? maxLevelMessage;
    if (maxLevel == null || maxLevel <= 0) {
      maxLevelMessage = 'Le niveau max doit être un entier positif.';
    } else if (minLevel != null && minLevel > 0 && minLevel > maxLevel) {
      maxLevelMessage = 'Le niveau max doit être supérieur ou égal au niveau min.';
    }

    String? weightMessage;
    if (weight == null || weight <= 0) {
      weightMessage = 'Le poids doit être un entier positif.';
    }

    return _EncounterEntryDraftValidation(
      speciesMessage: speciesMessage,
      minLevelMessage: minLevelMessage,
      maxLevelMessage: maxLevelMessage,
      weightMessage: weightMessage,
    );
  }

  String? _draftEncounterChance({
    required ProjectEncounterTable table,
  }) {
    final draftWeight = int.tryParse(_entryWeightController.text.trim());
    if (draftWeight == null || draftWeight <= 0) {
      return null;
    }

    var totalWeight = _tableTotalWeight(table);
    if (_editingEntryTableId == table.id && _editingEntryIndex != null) {
      final current = table.entries[_editingEntryIndex!];
      totalWeight = totalWeight - current.weight + draftWeight;
    } else {
      totalWeight += draftWeight;
    }

    if (totalWeight <= 0) {
      return null;
    }
    return _formatEncounterShare(draftWeight / totalWeight);
  }
}
