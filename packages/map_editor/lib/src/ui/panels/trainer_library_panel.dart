import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../app/providers/core/repository_providers.dart';
import '../../app/providers/pokedex/pokedex_providers.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_project_data_models.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/local_catalog_lookup_service.dart';
import '../../application/services/pokemon_items_catalog_lookup_service.dart';
import '../../application/services/pokemon_moves_catalog_lookup_service.dart';
import '../../application/services/pokemon_species_lookup_service.dart';
import '../../application/use_cases/load_pokemon_items_catalog_use_case.dart';
import '../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

const PokemonSpeciesLookupService _speciesLookupService =
    PokemonSpeciesLookupService();
const PokemonMovesCatalogLookupService _movesLookupService =
    PokemonMovesCatalogLookupService();
const PokemonItemsCatalogLookupService _itemsLookupService =
    PokemonItemsCatalogLookupService();
const List<String> _trainerQuickGenderValues = <String>[
  'male',
  'female',
  'any',
];

class TrainerLibraryPanel extends ConsumerStatefulWidget {
  const TrainerLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<TrainerLibraryPanel> createState() =>
      _TrainerLibraryPanelState();
}

class _TrainerLibraryPanelState extends ConsumerState<TrainerLibraryPanel> {
  // -------------------------------------------------------------------------
  // Formulaire de création d'un trainer
  // -------------------------------------------------------------------------

  final _newNameController = TextEditingController();
  final _newClassController = TextEditingController();
  final _newPortraitController = TextEditingController();
  final _newBattleThemeController = TextEditingController();
  final _newVictoryThemeController = TextEditingController();
  final _newTagsController = TextEditingController();
  String? _newCharacterId;
  bool _showCreateForm = false;
  bool _showCreateAdvanced = false;
  String? _createTrainerValidationMessage;

  // -------------------------------------------------------------------------
  // Formulaire d'édition du trainer sélectionné
  // -------------------------------------------------------------------------

  String? _editingTrainerId;
  final _editNameController = TextEditingController();
  final _editClassController = TextEditingController();
  final _editPortraitController = TextEditingController();
  final _editBattleThemeController = TextEditingController();
  final _editVictoryThemeController = TextEditingController();
  final _editTagsController = TextEditingController();
  String? _editCharacterId;
  bool _showEditAdvanced = false;
  String? _editTrainerValidationMessage;

  // -------------------------------------------------------------------------
  // Draft partagé pour ajout / édition d'un Pokémon de team
  // -------------------------------------------------------------------------

  String? _activePokemonTrainerId;
  int? _editingPokemonIndex;
  final _pokemonSpeciesController = TextEditingController();
  final _pokemonLevelController = TextEditingController(text: '1');
  final _pokemonItemController = TextEditingController();
  final _pokemonFormController = TextEditingController();
  final _pokemonGenderController = TextEditingController();
  late final List<TextEditingController> _pokemonMoveControllers =
      List<TextEditingController>.generate(
    4,
    (_) => TextEditingController(),
  );
  bool _pokemonShiny = false;
  String? _pokemonValidationMessage;

  // -------------------------------------------------------------------------
  // Références locales réutilisées par la surface auteur
  // -------------------------------------------------------------------------

  String? _referenceProjectRootPath;
  Future<_TrainerReferenceData>? _referenceDataFuture;
  final Map<String, Future<PokedexSpeciesDetail?>> _speciesDetailFutureCache =
      <String, Future<PokedexSpeciesDetail?>>{};

  @override
  void dispose() {
    _newNameController.dispose();
    _newClassController.dispose();
    _newPortraitController.dispose();
    _newBattleThemeController.dispose();
    _newVictoryThemeController.dispose();
    _newTagsController.dispose();

    _editNameController.dispose();
    _editClassController.dispose();
    _editPortraitController.dispose();
    _editBattleThemeController.dispose();
    _editVictoryThemeController.dispose();
    _editTagsController.dispose();

    _pokemonSpeciesController.dispose();
    _pokemonLevelController.dispose();
    _pokemonItemController.dispose();
    _pokemonFormController.dispose();
    _pokemonGenderController.dispose();
    for (final controller in _pokemonMoveControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    _ensureReferenceDataForState(state);

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.accentCoral;

    final content = project == null
        ? Center(
            child: Text(
              'No project loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : FutureBuilder<_TrainerReferenceData>(
            future: _referenceDataFuture,
            initialData: const _TrainerReferenceData.loading(),
            builder: (context, snapshot) {
              final references =
                  snapshot.data ?? const _TrainerReferenceData.loading();
              return ListView(
                padding: widget.embedded
                    ? kInspectorTileBodyPadding
                    : const EdgeInsets.fromLTRB(8, 8, 8, 8),
                children: [
                  _TrainerReferencesBanner(
                    references: references,
                    onRefresh: () => _refreshReferenceData(state),
                  ),
                  if ((state.errorMessage ?? '').trim().isNotEmpty ||
                      (state.statusMessage ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: _TrainerOperationBanner(
                        message:
                            (state.errorMessage?.trim().isNotEmpty ?? false)
                                ? state.errorMessage!.trim()
                                : state.statusMessage!.trim(),
                        isError:
                            (state.errorMessage?.trim().isNotEmpty ?? false),
                      ),
                    ),
                  if (!_showCreateForm)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CupertinoButton.filled(
                        key: const Key('trainer-library-new-trainer-button'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: const Size(1, 28),
                        onPressed: () => setState(() {
                          _showCreateForm = true;
                          _createTrainerValidationMessage = null;
                          _editingTrainerId = null;
                          _closePokemonEditor();
                        }),
                        child: const Text(
                          'New Trainer',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TrainerEditorCard(
                        key: const Key('trainer-library-create-card'),
                        title: 'NEW TRAINER',
                        accent: accent,
                        nameController: _newNameController,
                        classController: _newClassController,
                        portraitController: _newPortraitController,
                        battleThemeController: _newBattleThemeController,
                        victoryThemeController: _newVictoryThemeController,
                        tagsController: _newTagsController,
                        characters: project.characters,
                        elements: project.elements,
                        selectedCharacterId: _newCharacterId,
                        validationMessage: _createTrainerValidationMessage,
                        showAdvanced: _showCreateAdvanced,
                        createMode: true,
                        onToggleAdvanced: () => setState(() {
                          _showCreateAdvanced = !_showCreateAdvanced;
                        }),
                        onSelectCharacter: (characterId) => setState(() {
                          _newCharacterId = characterId;
                        }),
                        onCancel: () => setState(_resetCreateTrainerDraft),
                        onSubmit: () => _handleCreateTrainer(
                          notifier: notifier,
                          project: project,
                        ),
                      ),
                    ),
                  if (project.trainers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'No trainers yet',
                          style: TextStyle(color: subtle, fontSize: 13),
                        ),
                      ),
                    ),
                  for (final trainer in project.trainers)
                    _buildTrainerTile(
                      context: context,
                      trainer: trainer,
                      project: project,
                      notifier: notifier,
                      references: references,
                      accent: accent,
                    ),
                ],
              );
            },
          );

    if (widget.embedded) {
      return content;
    }
    return ColoredBox(
      color: EditorChrome.largeIslandSurfaceColor(context),
      child: content,
    );
  }

  // -------------------------------------------------------------------------
  // Chargement des références locales
  // -------------------------------------------------------------------------

  void _ensureReferenceDataForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (_referenceProjectRootPath == projectRootPath &&
        _referenceDataFuture != null) {
      return;
    }

    _referenceProjectRootPath = projectRootPath;
    _speciesDetailFutureCache.clear();

    final workspace = _workspaceForState(state);
    _referenceDataFuture = workspace == null
        ? Future<_TrainerReferenceData>.value(
            const _TrainerReferenceData.unavailable(),
          )
        : _loadReferenceData(workspace);
  }

  Future<void> _refreshReferenceData(EditorState state) async {
    final workspace = _workspaceForState(state);
    if (workspace == null) {
      return;
    }

    setState(() {
      _speciesDetailFutureCache.clear();
      _referenceDataFuture = _loadReferenceData(workspace);
    });
  }

  ProjectWorkspace? _workspaceForState(EditorState state) {
    final projectRootPath = state.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return null;
    }
    return ref.read(projectWorkspaceFactoryProvider).create(projectRootPath);
  }

  Future<_TrainerReferenceData> _loadReferenceData(
    ProjectWorkspace workspace,
  ) async {
    final speciesLoader = ref.read(pokedexEntryLoaderProvider);
    final movesLoader = ref.read(pokedexMovesCatalogLoaderProvider);
    final itemsLoader = ref.read(loadPokemonItemsCatalogUseCaseProvider);

    List<PokemonDatabaseIndexEntry> speciesEntries = const [];
    String speciesMessage =
        'Aucune espèce locale disponible. La saisie brute reste possible.';
    var isSpeciesAvailable = false;

    try {
      speciesEntries = await speciesLoader(workspace);
      isSpeciesAvailable = speciesEntries.isNotEmpty;
      speciesMessage = speciesEntries.isEmpty
          ? 'Aucune espèce locale n’a encore été indexée. La saisie brute reste possible.'
          : 'Recherche locale active sur ${speciesEntries.length} espèces du projet.';
    } catch (error) {
      speciesMessage =
          'Impossible de charger les espèces locales. La saisie brute reste possible.\n$error';
    }

    final movesCatalogView = await movesLoader(workspace);
    final itemsCatalogView = await itemsLoader.execute(workspace);

    return _TrainerReferenceData(
      speciesEntries: speciesEntries,
      isSpeciesAvailable: isSpeciesAvailable,
      speciesMessage: speciesMessage,
      movesCatalogView: movesCatalogView,
      itemsCatalogView: itemsCatalogView,
    );
  }

  Future<PokedexSpeciesDetail?> _loadSpeciesDetailIfPossible(
    ProjectWorkspace workspace,
    String rawSpeciesId,
  ) {
    final speciesId = rawSpeciesId.trim();
    if (speciesId.isEmpty) {
      return Future<PokedexSpeciesDetail?>.value(null);
    }

    final existingFuture = _speciesDetailFutureCache[speciesId];
    if (existingFuture != null) {
      return existingFuture;
    }

    final loader = ref.read(pokedexSpeciesDetailLoaderProvider);
    final future = loader(workspace, speciesId)
        .then<PokedexSpeciesDetail?>((detail) => detail)
        .catchError((_) => null);
    _speciesDetailFutureCache[speciesId] = future;
    return future;
  }

  // -------------------------------------------------------------------------
  // Trainer CRUD
  // -------------------------------------------------------------------------

  Future<void> _handleCreateTrainer({
    required EditorNotifier notifier,
    required ProjectManifest project,
  }) async {
    final validation = _validateTrainerDraft(
      project: project,
      name: _newNameController.text,
      trainerClass: _newClassController.text,
      portraitElementId: _newPortraitController.text,
    );
    setState(() {
      _createTrainerValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final success = await notifier.createTrainer(
      name: _newNameController.text,
      trainerClass: _newClassController.text,
      characterId: _newCharacterId,
      portraitElementId: _newPortraitController.text,
      battleThemeId: _newBattleThemeController.text,
      victoryThemeId: _newVictoryThemeController.text,
      tags: _splitCommaSeparatedValues(_newTagsController.text),
    );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_resetCreateTrainerDraft);
      return;
    }

    setState(() {
      _createTrainerValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to create trainer.';
    });
  }

  Future<void> _handleUpdateTrainer({
    required EditorNotifier notifier,
    required ProjectManifest project,
    required ProjectTrainerEntry trainer,
  }) async {
    final validation = _validateTrainerDraft(
      project: project,
      name: _editNameController.text,
      trainerClass: _editClassController.text,
      portraitElementId: _editPortraitController.text,
    );
    setState(() {
      _editTrainerValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final success = await notifier.updateTrainer(
      trainerId: trainer.id,
      name: _editNameController.text,
      trainerClass: _editClassController.text,
      characterId: _editCharacterId,
      portraitElementId: _editPortraitController.text,
      battleThemeId: _editBattleThemeController.text,
      victoryThemeId: _editVictoryThemeController.text,
      tags: _splitCommaSeparatedValues(_editTagsController.text),
    );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _editingTrainerId = null;
        _editTrainerValidationMessage = null;
        _showEditAdvanced = false;
      });
      return;
    }

    setState(() {
      _editTrainerValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to update trainer.';
    });
  }

  Future<void> _handleDeleteTrainer({
    required EditorNotifier notifier,
    required ProjectTrainerEntry trainer,
  }) async {
    final success = await notifier.deleteTrainer(trainer.id);
    if (!mounted || !success) {
      return;
    }
    setState(() {
      if (_editingTrainerId == trainer.id) {
        _editingTrainerId = null;
        _editTrainerValidationMessage = null;
      }
      if (_activePokemonTrainerId == trainer.id) {
        _closePokemonEditor();
      }
    });
  }

  String? _validateTrainerDraft({
    required ProjectManifest project,
    required String name,
    required String trainerClass,
    required String portraitElementId,
  }) {
    if (name.trim().isEmpty) {
      return 'Trainer name cannot be empty.';
    }
    if (trainerClass.trim().isEmpty) {
      return 'Trainer class cannot be empty.';
    }

    final portraitId = portraitElementId.trim();
    if (portraitId.isNotEmpty &&
        !project.elements.any((element) => element.id == portraitId)) {
      return 'Portrait element "$portraitId" does not exist in this project.';
    }

    return null;
  }

  void _resetCreateTrainerDraft() {
    _showCreateForm = false;
    _showCreateAdvanced = false;
    _createTrainerValidationMessage = null;
    _newNameController.clear();
    _newClassController.clear();
    _newPortraitController.clear();
    _newBattleThemeController.clear();
    _newVictoryThemeController.clear();
    _newTagsController.clear();
    _newCharacterId = null;
  }

  void _startEditingTrainer(ProjectTrainerEntry trainer) {
    setState(() {
      _editingTrainerId = trainer.id;
      _editNameController.text = trainer.name;
      _editClassController.text = trainer.trainerClass;
      _editPortraitController.text = trainer.portraitElementId ?? '';
      _editBattleThemeController.text = trainer.battleThemeId ?? '';
      _editVictoryThemeController.text = trainer.victoryThemeId ?? '';
      _editTagsController.text = trainer.tags.join(', ');
      _editCharacterId = trainer.characterId;
      _showEditAdvanced = false;
      _editTrainerValidationMessage = null;
      _showCreateForm = false;
      _closePokemonEditor();
    });
  }

  // -------------------------------------------------------------------------
  // Draft Pokémon team
  // -------------------------------------------------------------------------

  bool get _isAddingPokemon =>
      _activePokemonTrainerId != null && _editingPokemonIndex == null;

  bool _isEditingPokemon(
    String trainerId,
    int pokemonIndex,
  ) {
    return _activePokemonTrainerId == trainerId &&
        _editingPokemonIndex == pokemonIndex;
  }

  void _closePokemonEditor() {
    _activePokemonTrainerId = null;
    _editingPokemonIndex = null;
    _pokemonValidationMessage = null;
    _pokemonSpeciesController.clear();
    _pokemonLevelController.text = '1';
    _pokemonItemController.clear();
    _pokemonFormController.clear();
    _pokemonGenderController.clear();
    for (final controller in _pokemonMoveControllers) {
      controller.clear();
    }
    _pokemonShiny = false;
  }

  void _startAddingPokemon(String trainerId) {
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = null;
      _pokemonValidationMessage = null;
      _pokemonSpeciesController.clear();
      _pokemonLevelController.text = '1';
      _pokemonItemController.clear();
      _pokemonFormController.clear();
      _pokemonGenderController.clear();
      for (final controller in _pokemonMoveControllers) {
        controller.clear();
      }
      _pokemonShiny = false;
      _editingTrainerId = null;
      _showCreateForm = false;
    });
  }

  void _startEditingPokemon(
    String trainerId,
    int pokemonIndex,
    ProjectTrainerPokemonEntry pokemon,
  ) {
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = pokemonIndex;
      _pokemonValidationMessage = null;
      _pokemonSpeciesController.text = pokemon.speciesId;
      _pokemonLevelController.text = pokemon.level.toString();
      _pokemonItemController.text = pokemon.heldItemId ?? '';
      _pokemonFormController.text = pokemon.formId ?? '';
      _pokemonGenderController.text = pokemon.gender ?? '';
      for (var i = 0; i < _pokemonMoveControllers.length; i++) {
        _pokemonMoveControllers[i].text =
            i < pokemon.moves.length ? pokemon.moves[i] : '';
      }
      _pokemonShiny = pokemon.shiny;
      _editingTrainerId = null;
      _showCreateForm = false;
    });
  }

  Future<void> _handleSavePokemonDraft({
    required EditorNotifier notifier,
    required ProjectWorkspace workspace,
    required _TrainerReferenceData references,
  }) async {
    final trainerId = _activePokemonTrainerId;
    if (trainerId == null) {
      return;
    }

    final speciesDetail = await _loadSpeciesDetailIfPossible(
        workspace, _pokemonSpeciesController.text);
    final validation = _validatePokemonDraft(
      references: references,
      speciesDetail: speciesDetail,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _pokemonValidationMessage = validation;
    });
    if (validation != null) {
      return;
    }

    final draft = _buildPokemonDraft();
    if (draft.level == null) {
      setState(() {
        _pokemonValidationMessage = 'Level must be a positive integer.';
      });
      return;
    }

    final success = _editingPokemonIndex == null
        ? await notifier.addTrainerPokemon(
            trainerId: trainerId,
            speciesId: draft.speciesId,
            level: draft.level!,
            moves: draft.moves,
            heldItemId: draft.heldItemId,
            formId: draft.formId,
            gender: draft.gender,
            shiny: draft.shiny,
          )
        : await notifier.updateTrainerPokemon(
            trainerId: trainerId,
            pokemonIndex: _editingPokemonIndex!,
            speciesId: draft.speciesId,
            level: draft.level!,
            moves: draft.moves,
            heldItemId: draft.heldItemId,
            formId: draft.formId,
            gender: draft.gender,
            shiny: draft.shiny,
          );
    if (!mounted) {
      return;
    }

    if (success) {
      setState(_closePokemonEditor);
      return;
    }

    setState(() {
      _pokemonValidationMessage =
          ref.read(editorNotifierProvider).errorMessage ??
              'Failed to save trainer Pokémon.';
    });
  }

  Future<void> _handleDeletePokemon({
    required EditorNotifier notifier,
    required String trainerId,
    required int pokemonIndex,
  }) async {
    final success = await notifier.deleteTrainerPokemon(
      trainerId: trainerId,
      pokemonIndex: pokemonIndex,
    );
    if (!mounted || !success) {
      return;
    }

    setState(() {
      if (_isEditingPokemon(trainerId, pokemonIndex)) {
        _closePokemonEditor();
      }
    });
  }

  _TrainerPokemonDraft _buildPokemonDraft() {
    return _TrainerPokemonDraft(
      speciesId: _pokemonSpeciesController.text.trim(),
      level: int.tryParse(_pokemonLevelController.text.trim()),
      moves: _pokemonMoveControllers
          .map((controller) => controller.text.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false),
      heldItemId: _normalizeOptionalField(_pokemonItemController.text),
      formId: _normalizeOptionalField(_pokemonFormController.text),
      gender: _normalizeOptionalField(_pokemonGenderController.text),
      shiny: _pokemonShiny,
    );
  }

  String? _validatePokemonDraft({
    required _TrainerReferenceData references,
    required PokedexSpeciesDetail? speciesDetail,
  }) {
    final draft = _buildPokemonDraft();
    if (draft.speciesId.isEmpty) {
      return 'Species ID cannot be empty.';
    }

    if (draft.level == null || draft.level! <= 0) {
      return 'Level must be a positive integer.';
    }

    if (references.isSpeciesAvailable &&
        _speciesLookupService.findById(
                references.speciesEntries, draft.speciesId) ==
            null) {
      return 'Species "${draft.speciesId}" is not present in the local Pokédex.';
    }

    if (references.movesCatalogView.isAvailable) {
      for (var i = 0; i < draft.moves.length; i++) {
        final moveId = draft.moves[i];
        if (_movesLookupService.findById(
              references.movesCatalogView.entries,
              moveId,
            ) ==
            null) {
          return 'Move ${i + 1} references an unknown local move: $moveId';
        }
      }
    }

    if (references.itemsCatalogView.isAvailable &&
        draft.heldItemId != null &&
        draft.heldItemId!.isNotEmpty &&
        _itemsLookupService.findById(
              references.itemsCatalogView.entries,
              draft.heldItemId!,
            ) ==
            null) {
      return 'Held item "${draft.heldItemId}" is not present in the local items catalog.';
    }

    final availableForms = speciesDetail == null
        ? const <String>[]
        : _buildSpeciesFormSuggestions(speciesDetail.species);
    if (availableForms.isNotEmpty &&
        draft.formId != null &&
        draft.formId!.isNotEmpty &&
        !availableForms.contains(draft.formId)) {
      return 'Form "${draft.formId}" does not match the selected species.';
    }

    return null;
  }

  // -------------------------------------------------------------------------
  // Construction UI
  // -------------------------------------------------------------------------

  Widget _buildTrainerTile({
    required BuildContext context,
    required ProjectTrainerEntry trainer,
    required ProjectManifest project,
    required EditorNotifier notifier,
    required _TrainerReferenceData references,
    required Color accent,
  }) {
    final workspace = _workspaceForState(ref.read(editorNotifierProvider));
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final isEditing = _editingTrainerId == trainer.id;
    final isAddingPokemon =
        _isAddingPokemon && _activePokemonTrainerId == trainer.id;

    return Container(
      key: ValueKey(trainer.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEditing
              ? accent.withValues(alpha: 0.5)
              : CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trainer.trainerClass} • ${trainer.id}',
                        style: TextStyle(fontSize: 11, color: subtle),
                      ),
                      if (trainer.team.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Trainer has no Pokémon yet.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: EditorChrome.inspectorJoyCoral,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(1, 28),
                  onPressed: () {
                    if (isEditing) {
                      setState(() {
                        _editingTrainerId = null;
                        _editTrainerValidationMessage = null;
                        _showEditAdvanced = false;
                      });
                    } else {
                      _startEditingTrainer(trainer);
                    }
                  },
                  child: Icon(
                    isEditing
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.pencil,
                    size: 16,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(1, 28),
                  onPressed: () => _handleDeleteTrainer(
                    notifier: notifier,
                    trainer: trainer,
                  ),
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: 16,
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
              ],
            ),
          ),
          if (isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: _TrainerEditorCard(
                key: Key('trainer-library-edit-card-${trainer.id}'),
                title: 'EDIT TRAINER',
                accent: accent,
                nameController: _editNameController,
                classController: _editClassController,
                portraitController: _editPortraitController,
                battleThemeController: _editBattleThemeController,
                victoryThemeController: _editVictoryThemeController,
                tagsController: _editTagsController,
                characters: project.characters,
                elements: project.elements,
                selectedCharacterId: _editCharacterId,
                validationMessage: _editTrainerValidationMessage,
                showAdvanced: _showEditAdvanced,
                createMode: false,
                onToggleAdvanced: () => setState(() {
                  _showEditAdvanced = !_showEditAdvanced;
                }),
                onSelectCharacter: (characterId) => setState(() {
                  _editCharacterId = characterId;
                }),
                onCancel: () => setState(() {
                  _editingTrainerId = null;
                  _editTrainerValidationMessage = null;
                  _showEditAdvanced = false;
                }),
                onSubmit: () => _handleUpdateTrainer(
                  notifier: notifier,
                  project: project,
                  trainer: trainer,
                ),
              ),
            ),
          Container(
            height: 1,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: InspectorEmbeddedSectionLabel(
              'TEAM (${trainer.team.length})',
            ),
          ),
          if (trainer.team.isEmpty && !isAddingPokemon)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Text(
                'Add at least one Pokémon to make this trainer battle-ready.',
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          for (var i = 0; i < trainer.team.length; i++) ...[
            _TrainerPokemonSummaryRow(
              key: Key('trainer-library-pokemon-row-${trainer.id}-$i'),
              pokemon: trainer.team[i],
              speciesEntry: _speciesLookupService.findById(
                references.speciesEntries,
                trainer.team[i].speciesId,
              ),
              moveCatalogView: references.movesCatalogView,
              itemCatalogView: references.itemsCatalogView,
              onEdit: () =>
                  _startEditingPokemon(trainer.id, i, trainer.team[i]),
              onDelete: () => _handleDeletePokemon(
                notifier: notifier,
                trainerId: trainer.id,
                pokemonIndex: i,
              ),
            ),
            if (_isEditingPokemon(trainer.id, i) && workspace != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: _TrainerPokemonEditorCard(
                  key:
                      Key('trainer-library-edit-pokemon-card-${trainer.id}-$i'),
                  trainerId: trainer.id,
                  references: references,
                  speciesController: _pokemonSpeciesController,
                  levelController: _pokemonLevelController,
                  itemController: _pokemonItemController,
                  formController: _pokemonFormController,
                  genderController: _pokemonGenderController,
                  moveControllers: _pokemonMoveControllers,
                  shiny: _pokemonShiny,
                  validationMessage: _pokemonValidationMessage,
                  onToggleShiny: (value) => setState(() {
                    _pokemonShiny = value;
                  }),
                  onCancel: () => setState(_closePokemonEditor),
                  onSave: () => _handleSavePokemonDraft(
                    notifier: notifier,
                    workspace: workspace,
                    references: references,
                  ),
                  loadSpeciesDetail: (speciesId) =>
                      _loadSpeciesDetailIfPossible(workspace, speciesId),
                ),
              ),
          ],
          if (isAddingPokemon && workspace != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: _TrainerPokemonEditorCard(
                key: Key('trainer-library-add-pokemon-card-${trainer.id}'),
                trainerId: trainer.id,
                references: references,
                speciesController: _pokemonSpeciesController,
                levelController: _pokemonLevelController,
                itemController: _pokemonItemController,
                formController: _pokemonFormController,
                genderController: _pokemonGenderController,
                moveControllers: _pokemonMoveControllers,
                shiny: _pokemonShiny,
                validationMessage: _pokemonValidationMessage,
                onToggleShiny: (value) => setState(() {
                  _pokemonShiny = value;
                }),
                onCancel: () => setState(_closePokemonEditor),
                onSave: () => _handleSavePokemonDraft(
                  notifier: notifier,
                  workspace: workspace,
                  references: references,
                ),
                loadSpeciesDetail: (speciesId) =>
                    _loadSpeciesDetailIfPossible(workspace, speciesId),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
            child: CupertinoButton(
              key: Key('trainer-library-add-pokemon-button-${trainer.id}'),
              padding: EdgeInsets.zero,
              minimumSize: const Size(1, 28),
              onPressed: () {
                if (isAddingPokemon) {
                  setState(_closePokemonEditor);
                } else {
                  _startAddingPokemon(trainer.id);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAddingPokemon
                        ? CupertinoIcons.minus_circle
                        : CupertinoIcons.plus_circle,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isAddingPokemon ? 'Cancel' : 'Add Pokémon',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
// Widgets trainer
// ---------------------------------------------------------------------------

class _TrainerReferencesBanner extends StatelessWidget {
  const _TrainerReferencesBanner({
    required this.references,
    required this.onRefresh,
  });

  final _TrainerReferenceData references;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final itemState = references.itemsCatalogView.isAvailable
        ? '${references.itemsCatalogView.entries.length} items'
        : 'items indisponibles';
    final moveState = references.movesCatalogView.isAvailable
        ? '${references.movesCatalogView.entries.length} moves'
        : 'moves indisponibles';
    final speciesState = references.isSpeciesAvailable
        ? '${references.speciesEntries.length} espèces'
        : 'espèces indisponibles';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Local trainer assistance · $speciesState · $moveState · $itemState',
                    style: TextStyle(
                      color: label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                CupertinoButton(
                  key: const Key('trainer-library-refresh-references-button'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: const Size(1, 28),
                  onPressed: onRefresh,
                  child: const Text(
                    'Refresh',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              references.speciesMessage,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.movesCatalogView.isAvailable
                  ? references.movesCatalogView.description
                  : references.movesCatalogView.message ??
                      references.movesCatalogView.description,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              references.itemsCatalogView.isAvailable
                  ? references.itemsCatalogView.description
                  : references.itemsCatalogView.message ??
                      references.itemsCatalogView.description,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerOperationBanner extends StatelessWidget {
  const _TrainerOperationBanner({
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentJade;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: TextStyle(
            color: accent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TrainerEditorCard extends StatelessWidget {
  const _TrainerEditorCard({
    super.key,
    required this.title,
    required this.accent,
    required this.nameController,
    required this.classController,
    required this.portraitController,
    required this.battleThemeController,
    required this.victoryThemeController,
    required this.tagsController,
    required this.characters,
    required this.elements,
    required this.selectedCharacterId,
    required this.validationMessage,
    required this.showAdvanced,
    required this.createMode,
    required this.onToggleAdvanced,
    required this.onSelectCharacter,
    required this.onCancel,
    required this.onSubmit,
  });

  final String title;
  final Color accent;
  final TextEditingController nameController;
  final TextEditingController classController;
  final TextEditingController portraitController;
  final TextEditingController battleThemeController;
  final TextEditingController victoryThemeController;
  final TextEditingController tagsController;
  final List<ProjectCharacterEntry> characters;
  final List<ProjectElementEntry> elements;
  final String? selectedCharacterId;
  final String? validationMessage;
  final bool showAdvanced;
  final bool createMode;
  final VoidCallback onToggleAdvanced;
  final ValueChanged<String?> onSelectCharacter;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final knownPortraitIds = elements.map((element) => element.id).toSet();
    final portraitId = portraitController.text.trim();
    final portraitIsKnown =
        portraitId.isEmpty || knownPortraitIds.contains(portraitId);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InspectorEmbeddedSectionLabel(title),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-name-field'
                  : 'trainer-library-edit-name-field',
            ),
            controller: nameController,
            placeholder: 'Name (e.g. Ash)',
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: Key(
              createMode
                  ? 'trainer-library-create-class-field'
                  : 'trainer-library-edit-class-field',
            ),
            controller: classController,
            placeholder: 'Class (e.g. Pokémon Trainer)',
          ),
          const SizedBox(height: 6),
          _TrainerCharacterPicker(
            characters: characters,
            selectedCharacterId: selectedCharacterId,
            onSelected: onSelectCharacter,
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(1, 24),
            alignment: Alignment.centerLeft,
            onPressed: onToggleAdvanced,
            child: Text(
              showAdvanced ? 'Hide optional refs' : 'Show optional refs',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (showAdvanced) ...[
            const SizedBox(height: 8),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-portrait-field'
                    : 'trainer-library-edit-portrait-field',
              ),
              controller: portraitController,
              placeholder: 'Portrait element ID (optional)',
            ),
            if (!portraitIsKnown)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Portrait element ID is not present in the project elements.',
                  style: TextStyle(
                    color: EditorChrome.inspectorJoyCoral,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-battle-theme-field'
                    : 'trainer-library-edit-battle-theme-field',
              ),
              controller: battleThemeController,
              placeholder: 'Battle theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-victory-theme-field'
                    : 'trainer-library-edit-victory-theme-field',
              ),
              controller: victoryThemeController,
              placeholder: 'Victory theme ID (optional)',
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: Key(
                createMode
                    ? 'trainer-library-create-tags-field'
                    : 'trainer-library-edit-tags-field',
              ),
              controller: tagsController,
              placeholder: 'Tags (comma separated, optional)',
            ),
            const SizedBox(height: 6),
            Text(
              'Ces champs restent volontairement bruts : aucune source locale stable n’existe encore pour les assister proprement.',
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
          if (validationMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              validationMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onCancel,
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 6),
              CupertinoButton.filled(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(1, 28),
                onPressed: onSubmit,
                child: Text(
                  createMode ? 'Create' : 'Save',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrainerPokemonSummaryRow extends StatelessWidget {
  const _TrainerPokemonSummaryRow({
    super.key,
    required this.pokemon,
    required this.speciesEntry,
    required this.moveCatalogView,
    required this.itemCatalogView,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectTrainerPokemonEntry pokemon;
  final PokemonDatabaseIndexEntry? speciesEntry;
  final PokemonMovesCatalogView moveCatalogView;
  final PokemonItemsCatalogView itemCatalogView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedMoveLabels = pokemon.moves.map((moveId) {
      if (!moveCatalogView.isAvailable) {
        return moveId;
      }
      final match = _movesLookupService.findById(
        moveCatalogView.entries,
        moveId,
      );
      return match == null ? '$moveId (?)' : match.name;
    }).toList(growable: false);
    final resolvedItemLabel = pokemon.heldItemId == null ||
            pokemon.heldItemId!.trim().isEmpty ||
            !itemCatalogView.isAvailable
        ? pokemon.heldItemId?.trim()
        : _itemsLookupService
                .findById(itemCatalogView.entries, pokemon.heldItemId!.trim())
                ?.name ??
            '${pokemon.heldItemId!.trim()} (?)';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.islandFillElevated(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      speciesEntry == null
                          ? '${pokemon.speciesId} • Lv.${pokemon.level}'
                          : '${speciesEntry!.primaryName} • ${pokemon.speciesId} • Lv.${pokemon.level}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onEdit,
                    child: const Icon(
                      CupertinoIcons.pencil,
                      size: 14,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(1, 24),
                    onPressed: onDelete,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 12,
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
              ),
              if (speciesEntry == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Species absente du Pokédex local.',
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (resolvedMoveLabels.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Moves: ${resolvedMoveLabels.join(', ')}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if (resolvedItemLabel != null &&
                  resolvedItemLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Item: $resolvedItemLabel',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.formId ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Form: ${pokemon.formId!.trim()}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
              if ((pokemon.gender ?? '').trim().isNotEmpty ||
                  pokemon.shiny) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if ((pokemon.gender ?? '').trim().isNotEmpty)
                      'Gender: ${pokemon.gender!.trim()}',
                    if (pokemon.shiny) 'Shiny',
                  ].join(' • '),
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainerPokemonEditorCard extends StatefulWidget {
  const _TrainerPokemonEditorCard({
    super.key,
    required this.trainerId,
    required this.references,
    required this.speciesController,
    required this.levelController,
    required this.itemController,
    required this.formController,
    required this.genderController,
    required this.moveControllers,
    required this.shiny,
    required this.validationMessage,
    required this.onToggleShiny,
    required this.onCancel,
    required this.onSave,
    required this.loadSpeciesDetail,
  });

  final String trainerId;
  final _TrainerReferenceData references;
  final TextEditingController speciesController;
  final TextEditingController levelController;
  final TextEditingController itemController;
  final TextEditingController formController;
  final TextEditingController genderController;
  final List<TextEditingController> moveControllers;
  final bool shiny;
  final String? validationMessage;
  final ValueChanged<bool> onToggleShiny;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Future<PokedexSpeciesDetail?> Function(String speciesId)
      loadSpeciesDetail;

  @override
  State<_TrainerPokemonEditorCard> createState() =>
      _TrainerPokemonEditorCardState();
}

class _TrainerPokemonEditorCardState extends State<_TrainerPokemonEditorCard> {
  Future<PokedexSpeciesDetail?>? _speciesDetailFuture;
  String _lastSpeciesId = '';

  @override
  void initState() {
    super.initState();
    widget.speciesController.addListener(_onDraftFieldChanged);
    widget.levelController.addListener(_onDraftFieldChanged);
    widget.itemController.addListener(_onDraftFieldChanged);
    widget.formController.addListener(_onDraftFieldChanged);
    widget.genderController.addListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.addListener(_onDraftFieldChanged);
    }
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void didUpdateWidget(covariant _TrainerPokemonEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speciesController != widget.speciesController) {
      oldWidget.speciesController.removeListener(_onDraftFieldChanged);
      widget.speciesController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.levelController != widget.levelController) {
      oldWidget.levelController.removeListener(_onDraftFieldChanged);
      widget.levelController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.itemController != widget.itemController) {
      oldWidget.itemController.removeListener(_onDraftFieldChanged);
      widget.itemController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.formController != widget.formController) {
      oldWidget.formController.removeListener(_onDraftFieldChanged);
      widget.formController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.genderController != widget.genderController) {
      oldWidget.genderController.removeListener(_onDraftFieldChanged);
      widget.genderController.addListener(_onDraftFieldChanged);
    }
    if (oldWidget.moveControllers != widget.moveControllers) {
      for (final controller in oldWidget.moveControllers) {
        controller.removeListener(_onDraftFieldChanged);
      }
      for (final controller in widget.moveControllers) {
        controller.addListener(_onDraftFieldChanged);
      }
    }
    _refreshSpeciesDetailFuture(force: true);
  }

  @override
  void dispose() {
    widget.speciesController.removeListener(_onDraftFieldChanged);
    widget.levelController.removeListener(_onDraftFieldChanged);
    widget.itemController.removeListener(_onDraftFieldChanged);
    widget.formController.removeListener(_onDraftFieldChanged);
    widget.genderController.removeListener(_onDraftFieldChanged);
    for (final controller in widget.moveControllers) {
      controller.removeListener(_onDraftFieldChanged);
    }
    super.dispose();
  }

  void _onDraftFieldChanged() {
    _refreshSpeciesDetailFuture();
    if (mounted) {
      setState(() {});
    }
  }

  void _refreshSpeciesDetailFuture({bool force = false}) {
    final speciesId = widget.speciesController.text.trim();
    if (!force && speciesId == _lastSpeciesId) {
      return;
    }
    _lastSpeciesId = speciesId;
    _speciesDetailFuture = widget.loadSpeciesDetail(speciesId);
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final resolvedSpecies = widget.references.isSpeciesAvailable
        ? _speciesLookupService.findById(
            widget.references.speciesEntries,
            widget.speciesController.text,
          )
        : null;
    final speciesCatalogReady = widget.references.isSpeciesAvailable;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.accentWarm.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InspectorEmbeddedSectionLabel('TRAINER POKÉMON'),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Species ID',
              fieldKey: const Key('trainer-library-pokemon-species-field'),
              controller: widget.speciesController,
              placeholder: 'pikachu',
            ),
            const SizedBox(height: 8),
            _TrainerCatalogAssistField<PokemonDatabaseIndexEntry>(
              keyPrefix: 'trainer-library-pokemon-species',
              title: 'Species assist',
              description: speciesCatalogReady
                  ? 'Recherche locale par id, nom ou dex.'
                  : widget.references.speciesMessage,
              entries: widget.references.speciesEntries,
              lookupService: _speciesLookupService,
              enabled: speciesCatalogReady,
              searchPlaceholder: 'Chercher une espèce locale',
              subtitleBuilder: (entry) =>
                  '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.id}',
              onSelected: (entry) {
                widget.speciesController.text = entry.id;
              },
            ),
            const SizedBox(height: 6),
            Text(
              resolvedSpecies == null
                  ? speciesCatalogReady
                      ? 'Espèce brute non résolue dans le Pokédex local.'
                      : 'La validation d’espèce reste limitée tant que l’index local est indisponible.'
                  : 'Espèce retenue : ${resolvedSpecies.primaryName} • ${resolvedSpecies.id}',
              style: TextStyle(
                color: resolvedSpecies == null
                    ? EditorChrome.inspectorJoyCoral
                    : subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TrainerInlineField(
                    label: 'Level',
                    fieldKey: const Key('trainer-library-pokemon-level-field'),
                    controller: widget.levelController,
                    placeholder: '1',
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrainerInlineField(
                    label: 'Gender',
                    fieldKey: const Key('trainer-library-pokemon-gender-field'),
                    controller: widget.genderController,
                    placeholder: 'male / female / any',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final gender in _trainerQuickGenderValues)
                  PushButton(
                    controlSize: ControlSize.small,
                    secondary: widget.genderController.text.trim() != gender,
                    onPressed: () {
                      widget.genderController.text = gender;
                    },
                    child: Text(gender),
                  ),
                PushButton(
                  controlSize: ControlSize.small,
                  secondary: widget.genderController.text.trim().isNotEmpty,
                  onPressed: () {
                    widget.genderController.clear();
                  },
                  child: const Text('Clear gender'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Shiny',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                MacosSwitch(
                  value: widget.shiny,
                  onChanged: widget.onToggleShiny,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const InspectorEmbeddedSectionLabel('MOVES'),
            const SizedBox(height: 8),
            for (var i = 0; i < widget.moveControllers.length; i++) ...[
              _TrainerMoveSlotEditor(
                slotIndex: i,
                controller: widget.moveControllers[i],
                catalogView: widget.references.movesCatalogView,
              ),
              if (i != widget.moveControllers.length - 1)
                const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            const InspectorEmbeddedSectionLabel('ITEM / FORM'),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Held item ID',
              fieldKey: const Key('trainer-library-pokemon-item-field'),
              controller: widget.itemController,
              placeholder: 'oran_berry',
            ),
            const SizedBox(height: 8),
            _TrainerCatalogAssistField<PokemonItemCatalogEntryView>(
              keyPrefix: 'trainer-library-pokemon-item',
              title: 'Item assist',
              description: widget.references.itemsCatalogView.isAvailable
                  ? 'Recherche locale par id ou nom.'
                  : widget.references.itemsCatalogView.message ??
                      widget.references.itemsCatalogView.description,
              entries: widget.references.itemsCatalogView.entries,
              lookupService: _itemsLookupService,
              enabled: widget.references.itemsCatalogView.isAvailable,
              searchPlaceholder: 'Chercher un objet local',
              subtitleBuilder: (entry) => entry.id,
              onSelected: (entry) {
                widget.itemController.text = entry.id;
              },
            ),
            const SizedBox(height: 8),
            _TrainerInlineField(
              label: 'Form ID',
              fieldKey: const Key('trainer-library-pokemon-form-field'),
              controller: widget.formController,
              placeholder: 'base / alternate form id',
            ),
            const SizedBox(height: 8),
            FutureBuilder<PokedexSpeciesDetail?>(
              future: _speciesDetailFuture,
              builder: (context, snapshot) {
                final detail = snapshot.data;
                final availableForms = detail == null
                    ? const <String>[]
                    : _buildSpeciesFormSuggestions(detail.species);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.connectionState == ConnectionState.waiting &&
                              widget.speciesController.text.trim().isNotEmpty
                          ? 'Chargement des formes locales pour cette espèce…'
                          : availableForms.isEmpty
                              ? 'Aucune suggestion de forme locale disponible pour cette espèce.'
                              : 'Suggestions de formes locales :',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    if (availableForms.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final formId in availableForms)
                            PushButton(
                              key: Key(
                                'trainer-library-pokemon-form-suggestion-$formId',
                              ),
                              controlSize: ControlSize.small,
                              secondary:
                                  widget.formController.text.trim() != formId,
                              onPressed: () {
                                widget.formController.text = formId;
                              },
                              child: Text(formId),
                            ),
                          PushButton(
                            key: const Key(
                              'trainer-library-pokemon-form-clear-button',
                            ),
                            controlSize: ControlSize.small,
                            secondary:
                                widget.formController.text.trim().isNotEmpty,
                            onPressed: () {
                              widget.formController.clear();
                            },
                            child: const Text('Clear form'),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
            if (widget.validationMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                widget.validationMessage!,
                style: const TextStyle(
                  color: EditorChrome.inspectorJoyCoral,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6),
                CupertinoButton.filled(
                  key: const Key('trainer-library-pokemon-save-button'),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(1, 28),
                  onPressed: widget.onSave,
                  child: const Text('Save Pokémon',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerMoveSlotEditor extends StatelessWidget {
  const _TrainerMoveSlotEditor({
    required this.slotIndex,
    required this.controller,
    required this.catalogView,
  });

  final int slotIndex;
  final TextEditingController controller;
  final PokemonMovesCatalogView catalogView;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final moveId = controller.text.trim();
    final resolvedMove = catalogView.isAvailable
        ? _movesLookupService.findById(catalogView.entries, moveId)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TrainerInlineField(
          label: 'Move ${slotIndex + 1}',
          fieldKey: Key('trainer-library-pokemon-move-$slotIndex-field'),
          controller: controller,
          placeholder: 'move id',
        ),
        const SizedBox(height: 6),
        _TrainerCatalogAssistField<PokemonMoveCatalogEntryView>(
          keyPrefix: 'trainer-library-pokemon-move-$slotIndex',
          title: 'Move ${slotIndex + 1} assist',
          description: catalogView.isAvailable
              ? 'Recherche locale par id ou nom.'
              : catalogView.message ?? catalogView.description,
          entries: catalogView.entries,
          lookupService: _movesLookupService,
          enabled: catalogView.isAvailable,
          searchPlaceholder: 'Chercher un move local',
          subtitleBuilder: (entry) => [
            if (entry.type != null) entry.type!,
            if (entry.category != null) entry.category!,
            if (entry.pp != null) 'PP ${entry.pp}',
          ].join(' • '),
          onSelected: (entry) {
            controller.text = entry.id;
          },
        ),
        const SizedBox(height: 4),
        Text(
          moveId.isEmpty
              ? 'Slot vide.'
              : resolvedMove == null
                  ? catalogView.isAvailable
                      ? 'Move brut non résolu dans le catalogue local.'
                      : 'Catalogue moves indisponible : la valeur brute reste conservée.'
                  : 'Move retenu : ${resolvedMove.name} • ${resolvedMove.id}',
          style: TextStyle(
            color: moveId.isNotEmpty && resolvedMove == null
                ? EditorChrome.inspectorJoyCoral
                : subtle,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _TrainerCatalogAssistField<T> extends StatefulWidget {
  const _TrainerCatalogAssistField({
    required this.keyPrefix,
    required this.title,
    required this.description,
    required this.entries,
    required this.lookupService,
    required this.enabled,
    required this.searchPlaceholder,
    required this.onSelected,
    this.subtitleBuilder,
  });

  final String keyPrefix;
  final String title;
  final String description;
  final List<T> entries;
  final ProgressiveLocalCatalogLookupService<T> lookupService;
  final bool enabled;
  final String searchPlaceholder;
  final ValueChanged<T> onSelected;
  final String Function(T entry)? subtitleBuilder;

  @override
  State<_TrainerCatalogAssistField<T>> createState() =>
      _TrainerCatalogAssistFieldState<T>();
}

class _TrainerCatalogAssistFieldState<T>
    extends State<_TrainerCatalogAssistField<T>> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectEntry(T entry) {
    widget.onSelected(entry);
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final canSearch = widget.enabled && widget.entries.isNotEmpty;
    final suggestions = canSearch
        ? widget.lookupService.search(
            widget.entries,
            _searchController.text,
            limit: 8,
          )
        : List<T>.empty(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: Key('${widget.keyPrefix}-search-field'),
          controller: _searchController,
          enabled: canSearch,
          placeholder: widget.enabled
              ? widget.searchPlaceholder
              : 'Assistance locale indisponible',
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        const SizedBox(height: 4),
        Text(
          widget.description,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        if (_searchController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (!canSearch)
            Text(
              'Aucune suggestion locale disponible pour le moment.',
              key: Key('${widget.keyPrefix}-search-unavailable'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (suggestions.isEmpty)
            Text(
              'Aucun résultat local pour cette recherche.',
              key: Key('${widget.keyPrefix}-search-empty'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Container(
              key: Key('${widget.keyPrefix}-suggestions'),
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final entry = suggestions[index];
                  final title = widget.lookupService.labelOf(entry);
                  final id = widget.lookupService.idOf(entry);
                  final subtitle = widget.subtitleBuilder?.call(entry);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: EditorChrome.islandFillElevated(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EditorChrome.accentWarm.withValues(alpha: 0.22),
                        width: 1,
                      ),
                    ),
                    child: CupertinoButton(
                      key: Key('${widget.keyPrefix}-suggestion-$id'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      onPressed: () => _selectEntry(entry),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$title • $id',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle != null &&
                                    subtitle.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: subtle,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Use',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

class _TrainerInlineField extends StatelessWidget {
  const _TrainerInlineField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          key: fieldKey,
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }
}

class _TrainerCharacterPicker extends StatelessWidget {
  const _TrainerCharacterPicker({
    required this.characters,
    required this.selectedCharacterId,
    required this.onSelected,
  });

  final List<ProjectCharacterEntry> characters;
  final String? selectedCharacterId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    ProjectCharacterEntry? selected;
    for (final character in characters) {
      if (character.id == selectedCharacterId) {
        selected = character;
        break;
      }
    }
    final label = selected?.name ?? 'None';

    return Align(
      alignment: Alignment.centerLeft,
      child: PushButton(
        controlSize: ControlSize.regular,
        secondary: true,
        onPressed: () async {
          final picked = await showCupertinoListPicker<ProjectCharacterEntry?>(
            context: context,
            title: 'Trainer Character',
            items: [null, ...characters],
            labelOf: (value) => value?.name ?? 'None',
          );
          onSelected(picked?.id);
        },
        child: Text('Character: $label'),
      ),
    );
  }
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

List<String> _buildSpeciesFormSuggestions(PokemonSpeciesFile species) {
  final candidates = <String>[
    species.forms.formId.trim().isEmpty ? 'base' : species.forms.formId.trim(),
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
