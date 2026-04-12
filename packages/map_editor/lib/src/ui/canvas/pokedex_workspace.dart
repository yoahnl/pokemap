import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/pokedex_providers.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../infrastructure/filesystem/project_filesystem.dart';
import 'pokedex_workspace_loader.dart';
import 'pokedex_workspace_views.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _allStatusesFilterValue = '__all_statuses__';
const String _enabledStatusFilterValue = '__enabled_only__';
const String _overviewTabId = 'overview';

/// Workspace central Pokédex du lot 13.
///
/// Le widget public reste volontairement lisible :
/// - il lit le contexte éditeur existant ;
/// - il délègue le chargement par défaut à un helper local dédié ;
/// - il compose les quatre états UI strictement nécessaires.
///
/// On évite ainsi deux extrêmes :
/// - un gros widget fourre-tout mêlant UI et instanciation infra ;
/// - une nouvelle architecture Pokédex "future-ready" disproportionnée.
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
    this.detailLoader,
    this.importPreviewer,
    this.importer,
    this.pickJsonImportFile,
    this.metadataSaver,
    this.formsClassificationSaver,
    this.learnsetSaver,
    this.evolutionSaver,
    this.mediaSaver,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;
  final PokedexImportPreviewer? importPreviewer;
  final PokedexImporter? importer;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesMetadataSaver? metadataSaver;
  final PokedexSpeciesFormsClassificationSaver? formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver? learnsetSaver;
  final PokedexSpeciesEvolutionSaver? evolutionSaver;
  final PokedexSpeciesMediaSaver? mediaSaver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);
    final PokedexImportPreviewer resolvedImportPreviewer =
        importPreviewer ?? ref.watch(pokedexImportPreviewerProvider);
    final PokedexImporter resolvedImporter =
        importer ?? ref.watch(pokedexImporterProvider);
    final PokedexSpeciesMetadataSaver resolvedMetadataSaver =
        metadataSaver ?? ref.watch(pokedexSpeciesMetadataSaverProvider);
    final PokedexSpeciesFormsClassificationSaver
        resolvedFormsClassificationSaver = formsClassificationSaver ??
            ref.watch(pokedexSpeciesFormsClassificationSaverProvider);
    final PokedexSpeciesLearnsetSaver resolvedLearnsetSaver =
        learnsetSaver ?? ref.watch(pokedexSpeciesLearnsetSaverProvider);
    final PokedexSpeciesEvolutionSaver resolvedEvolutionSaver =
        evolutionSaver ?? ref.watch(pokedexSpeciesEvolutionSaverProvider);
    final PokedexSpeciesMediaSaver resolvedMediaSaver =
        mediaSaver ?? ref.watch(pokedexSpeciesMediaSaverProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      importPreviewer: resolvedImportPreviewer,
      importer: resolvedImporter,
      pickJsonImportFile: pickJsonImportFile,
      metadataSaver: resolvedMetadataSaver,
      formsClassificationSaver: resolvedFormsClassificationSaver,
      learnsetSaver: resolvedLearnsetSaver,
      evolutionSaver: resolvedEvolutionSaver,
      mediaSaver: resolvedMediaSaver,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
    required this.importPreviewer,
    required this.importer,
    required this.pickJsonImportFile,
    required this.metadataSaver,
    required this.formsClassificationSaver,
    required this.learnsetSaver,
    required this.evolutionSaver,
    required this.mediaSaver,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexImportPreviewer importPreviewer;
  final PokedexImporter importer;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesMetadataSaver metadataSaver;
  final PokedexSpeciesFormsClassificationSaver formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver learnsetSaver;
  final PokedexSpeciesEvolutionSaver evolutionSaver;
  final PokedexSpeciesMediaSaver mediaSaver;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  bool _filtersExpanded = false;
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;
  String _selectedStatus = _allStatusesFilterValue;
  String? _selectedSpeciesId;
  Future<PokedexSpeciesDetail>? _detailFuture;
  String _selectedDetailTabId = _overviewTabId;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _buildEntriesFuture();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PokedexWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.loader != widget.loader ||
        oldWidget.detailLoader != widget.detailLoader) {
      _entriesFuture = _buildEntriesFuture();
      // Les raffinements UI des lots 14 et 15 restent purement locaux :
      // quand on change de workspace projet ou de source de chargement, on
      // réinitialise la query et les filtres pour éviter de conserver des
      // critères devenus trompeurs sur une autre liste déjà chargée.
      _searchQuery = '';
      _filtersExpanded = false;
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
      _selectedSpeciesId = null;
      _detailFuture = null;
      _selectedDetailTabId = _overviewTabId;
    }
  }

  Future<List<PokemonDatabaseIndexEntry>> _buildEntriesFuture() {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return Future<List<PokemonDatabaseIndexEntry>>.value(
        const <PokemonDatabaseIndexEntry>[],
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    return widget.loader(workspace);
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return const PokedexWorkspaceStateCard(
        title: 'Pokédex',
        message:
            'Chargez un projet pour afficher la liste locale des espèces importées.',
      );
    }

    return FutureBuilder<List<PokemonDatabaseIndexEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceLoadingState();
        }

        if (snapshot.hasError) {
          return PokedexWorkspaceErrorState(error: snapshot.error);
        }

        final entries = snapshot.data ?? const <PokemonDatabaseIndexEntry>[];
        final availableTypes = _buildAvailableTypes(entries);
        final availableGenerations = _buildAvailableGenerations(entries);
        final workspace = ProjectFileSystem(projectRootPath);

        // Les lots 14 et 15 restent volontairement locaux à la UI :
        // - on ne recharge pas le disque à chaque frappe ou changement de filtre ;
        // - on ne crée pas de provider/notifier Pokédex dédié ;
        // - on filtre simplement la liste déjà chargée en mémoire ;
        // - on conserve l'ordre fourni par l'index local existant.
        final filteredEntries = _filterEntries(entries);
        final selectedEntry = _resolveSelectedEntry(filteredEntries);

        // Décision UX explicite du mini-fix :
        // si la sélection courante n'est plus visible dans la liste filtrée,
        // on vide la fiche détail au lieu de garder un élément "fantôme".
        // Le reset d'état est planifié hors build pour rester propre côté
        // Flutter, mais le rendu revient tout de suite à l'état vide car
        // `selectedEntry` est déjà résolu sur la liste visible.
        _clearSelectionIfInvisible(filteredEntries);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: PokedexWorkspaceSpeciesList(
                entries: filteredEntries,
                selectedSpeciesId: _selectedSpeciesId,
                onEntrySelected: (entry) => _selectEntry(
                  workspace: workspace,
                  entry: entry,
                ),
                onImportRequested: () => _openImportFlow(workspace),
                query: _searchQuery,
                onQueryChanged: _updateSearchQuery,
                filtersExpanded: _filtersExpanded,
                onToggleFiltersExpanded: _toggleFiltersExpanded,
                availableTypes: availableTypes,
                selectedType: _selectedType,
                onTypeChanged: _updateSelectedType,
                availableGenerations: availableGenerations,
                selectedGeneration: _selectedGeneration,
                onGenerationChanged: _updateSelectedGeneration,
                selectedStatus: _selectedStatus,
                onStatusChanged: _updateSelectedStatus,
                feedbackMessage: _feedbackMessage,
                feedbackIsError: _feedbackIsError,
                emptyStateChild: entries.isEmpty
                    ? PokedexWorkspaceImportEmptyState(
                        onImportRequested: () => _openImportFlow(workspace),
                      )
                    : null,
                emptyResultsChild: entries.isNotEmpty && filteredEntries.isEmpty
                    ? PokedexWorkspaceNoResultsState(
                        query: _searchQuery,
                        selectedType: _selectedType == _allTypesFilterValue
                            ? null
                            : _selectedType,
                        selectedGeneration:
                            _selectedGeneration == _allGenerationsFilterValue
                                ? null
                                : _selectedGeneration,
                        selectedStatus:
                            _selectedStatus == _allStatusesFilterValue
                                ? null
                                : _selectedStatus,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 480,
              child: PokedexWorkspaceDetailPane(
                selectedEntry: selectedEntry,
                selectedTabId: _selectedDetailTabId,
                onTabChanged: _updateSelectedDetailTab,
                detailFuture: _detailFuture,
                onSaveMetadata: _saveMetadata,
                onSaveFormsClassification: _saveFormsClassification,
                onSaveLearnset: _saveLearnset,
                onSaveEvolution: _saveEvolution,
                onSaveMedia: _saveMedia,
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSearchQuery(String value) {
    if (value == _searchQuery) return;
    setState(() => _searchQuery = value);
  }

  void _toggleFiltersExpanded() {
    setState(() => _filtersExpanded = !_filtersExpanded);
  }

  void _updateSelectedType(String value) {
    if (value == _selectedType) return;
    setState(() => _selectedType = value);
  }

  void _updateSelectedGeneration(String value) {
    if (value == _selectedGeneration) return;
    setState(() => _selectedGeneration = value);
  }

  void _updateSelectedStatus(String value) {
    if (value == _selectedStatus) return;
    setState(() => _selectedStatus = value);
  }

  void _updateSelectedDetailTab(String value) {
    if (value == _selectedDetailTabId) return;
    setState(() => _selectedDetailTabId = value);
  }

  void _showFeedback(String message, {required bool isError}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _feedbackMessage = null);
    });
  }

  Future<void> _openImportFlow(ProjectFileSystem workspace) async {
    final result = await showPokedexImportFlowSheet(
      context: context,
      workspace: workspace,
      previewImport: widget.importPreviewer,
      importPokemon: widget.importer,
      pickJsonSourceFile: widget.pickJsonImportFile,
    );
    if (!mounted || result == null) {
      return;
    }

    final importedSpeciesId = result.preview.speciesId.trim();
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      _searchQuery = '';
      _filtersExpanded = false;
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
      _selectedSpeciesId = importedSpeciesId;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, importedSpeciesId);
    });

    final importedArtifacts = <String>[
      'espèce',
      if (result.importedLearnset) 'learnset',
      if (result.importedEvolution) 'évolutions',
      if (result.importedMedia) 'médias',
    ];
    _showFeedback(
      'Import terminé pour ${result.preview.primaryName} · ${importedArtifacts.join(', ')}',
      isError: false,
    );
  }

  void _selectEntry({
    required ProjectFileSystem workspace,
    required PokemonDatabaseIndexEntry entry,
  }) {
    if (_selectedSpeciesId == entry.id && _detailFuture != null) {
      return;
    }
    setState(() {
      _selectedSpeciesId = entry.id;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, entry.id);
    });
  }

  void _clearSelectionIfInvisible(
    List<PokemonDatabaseIndexEntry> visibleEntries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return;
    }

    final stillVisible = visibleEntries.any((entry) => entry.id == selectedId);
    if (stillVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedSpeciesId != selectedId) return;
      setState(() {
        _selectedSpeciesId = null;
        _detailFuture = null;
        _selectedDetailTabId = _overviewTabId;
      });
    });
  }

  Future<void> _saveMetadata(
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.metadataSaver(workspace, request),
    );
  }

  Future<void> _saveFormsClassification(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) =>
          widget.formsClassificationSaver(workspace, request),
    );
  }

  Future<void> _saveLearnset(
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.learnsetSaver(workspace, request),
    );
  }

  Future<void> _saveEvolution(
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.evolutionSaver(workspace, request),
    );
  }

  Future<void> _saveMedia(
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.mediaSaver(workspace, request),
    );
  }

  Future<void> _runLocalPokemonSave({
    required String speciesId,
    required Future<void> Function(ProjectFileSystem workspace) saveOperation,
  }) async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot save local Pokemon data without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    await saveOperation(workspace);
    if (!mounted) {
      return;
    }

    // Après une sauvegarde locale, on relit la même source de vérité que le
    // reste du workspace :
    // - l'index léger pour la liste et les filtres ;
    // - la fiche détail complète pour l'espèce sélectionnée.
    //
    // On évite ainsi tout cache parallèle "enabled" ou "draft saved" qui
    // pourrait diverger du JSON réellement persisté.
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      if (_selectedSpeciesId == speciesId.trim()) {
        _detailFuture = widget.detailLoader(workspace, speciesId);
      }
    });
  }

  List<PokemonDatabaseIndexEntry> _filterEntries(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final normalizedQuery = _searchQuery.trim();
    final normalizedTextQuery = normalizedQuery.toLowerCase();
    final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
    final hasExactDexQuery = RegExp(r'^\d+$').hasMatch(normalizedDexQuery);

    // Le lot 15 demande des filtres simples, pas un moteur de règles :
    // chaque critère local vaut soit "tout", soit une valeur unique exacte.
    final typeFilter = _selectedType.toLowerCase();
    final hasTypeFilter = _selectedType != _allTypesFilterValue;
    final hasGenerationFilter =
        _selectedGeneration != _allGenerationsFilterValue;
    final hasStatusFilter = _selectedStatus != _allStatusesFilterValue;

    return entries.where((entry) {
      final matchesSearch = _matchesSearchQuery(
        entry: entry,
        normalizedQuery: normalizedQuery,
        normalizedTextQuery: normalizedTextQuery,
        normalizedDexQuery: normalizedDexQuery,
        hasExactDexQuery: hasExactDexQuery,
      );

      final matchesType = !hasTypeFilter ||
          entry.types.any((type) => type.toLowerCase() == typeFilter);
      final matchesGeneration = !hasGenerationFilter ||
          entry.genIntroduced.toString() == _selectedGeneration;
      final matchesStatus = !hasStatusFilter ||
          (_selectedStatus == _enabledStatusFilterValue
              ? entry.isEnabledInProject
              : !entry.isEnabledInProject);

      return matchesSearch && matchesType && matchesGeneration && matchesStatus;
    }).toList(growable: false);
  }

  bool _matchesSearchQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedQuery,
    required String normalizedTextQuery,
    required String normalizedDexQuery,
    required bool hasExactDexQuery,
  }) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final matchesName =
        entry.primaryName.toLowerCase().contains(normalizedTextQuery);
    final matchesId = entry.id.toLowerCase().contains(normalizedTextQuery);

    // Règle produit explicite du lot 14 :
    // - si la query ressemble à un numéro dex, on ne fait pas un `contains`
    //   numérique ;
    // - on compare exactement `1`, `0001`, `#1`, `#0001` au dex courant ;
    // - cela évite qu'une recherche "1" remonte 10, 11, 21, etc.
    final matchesDex = hasExactDexQuery &&
        _matchesExactDexQuery(
          entry: entry,
          normalizedDexQuery: normalizedDexQuery,
        );

    return matchesName || matchesId || matchesDex;
  }

  List<String> _buildAvailableTypes(List<PokemonDatabaseIndexEntry> entries) {
    final uniqueTypes = entries
        .expand((entry) => entry.types)
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort(
          (left, right) => left.toLowerCase().compareTo(right.toLowerCase()));

    return uniqueTypes;
  }

  List<String> _buildAvailableGenerations(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final uniqueGenerations = entries
        .map((entry) => entry.genIntroduced)
        .toSet()
        .toList(growable: false)
      ..sort();

    return uniqueGenerations
        .map((generation) => generation.toString())
        .toList(growable: false);
  }

  PokemonDatabaseIndexEntry? _resolveSelectedEntry(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    for (final entry in entries) {
      if (entry.id == selectedId) {
        return entry;
      }
    }
    return null;
  }

  String _normalizeDexQuery(String query) {
    final trimmed = query.trim();
    if (!trimmed.startsWith('#')) {
      return trimmed;
    }
    return trimmed.substring(1).trim();
  }

  bool _matchesExactDexQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedDexQuery,
  }) {
    final rawDex = entry.nationalDex.toString();
    final paddedDex = entry.nationalDex.toString().padLeft(4, '0');
    return normalizedDexQuery == rawDex || normalizedDexQuery == paddedDex;
  }
}
