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
            'Aucun workspace Pokémon exploitable. La saisie brute reste possible, mais sans assistance locale.',
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
