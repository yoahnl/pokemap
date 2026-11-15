part of 'spatial_map_editing_viewport.dart';

extension _SpatialGizmoEditing on _SpatialMapEditingViewportState {
  List<MapSelectionTarget> get gizmoTargets =>
      locked ||
          editingExterior ||
          widget.view.tool != StudioMapTool.select ||
          widget.view.pendingMove != null
      ? const []
      : widget.view.selectionIn(editingDocument.current.id);

  List<SpatialModelInstance> get gizmoInstances {
    final instances = {
      for (final instance in editingDocument.current.spatialScene!.instances)
        instance.id: instance,
    };
    return [
      for (final target in gizmoTargets)
        if (target.family == MapSelectionFamily.decor) ?instances[target.id],
    ];
  }

  Model3dVector3 gizmoPosition(SpatialModelInstance instance) {
    final axis = gizmoAxis;
    final position = instance.position;
    if (axis == null || gizmoStep == 0) return position;
    if (axis == SpatialGizmoAxis.z) {
      return Model3dVector3(
        x: position.x,
        y: position.y + gizmoStep,
        z: position.z,
      );
    }
    final scene = editingDocument.current.spatialScene!;
    final x = position.x + (axis == SpatialGizmoAxis.x ? gizmoStep : 0);
    final z = position.z + (axis == SpatialGizmoAxis.y ? gizmoStep : 0);
    final elevation =
        position.y -
        scene.worldHeightAt(
          position.x,
          position.z,
          excludingRampSurface: instance.id,
        );
    return Model3dVector3(
      x: x,
      y:
          scene.worldHeightAt(x, z, excludingRampSurface: instance.id) +
          elevation,
      z: z,
    );
  }

  List<SpatialSceneContentPreview> get gizmoPreviews =>
      gizmoAxis == null || gizmoStep == 0
      ? const []
      : [
          for (final instance in gizmoInstances)
            SpatialSceneContentPreview(
              kind: SpatialSceneContentKind.model,
              id: instance.id,
              position: gizmoPosition(instance),
            ),
        ];

  void resetGizmo() {
    gizmoAxis = null;
    gizmoStep = 0;
  }

  void dragGizmo(SpatialGizmoAxis axis, double distance, bool fine) {
    final step = spatialGizmoStep(axis, distance, fine: fine);
    if (axis == gizmoAxis && step == gizmoStep) return;
    gizmoAxis = axis;
    gizmoStep = step;
    widget.onChanged();
  }

  void finishGizmo() {
    final axis = gizmoAxis, step = gizmoStep;
    final targets = gizmoTargets;
    resetGizmo();
    if (axis != null && step != 0 && targets.isNotEmpty) {
      try {
        MapSelectionCommands(editingDocument, widget.project).translate(
          targets,
          dx: axis == SpatialGizmoAxis.x ? step : 0,
          dz: axis == SpatialGizmoAxis.y ? step : 0,
          elevation: axis == SpatialGizmoAxis.z ? step : 0,
        );
      } on Object catch (failure) {
        editingDocument.error = mapFailureMessage(failure);
      }
    }
    widget.onChanged();
  }

  void cancelGizmo() {
    resetGizmo();
    widget.onChanged();
  }

  Widget? gizmoOverlay(BuildContext context) {
    final instances = gizmoInstances;
    if (instances.isEmpty) {
      resetGizmo();
      return null;
    }
    final scheme = Theme.of(context).colorScheme;
    final tokens = StudioColors.of(context);
    return SpatialTransformGizmo(
      origin: gizmoPosition(instances.first),
      project: camera.projectToViewport,
      repaint: Listenable.merge([camera, widget.view.transform]),
      colors: (x: scheme.error, y: tokens.success, z: tokens.canvasSelection),
      onDrag: dragGizmo,
      onEnd: finishGizmo,
      onCancel: cancelGizmo,
    );
  }
}
