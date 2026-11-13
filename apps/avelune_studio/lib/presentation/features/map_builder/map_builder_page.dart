import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/app/di/event_providers.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/app/di/narrative_providers.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_builders.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_canvas_readiness.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_surface.dart';
import 'package:avelune_studio/presentation/shell/studio_rail.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_header.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_canvas.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_inspector.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_opening.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_side_panel.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_status_bar.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_playtest_page.dart';
import 'package:avelune_studio/features/map_workspace/application/map_palette_intent.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/presentation/shared/widgets/minimum_size_viewport.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_tool_labels.dart';

const mapBuilderMinimumSize = Size(1280, 720);

class MapBuilderPage extends ConsumerStatefulWidget {
  const MapBuilderPage({
    super.key,
    required this.session,
    required this.onHome,
    this.progress,
  });

  final ProjectSession session;
  final Future<void> Function() onHome;
  final ProjectOpeningProgress? progress;

  @override
  ConsumerState<MapBuilderPage> createState() => _MapBuilderPageState();
}

class _MapBuilderPageState extends ConsumerState<MapBuilderPage> {
  late final ProviderSubscription<MapWorkspaceController> _subscription;
  late final ProviderSubscription<MapConnectionPort> _connections;
  ProviderSubscription<StudioRuntimeBuilder>? _runtime;
  late final MapWorkspaceController _maps;
  late final MapEditingInputSession _input;
  final _views = <String, MapEditingViewportSession>{};
  MapWorkspaceVisuals? _visuals;
  String? _visualsError;
  var _saveFailed = false;
  var _testing = false;
  late final _projection = WorkspaceVisualProjectionQueue(
    currentVisuals: () => _visuals,
    activeMap: () => _maps.active?.current,
    isActive: () => !_disposed,
    prepared: (_) {},
    failed: (failure) =>
        _visualsError = context.l10n.mapResourcesUnavailable('$failure'),
    changed: _changed,
  );
  late final _resources = MapBuilderResourceBinding(
    maps: _maps,
    view: () => _view,
    visuals: () => _visuals,
    isActive: () => !_disposed,
    changed: _changed,
  );
  late final _gameplay = MapBuilderGameplayBinding(
    maps: _maps,
    view: () => _view,
    port: configuredConnectionPort(_connections.read),
    isActive: () => !_disposed,
    changed: _changed,
    labels: () => context.l10n,
  );
  late final _story = MapBuilderStoryBinding(
    maps: _maps,
    changed: _changed,
    view: () => _view,
    zoneName: () => context.l10n.storyNewZone,
    behaviourName: (index) => context.l10n.storyBehaviourName(index),
    loadMedia: (project) async =>
        switch (ref.read(eventPortProvider(widget.session))) {
          final EventPresentationCatalogPort port =>
            await port.loadPresentationMediaCatalog(project),
          _ => null,
        },
  );
  late final _ambiance = MapBuilderAmbianceBinding(
    maps: _maps,
    changed: _changed,
    view: () => _view,
  );
  late final _opening = MapBuilderOpening(widget.progress);
  var _space = MapBuilderSpace.construction;
  var _inspectorOpen = true;
  var _disposed = false;

  MapEditingViewportSession? get _view {
    final document = _maps.active;
    if (document == null) return null;
    return _views.putIfAbsent(
      document.base.mapId,
      () => MapEditingViewportSession()
        ..ambiencePreview = _space == MapBuilderSpace.ambiance,
    );
  }

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual(
      mapWorkspaceControllerProvider(widget.session),
      (_, _) {},
    );
    _maps = _subscription.read();
    _connections = ref.listenManual(
      mapConnectionPortProvider(widget.session),
      (_, _) {},
    );
    _input = MapEditingInputSession(controller: _maps, view: () => _view);
    _maps.addListener(_changed);
    unawaited(_open());
  }

  Future<void> _open() async {
    _opening.loadingMap();
    await _maps.initialize();
    final project = _maps.project;
    if (_disposed) return;
    _opening.mapSettled(failed: _maps.error != null);
    if (project == null) return;
    try {
      final visuals = await ref.read(workspaceVisualsLoaderProvider)(
        widget.session,
        project,
      );
      if (_disposed) {
        unawaited(visuals.dispose());
        return;
      }
      visuals.addListener(_changed);
      _visuals = visuals;
      _opening.resourcesReady();
      _changed();
      _opening.awaitScene(hasMap: _maps.active != null);
      unawaited(
        _resources.load().then((_) {
          if (_disposed) return;
          _opening.paletteSettled(
            failed: _resources.problem == MapBuilderResourceProblem.loadFailed,
          );
        }),
      );
    } catch (failure) {
      _opening.resourcesFailed();
      if (!_disposed) {
        setState(
          () => _visualsError = context.l10n.mapResourcesUnavailable(
            '$failure',
          ),
        );
      }
    }
  }

  void _changed() {
    if (_disposed) return;
    releaseStaleMapMoves(_views, _maps.active);
    _projection.synchronize(_maps.visualProject);
    _resources.follow(_activeEntry);
    _resources.reconcileTool();
    _gameplay.reconcile();
    _ambiance.reconcile();
    _story.reconcile();
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saveFailed = false);
    final saved = await _saveEverything();
    if (!_disposed) setState(() => _saveFailed = !saved);
  }

  Future<bool> _saveEverything() async {
    if (_maps.dirty && !await _maps.saveAll()) return false;
    if (_disposed) return false;
    return _story.publish(ref.read(eventPortProvider(widget.session)));
  }

  Future<void> _testMap() async {
    final document = _maps.active;
    final entry = _activeEntry;
    if (document == null || entry == null || _testing) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _testing = true;
      _saveFailed = false;
    });
    try {
      if (_maps.dirty || _story.dirty) {
        final saved = await _saveEverything();
        if (!mounted) return;
        if (!saved) {
          setState(() => _saveFailed = true);
          return;
        }
      }
      if (!mounted || !identical(_maps.active, document) || _maps.loading) {
        return;
      }
      if (_maps.dirty) {
        document.error = context.l10n.testMapChangedAgain;
        _changed();
        return;
      }
      final runtime = (_runtime ??= ref.listenManual(
        sessionRuntimeBuilderProvider(widget.session),
        (_, _) {},
      )).read();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (route) => MapBuilderPlaytestPage(
            entry: entry,
            revision: document.base.revision,
            runtime: runtime,
            onClose: () => Navigator.of(route).pop(),
          ),
        ),
      );
    } finally {
      if (!_disposed) setState(() => _testing = false);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ambiance.dispose();
    _maps.removeListener(_changed);
    _input.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
    final visuals = _visuals;
    if (visuals != null) {
      visuals.removeListener(_changed);
      unawaited(visuals.dispose());
    }
    _runtime?.close();
    _connections.close();
    _subscription.close();
    super.dispose();
  }

  bool get _editable => !_maps.loading && !_maps.catalogBusy && !_maps.saving;

  ProjectMapEntry? get _activeEntry {
    final id = _maps.active?.base.mapId;
    return _maps.project?.maps.where((item) => item.id == id).firstOrNull;
  }

  void _setTool(StudioMapTool tool) {
    final view = _view;
    if (view == null) return;
    if (tool == StudioMapTool.select) {
      _resources.release();
      return;
    }
    view.tool = tool;
    _changed();
  }

  void _setSpace(MapBuilderSpace space) {
    if (space != MapBuilderSpace.construction) _resources.release();
    if (space != MapBuilderSpace.gameplay) _gameplay.leave();
    if (space != MapBuilderSpace.story) {
      _story
        ..cancelAdding()
        ..choosing = false;
    } else {
      unawaited(_story.prepare());
    }
    _gameplay
      ..shown = space == MapBuilderSpace.gameplay
      ..reconcile();
    _ambiance
      ..shown = space == MapBuilderSpace.ambiance
      ..reconcile();
    for (final view in _views.values) {
      view.ambiencePreview = space == MapBuilderSpace.ambiance;
    }
    setState(() => _space = space);
  }

  @override
  Widget build(BuildContext context) {
    final project = _maps.project;
    final document = _maps.active;
    final entry = _activeEntry;
    final view = _view;
    final intent = view == null
        ? null
        : mapPaletteIntent(
            view,
            spatial: document?.current.spatialScene != null,
            project: _resources.catalog,
          );
    final toolLabel = view == null
        ? null
        : context.l10n.toolAction(
            view,
            spatial: document?.current.spatialScene != null,
          );
    return Scaffold(
      key: const ValueKey('map-builder'),
      body: MinimumSizeViewport(
        minimum: mapBuilderMinimumSize,
        child: Column(
          children: [
            MapBuilderHeader(
              maps: _maps,
              projectName: project?.name ?? widget.session.name,
              editable: _editable,
              saveFailed: _saveFailed,
              onSave: () => unawaited(_save()),
              onTestMap: () => unawaited(_testMap()),
              testing: _testing,
              ambiance: _space == MapBuilderSpace.ambiance ? _ambiance : null,
              story: _space == MapBuilderSpace.story ? _story : null,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudioRail(onHome: () => unawaited(widget.onHome())),
                  MapBuilderSidePanel(
                    space: _space,
                    story: _story,
                    gameplay: _gameplay,
                    ambiance: _ambiance,
                    resources: _resources,
                    maps: _maps,
                    visuals: _visuals,
                    enabled: _editable,
                  ),
                  Expanded(
                    child: MapBuilderCanvas(
                      space: _space,
                      onSpace: _setSpace,
                      entry: entry,
                      tool: view?.tool ?? StudioMapTool.select,
                      onTool: _setTool,
                      inspectorOpen: _inspectorOpen,
                      onToggleInspector: () =>
                          setState(() => _inspectorOpen = !_inspectorOpen),
                      error:
                          _maps.error ??
                          _visualsError ??
                          _resourceProblem() ??
                          document?.error,
                      surface: _surface(),
                      statusBar: MapBuilderStatusBar(
                        toolLabel:
                            _resources.armed != null || _gameplay.placing
                            ? toolLabel ?? context.l10n.statusBuilding
                            : view?.tool == StudioMapTool.pan
                            ? context.l10n.toolPan
                            : context.l10n.toolSelect,
                        view: view,
                        spatial: document?.current.spatialScene != null,
                        onChanged: _changed,
                      ),
                    ),
                  ),
                  if (_inspectorOpen)
                    MapBuilderInspector(
                      entry: entry,
                      projectName: project?.name ?? widget.session.name,
                      space: _space,
                      armed: _resources.armed,
                      toolLabel: toolLabel,
                      toolHint: view == null
                          ? null
                          : context.l10n.toolHint(
                              view,
                              armed: intent?.armed ?? false,
                            ),
                      onRelease: _resources.release,
                      onCollapse: () => setState(() => _inspectorOpen = false),
                      body: mapBuilderSpaceInspector(
                        _space,
                        _gameplay,
                        _ambiance,
                        context.l10n,
                        enabled: _editable,
                        story: _story,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _resourceProblem() => switch (_resources.problem) {
    MapBuilderResourceProblem.loadFailed => context.l10n.resourcesUnavailable(
      '${_resources.problemCause}',
    ),
    MapBuilderResourceProblem.tileUnavailable =>
      context.l10n.tileChoiceUnavailable,
    null => _resources.error,
  };

  Widget? _surface() {
    final visuals = _visuals;
    final view = _view;
    if (visuals == null || view == null || _maps.active == null) return null;
    return MapCanvasReadinessScope(
      readiness: _opening.readiness,
      child: MapEditingSurface(
        controller: _maps,
        visuals: visuals,
        view: view,
        input: _input,
        onChanged: _changed,
        onSave: () => unawaited(_save()),
        onUndo: () => _historyStep(redo: false)?.call(),
        onRedo: () => _historyStep(redo: true)?.call(),
        onZoneDrawn: _space == MapBuilderSpace.story ? _story.addZone : null,
        busy: !_editable,
      ),
    );
  }

  VoidCallback? _historyStep({required bool redo}) => mapBuilderHistoryStep(
    _maps,
    redo: redo,
    editable: _editable,
    ambiance: _space == MapBuilderSpace.ambiance ? _ambiance : null,
    story: _space == MapBuilderSpace.story ? _story : null,
  );
}
