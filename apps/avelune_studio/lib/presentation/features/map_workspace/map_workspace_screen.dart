import 'dart:async';
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
import '../narrative/narrative_navigation.dart';
import '../narrative/narrative_overview_view_state.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_shortcuts.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import '../resources/resource_navigation.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_image_import.dart';
import 'workspace_secondary_content.dart';
import '../resources/resource_brush_selection.dart';
import 'map_workspace_layout.dart';
import '../../../features/narrative/domain/narrative_port.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../shell/studio_home_navigation.dart';
export 'workspace_actions.dart' show StudioRuntimeBuilder;

part 'workspace_home_binding.dart';
part 'workspace_story_binding.dart';
part 'workspace_progression_binding.dart';
part 'workspace_screen_body.dart';

class MapWorkspaceScreen extends StatefulWidget {
  const MapWorkspaceScreen({
    super.key,
    required this.controller,
    required this.loadVisuals,
    required this.runtimeBuilder,
    required this.onClose,
    required this.registerExitGuard,
    this.resourcePort,
    this.imagePicker,
    this.narrativePort,
    this.scenePort,
    this.storyPort,
    this.home,
  });
  final MapWorkspaceController controller;
  final StudioHomeNavigation? home;
  final ResourcePort? resourcePort;
  final NarrativePort? narrativePort;
  final ScenePort? scenePort;
  final StoryPort? storyPort;
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
  NarrativeWorkspaceController? _narrative;
  SceneWorkspaceController? _scenes;
  StoryWorkspaceController? _stories;
  final _progressionViews = StoryProgressionViewStore();
  WorkspaceSpace _sceneOrigin = WorkspaceSpace.story;
  final _sceneViews = SceneBuilderViewStore();
  bool? _inspector;
  MapData? _preparedMap;
  MapWorkspaceVisuals? _visuals;
  String? _resourceError;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _interactionNotice;
  int _gestureGeneration = 0;
  int _navigationRequest = 0;
  late final WorkspaceActions _actions;
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
      runtimeBuilder: widget.runtimeBuilder,
    );
    widget.registerExitGuard(_actions.allowClose);
    widget.home?.allowSwitch = _actions.allowClose;
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

  void _toolChanged() {
    _gestureGeneration++;
    retainWorkspaceBrush(_visuals, _view);
    _changed();
  }

  void _show(WorkspaceSpace space) {
    if (_space == WorkspaceSpace.progression) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (space == WorkspaceSpace.story) {
        _storyViewState.storyId = _stories?.activeId;
        _storyViewState.stepId = null;
      }
    }
    _navigationRequest++;
    _interactionNotice?.close();
    _narrative?.cancelOpening();
    if (mounted) setState(() => _space = space);
  }

  Future<void> _close() async {
    if (await _actions.allowClose() && mounted) await widget.onClose();
  }

  void _keyboard(void Function() action) {
    if (_space != WorkspaceSpace.map) return;
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null ||
        _controller.loading ||
        _actions.testing ||
        _actions.closing) {
      return;
    }
    action();
    _toolChanged();
  }

  @override
  void dispose() {
    widget.registerExitGuard(null);
    _controller.removeListener(_changed);
    _controller.historyGuard = null;
    final visuals = _visuals;
    if (visuals != null) {
      visuals.removeListener(_changed);
      unawaited(visuals.dispose());
    }
    _resources?.removeListener(_changed);
    _resources?.dispose();
    _narrative?.dispose();
    _scenes?.dispose();
    _stories?.dispose();
    _progressionViews.dispose();
    _sceneViews.dispose();
    _storyViewState.dispose();
    _search.dispose();
    _homeSearch.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildWorkspace(context);
}
