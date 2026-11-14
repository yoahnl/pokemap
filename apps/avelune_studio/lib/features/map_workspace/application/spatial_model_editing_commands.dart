import 'package:map_core/map_core_domain.dart';
import 'package:map_authoring/map_authoring_editing.dart';

import 'editable_map_document.dart';

part 'spatial_model_binding_commands.dart';
part 'spatial_model_duplication.dart';

class SpatialModelEditingCommands {
  const SpatialModelEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;

  bool number(String text, void Function(double) update) {
    final value = double.tryParse(text.trim());
    if (value == null || !value.isFinite) {
      document.error = 'Saisissez un nombre valide.';
      return false;
    }
    try {
      update(value);
      return true;
    } on Object catch (error) {
      document.error = error.toString();
      return false;
    }
  }

  static const operations = SpatialMapOperations();
  static const environments = EnvironmentEditing();
  static const paintedTerrainMessage =
      'Ces pièces appartiennent à un terrain peint. Choisissez Terrains et son calque pour modifier ou effacer les cases.';
  static const generatedBorderMessage =
      'Cette pièce appartient à une bordure générée. Choisissez Bordures et son tracé pour la régénérer ou le supprimer.';
  void _requireIndependent(String id) {
    if (document.isElementHidden('model', id)) {
      throw StateError('Ce décor est masqué. Affichez-le dans Éléments.');
    }
    if (document.isElementLocked('model', id)) {
      throw StateError(
        'Ce décor est verrouillé. Déverrouillez-le dans Éléments.',
      );
    }
    if (id.startsWith('smt_')) throw StateError(paintedTerrainMessage);
    if (borderOwner(id) != null) throw StateError(generatedBorderMessage);
  }

  ({String layerId, String featureId})? borderOwner(String id) {
    for (final layer in document.current.layers.whereType<BorderLayer>()) {
      for (final feature in layer.content.features) {
        if (feature.generatedPlacementIds.contains(id)) {
          return (layerId: layer.id, featureId: feature.id);
        }
      }
    }
    return null;
  }

  ({String layerId, String areaId})? owner(String id) {
    for (final layer in document.current.layers.whereType<EnvironmentLayer>()) {
      if (!layer.content.targetsSpatialTerrain) continue;
      for (final area in layer.content.areas) {
        if (area.generatedPlacementIds.contains(id)) {
          return (layerId: layer.id, areaId: area.id);
        }
      }
    }
    return null;
  }

  SpatialModelInstance? selected([String? id]) => document
      .current
      .spatialScene
      ?.instances
      .where(
        (item) =>
            !item.id.startsWith('smt_') &&
            item.id == (id ?? document.selectedId),
      )
      .firstOrNull;
  String _id() {
    final ids = document.current.spatialScene!.instances
        .map((item) => item.id)
        .toSet();
    var index = 1;
    while (ids.contains('model_$index')) {
      index++;
    }
    return 'model_$index';
  }

  Model3dVector3 _position(double x, double z, {String? excludingRampSurface}) {
    final scene = document.current.spatialScene!;
    if (!x.isFinite ||
        !z.isFinite ||
        x < 0 ||
        z < 0 ||
        x >= scene.width ||
        z >= scene.depth) {
      throw StateError('Placez le décor à l’intérieur de la carte.');
    }
    return Model3dVector3(
      x: x,
      y: scene.worldHeightAt(x, z, excludingRampSurface: excludingRampSurface),
      z: z,
    );
  }

  SpatialModelInstance place(ProjectModel3dEntry model, GridPos cell) =>
      placeAt(model, Model3dVector3(x: cell.x + .5, y: 0, z: cell.y + .5));

  SpatialModelInstance placeAt(
    ProjectModel3dEntry model,
    Model3dVector3 position,
  ) {
    final currentModel = project.models3d
        .where((item) => item.id == model.id)
        .firstOrNull;
    if (currentModel == null) {
      throw StateError('Cette ressource n’existe plus.');
    }
    final instance = SpatialModelInstance(
      id: _id(),
      modelId: model.id,
      position: _position(position.x, position.z),
      blocksMovement: currentModel.blocksMovementByDefault,
    );
    document.commit(
      operations.upsertInstance(
        document.current,
        instance,
        model: currentModel,
      ),
    );
    document.selectedId = instance.id;
    return selected(instance.id)!;
  }

  void update(
    String id, {
    double? x,
    double? z,
    double? rotation,
    double? scale,
    bool? blocksMovement,
    bool? castsShadows,
    bool clearCastsShadows = false,
    double? heightOffset,
    int? animationIndex,
    bool clearAnimation = false,
    bool? animationLoop,
    double? animationSpeed,
  }) {
    _requireIndependent(id);
    final instance = selected(id);
    if (instance == null) throw StateError('Ce décor n’existe plus.');
    if (animationIndex != null &&
        !project.models3d
            .where((model) => model.id == instance.modelId)
            .any(
              (model) => model.inspection.animations.any(
                (clip) => clip.index == animationIndex,
              ),
            )) {
      throw StateError('Cette animation n’existe pas pour ce décor.');
    }
    if (heightOffset != null && !heightOffset.isFinite) {
      throw StateError('Saisissez un décalage vertical valide.');
    }
    final scene = document.current.spatialScene!;
    final elevated =
        instance.position.y -
        scene.worldHeightAt(
          instance.position.x,
          instance.position.z,
          excludingRampSurface: id,
        );
    final anchor = _position(
      x ?? instance.position.x,
      z ?? instance.position.z,
      excludingRampSurface: id,
    );
    final next = instance.copyWith(
      position: x == null && z == null && heightOffset == null
          ? null
          : Model3dVector3(
              x: anchor.x,
              y: anchor.y + (heightOffset ?? elevated),
              z: anchor.z,
            ),
      rotationDegrees: rotation,
      scale: scale,
      blocksMovement: blocksMovement,
      castsShadows: castsShadows,
      clearCastsShadows: clearCastsShadows,
      animationIndex: animationIndex,
      clearAnimation: clearAnimation,
      animationLoop: animationLoop,
      animationSpeed: animationSpeed,
    );
    final source = owner(id);
    final map = source == null
        ? document.current
        : environments.moveGeneratedPlacement(
            document.current,
            layerId: source.layerId,
            areaId: source.areaId,
            placementId: id,
            pos: GridPos(
              x: next.position.x.floor(),
              y: next.position.z.floor(),
            ),
          );
    document.commit(
      operations.upsertInstance(
        map,
        next,
        model: project.models3d
            .where((model) => model.id == instance.modelId)
            .firstOrNull,
      ),
    );
  }

  void replaceModel(String id, ProjectModel3dEntry model) {
    _requireIndependent(id);
    if (owner(id) != null) {
      throw StateError('Ce décor est piloté par une zone d’environnement.');
    }
    if (selected(id) == null) throw StateError('Ce décor n’existe plus.');
    final current = project.models3d
        .where((item) => item.id == model.id)
        .firstOrNull;
    if (current == null) throw StateError('Cette ressource n’existe plus.');
    document.commit(
      replaceSpatialInstanceModel(
        document.current,
        instanceId: id,
        model: current,
      ),
    );
  }

  bool delete(String id) {
    _requireIndependent(id);
    final problem = document.modelDeletionProblem?.call(id);
    if (problem != null) {
      document.error = problem;
      return false;
    }
    final source = owner(id);
    document.commit(
      source == null
          ? operations.deleteInstance(document.current, id)
          : environments.deleteGeneratedPlacement(
              document.current,
              layerId: source.layerId,
              areaId: source.areaId,
              placementId: id,
            ),
    );
    return true;
  }
}
