import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring_editing.dart';

import 'editable_map_document.dart';

class SpatialModelEditingCommands {
  const SpatialModelEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static const operations = SpatialMapOperations();
  static const environments = EnvironmentEditing();
  static const paintedTerrainMessage =
      'Ces pièces appartiennent à un terrain peint. Choisissez Terrains et son calque pour modifier ou effacer les cases.';
  static const generatedBorderMessage =
      'Cette pièce appartient à une bordure générée. Choisissez Bordures et son tracé pour la régénérer ou le supprimer.';
  void _requireIndependent(String id) {
    if (document.isElementLocked('model', id)) throw StateError('Ce décor est verrouillé. Déverrouillez-le dans Éléments.');
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

  void delete(String id) {
    _requireIndependent(id);
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
  }

  void duplicate(String id) {
    _requireIndependent(id);
    final item = selected(id);
    if (item == null) throw StateError('Ce décor n’existe plus.');
    final next = SpatialModelInstance(
      id: _id(),
      modelId: item.modelId,
      position: item.position,
      rotationDegrees: item.rotationDegrees,
      scale: item.scale,
      animationIndex: item.animationIndex,
      animationLoop: item.animationLoop,
      animationSpeed: item.animationSpeed,
      blocksMovement: item.blocksMovement,
      castsShadows: item.castsShadows,
      clip: item.clip,
    );
    final source = owner(id);
    final map = source == null
        ? document.current
        : environments.addGeneratedPlacement(
            project,
            document.current,
            layerId: source.layerId,
            areaId: source.areaId,
            placementId: next.id,
            modelId: next.modelId,
            pos: GridPos(
              x: next.position.x.floor(),
              y: next.position.z.floor(),
            ),
          );
    final model = project.models3d
        .where((model) => model.id == item.modelId)
        .firstOrNull;
    if (model?.rampProfile != null) {
      final scene = map.spatialScene!;
      final elevated =
          item.position.y -
          scene.worldHeightAt(
            item.position.x,
            item.position.z,
            excludingRampSurface: item.id,
          );
      for (var distance = 1; distance < scene.width + scene.depth; distance++) {
        for (final offset in [
          (distance, 0),
          (-distance, 0),
          (0, distance),
          (0, -distance),
        ]) {
          final x = next.position.x + offset.$1;
          final z = next.position.z + offset.$2;
          if (x < 0 || z < 0 || x >= scene.width || z >= scene.depth) continue;
          final candidate = next.copyWith(
            position: Model3dVector3(
              x: x,
              y:
                  scene.worldHeightAt(x, z, excludingRampSurface: item.id) +
                  elevated,
              z: z,
            ),
          );
          try {
            final result = operations.upsertInstance(
              map,
              candidate,
              model: model,
            );
            document.commit(result);
            document.selectedId = next.id;
            return;
          } on FormatException {
            continue;
          }
        }
      }
      throw StateError(
        'Aucune place libre pour dupliquer cet escalier et sa pente.',
      );
    }
    if (map.spatialScene!.navigation.ramps.any(
      (ramp) => ramp.surfaceInstanceId == item.id,
    )) {
      throw StateError(
        'Définissez le comportement Escalier dans Ressources avant de dupliquer cet ancien assemblage manuel.',
      );
    }
    document.commit(operations.upsertInstance(map, next, model: model));
    document.selectedId = next.id;
  }
}
