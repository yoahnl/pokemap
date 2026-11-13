import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_input_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/spatial_map_neighbor_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_visual_projection_queue.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_surface.dart';
import 'package:flutter/widgets.dart';

class NeutralMapEditingHost extends StatefulWidget {
  const NeutralMapEditingHost({
    super.key,
    required this.controller,
    required this.visuals,
  });

  final MapWorkspaceController controller;
  final MapWorkspaceVisuals visuals;

  @override
  State<NeutralMapEditingHost> createState() => _NeutralMapEditingHostState();
}

class _NeutralMapEditingHostState extends State<NeutralMapEditingHost> {
  final _views = <String, MapEditingViewportSession>{};
  final _neighbors = SpatialMapNeighborSession();
  late final MapEditingInputSession _input;
  late final WorkspaceVisualProjectionQueue _projection;

  MapEditingViewportSession get _view => _views.putIfAbsent(
    widget.controller.active?.base.mapId ?? '',
    MapEditingViewportSession.new,
  );

  void _synchronize() =>
      _projection.synchronize(widget.controller.visualProject);

  void _changed() {
    if (!mounted) return;
    _synchronize();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _input = MapEditingInputSession(
      controller: widget.controller,
      view: () => _view,
    );
    _projection = WorkspaceVisualProjectionQueue(
      currentVisuals: () => widget.visuals,
      activeMap: () => widget.controller.active?.current,
      isActive: () => mounted,
      prepared: (_) {},
      failed: (_) {},
      changed: _changed,
    );
    widget.controller.addListener(_changed);
    widget.visuals.addListener(_changed);
    _neighbors.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) => _changed());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.visuals.removeListener(_changed);
    _neighbors.removeListener(_changed);
    _neighbors.dispose();
    _input.dispose();
    for (final view in _views.values) {
      view.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final document = controller.active;
    final project = controller.project;
    if (document == null || project == null) return const SizedBox();
    _neighbors.refresh(
      map: document.current,
      controller: controller,
      project: project,
      visuals: widget.visuals,
    );
    final surface = MapEditingSurface(
      controller: controller,
      visuals: widget.visuals,
      view: _view,
      input: _input,
      neighbors: _neighbors,
      onChanged: _changed,
      busy: _projection.loading,
    );
    return surface;
  }
}
