import 'package:map_core/map_core_domain.dart';

import 'editable_map_document.dart';
import 'map_context_menu_model.dart';
import 'map_selection_commands.dart';
import 'map_selection_context.dart';
import 'map_workspace_editing_state.dart';
import 'spatial_model_editing_commands.dart';

sealed class MapSelectionProperties {
  const MapSelectionProperties();
}

final class SpatialModelProperties extends MapSelectionProperties {
  const SpatialModelProperties({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.z,
    required this.rotation,
    required this.scale,
    required this.animated,
  });
  final String id, name;
  final double x, y, z, rotation, scale;
  final bool? animated;
}

final class GridElementProperties extends MapSelectionProperties {
  const GridElementProperties({
    required this.target,
    required this.name,
    required this.position,
  });
  final MapSelectionTarget target;
  final String name;
  final GridPos position;
}

final class GroupSelectionProperties extends MapSelectionProperties {
  const GroupSelectionProperties(this.count);
  final int count;
}

MapSelectionProperties? mapSelectionProperties(
  EditableMapDocument document,
  ProjectManifest project,
  List<MapSelectionTarget> targets,
) {
  if (targets.isEmpty) return null;
  if (targets.length > 1) return GroupSelectionProperties(targets.length);
  final target = targets.single;
  final spatial = SpatialModelEditingCommands(document, project);
  final instance = target.family == MapSelectionFamily.decor
      ? spatial.selected(target.id)
      : null;
  if (instance != null) {
    final model = project.models3d
        .where((item) => item.id == instance.modelId)
        .firstOrNull;
    return SpatialModelProperties(
      id: instance.id,
      name: model?.name ?? instance.modelId,
      x: instance.position.x,
      y: instance.position.z,
      z: spatial.elevationOf(instance),
      rotation: instance.rotationDegrees,
      scale: instance.scale,
      animated: model == null || model.inspection.animations.isEmpty
          ? null
          : instance.animationIndex != null,
    );
  }
  final placement = locateMapContextTarget(
    document,
    project,
    contextFamilyOf(target.family),
    target.id,
  );
  if (placement == null) return null;
  return GridElementProperties(
    target: target,
    name: placement.target.label,
    position: placement.at,
  );
}

class MapSelectionPropertyCommands {
  const MapSelectionPropertyCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;

  void setSpatial(
    String id, {
    double? x,
    double? y,
    double? z,
    double? rotation,
    double? scale,
  }) => SpatialModelEditingCommands(
    document,
    project,
  ).update(id, x: x, z: y, heightOffset: z, rotation: rotation, scale: scale);

  void setAnimated(String id, {required bool animated}) {
    final commands = SpatialModelEditingCommands(document, project);
    final instance = commands.selected(id);
    if (instance == null) throw StateError('Ce décor n’existe plus.');
    if (!animated) {
      commands.update(id, clearAnimation: true);
      return;
    }
    final clip = project.models3d
        .where((model) => model.id == instance.modelId)
        .firstOrNull
        ?.inspection
        .animations
        .firstOrNull;
    if (clip == null) {
      throw StateError('Ce modèle ne contient aucune animation.');
    }
    commands.update(id, animationIndex: clip.index);
  }

  void setGrid(GridElementProperties element, GridPos position) =>
      MapSelectionCommands(document, project).move(
        [element.target],
        position.x - element.position.x,
        position.y - element.position.y,
      );
}
