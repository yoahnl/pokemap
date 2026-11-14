part of 'spatial_model_editing_commands.dart';

extension SpatialModelBindingCommands on SpatialModelEditingCommands {
  Future<bool> configureVisibility(
    String id,
    NarrativeEventConditionExpression? value,
  ) {
    final publish = document.configureSpatialModelVisibility;
    if (publish == null) return Future.value(false);
    return publish(
      id,
      value is NarrativeEventConditionAll && value.children.isEmpty
          ? null
          : value,
    );
  }

  bool canConfigureFieldObstacle(String id) {
    final instance = selected(id);
    if (instance == null) return false;
    final bound = document.current.entities
        .where((entity) => entity.id == instance.entityId)
        .firstOrNull;
    final model = project.models3d
        .where((model) => model.id == instance.modelId)
        .firstOrNull;
    return bound?.fieldObstacle != null ||
        instance.blocksMovement &&
            instance.animationIndex == null &&
            instance.clip == null &&
            model != null &&
            model.inspection.animations.isEmpty &&
            model.rampProfile == null &&
            (instance.entityId == null || bound?.kind == MapEntityKind.custom);
  }

  Iterable<MapEntity> bindableEntities(String id) {
    final occupied = {
      for (final model in document.current.spatialScene!.instances)
        if (model.id != id && model.entityId != null) model.entityId!,
    };
    return document.current.entities.where(
      (entity) =>
          entity.kind != MapEntityKind.npc &&
          !occupied.contains(entity.id) &&
          (entity.item == null ||
              entity.item!.pickupMode == ItemPickupMode.once &&
                  entity.item!.respawnPolicy == ItemRespawnPolicy.none),
    );
  }

  Future<bool> configureFieldObstacle(
    String id,
    MapEntityFieldObstacleData? value,
  ) async {
    if (document.saving) return false;
    final publish = document.configureSpatialFieldObstacle;
    if (publish != null) return publish(id, value);
    try {
      document.commit(
        const SpatialMapActions().configureFieldObstacle(
          document.current,
          project: project,
          instanceId: id,
          fieldObstacle: value,
        ),
      );
      document.error = null;
      return true;
    } on Object {
      document.error = 'Choisissez un décor statique bloquant sans autre rôle de jeu pour Coupe, Force ou Éclate-Roc.';
      return false;
    }
  }

  bool bindEntity(String instanceId, String entityId) {
    if (document.saving) return false;
    try {
      final instance = selected(instanceId);
      if (instance == null) {
        throw const FormatException('Missing model instance.');
      }
      final next = instance.copyWith(
        entityId: entityId.isEmpty ? null : entityId,
        clearEntityBinding: entityId.isEmpty,
      );
      document.commit(
        SpatialModelEditingCommands.operations.upsertInstance(
          document.current,
          next,
          model: project.models3d
              .where((model) => model.id == next.modelId)
              .firstOrNull,
        ),
      );
      document.error = null;
      return true;
    } on FormatException {
      document.error = 'Choisissez un élément de cette carte qui n’est pas déjà lié à un autre décor.';
      return false;
    }
  }
}
