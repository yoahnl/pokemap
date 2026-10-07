import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'spatial_scene_components.dart';
import 'spatial_selection.dart';

final class SpatialModelPlacementPreview {
  const SpatialModelPlacementPreview({
    required this.modelId,
    required this.position,
    this.rotationDegrees = 0,
    this.scale = 1,
  });

  final String modelId;
  final Model3dVector3 position;
  final double rotationDegrees, scale;
}

final class SpatialPlacementPreviewRenderer {
  SpatialPlacementPreviewRenderer(
    Component parent, {
    required this.loadModel,
    this.onStatus,
  }) : _components = SpatialSceneComponents(parent);

  final Future<Model> Function(ProjectModel3dEntry) loadModel;
  final ValueChanged<Object?>? onStatus;
  final SpatialSceneComponents _components;
  ModelComponent? get component => _component;
  _PlacementModelComponent? _component;
  ProjectModel3dEntry? _definition;
  int _generation = 0;
  bool _closed = false;

  Future<void> sync({
    required SpatialModelPlacementPreview? preview,
    required List<ProjectModel3dEntry> models,
    required Color color,
    Offset offset = Offset.zero,
  }) async {
    if (_closed) return;
    final definition = models
        .where((entry) => entry.id == preview?.modelId)
        .firstOrNull;
    if (preview == null || definition == null) {
      clear();
      onStatus?.call(null);
      return;
    }
    final current = _component;
    if (current != null && _definition == definition) {
      current.sync(preview, definition, color, offset);
      onStatus?.call(null);
      return;
    }
    final ticket = ++_generation;
    _components.dispose();
    _component = null;
    _definition = null;
    try {
      final model = await loadModel(definition);
      if (_closed || ticket != _generation) return;
      final next = _PlacementModelComponent(model: model)
        ..sync(preview, definition, color, offset);
      _component = next;
      _definition = definition;
      final committed = await _components.replace([
        next,
      ], isCurrent: () => !_closed && ticket == _generation);
      if (ticket == _generation && !_closed) {
        if (committed) {
          onStatus?.call(null);
        } else {
          clear();
        }
      }
    } on Object catch (error) {
      if (_closed || ticket != _generation) return;
      if (onStatus != null) {
        onStatus!(error);
        return;
      }
      rethrow;
    }
  }

  void clear() {
    _generation++;
    _components.dispose();
    _component = null;
    _definition = null;
  }

  void dispose() {
    _closed = true;
    clear();
  }
}

final class _PlacementModelComponent extends ModelComponent {
  _PlacementModelComponent({required super.model});

  double? _frameScale;
  Color? _frameColor;
  List<MeshComponent> _frame = [];
  UnlitMaterial? _frameMaterial;

  void sync(
    SpatialModelPlacementPreview preview,
    ProjectModel3dEntry definition,
    Color color,
    Offset offset,
  ) {
    final combinedScale = definition.scale * preview.scale;
    rotation.setFrom(
      Quaternion.axisAngle(
        Vector3(0, 1, 0),
        preview.rotationDegrees * math.pi / 180,
      ),
    );
    scale.setValues(combinedScale, combinedScale, combinedScale);
    final pivot =
        Vector3(definition.pivot.x, definition.pivot.y, definition.pivot.z) *
        combinedScale;
    rotation.rotate(pivot);
    position.setValues(
      preview.position.x + offset.dx - pivot.x,
      preview.position.y - pivot.y,
      preview.position.z + offset.dy - pivot.z,
    );
    if (_frameScale == combinedScale && _frameColor == color) return;
    final material = _frameMaterial ??= UnlitMaterial(albedoColor: color);
    material.albedoColor = color;
    if (_frame.isEmpty) {
      _frame = [
        for (var index = 0; index < 12; index++)
          MeshComponent(
            mesh: CuboidMesh(size: Vector3.all(1), material: material),
          ),
      ];
      addAll(_frame);
    }
    final bounds = definition.inspection.bounds;
    final thickness = .04 / combinedScale;
    final edges = spatialSelectionEdges(
      Vector3(bounds.min.x, bounds.min.y, bounds.min.z),
      Vector3(bounds.max.x, bounds.max.y, bounds.max.z),
      thickness,
    );
    for (final (index, (start, end)) in edges.indexed) {
      _frame[index].position.setFrom((start + end) / 2);
      _frame[index].scale.setFrom(end - start + Vector3.all(thickness));
    }
    _frameScale = combinedScale;
    _frameColor = color;
  }

  @override
  bool isVisible(CameraComponent3D camera) => true;
}
