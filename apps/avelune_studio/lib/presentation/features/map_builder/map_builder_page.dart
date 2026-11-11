import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avelune_studio/app/di/map_workspace_providers.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_context.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_surface.dart';
import 'package:avelune_studio/presentation/shell/studio_rail.dart';
import 'package:avelune_studio/presentation/shell/studio_top_bar.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_canvas.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_library.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/shared/widgets/minimum_size_viewport.dart';

const mapBuilderMinimumSize = Size(1280, 720);

class MapBuilderPage extends ConsumerStatefulWidget {
  const MapBuilderPage({
    super.key,
    required this.session,
    required this.onHome,
  });

  final ProjectSession session;
  final Future<void> Function() onHome;

  @override
  ConsumerState<MapBuilderPage> createState() => _MapBuilderPageState();
}

class _MapBuilderPageState extends ConsumerState<MapBuilderPage> {
  late final ProviderSubscription<MapWorkspaceController> _subscription;
  late final MapWorkspaceController _maps;
  late final MapEditingInputSession _input;
  final _views = <String, MapEditingViewportSession>{};
  MapWorkspaceVisuals? _visuals;
  String? _visualsError;
  var _saveFailed = false;
  late final _projection = WorkspaceVisualProjectionQueue(
    currentVisuals: () => _visuals,
    activeMap: () => _maps.active?.current,
    isActive: () => !_disposed,
    prepared: (_) {},
    failed: (failure) => _visualsError =
        'Les ressources de la carte ne peuvent pas être chargées : $failure',
    changed: _changed,
  );
  var _space = MapBuilderSpace.construction;
  var _inspectorOpen = true;
  var _disposed = false;

  MapEditingViewportSession? get _view {
    final document = _maps.active;
    if (document == null) return null;
    return _views.putIfAbsent(
      document.base.mapId,
      MapEditingViewportSession.new,
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
    _input = MapEditingInputSession(controller: _maps, view: () => _view);
    _maps.addListener(_changed);
    unawaited(_open());
  }

  Future<void> _open() async {
    await _maps.initialize();
    final project = _maps.project;
    if (_disposed || project == null) return;
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
      _changed();
    } catch (failure) {
      if (!_disposed) {
        setState(
          () => _visualsError =
              'Les ressources de la carte ne peuvent pas être chargées : $failure',
        );
      }
    }
  }

  void _changed() {
    if (_disposed) return;
    releaseStaleMapMoves(_views, _maps.active);
    _projection.synchronize(_maps.visualProject);
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saveFailed = false);
    final saved = await _maps.saveAll();
    if (!_disposed) setState(() => _saveFailed = !saved);
  }

  @override
  void dispose() {
    _disposed = true;
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
    _subscription.close();
    super.dispose();
  }

  StudioSaveState get _saveState {
    if (_maps.saving) return StudioSaveState.saving;
    if (_saveFailed) return StudioSaveState.failed;
    return _maps.dirty ? StudioSaveState.unsaved : StudioSaveState.saved;
  }

  bool get _editable => !_maps.loading && !_maps.catalogBusy && !_maps.saving;

  void _setTool(StudioMapTool tool) {
    final view = _view;
    if (view == null) return;
    setState(() => view.tool = tool);
  }

  @override
  Widget build(BuildContext context) {
    final project = _maps.project;
    final document = _maps.active;
    final entry = project?.maps
        .where((item) => item.id == document?.base.mapId)
        .firstOrNull;
    return Scaffold(
      key: const ValueKey('map-builder'),
      body: MinimumSizeViewport(
        minimum: mapBuilderMinimumSize,
        child: Column(
          children: [
            StudioTopBar(
              projectName: project?.name ?? widget.session.name,
              maps: project?.maps ?? const [],
              activeMapId: document?.base.mapId,
              onSelectMap: _editable
                  ? (entry) => unawaited(_maps.activate(entry))
                  : null,
              onUndo: _editable && document?.canUndo == true
                  ? () => _maps.restore(redo: false)
                  : null,
              onRedo: _editable && document?.canRedo == true
                  ? () => _maps.restore(redo: true)
                  : null,
              saveState: _saveState,
              onSave: _editable && _maps.dirty
                  ? () => unawaited(_save())
                  : null,
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudioRail(onHome: () => unawaited(widget.onHome())),
                  MapBuilderLibrary(
                    groups: project?.groups ?? const [],
                    maps: project?.maps ?? const [],
                    activeMapId: document?.base.mapId,
                    onSelectMap: _editable
                        ? (entry) => unawaited(_maps.activate(entry))
                        : null,
                  ),
                  Expanded(
                    child: MapBuilderCanvas(
                      space: _space,
                      onSpace: (space) => setState(() => _space = space),
                      entry: entry,
                      tool: _view?.tool ?? StudioMapTool.select,
                      onTool: _setTool,
                      inspectorOpen: _inspectorOpen,
                      onToggleInspector: () =>
                          setState(() => _inspectorOpen = !_inspectorOpen),
                      error: _maps.error ?? _visualsError ?? document?.error,
                      surface: _surface(),
                    ),
                  ),
                  if (_inspectorOpen)
                    MapBuilderInspector(
                      entry: entry,
                      projectName: project?.name ?? widget.session.name,
                      onCollapse: () => setState(() => _inspectorOpen = false),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _surface() {
    final visuals = _visuals;
    final view = _view;
    if (visuals == null || view == null || _maps.active == null) return null;
    return MapEditingSurface(
      controller: _maps,
      visuals: visuals,
      view: view,
      input: _input,
      onChanged: _changed,
      onSave: () => unawaited(_save()),
      busy: !_editable,
    );
  }
}
