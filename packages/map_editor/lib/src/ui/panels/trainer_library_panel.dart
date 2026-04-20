import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

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
import 'battle_background_path_utils.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

// Keep the trainer library in one Dart library so we can split the corrective
// pass into neighboring `part` files without changing visibility or adding a
// new trainer-specific architecture.
part 'trainer_library_panel_support.dart';
part 'trainer_library_panel_trainer_widgets.dart';
part 'trainer_library_panel_pokemon_widgets.dart';
part 'trainer_library_panel_workspace_widgets.dart';

const PokemonSpeciesLookupService _speciesLookupService =
    PokemonSpeciesLookupService();
const PokemonMovesCatalogLookupService _movesLookupService =
    PokemonMovesCatalogLookupService();
const PokemonItemsCatalogLookupService _itemsLookupService =
    PokemonItemsCatalogLookupService();
const String _trainerLevelValidationMessage =
    'Level must be between 1 and 100.';
const List<String> _trainerFallbackGenderValues = <String>[
  'male',
  'female',
  'genderless',
  'any',
];
final List<int> _trainerLevelValues = List<int>.generate(
  100,
  (index) => index + 1,
  growable: false,
);

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
  final _trainerSearchController = TextEditingController();
  String? _newCharacterId;
  int? _newBattleDifficulty;
  String? _newBattleBackgroundRelativePath;
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
  int? _editBattleDifficulty;
  String? _editBattleBackgroundRelativePath;
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
  void initState() {
    super.initState();
    // The roster filter stays local to the trainer surface. It is not part of
    // editor-wide state and should never leak into the notifier.
    _trainerSearchController.addListener(_handleRosterSearchChanged);
  }

  @override
  void dispose() {
    _newNameController.dispose();
    _newClassController.dispose();
    _newPortraitController.dispose();
    _newBattleThemeController.dispose();
    _newVictoryThemeController.dispose();
    _newTagsController.dispose();
    _trainerSearchController
      ..removeListener(_handleRosterSearchChanged)
      ..dispose();

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

  void _handleRosterSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = state.project;

    _ensureReferenceDataForState(state);

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
              return widget.embedded
                  ? _buildEmbeddedTrainerLibrary(
                      context: context,
                      state: state,
                      project: project,
                      notifier: notifier,
                      references: references,
                    )
                  : _buildTrainerStudioWorkspace(
                      context: context,
                      state: state,
                      project: project,
                      notifier: notifier,
                      references: references,
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
          'Impossible de charger les espèces locales. La saisie brute reste possible.';
    }

    late final PokemonMovesCatalogView movesCatalogView;
    try {
      movesCatalogView = await movesLoader(workspace);
    } catch (error) {
      // The panel should degrade honestly if a loader blows up unexpectedly.
      // We keep the authoring surface usable with raw IDs instead of leaving
      // the future in an error state that the current builder does not render.
      movesCatalogView = const PokemonMovesCatalogView(
        entries: <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message:
            'Impossible de charger le catalogue local des attaques. La saisie brute reste possible.',
      );
    }

    late final PokemonItemsCatalogView itemsCatalogView;
    try {
      itemsCatalogView = await itemsLoader.execute(workspace);
    } catch (error) {
      itemsCatalogView = const PokemonItemsCatalogView(
        entries: <PokemonItemCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des objets indisponible.',
        message:
            'Impossible de charger le catalogue local des objets. La saisie brute reste possible.',
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
      battleDifficulty: _newBattleDifficulty,
      battleBackgroundRelativePath: _newBattleBackgroundRelativePath,
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
      battleDifficulty: _newBattleDifficulty,
      battleBackgroundRelativePath: _newBattleBackgroundRelativePath,
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
      battleDifficulty: _editBattleDifficulty,
      battleBackgroundRelativePath: _editBattleBackgroundRelativePath,
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
      battleDifficulty: _editBattleDifficulty,
      battleBackgroundRelativePath: _editBattleBackgroundRelativePath,
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
    required int? battleDifficulty,
    required String? battleBackgroundRelativePath,
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

    if (battleDifficulty != null &&
        (battleDifficulty < 1 || battleDifficulty > 10)) {
      return 'Battle difficulty must stay between 1 and 10.';
    }

    final normalizedBattleBackgroundPath =
        _normalizeOptionalField(battleBackgroundRelativePath ?? '');
    if (normalizedBattleBackgroundPath != null) {
      final normalizedPath =
          normalizedBattleBackgroundPath.replaceAll(r'\', '/');
      if (normalizedPath.startsWith('/') ||
          normalizedPath.startsWith('\\') ||
          normalizedPath.contains(':\\') ||
          normalizedPath.contains(':/') ||
          normalizedPath.contains('..')) {
        return 'Battle background image must stay inside the project as a relative path.';
      }
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
    _newBattleDifficulty = null;
    _newBattleBackgroundRelativePath = null;
  }

  void _openCreateTrainerForm() {
    setState(() {
      _showCreateForm = true;
      _createTrainerValidationMessage = null;
      _editingTrainerId = null;
      _closePokemonEditor();
    });
  }

  void _toggleCreateAdvanced() {
    setState(() {
      _showCreateAdvanced = !_showCreateAdvanced;
    });
  }

  void _setNewCharacterId(String? characterId) {
    setState(() {
      _newCharacterId = characterId;
    });
  }

  void _cancelCreateTrainerDraft() {
    setState(_resetCreateTrainerDraft);
  }

  ProjectTrainerEntry? _selectedTrainerForWorkspace(
    ProjectManifest project,
    EditorState state,
  ) {
    final selectedTrainerId = state.selectedTrainerId;
    if (selectedTrainerId != null) {
      for (final trainer in project.trainers) {
        if (trainer.id == selectedTrainerId) {
          return trainer;
        }
      }
    }
    return project.trainers.isEmpty ? null : project.trainers.first;
  }

  void _selectTrainerForWorkspace(String? trainerId) {
    // The central workspace owns the detailed trainer authoring experience.
    // Switching roster selection should therefore also clean up any draft that
    // belongs to another trainer, instead of leaving a stale editor visible in
    // the wrong context.
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
    setState(() {
      if (_showCreateForm && trainerId != null) {
        _resetCreateTrainerDraft();
      }
      if (_editingTrainerId != null && _editingTrainerId != trainerId) {
        _closeTrainerEditor();
      }
      if (_activePokemonTrainerId != null &&
          _activePokemonTrainerId != trainerId) {
        _closePokemonEditor();
      }
    });
  }

  void _startEditingTrainer(ProjectTrainerEntry trainer) {
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainer.id);
    setState(() {
      _editingTrainerId = trainer.id;
      _editNameController.text = trainer.name;
      _editClassController.text = trainer.trainerClass;
      _editPortraitController.text = trainer.portraitElementId ?? '';
      _editBattleThemeController.text = trainer.battleThemeId ?? '';
      _editVictoryThemeController.text = trainer.victoryThemeId ?? '';
      _editTagsController.text = trainer.tags.join(', ');
      _editCharacterId = trainer.characterId;
      _editBattleDifficulty = trainer.battleDifficulty;
      _editBattleBackgroundRelativePath =
          trainer.battleBackgroundRelativePath;
      _showEditAdvanced = false;
      _editTrainerValidationMessage = null;
      _showCreateForm = false;
      _closePokemonEditor();
    });
  }

  void _toggleEditAdvanced() {
    setState(() {
      _showEditAdvanced = !_showEditAdvanced;
    });
  }

  void _setEditCharacterId(String? characterId) {
    setState(() {
      _editCharacterId = characterId;
    });
  }

  void _cancelTrainerEditor() {
    setState(_closeTrainerEditor);
  }

  void _setNewBattleDifficulty(double value) {
    setState(() {
      _newBattleDifficulty = value.round().clamp(1, 10);
      _createTrainerValidationMessage = null;
    });
  }

  void _setEditBattleDifficulty(double value) {
    setState(() {
      _editBattleDifficulty = value.round().clamp(1, 10);
      _editTrainerValidationMessage = null;
    });
  }

  void _clearNewBattleDifficulty() {
    setState(() {
      _newBattleDifficulty = null;
      _createTrainerValidationMessage = null;
    });
  }

  void _clearEditBattleDifficulty() {
    setState(() {
      _editBattleDifficulty = null;
      _editTrainerValidationMessage = null;
    });
  }

  Future<void> _pickCreateBattleBackground() async {
    await _pickBattleBackgroundImage(
      createMode: true,
    );
  }

  Future<void> _pickEditBattleBackground() async {
    await _pickBattleBackgroundImage(
      createMode: false,
    );
  }

  void _clearCreateBattleBackground() {
    setState(() {
      _newBattleBackgroundRelativePath = null;
      _createTrainerValidationMessage = null;
    });
  }

  void _clearEditBattleBackground() {
    setState(() {
      _editBattleBackgroundRelativePath = null;
      _editTrainerValidationMessage = null;
    });
  }

  Future<void> _pickBattleBackgroundImage({
    required bool createMode,
  }) async {
    final projectRootPath =
        ref.read(editorNotifierProvider).projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      setState(() {
        if (createMode) {
          _createTrainerValidationMessage =
              'A valid project workspace is required before linking a battle background image.';
        } else {
          _editTrainerValidationMessage =
              'A valid project workspace is required before linking a battle background image.';
        }
      });
      return;
    }

    final pickedAbsolutePath =
        await _pickBattleBackgroundAbsolutePath(projectRootPath);
    if (pickedAbsolutePath == null) {
      return;
    }

    final relativePath = _normalizePickedBattleBackgroundPath(
      createMode: createMode,
      projectRootPath: projectRootPath,
      pickedAbsolutePath: pickedAbsolutePath,
    );
    if (relativePath == null) {
      return;
    }

    setState(() {
      if (createMode) {
        _newBattleBackgroundRelativePath = relativePath;
        _createTrainerValidationMessage = null;
      } else {
        _editBattleBackgroundRelativePath = relativePath;
        _editTrainerValidationMessage = null;
      }
    });
  }

  Future<String?> _pickBattleBackgroundAbsolutePath(String projectRootPath) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>[
        'png',
        'jpg',
        'jpeg',
        'webp',
        'bmp',
        'gif',
      ],
      withData: false,
    );
    return result?.files.single.path?.trim();
  }

  String? _normalizePickedBattleBackgroundPath({
    required bool createMode,
    required String projectRootPath,
    required String pickedAbsolutePath,
  }) {
    final relativePath = normalizeProjectLocalBattleBackgroundPath(
      projectRootPath: projectRootPath,
      pickedAbsolutePath: pickedAbsolutePath,
    );

    if (relativePath == null) {
      setState(() {
        const message =
            'This lot only links project-local images. Move the background into the project folder, then pick it again.';
        if (createMode) {
          _createTrainerValidationMessage = message;
        } else {
          _editTrainerValidationMessage = message;
        }
      });
    }
    return relativePath;
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

  void _cancelPokemonEditor() {
    setState(_closePokemonEditor);
  }

  void _setPokemonShiny(bool value) {
    setState(() {
      _pokemonShiny = value;
    });
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
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
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
    ref.read(editorNotifierProvider.notifier).selectTrainer(trainerId);
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
    if (draft.level == null || draft.level! < 1 || draft.level! > 100) {
      setState(() {
        _pokemonValidationMessage = _trainerLevelValidationMessage;
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

    if (draft.level == null || draft.level! < 1 || draft.level! > 100) {
      return _trainerLevelValidationMessage;
    }

    if (references.isSpeciesAvailable &&
        _speciesLookupService.findById(
                references.speciesEntries, draft.speciesId) ==
            null) {
      return 'Species "${draft.speciesId}" is not present in the local Pokédex.';
    }

    final seenMoveIds = <String>{};
    for (var i = 0; i < draft.moves.length; i++) {
      final moveId = draft.moves[i];
      final normalizedMoveId = moveId.toLowerCase();
      if (!seenMoveIds.add(normalizedMoveId)) {
        // Duplicate move picks make the authoring UI ambiguous and are not
        // accepted by the trainer contract. The guided dropdown already hides
        // used moves, but the raw fallback must still respect the same rule
        // even when the move catalog is temporarily unavailable.
        return 'Move ${i + 1} duplicates another selected move: $moveId';
      }
      if (references.movesCatalogView.isAvailable) {
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

    final availableGenders = speciesDetail == null
        ? const <String>[]
        : _buildTrainerGenderSuggestions(speciesDetail.species);
    if (availableGenders.isNotEmpty &&
        draft.gender != null &&
        draft.gender!.isNotEmpty &&
        !availableGenders.contains(draft.gender)) {
      return 'Gender "${draft.gender}" does not match the selected species.';
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
    _editBattleDifficulty = null;
    _editBattleBackgroundRelativePath = null;
  }
}
