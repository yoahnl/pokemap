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

// Keep the trainer library in one Dart library so we can split the corrective
// pass into neighboring `part` files without changing visibility or adding a
// new trainer-specific architecture.
part 'trainer_library_panel_support.dart';
part 'trainer_library_panel_trainer_widgets.dart';
part 'trainer_library_panel_pokemon_widgets.dart';

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

    late final PokemonMovesCatalogView movesCatalogView;
    try {
      movesCatalogView = await movesLoader(workspace);
    } catch (error) {
      // The panel should degrade honestly if a loader blows up unexpectedly.
      // We keep the authoring surface usable with raw IDs instead of leaving
      // the future in an error state that the current builder does not render.
      movesCatalogView = PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message:
            'Impossible de charger le catalogue local des attaques. La saisie brute reste possible.\n$error',
      );
    }

    late final PokemonItemsCatalogView itemsCatalogView;
    try {
      itemsCatalogView = await itemsLoader.execute(workspace);
    } catch (error) {
      itemsCatalogView = PokemonItemsCatalogView(
        entries: const <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        message:
            'Impossible de charger le catalogue local des objets. La saisie brute reste possible.\n$error',
      );
    }

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
      setState(_closeTrainerEditor);
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
        _closeTrainerEditor();
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
    _resetPokemonDraftFields();
  }

  // Keeping the shared Pokémon draft reset in one place avoids tiny
  // field-reset mismatches between add/edit/cancel flows.
  void _resetPokemonDraftFields() {
    _pokemonValidationMessage = null;
    _pokemonSpeciesController.clear();
    _pokemonLevelController.text = '1';
    _pokemonItemController.clear();
    _pokemonFormController.clear();
    _pokemonGenderController.clear();
    _clearTextControllers(_pokemonMoveControllers);
    _pokemonShiny = false;
  }

  void _startAddingPokemon(String trainerId) {
    setState(() {
      _activePokemonTrainerId = trainerId;
      _editingPokemonIndex = null;
      _resetPokemonDraftFields();
      _closeTrainerEditor();
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
      _closeTrainerEditor();
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

  // Trainer edition is a presentation concern only. Keeping this reset local
  // avoids pushing UI mode flags into the notifier or the use cases.
  void _closeTrainerEditor() {
    _editingTrainerId = null;
    _editTrainerValidationMessage = null;
    _showEditAdvanced = false;
  }

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
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'No Pokémon assigned yet.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: subtle,
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
                      setState(_closeTrainerEditor);
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
                onCancel: () => setState(_closeTrainerEditor),
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
                'You can save this trainer now and add the team later.',
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
              isSpeciesCatalogAvailable: references.isSpeciesAvailable,
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
