import 'dart:async';
import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_port.dart';
import '../../../features/pokemon/domain/pokemon_commerce_port.dart';
import '../pokemon/pokemon_workspace_page.dart';
import '../pokemon/pokemon_draft_dialog.dart';
import '../../../features/game_export/domain/studio_game_export_port.dart';
import '../game_export/studio_game_export_page.dart';
import '../../../features/presentations/application/presentation_workspace_controller.dart';
import '../../../features/scenes/domain/scene_presentation_creation_request.dart';
import '../presentations/presentation_view_state.dart';
import '../presentations/presentation_workspace_page.dart';
import '../presentations/presentation_workspace_visuals.dart';
import '../presentations/presentation_media_picker.dart';
import '../../../features/cinematics/domain/cinematic_port.dart';
import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../cinematics/cinematic_view_state.dart';
import '../../../features/dialogues/domain/dialogue_port.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../../features/scenes/application/scene_dialogue_results.dart';
import '../dialogues/dialogue_view_state.dart';
import '../../../features/events/domain/event_port.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import '../events/event_view_state.dart';
import '../events/event_map_loader.dart';
import '../events/event_labels.dart';
import '../events/event_playtest.dart';
import '../narrative/narrative_name_dialog.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../../features/stories/domain/story_port.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../stories/story_progression_view_store.dart';
import '../../../features/scenes/domain/scene_port.dart';
import '../../../features/scenes/application/scene_workspace_controller.dart';
import '../../../presentation/features/scenes/scene_builder_page.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'workspace_actions.dart';
import 'workspace_session_loader.dart';
import '../../../features/verification/application/verification_workspace_controller.dart';
import '../../../features/world/application/world_workspace_controller.dart';
import '../stories/story_view_state.dart';
import '../verification/verification_view_state.dart';
import '../verification/verification_workspace_page.dart';
import '../world/world_view_state.dart';
import '../world/world_workspace_page.dart';
import '../narrative/narrative_navigation.dart';
import '../narrative/narrative_overview_view_state.dart';
import 'package:flutter/services.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_selection_context.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_shortcuts.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import '../resources/resource_navigation.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_image_import.dart';
import 'workspace_secondary_content.dart';
import '../resources/resource_brush_selection.dart';
import 'map_context_menu.dart';
import 'map_workspace_layout.dart';
import '../../../features/narrative/domain/narrative_port.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../shell/studio_home_navigation.dart';
export 'workspace_actions.dart' show StudioRuntimeBuilder;

part 'workspace_home_binding.dart';
part 'workspace_story_binding.dart';
part 'workspace_progression_binding.dart';
part 'workspace_screen_body.dart';
part 'workspace_event_binding.dart';
part 'workspace_dialogue_binding.dart';
part 'workspace_cinematic_binding.dart';
part 'workspace_presentation_binding.dart';
part 'workspace_keyboard_binding.dart';
part 'workspace_lifecycle_binding.dart';
part 'workspace_context_menu_binding.dart';
part 'workspace_navigation_binding.dart';
part 'workspace_world_binding.dart';
part 'workspace_verification_binding.dart';
part 'workspace_export_binding.dart';

class MapWorkspaceScreen extends StatefulWidget {
  const MapWorkspaceScreen({
    super.key,
    required this.controller,
    required this.loadVisuals,
    required this.runtimeBuilder,
    required this.onClose,
    required this.registerExitGuard,
    this.resourcePort,
    this.pokemonPort,
    this.pokemonCommercePort,
    this.pokemonJsonPicker,
    this.pokemonPngPicker,
    this.imagePicker,
    this.narrativePort,
    this.scenePort,
    this.storyPort,
    this.eventPort,
    this.dialoguePort,
    this.cinematicPort,
    this.presentationPort,
    this.worldPort,
    this.verificationPort,
    this.presentationMediaPicker,
    this.gameExportPicker,
    this.gameExport,
    this.home,
  });
  final MapWorkspaceController controller;
  final StudioHomeNavigation? home;
  final ResourcePort? resourcePort;
  final PokemonWorkspacePort? pokemonPort;
  final PokemonCommercePort? pokemonCommercePort;
  final Future<String?> Function()? pokemonJsonPicker;
  final Future<String?> Function()? pokemonPngPicker;
  final NarrativePort? narrativePort;
  final ScenePort? scenePort;
  final StoryPort? storyPort;
  final EventPort? eventPort;
  final DialoguePort? dialoguePort;
  final CinematicPort? cinematicPort;
  final PresentationPort? presentationPort;
  final WorldPort? worldPort;
  final VerificationPort? verificationPort;
  final PickPresentationMedia? presentationMediaPicker;
  final PickGameExportFile? gameExportPicker;
  final StudioGameExportPort? gameExport;
  final PickResourceImage? imagePicker;
  final LoadWorkspaceVisuals loadVisuals;
  final StudioRuntimeBuilder runtimeBuilder;
  final Future<void> Function() onClose;
  final void Function(Future<bool> Function()? guard) registerExitGuard;
  @override
  State<MapWorkspaceScreen> createState() => _MapWorkspaceScreenState();
}

class _MapWorkspaceScreenState extends State<MapWorkspaceScreen> {
  final _views = <String, MapWorkspaceViewState>{};
  final _search = TextEditingController();
  final _homeSearch = TextEditingController();
  bool _palette = true;
  WorkspaceSpace _space = WorkspaceSpace.map;
  WorkspaceSpace _interactionOrigin = WorkspaceSpace.map;
  final _storyViewState = NarrativeOverviewViewState();
  ResourceNavigation? _resources;
  PokemonWorkspaceController? _pokemon;
  NarrativeWorkspaceController? _narrative;
  SceneWorkspaceController? _scenes;
  StoryWorkspaceController? _stories;
  EventWorkspaceController? _events;
  DialogueWorkspaceController? _dialogues;
  PresentationWorkspaceController? _presentations;
  final _presentationViews = PresentationViewStore();
  PresentationWorkspaceVisuals? _presentationVisuals;
  Object? _presentationVisualKey;
  WorkspaceReturn _presentationOrigin = WorkspaceReturn.story;
  CinematicWorkspaceController? _cinematics;
  final _cinematicViews = CinematicViewStore();
  WorkspaceSpace _cinematicOrigin = WorkspaceSpace.story;
  bool _cinematicMapReturn = false;
  final _dialogueViews = DialogueViewStore();
  WorkspaceSpace _dialogueOrigin = WorkspaceSpace.story;
  final _eventView = EventViewState();
  late final _eventMaps = EventMapLoader(_controller);
  late final _draftReferences = MapDraftReferenceIndex(_draftReferenceSources);
  GridPos? _contextCell;
  MapContextTarget? _contextTarget;
  MapContextMenuRequest? _contextRequest;
  String? _contextMapId;
  WorkspaceSpace _eventOrigin = WorkspaceSpace.story;
  bool _eventMapReturn = false;
  final _progressionViews = StoryProgressionViewStore();
  WorkspaceReturn _sceneOrigin = WorkspaceReturn.story;
  WorldWorkspaceController? _world;
  final _worldView = WorldViewState();
  WorkspaceReturn _worldOrigin = WorkspaceReturn.story;
  bool _verificationMapReturn = false;
  WorkspaceReturn _progressionOrigin = WorkspaceReturn.story;
  VerificationWorkspaceController? _verification;
  final _verificationView = VerificationViewState();
  WorkspaceReturn _verificationOrigin = WorkspaceReturn.story;
  final _sceneViews = SceneBuilderViewStore();
  bool? _inspector;
  MapData? _preparedMap;
  MapWorkspaceVisuals? _visuals;
  String? _resourceError;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _interactionNotice;
  int _gestureGeneration = 0;
  int _navigationRequest = 0;
  late final WorkspaceActions _actions;
  StudioGameExportPort? get _gameExport => widget.gameExport;
  MapWorkspaceController get _controller => widget.controller;
  MapWorkspaceViewState? get _view {
    final id = _controller.active?.base.mapId;
    return id == null
        ? null
        : _views.putIfAbsent(id, MapWorkspaceViewState.new);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
    _actions = WorkspaceActions(
      controller: _controller,
      context: () => context,
      mounted: () => mounted,
      changed: () {
        _gestureGeneration++;
        _changed();
      },
      resources: () => _resources,
      narrative: () => _narrative,
      scenes: () => _scenes,
      events: () => _events,
      dialogues: () => _dialogues,
      cinematics: () => _cinematics,
      presentations: () => _presentations,
      world: () => _world,
      worldInputsValid: () => _worldView.invalidFields.isEmpty,
      publishedCinematicContext: () => _space == WorkspaceSpace.cinematic,
      runtimeBuilder: widget.runtimeBuilder,
    );
    widget.registerExitGuard(_allowCloseWithExport);
    widget.home?.allowSwitch = _allowCloseWithExport;
    _initializePokemon();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final loaded = await loadWorkspaceSession(
        widget,
        mounted: () => mounted,
        changed: _changed,
        onUse: _useResource,
      );
      if (loaded == null) return;
      _visuals = loaded.visuals;
      _resources = loaded.resources;
      _narrative = loaded.narrative;
      _initializeScenes();
      _initializeStories();
      _initializeEvents();
      _initializeDialogues();
      _initializeCinematics();
      _initializePresentations();
      _initializeWorld();
      _initializeVerification();
      _changed();
    } catch (_) {
      if (mounted) {
        setState(
          () => _resourceError =
              'Impossible de charger les ressources de ce projet.',
        );
      }
    }
  }

  void _changed() {
    _releaseStaleMapState();
    final map = _controller.active?.current;
    if (map != null && _visuals != null && !identical(map, _preparedMap)) {
      _preparedMap = map;
      _visuals!.setActiveMap(map);
    }
    if (mounted) {
      setState(() {});
      _publishHome();
    }
  }

  void _enterSpace(WorkspaceSpace space) {
    if (mounted) setState(() => _space = space);
  }

  Future<void> _close() async {
    if (await _allowCloseWithExport() && mounted) await widget.onClose();
  }

  @override
  void dispose() {
    disposeWorkspace();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildWorkspace(context);
}
