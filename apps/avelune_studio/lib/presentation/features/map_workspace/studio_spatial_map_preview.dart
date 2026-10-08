import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../../shared/widgets/feedback/studio_notice.dart';
import 'map_workspace_visuals.dart';

class StudioSpatialMapPreview extends StatefulWidget {
  const StudioSpatialMapPreview({
    super.key,
    required this.map,
    required this.project,
    required this.visuals,
    required this.controller,
    required this.onCell,
    this.onContent,
    this.onHover,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
    this.selectedContent,
    this.overlays = const [],
    this.loadActors = true,
    this.actorFrames,
    this.cameraPose,
    this.selectContent = true,
  });
  final MapData map;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final SpatialSceneController controller;
  final void Function(int, int) onCell;
  final ValueChanged<SpatialSceneContentHit>? onContent;
  final ValueChanged<SpatialSurfaceHit?>? onHover;
  final bool Function(int, int, SpatialSceneContentHit?)? onDragStart;
  final ValueChanged<(int, int)>? onDragUpdate;
  final VoidCallback? onDragEnd, onDragCancel;
  final SpatialSceneContentHit? selectedContent;
  final List<SpatialCellOverlay> overlays;
  final bool loadActors, selectContent;
  final Map<String, SpatialActorVisual> Function(double dt)? actorFrames;
  final ({double x, double y, double z, double zoom})? Function()? cameraPose;

  @override
  State<StudioSpatialMapPreview> createState() =>
      _StudioSpatialMapPreviewState();
}

class _StudioSpatialMapPreviewState extends State<StudioSpatialMapPreview> {
  SpatialNpcPreview? _preview;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(StudioSpatialMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.map != oldWidget.map ||
        widget.visuals != oldWidget.visuals ||
        widget.project != oldWidget.project ||
        widget.loadActors != oldWidget.loadActors) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    _error = null;
    _preview?.dispose();
    _preview = null;
    if (!widget.loadActors || widget.visuals is! SpatialWorkspaceVisuals) {
      return;
    }
    try {
      final preview = await (widget.visuals as SpatialWorkspaceVisuals)
          .spatialPreview(widget.map);
      if (!mounted || request != _request) {
        preview.dispose();
        return;
      }
      setState(() {
        _preview?.dispose();
        _preview = preview;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() => _error = 'Sprites indisponibles : $error');
    }
  }

  @override
  void dispose() {
    _request++;
    _preview?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.visuals;
    final scene = widget.map.spatialScene;
    if (source is! SpatialWorkspaceVisuals || scene == null) {
      return const Center(
        child: StudioNotice('L’aperçu de cette carte 3D est indisponible.'),
      );
    }
    final visuals = source as SpatialWorkspaceVisuals;
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: SpatialSceneView(
            scene: scene,
            models: widget.project.models3d,
            loadModel: visuals.readModel,
            groundMap: widget.map,
            groundProject: widget.project,
            loadGroundImage: visuals.readGroundImage,
            controller: widget.controller,
            onCell: widget.onCell,
            onContent: widget.onContent,
            onHover: widget.onHover,
            onDragStart: widget.onDragStart,
            onDragUpdate: widget.onDragUpdate,
            onDragEnd: widget.onDragEnd,
            onDragCancel: widget.onDragCancel,
            selectContent: widget.selectContent,
            selectedContent: widget.selectedContent,
            selectionColor: colors.primary,
            cellOverlays: widget.overlays,
            actorFrames: (dt) => {
              ...?_preview?.frames,
              ...?widget.actorFrames?.call(dt),
            },
            cameraPose: widget.cameraPose,
            background: colors.surfaceContainerLowest,
            ground: colors.primaryContainer,
            edge: colors.outlineVariant,
            errorBuilder: (_, error) => Center(
              child: StudioNotice(
                'Rendu 3D indisponible : $error',
                isError: true,
              ),
            ),
          ),
        ),
        if (_error != null)
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: StudioNotice(_error!, isError: true),
          ),
      ],
    );
  }
}
