part of 'pokedex_workspace_page.dart';

// Colonne gauche du workspace Pokédex.
//
// Elle regroupe le header produit, la barre d'actions légère, les états vides
// et la liste des espèces. Toute la donnée vient des loaders et de l'état local
// du workspace ; aucun parsing ni accès fichier ne part d'ici.

class PokedexWorkspaceSpeciesList extends StatelessWidget {
  const PokedexWorkspaceSpeciesList({
    super.key,
    required this.projectRootPath,
    required this.entries,
    required this.selectedSpeciesId,
    required this.onEntrySelected,
    required this.onImportRequested,
    required this.query,
    required this.onQueryChanged,
    required this.filtersExpanded,
    required this.onToggleFiltersExpanded,
    required this.availableTypes,
    required this.selectedType,
    required this.onTypeChanged,
    required this.availableGenerations,
    required this.selectedGeneration,
    required this.onGenerationChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.emptyStateChild,
    this.emptyResultsChild,
  });

  /// Chemin racine du projet affiché.
  ///
  /// Il sert uniquement à résoudre les portraits locaux déjà calculés par la
  /// couche applicative. On ne lit aucun JSON ici.
  final String projectRootPath;
  final List<PokemonDatabaseIndexEntry> entries;
  final String? selectedSpeciesId;
  final ValueChanged<PokemonDatabaseIndexEntry> onEntrySelected;
  final VoidCallback onImportRequested;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final bool filtersExpanded;
  final VoidCallback onToggleFiltersExpanded;
  final List<String> availableTypes;
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final List<String> availableGenerations;
  final String selectedGeneration;
  final ValueChanged<String> onGenerationChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final Widget? emptyStateChild;
  final Widget? emptyResultsChild;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: EditorChrome.accentJade.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EditorChrome.accentJade.withValues(alpha: 0.55),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      CupertinoIcons.square_stack_3d_down_right_fill,
                      size: 18,
                      color: EditorChrome.accentJade,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pokédex',
                          style: TextStyle(
                            color: label,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Importez, filtrez et ouvrez les espèces locales du projet sans quitter l’éditeur.',
                          style: TextStyle(
                            color: subtle,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    key: const Key('pokedex-import-button'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: EditorChrome.accentJade.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onImportRequested,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                        SizedBox(width: 8),
                        Text('Importer des Pokémon'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (feedbackMessage != null) ...[
                const SizedBox(height: 12),
                PokedexWorkspaceFeedbackBanner(
                  message: feedbackMessage!,
                  isError: feedbackIsError,
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PokedexSearchField(
                      query: query,
                      onChanged: onQueryChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    key: const Key('pokedex-toggle-filters-button'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    color: EditorChrome.islandFillElevated(context),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: onToggleFiltersExpanded,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.slider_horizontal_3,
                          size: 16,
                          color: CupertinoColors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(filtersExpanded ? 'Masquer' : 'Filtres'),
                      ],
                    ),
                  ),
                ],
              ),
              if (filtersExpanded) ...[
                const SizedBox(height: 12),
                _PokedexSimpleFiltersBar(
                  availableTypes: availableTypes,
                  selectedType: selectedType,
                  onTypeChanged: onTypeChanged,
                  availableGenerations: availableGenerations,
                  selectedGeneration: selectedGeneration,
                  onGenerationChanged: onGenerationChanged,
                  selectedStatus: selectedStatus,
                  onStatusChanged: onStatusChanged,
                ),
              ] else if (_hasAnyFilterApplied()) ...[
                const SizedBox(height: 10),
                Text(
                  _activeFiltersSummary(),
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (entries.isNotEmpty) ...[
          const _PokedexListHeader(),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: emptyStateChild != null
              ? SingleChildScrollView(child: emptyStateChild)
              : emptyResultsChild != null
                  ? SingleChildScrollView(child: emptyResultsChild)
                  : ListView.separated(
                      key: const Key('pokedex-species-list'),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _PokedexListRow(
                          entry: entry,
                          projectRootPath: projectRootPath,
                          isSelected: selectedSpeciesId == entry.id,
                          onPressed: () => onEntrySelected(entry),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  bool _hasAnyFilterApplied() {
    return selectedType != _PokedexFilterDropdown.allTypesValue ||
        selectedGeneration != _PokedexFilterDropdown.allGenerationsValue ||
        selectedStatus != _PokedexFilterDropdown.allStatusesValue;
  }

  String _activeFiltersSummary() {
    final parts = <String>[];
    if (selectedType != _PokedexFilterDropdown.allTypesValue) {
      parts.add('Type : $selectedType');
    }
    if (selectedGeneration != _PokedexFilterDropdown.allGenerationsValue) {
      parts.add('Génération : $selectedGeneration');
    }
    if (selectedStatus == _PokedexFilterDropdown.enabledOnlyValue) {
      parts.add('Activées');
    } else if (selectedStatus == _PokedexFilterDropdown.disabledOnlyValue) {
      parts.add('Désactivées');
    }
    return parts.join(' · ');
  }
}

class _PokedexListHeader extends StatelessWidget {
  const _PokedexListHeader();

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              'Portrait',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 88,
            child: Text(
              'Numéro',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Nom',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'ID',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              'Types',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 92,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Statut',
                style: _headerStyle(subtle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
    );
  }
}
