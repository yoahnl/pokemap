part of 'trainer_library_panel.dart';

// ---------------------------------------------------------------------------
// Références locales et draft UI
// ---------------------------------------------------------------------------

class _TrainerReferenceData {
  const _TrainerReferenceData({
    required this.speciesEntries,
    required this.isSpeciesAvailable,
    required this.speciesMessage,
    required this.movesCatalogView,
    required this.itemsCatalogView,
  });

  const _TrainerReferenceData.loading()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Chargement des références locales… La saisie brute reste possible pendant ce chargement.',
        movesCatalogView = const PokemonMovesCatalogView(
          entries: <PokemonMoveCatalogEntryView>[],
          isAvailable: false,
          description: 'Chargement du catalogue local des attaques…',
        ),
        itemsCatalogView = const PokemonItemsCatalogView(
          entries: <PokemonItemCatalogEntryView>[],
          isAvailable: false,
          description: 'Chargement du catalogue local des objets…',
        );

  const _TrainerReferenceData.unavailable()
      : speciesEntries = const <PokemonDatabaseIndexEntry>[],
        isSpeciesAvailable = false,
        speciesMessage =
            'Aucun workspace Pokémon exploitable. La saisie brute reste possible, mais sans suggestions locales guidées.',
        movesCatalogView = const PokemonMovesCatalogView(
          entries: <PokemonMoveCatalogEntryView>[],
          isAvailable: false,
          description: 'Catalogue local des attaques indisponible.',
        ),
        itemsCatalogView = const PokemonItemsCatalogView(
          entries: <PokemonItemCatalogEntryView>[],
          isAvailable: false,
          description: 'Catalogue local des objets indisponible.',
        );

  final List<PokemonDatabaseIndexEntry> speciesEntries;
  final bool isSpeciesAvailable;
  final String speciesMessage;
  final PokemonMovesCatalogView movesCatalogView;
  final PokemonItemsCatalogView itemsCatalogView;
}

class _TrainerPokemonDraft {
  const _TrainerPokemonDraft({
    required this.speciesId,
    required this.level,
    required this.moves,
    required this.heldItemId,
    required this.formId,
    required this.gender,
    required this.shiny,
  });

  final String speciesId;
  final int? level;
  final List<String> moves;
  final String? heldItemId;
  final String? formId;
  final String? gender;
  final bool shiny;
}

class _TrainerGuidedMoveSuggestions {
  const _TrainerGuidedMoveSuggestions({
    required this.description,
    required this.disabledPlaceholder,
    this.entries = const <PokemonMoveCatalogEntryView>[],
    this.sourceLabelsByMoveId = const <String, List<String>>{},
    this.missingCatalogMoveIds = const <String>[],
  });

  final String description;
  final String disabledPlaceholder;
  final List<PokemonMoveCatalogEntryView> entries;
  final Map<String, List<String>> sourceLabelsByMoveId;
  final List<String> missingCatalogMoveIds;
}

// ---------------------------------------------------------------------------
// Helpers purs
// ---------------------------------------------------------------------------

String? _normalizeOptionalField(String rawValue) {
  final trimmed = rawValue.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _splitCommaSeparatedValues(String rawValue) {
  return rawValue
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

void _clearTextControllers(Iterable<TextEditingController> controllers) {
  for (final controller in controllers) {
    controller.clear();
  }
}

bool _trainerMatchesSearch(ProjectTrainerEntry trainer, String rawQuery) {
  final query = rawQuery.trim().toLowerCase();
  if (query.isEmpty) {
    return true;
  }

  final searchTerms = <String>[
    trainer.id,
    trainer.name,
    trainer.trainerClass,
    ...trainer.tags,
    ...trainer.team.map((pokemon) => pokemon.speciesId),
  ].map((value) => value.trim().toLowerCase());

  for (final term in searchTerms) {
    if (term.contains(query)) {
      return true;
    }
  }
  return false;
}

List<String> _buildSpeciesFormSuggestions(PokemonSpeciesFile species) {
  // We only expose forms that truly exist in the local species payload.
  // Earlier code synthesized a `base` value when the data did not provide one,
  // which made the assist UI look more certain than it really was.
  final candidates = <String>[
    if (species.forms.formId.trim().isNotEmpty) species.forms.formId.trim(),
    ...species.forms.otherForms
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty),
  ];

  final unique = <String>[];
  final seen = <String>{};
  for (final candidate in candidates) {
    if (candidate.isEmpty) {
      continue;
    }
    if (seen.add(candidate)) {
      unique.add(candidate);
    }
  }
  return unique;
}

List<String> _buildTrainerGenderSuggestions(PokemonSpeciesFile species) {
  final ratio = species.breeding.genderRatio;
  final isGenderless = (ratio['genderless'] ?? 0) > 0;
  if (isGenderless) {
    return const <String>['genderless'];
  }

  final suggestions = <String>[
    if ((ratio['male'] ?? 0) > 0) 'male',
    if ((ratio['female'] ?? 0) > 0) 'female',
  ];
  if (suggestions.length > 1) {
    // `any` stays useful as an author-facing shorthand for “leave the final
    // runtime pick unconstrained between the locally valid sexes”.
    suggestions.add('any');
  }
  return suggestions;
}

String _trainerGenderLabel(String gender) {
  return switch (gender.trim().toLowerCase()) {
    'male' => 'Male',
    'female' => 'Female',
    'genderless' => 'Genderless',
    'any' => 'Any',
    _ => gender,
  };
}

String _buildAuthorFacingCatalogUnavailableMessage({
  required String subjectLabel,
  required String fallbackMessage,
  String? technicalMessage,
}) {
  final trimmedTechnicalMessage = technicalMessage?.trim() ?? '';

  // The authoring surface should explain the degraded state in product terms
  // first. Raw file paths or manifest jargon belong in logs/tests, not in the
  // primary UI copy that blocks someone from finishing a trainer.
  if (trimmedTechnicalMessage.isEmpty) {
    return 'Impossible de charger le catalogue local ($subjectLabel) pour ce projet. '
        '$fallbackMessage';
  }

  final normalizedTechnicalMessage = trimmedTechnicalMessage.toLowerCase();
  if (normalizedTechnicalMessage.contains('manifest') ||
      normalizedTechnicalMessage.contains('catalog') ||
      normalizedTechnicalMessage.contains('not found') ||
      normalizedTechnicalMessage.contains('workspace')) {
    return 'Impossible de charger le catalogue local ($subjectLabel) pour ce projet. '
        '$fallbackMessage';
  }

  final firstLine = trimmedTechnicalMessage.split('\n').first.trim();
  return firstLine.isEmpty
      ? 'Impossible de charger le catalogue local ($subjectLabel) pour ce projet. '
          '$fallbackMessage'
      : '$firstLine $fallbackMessage';
}

_TrainerGuidedMoveSuggestions _buildTrainerGuidedMoveSuggestions({
  required String rawSpeciesId,
  required int? level,
  required bool isSpeciesCatalogAvailable,
  required PokemonDatabaseIndexEntry? resolvedSpecies,
  required PokedexSpeciesDetail? speciesDetail,
  required PokemonMovesCatalogView movesCatalogView,
}) {
  final speciesId = rawSpeciesId.trim();
  if (speciesId.isEmpty) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'Choisissez d’abord une espèce. Les suggestions de capacités dépendent du Pokémon sélectionné et de son niveau actuel.',
      disabledPlaceholder: 'Choisissez d’abord une espèce',
    );
  }

  if (level == null || level <= 0) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'Saisissez d’abord un niveau valide. Les suggestions de capacités ne montrent que les attaques disponibles à ce niveau.',
      disabledPlaceholder: 'Saisissez d’abord un niveau valide',
    );
  }

  if (!movesCatalogView.isAvailable) {
    return _TrainerGuidedMoveSuggestions(
      description: _buildAuthorFacingCatalogUnavailableMessage(
        subjectLabel: 'des capacités',
        fallbackMessage:
            'Les suggestions guidées sont indisponibles, mais vous pouvez saisir l’ID brut de la capacité ci-dessous.',
        technicalMessage: movesCatalogView.message,
      ),
      disabledPlaceholder: 'Suggestions guidées indisponibles',
    );
  }

  if (resolvedSpecies == null && isSpeciesCatalogAvailable) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'L’espèce sélectionnée n’est pas présente dans le Pokédex local. Les suggestions guidées de capacités sont indisponibles.',
      disabledPlaceholder: 'Espèce locale inconnue',
    );
  }

  if (speciesDetail == null) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'Aucun détail local n’est disponible pour ce Pokémon actuellement. Les suggestions sont indisponibles, mais les ID bruts restent possibles.',
      disabledPlaceholder: 'Détail de l’espèce indisponible',
    );
  }

  final learnset = speciesDetail.learnset;
  if (learnset == null) {
    return const _TrainerGuidedMoveSuggestions(
      description:
          'Aucun learnset local n’est disponible pour cette espèce. Les suggestions sont indisponibles, mais les ID bruts restent possibles.',
      disabledPlaceholder: 'Aucun learnset local',
    );
  }

  final sourceLabelsByMoveId = <String, List<String>>{};

  void addSource(String moveId, String label) {
    final normalizedMoveId = moveId.trim();
    if (normalizedMoveId.isEmpty) {
      return;
    }
    final labels = sourceLabelsByMoveId.putIfAbsent(
      normalizedMoveId,
      () => <String>[],
    );
    if (!labels.contains(label)) {
      labels.add(label);
    }
  }

  for (final moveId in learnset.startingMoves) {
    addSource(moveId, 'Départ');
  }
  for (final moveId in learnset.relearnMoves) {
    addSource(moveId, 'Réapp.');
  }
  for (final entry in learnset.levelUp) {
    if (entry.level <= level) {
      addSource(entry.moveId, 'Niv. ${entry.level}');
    }
  }

  if (sourceLabelsByMoveId.isEmpty) {
    return _TrainerGuidedMoveSuggestions(
      description:
          'Aucune capacité de départ, de réapprentissage ou de niveau n’est disponible localement pour cette espèce au Niv. $level.',
      disabledPlaceholder: 'Aucune capacité guidée disponible',
    );
  }

  final resolvedEntries = <PokemonMoveCatalogEntryView>[];
  final missingCatalogMoveIds = <String>[];
  for (final moveId in sourceLabelsByMoveId.keys) {
    final entry = _movesLookupService.findById(
      movesCatalogView.entries,
      moveId,
    );
    if (entry == null) {
      missingCatalogMoveIds.add(moveId);
      continue;
    }
    resolvedEntries.add(entry);
  }

  final missingSuffix = missingCatalogMoveIds.isEmpty
      ? ''
      : ' Certaines capacités du learnset manquent dans le catalogue de capacités local : ${missingCatalogMoveIds.join(', ')}.';

  if (resolvedEntries.isEmpty) {
    return _TrainerGuidedMoveSuggestions(
      description:
          'Le learnset local pour cette espèce ne correspond à aucune capacité du catalogue local.$missingSuffix Les ID bruts restent possibles.',
      disabledPlaceholder: 'Aucune capacité guidée disponible',
      missingCatalogMoveIds: missingCatalogMoveIds,
    );
  }

  return _TrainerGuidedMoveSuggestions(
    description:
        'Affichage des capacités disponibles au départ, par réapprentissage et par montée de niveau jusqu’au Niv. $level.$missingSuffix',
    disabledPlaceholder: 'Rechercher parmi les capacités disponibles',
    entries: resolvedEntries,
    sourceLabelsByMoveId: sourceLabelsByMoveId,
    missingCatalogMoveIds: missingCatalogMoveIds,
  );
}
