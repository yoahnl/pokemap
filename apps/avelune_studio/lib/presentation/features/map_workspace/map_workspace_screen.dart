import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_destination_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_pokemon_reference_route.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_failure_routing.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_publication_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_map_catalog_bindings.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_resource_owner_bindings.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workshop_routes.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';

import '../../../features/project_cs/application/project_cs_controller.dart';
import '../../../features/project_audio/application/project_audio_controller.dart';
import '../../../features/project_audio/domain/project_audio_port.dart';
import '../../../features/project_settings/application/project_identity_controller.dart';
import '../../../features/project_settings/application/project_settings_session_controller.dart';
import '../../../features/verification/application/studio_failure_diagnosis.dart';
import '../verification/test_launch_dialog.dart';

import 'dart:async';

import '../../../features/map_workspace/application/map_layout_preferences.dart';
import '../../shared/widgets/dialogs/studio_command_palette.dart';
import 'map_tool_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_commands.dart';
import '../../../features/project_surf/application/project_surf_controller.dart';
import '../../../platform/playtest/studio_playtest_builders.dart';
import 'project_settings_recovery_pane.dart';
import '../../../features/project_visuals/application/project_visuals_controller.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';

import '../../../features/regional_map/application/regional_map_controller.dart';
import '../../../features/regional_map/domain/regional_map_port.dart';
import '../regional_map/regional_map_page.dart';
import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/application/pokemon_workspace_workflow.dart';
import '../../../features/pokemon/domain/pokemon_workspace_port.dart';
import '../../../features/pokemon/domain/pokemon_commerce_port.dart';
import '../../../features/pokemon/domain/pokemon_combat_port.dart';
import '../pokemon/pokemon_workspace_page.dart';
import '../pokemon/pokemon_draft_dialog.dart';
import '../../../features/game_export/domain/studio_game_export_port.dart';
import '../../../features/game_export/application/studio_game_export_mode.dart';
import '../game_export/studio_game_export_page.dart';
import '../../../features/presentations/application/presentation_workspace_controller.dart';
import '../../../features/scenes/domain/scene_presentation_creation_request.dart';
import '../presentations/presentation_view_state.dart';
import '../presentations/presentation_workspace_page.dart';
import 'package:avelune_studio/platform/rendering/contracts/presentation_workspace_visuals.dart';
import 'package:avelune_studio/features/presentations/domain/presentation_media_picker.dart';
import '../../../features/cinematics/domain/cinematic_port.dart';
import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../cinematics/cinematic_view_state.dart';
import '../../../features/dialogues/domain/dialogue_port.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../dialogues/dialogue_view_state.dart';
import '../../../features/events/domain/event_port.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import '../events/event_view_state.dart';
import 'package:avelune_studio/features/events/application/event_map_loader.dart';
import '../events/event_labels.dart';
import '../../../features/events/application/event_playtest.dart';
import '../narrative/narrative_name_dialog.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../../features/stories/domain/story_port.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../../features/scenes/domain/scene_port.dart';
import '../../../features/scenes/application/scene_workspace_controller.dart';

import 'package:flutter/material.dart';

import '../../../features/resources/domain/resource_pack_port.dart';

import 'package:map_core/map_core_domain.dart';

import 'workspace_actions.dart';

import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';

import '../../../features/verification/application/verification_workspace_controller.dart';
import '../../../features/world/application/world_workspace_controller.dart';
import '../../../features/world/application/world_draft_inputs.dart';

import 'package:avelune_studio/features/narrative/application/narrative_navigation.dart';

import '../narrative/narrative_overview_view_state.dart';

import 'package:flutter/services.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_interaction_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';

import '../../../features/map_workspace/domain/map_workspace_port.dart';

import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

import '../resources/model_resource_library.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import '../../../features/resources/domain/resource_usage_port.dart';
import '../resources/resource_image_import.dart';
import 'workspace_secondary_content.dart';
import '../resources/resource_brush_selection.dart';
import 'map_context_menu.dart';
import 'map_workspace_layout.dart';
import 'studio_home_map_preview.dart';
import '../../../features/narrative/domain/narrative_port.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../shell/studio_home_navigation.dart';
export 'workspace_actions.dart' show StudioRuntimeBuilder;
import '../../../features/map_workspace/domain/map_dive_pair_port.dart';
import 'map_dive_zone_panel.dart';

part 'workspace_scoped_catalog_binding.dart';
part 'workspace_home_binding.dart';
part 'workspace_environment_binding.dart';
part 'workspace_story_binding.dart';
part 'workspace_progression_binding.dart';
part 'workspace_screen_body.dart';
part 'workspace_settings_recovery_binding.dart';
part 'workspace_event_binding.dart';
part 'workspace_dialogue_binding.dart';
part 'workspace_cinematic_binding.dart';
part 'workspace_presentation_binding.dart';
part 'workspace_keyboard_binding.dart';
part 'workspace_command_binding.dart';
part 'workspace_lifecycle_binding.dart';
part 'workspace_resource_usage_binding.dart';
part 'workspace_context_menu_binding.dart';
part 'workspace_navigation_binding.dart';
part 'workspace_scene_return_binding.dart';
part 'workspace_world_binding.dart';
part 'workspace_verification_binding.dart';
part 'workspace_export_binding.dart';
part 'workspace_map_library_binding.dart';
part 'workspace_connection_binding.dart';

typedef WorkspaceResourceLibraryBuilder = Widget Function(
  BuildContext context,
  void Function(Future<bool> Function()?) registerExitGuard,
  Future<void> Function() onSaved,
  VoidCallback onOpenTools,
  Future<bool> Function(String modelId) onReplaceModelSource,
);

class MapWorkspaceScreen extends StatefulWidget {
  const MapWorkspaceScreen({
    super.key,
    required this.controller,
    this.layoutPreferences,
    required this.loadVisuals,
    required this.runtimeBuilder,
    this.projectRuntimeBuilder,
    this.visualTestBuilder,
    required this.onClose,
    required this.registerExitGuard,
    this.resourcePort,
    this.resourceLibraryBuilder,
    this.resourcePackPort,
    this.resourcePackPicker,
    this.resourcePackLicensePicker,
    this.resourcePackExportSink,
    this.mapConnectionPort,
    this.pokemonPort,
    this.pokemonCommercePort,
    this.pokemonCombatPort,
    this.pokemonJsonPicker,
    this.pokemonPngPicker,
    this.imagePicker,
    this.narrativePort,
    this.regionalMapPort,
    this.scenePort,
    this.storyPort,
    this.eventPort,
    this.dialoguePort,
    this.cinematicPort,
    this.presentationPort,
    this.worldPort,
    this.verificationPort,
    this.presentationMediaPicker,
    this.audioPreview,
    this.gameExportPicker,
    this.gameExport,
    this.home,
  });
  final MapWorkspaceController controller;
  final MapLayoutPreferences? layoutPreferences;
  final StudioHomeNavigation? home;
  final ResourcePort? resourcePort;
  final WorkspaceResourceLibraryBuilder? resourceLibraryBuilder;
  final ResourcePackPort? resourcePackPort;
  final PickResourcePack? resourcePackPicker;
  final PickResourcePackLicenses? resourcePackLicensePicker;
  final ResourcePackExportSink? resourcePackExportSink;
  final MapConnectionPort? mapConnectionPort;
  final PokemonWorkspacePort? pokemonPort;
  final PokemonCommercePort? pokemonCommercePort;
  final PokemonCombatPort? pokemonCombatPort;
  final Future<String?> Function()? pokemonJsonPicker, pokemonPngPicker;
  final NarrativePort? narrativePort;
  final RegionalMapPort? regionalMapPort;
  final ScenePort? scenePort;
  final StoryPort? storyPort;
  final EventPort? eventPort;
  final DialoguePort? dialoguePort;
  final CinematicPort? cinematicPort;
  final PresentationPort? presentationPort;
  final WorldPort? worldPort;
  final VerificationPort? verificationPort;
  final PickPresentationMedia? presentationMediaPicker;
  final ProjectAudioPreviewPort? audioPreview;
  final PickGameExportFile? gameExportPicker;
  final StudioGameExportPort? gameExport;
  final PickResourceImage? imagePicker;
  final LoadWorkspaceVisuals loadVisuals;
  final StudioRuntimeBuilder runtimeBuilder;
  final Widget Function(VoidCallback onClose)? projectRuntimeBuilder;
  final StudioVisualTestBuilder? visualTestBuilder;
  final Future<void> Function() onClose;
  final void Function(Future<bool> Function()? guard) registerExitGuard;
  @override
  State<MapWorkspaceScreen> createState() => _MapWorkspaceScreenState();
}

class _MapWorkspaceScreenState extends State<MapWorkspaceScreen> {
  final _views = <String, MapWorkspaceViewState>{};
  late final _navigation = WorkspaceNavigationSession(
    controller: _controller,
    isActive: () => mounted,
    changed: _changed,
    scenes: () => _scenes,
    dialogues: () => _dialogues,
    presentations: () => _presentations,
    cinematics: () => _cinematics,
    events: () => _events,
    narrative: () => _narrative,
    homeVisible: () => widget.home?.visible == true,
    readEventFilter: () => _eventView.filterMapId,
    eventFilterChanged: (value) => _eventView.filterMapId = value,
    stories: () => _stories,
    world: () => _world,
    verification: () => _verification,
    prepareWorkshop: _prepareWorkshopRoute,
    navigationRequest: () => _navigationRequest,
    nextNavigationRequest: () => ++_navigationRequest,
    mapView: () => _view,
    toolChanged: _toolChanged,
    resources: () => _resources,
    resourceUsageBusy: () => _actions.busy,
    flushResourceFocus: () {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    },
    afterViewportLayout: (action) => WidgetsBinding.instance.addPostFrameCallback((_) => action()),
    onShow: _show,
  );
  late final _mapCatalogBindings = WorkspaceMapCatalogBindings(
    controller: _controller,
    views: () => _views,
    activeView: () => _view,
    preparedMap: () => _preparedMap,
    reconcileBrushes: _reconcileResourceBrushes,
    isBusy: () => _actions.busy,
    hasDependencyDraft: () => _actions.hasCatalogDependencyDraft,
    boundsChanged: () => _gestureGeneration++,
  );
  late final _sessions = WorkspaceSessionControllers(
    controller: _controller,
    isActive: () => mounted,
    changed: _changed,
    visualCatalogChanged: (project) => _visualCatalog = project,
    flushEditors: () => _actions.flushEditors(),
    pokemonPort: widget.pokemonPort,
    pokemonCommercePort: widget.pokemonCommercePort,
    pokemonCombatPort: widget.pokemonCombatPort,
    regionalMapPort: widget.regionalMapPort,
    scenePort: widget.scenePort,
    storyPort: widget.storyPort,
    eventPort: widget.eventPort,
    dialoguePort: widget.dialoguePort,
    cinematicPort: widget.cinematicPort,
    presentationPort: widget.presentationPort,
    worldPort: widget.worldPort,
    verificationPort: widget.verificationPort,
    audioPreview: widget.audioPreview,
    gameExport: widget.gameExport,
  );
  late final _destinations = WorkspaceDestinationWorkflow(
    controller: _controller,
    navigation: _navigation,
    sessions: _sessions,
    workshops: _workshops,
    isActive: () => mounted,
    changed: _changed,
    leavePokemon: _allowLeavePokemon,
    exporter: () => _gameExport,
    libraryExitGuard: () => _libraryExitGuard,
    libraryReleased: () => _resourceLibrary = null,
    customResourceLibrary: () => widget.resourceLibraryBuilder != null,
    flushFocus: () {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
    },
    closeContext: _closeContextMenu,
    clearNotice: () {
      _interactionNotice?.close();
      _interactionNotice = null;
    },
    returnFromProgression: (storyId) {
      _storyViewState.storyId = storyId;
      _storyViewState.stepId = null;
    },
  );
  late final _layout = widget.layoutPreferences ?? MapLayoutPreferences();
  final _search = TextEditingController(),
      _homeSearch = TextEditingController();
  bool _palette = true;
  late final _connections = MapWorkspaceConnectionActions(
    controller: _controller,
    port: widget.mapConnectionPort,
    isActive: () => mounted,
    changed: _changed,
  );
  bool get _connectionBusy => _connections.busy;
  String? get _connectionError => _connections.error;
  WorkspaceSpace get _space => _navigation.space;
  WorkspaceSpace _settingsOrigin = WorkspaceSpace.map;
  WorkspaceSpace get _interactionOrigin => _navigation.interactionOrigin;
  set _interactionOrigin(WorkspaceSpace value) => _navigation.interactionOrigin = value;
  final _storyViewState = NarrativeOverviewViewState();
  ResourceNavigation? _resources;
  late final _resourceOwners = WorkspaceResourceOwnerBindings(
    controller: _controller,
    views: () => _views,
    pokemon: () => _pokemon,
    dialogues: () => _dialogues,
    narrative: () => _narrative,
    cinematics: () => _cinematics,
    drawEnvironment: _drawEnvironment,
    retainBrush: () => retainWorkspaceBrush(_visuals, _view),
  );
  Future<bool> Function()? _libraryExitGuard;
  Widget? _resourceLibrary;
  PokemonWorkspaceController? get _pokemon => _sessions.pokemon;
  late final _pokemonExitWorkflow = PokemonWorkspaceWorkflow(
    current: () => _pokemon,
    isActive: () => mounted,
    confirmDraft: () => showPokemonDraftDialog(context),
  );
  NarrativeWorkspaceController? get _narrative => _sessions.narrative;
  RegionalMapController? get _regionalMap => _sessions.regionalMap;
  SceneWorkspaceController? get _scenes => _sessions.scenes;
  StoryWorkspaceController? get _stories => _sessions.stories;
  EventWorkspaceController? get _events => _sessions.events;
  DialogueWorkspaceController? get _dialogues => _sessions.dialogues;
  PresentationWorkspaceController? get _presentations =>
      _sessions.presentations;
  late final _presentationViews = PresentationViewStore(editingSessions: _sessions.presentationEditing);
  WorkspaceReturn get _presentationOrigin => _navigation.presentationOrigin;
  set _presentationOrigin(WorkspaceReturn value) => _navigation.presentationOrigin = value;
  CinematicWorkspaceController? get _cinematics => _sessions.cinematics;
  final _cinematicViews = CinematicViewStore();
  WorkspaceSpace get _cinematicOrigin => _navigation.cinematicOrigin;
  set _cinematicOrigin(WorkspaceSpace value) => _navigation.cinematicOrigin = value;
  bool get _cinematicMapReturn => _destinations.cinematicMapReturn;
  set _cinematicMapReturn(bool value) => _destinations.cinematicMapReturn = value;
  final _dialogueViews = DialogueViewStore();
  WorkspaceSpace get _dialogueOrigin => _navigation.dialogueOrigin;
  set _dialogueOrigin(WorkspaceSpace value) => _navigation.dialogueOrigin = value;
  final _eventView = EventViewState();
  late final _eventMaps = EventMapLoader(_controller);
  MapDraftReferenceIndex get _draftReferences => _sessions.draftReferences;
  late final _contextInteraction = MapContextInteractionSession(
    contextAt: _contextAt,
    view: () => _view,
    navigation: _contextNavigation,
    changed: _changed,
  );
  MapContextMenuRequest? get _contextRequest => _contextInteraction.request;
  WorkspaceSpace get _eventOrigin => _navigation.eventOrigin;
  bool get _eventMapReturn => _navigation.eventMapReturn;
  set _eventMapReturn(bool value) => _navigation.eventMapReturn = value;
  WorkspaceReturn get _sceneOrigin => _navigation.sceneOrigin;
  WorldWorkspaceController? get _world => _sessions.world;
  final _worldInputs = WorldDraftInputs();
  set _worldOrigin(WorkspaceReturn value) => _navigation.worldOrigin = value;
  bool get _verificationMapReturn => _navigation.verificationMapReturn;
  set _verificationMapReturn(bool value) => _navigation.verificationMapReturn = value;
  bool get _pokemonMapReturn => _destinations.pokemonMapReturn;
  set _pokemonMapReturn(bool value) => _destinations.pokemonMapReturn = value;
  late final _pokemonReferences = WorkspacePokemonReferenceRoute(
    controller: _controller,
    isActive: () => mounted,
    leavePokemon: _allowLeavePokemon,
    sceneUnavailable: () =>
        _navigationNotice('L’éditeur de scènes est indisponible.'),
    showMap: () => _show(WorkspaceSpace.map),
    selectEntity: _selectMapEntity,
    opened: () {
      _pokemonMapReturn = true;
      _changed();
    },
  );
  VerificationWorkspaceController? get _verification => _sessions.verification;
  set _verificationOrigin(WorkspaceReturn value) => _navigation.verificationOrigin = value;
  bool? _inspector;
  MapData? get _preparedMap => _visualProjection.preparedMap;
  set _preparedMap(MapData? value) => _visualProjection.preparedMap = value;
  MapWorkspaceVisuals? _visuals;
  set _visualCatalog(ProjectManifest? value) =>
      _visualProjection.acknowledgeDefinitions(value);
  late final _visualProjection = WorkspaceVisualProjectionQueue(
    currentVisuals: () => _visuals,
    activeMap: () => _controller.active?.current,
    isActive: () => mounted,
    prepared: (map) => _preparedMap = map,
    failed: (failure) => _resourceError =
        'Les ressources de cette carte ne peuvent pas être chargées : $failure',
    changed: _changed,
  );
  bool get _projectionVisualsLoading => _visualProjection.loading;
  late final _workshops = WorkspaceWorkshopRoutes(
    controller: _controller,
    isActive: () => mounted,
    failed: (failure) => _resourceError = failure == null
        ? null
        : 'Cet atelier ne peut pas être chargé : $failure',
    changed: _changed,
  );
  bool get _openingWorkshop => _workshops.loading;
  String? _resourceError;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _interactionNotice;
  int _gestureGeneration = 0;
  int get _navigationRequest => _workshops.request;
  set _navigationRequest(int value) => _workshops.request = value;
  late final WorkspaceActions _actions;
  late final _publication = WorkspacePublicationWorkflow(
    controller: _controller,
    workflow: _actions,
    isActive: () => mounted,
    connectionBusy: () => _connectionBusy,
    exporter: () => _gameExport,
    resources: () => _resources,
    pokemon: () => _pokemon,
  );
  ProjectSurfController? get _projectSurf => _sessions.projectSurf;
  ProjectCsController? get _projectCs => _sessions.projectCs;
  ProjectAudioController? get _projectAudio => _sessions.projectAudio;
  ProjectIdentityController? get _projectIdentity => _sessions.projectIdentity;
  ProjectVisualsController? get _projectVisuals => _sessions.projectVisuals;
  ProjectIdentityController? get _identityOwner => _sessions.identityOwner;
  StudioGameExportPort? get _gameExport => widget.gameExport;
  MapWorkspaceController get _controller => widget.controller;
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
      regionalMap: () => _regionalMap,
      world: () => _world,
      projectVisuals: () => _projectVisuals,
      projectSurf: () => _projectSurf,
      projectCs: () => _projectCs,
      projectAudio: () => _projectAudio,
      projectIdentity: () => _projectIdentity,
      confirmLaunch: (preflight) => showTestLaunchDialog(context, preflight),
      worldInputsValid: () => _worldInputs.valid,
      publishedCinematicContext: () => _space == WorkspaceSpace.cinematic,
      runtimeBuilder: widget.runtimeBuilder,
      projectRuntimeBuilder: widget.projectRuntimeBuilder,
    );
    _configureCatalogueGuard();
    widget.registerExitGuard(_allowCloseWithExport);
    widget.home?.allowSwitch = _allowCloseWithExport;
    _initializePokemon();
    unawaited(_initialize());
  }

  void _changed() {
    if (_space != WorkspaceSpace.projectSettings) {
      _settingsOrigin = WorkspaceSpace.map;
    }
    _reconcileCatalogueView();
    _releaseStaleMapState();
    _visualProjection.follow(_controller, _workshops);
    if (mounted) {
      setState(() {});
      _publishHome();
    }
  }

  @override
  void dispose() {
    _contextInteraction.dispose();
    _destinations.dispose();
    _pokemonExitWorkflow.dispose();
    disposeWorkspace();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DivePairPublishingScope(
    controller: _controller,
    port: widget.mapConnectionPort is MapDivePairPort
        ? widget.mapConnectionPort as MapDivePairPort
        : null,
    child: _buildWorkspace(context),
  );

}
