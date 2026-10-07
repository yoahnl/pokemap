import 'package:map_core/map_core.dart';
import 'editable_map_document.dart';

class SpatialModelEditingCommands {
  const SpatialModelEditingCommands(this.document, this.project);
  final EditableMapDocument document;
  final ProjectManifest project;
  static const operations = SpatialMapOperations();
  SpatialModelInstance? selected([String? id]) => document
      .current
      .spatialScene
      ?.instances
      .where((item) => item.id == (id ?? document.selectedId))
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

  Model3dVector3 _position(double x, double z) {
    final scene = document.current.spatialScene!;
    if (!x.isFinite ||
        !z.isFinite ||
        x < 0 ||
        z < 0 ||
        x >= scene.width ||
        z >= scene.depth) {
      throw StateError('Placez le décor à l’intérieur de la carte.');
    }
    return Model3dVector3(x: x, y: scene.worldHeightAt(x, z), z: z);
  }

  SpatialModelInstance place(ProjectModel3dEntry model, GridPos cell) =>
      placeAt(model, Model3dVector3(x: cell.x + .5, y: 0, z: cell.y + .5));

  SpatialModelInstance placeAt(
    ProjectModel3dEntry model,
    Model3dVector3 position,
  ) {
    if (!project.models3d.any((item) => item.id == model.id)) {
      throw StateError('Cette ressource n’existe plus.');
    }
    final instance = SpatialModelInstance(
      id: _id(),
      modelId: model.id,
      position: _position(position.x, position.z),
    );
    document.commit(operations.upsertInstance(document.current, instance));
    document.selectedId = instance.id;
    return instance;
  }

  void update(
    String id, {
    double? x,
    double? z,
    double? rotation,
    double? scale,
    bool? blocksMovement,
    int? heightLevel,
  }) {
    final instance = selected(id);
    if (instance == null) throw StateError('Ce décor n’existe plus.');
    if (heightLevel != null && (heightLevel < 0 || heightLevel > 32)) {
      throw StateError('Choisissez une hauteur de 0 à 32 blocs.');
    }
    final scene = document.current.spatialScene!;
    final elevated =
        instance.position.y -
        scene.worldHeightAt(instance.position.x, instance.position.z);
    final alignment =
        elevated - (elevated / scene.levelHeight).round() * scene.levelHeight;
    final anchor = _position(
      x ?? instance.position.x,
      z ?? instance.position.z,
    );
    final next = instance.copyWith(
      position: x == null && z == null && heightLevel == null
          ? null
          : Model3dVector3(
              x: anchor.x,
              y:
                  anchor.y +
                  (heightLevel == null
                      ? elevated
                      : heightLevel * scene.levelHeight + alignment),
              z: anchor.z,
            ),
      rotationDegrees: rotation,
      scale: scale,
      blocksMovement: blocksMovement,
    );
    document.commit(operations.upsertInstance(document.current, next));
  }

  void delete(String id) =>
      document.commit(operations.deleteInstance(document.current, id));
  void duplicate(String id) {
    final item = selected(id);
    if (item == null) throw StateError('Ce décor n’existe plus.');
    final next = SpatialModelInstance(
      id: _id(),
      modelId: item.modelId,
      position: item.position,
      rotationDegrees: item.rotationDegrees,
      scale: item.scale,
      animationIndex: item.animationIndex,
      blocksMovement: item.blocksMovement,
    );
    document.commit(operations.upsertInstance(document.current, next));
    document.selectedId = next.id;
  }
}
