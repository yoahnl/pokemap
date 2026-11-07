import '../events/event_conditions.dart';
import '../../shared/widgets/buttons/studio_button.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart' hide SpatialMapOperations;

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'spatial_model_roles.dart';

class SpatialModelEntityControls extends StatelessWidget {
  const SpatialModelEntityControls({
    super.key,
    required this.document,
    required this.project,
    required this.instance,
    required this.onChanged,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final SpatialModelInstance instance;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final map = document.current;
    final ownership = SpatialEntityModelOwnership(map);
    final manual = ownership.isManual(instance.id);
    final visibility = _SpatialModelVisibilityControls(
      document: document,
      project: project,
      instance: instance,
      onChanged: onChanged,
    );
    final roles = SpatialModelRolesSummary(
      map: map,
      project: project,
      instance: instance,
    );
    if (!ownership.canBind(instance.id)) {
      final protected =
          instance.id.startsWith('smt_') ||
          map.layers.whereType<BorderLayer>().any(
            (layer) => layer.content.features.any(
              (feature) => feature.generatedPlacementIds.contains(instance.id),
            ),
          );
      return protected
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [roles, const SizedBox(height: 12), visibility],
            );
    }
    final bound = map.entities
        .where((entity) => entity.id == instance.entityId)
        .firstOrNull;
    final obstacle = bound?.fieldObstacle;
    final model = project.models3d
        .where((model) => model.id == instance.modelId)
        .firstOrNull;
    final canConfigure =
        obstacle != null ||
        instance.blocksMovement &&
            instance.animationIndex == null &&
            instance.clip == null &&
            model != null &&
            model.inspection.animations.isEmpty &&
            model.rampProfile == null &&
            (instance.entityId == null || bound?.kind == MapEntityKind.custom);
    void configure(MapEntityFieldObstacleData? value) {
      final publish = document.configureSpatialFieldObstacle;
      if (publish != null) {
        unawaited(publish(instance.id, value).then((_) => onChanged()));
        return;
      }
      try {
        document.commit(
          const SpatialMapActions().configureFieldObstacle(
            document.current,
            project: project,
            instanceId: instance.id,
            fieldObstacle: value,
          ),
        );
        document.error = null;
      } on Object {
        document.error = 'Choisissez un décor statique bloquant sans autre rôle de jeu pour Coupe, Force ou Éclate-Roc.';
      }
      onChanged();
    }

    final occupied = {
      for (final model in map.spatialScene!.instances)
        if (model.id != instance.id && model.entityId != null) model.entityId!,
    };
    final entities = map.entities.where(
      (entity) =>
          entity.kind != MapEntityKind.npc &&
          !occupied.contains(entity.id) &&
          (entity.item == null ||
              entity.item!.pickupMode == ItemPickupMode.once &&
                  entity.item!.respawnPolicy == ItemRespawnPolicy.none),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        roles,
        const SizedBox(height: 12),
        visibility,
        if (!manual) ...[
        StudioSelect(
          key: const ValueKey('spatial-model-field-obstacle'),
          label: 'Obstacle CS',
          value: obstacle?.kind.name ?? '',
          options: const {
            '': 'Aucun',
            'cutTree': 'Coupe',
            'strengthBoulder': 'Force · rocher à pousser',
            'rockSmashRock': 'Éclate-Roc',
          },
          onChanged: document.saving || !canConfigure
              ? null
              : (value) => configure(
                  value.isEmpty
                      ? null
                      : MapEntityFieldObstacleData(
                          kind: FieldObstacleKind.values.byName(value),
                          resetPolicy:
                              obstacle?.resetPolicy ??
                              FieldObstacleResetPolicy.mapInstance,
                        ),
                ),
        ),
        if (obstacle == null && !canConfigure)
          if (spatialFieldObstacleRefusal(instance, model, bound)
              case final refusal?)
            StudioNotice(
              refusal,
              key: const ValueKey('spatial-model-field-obstacle-refusal'),
            ),
        if (obstacle != null) ...[
          const SizedBox(height: 8),
          StudioSelect(
            key: const ValueKey('spatial-model-field-obstacle-reset'),
            label: 'Après utilisation',
            value: obstacle.resetPolicy.name,
            options: const {
              'persistent': 'Conservé dans la sauvegarde',
              'mapInstance': 'Réinitialisé à la nouvelle instance',
            },
            onChanged: document.saving
                ? null
                : (value) => configure(
                    MapEntityFieldObstacleData(
                      kind: obstacle.kind,
                      resetPolicy: FieldObstacleResetPolicy.values.byName(
                        value,
                      ),
                    ),
                  ),
          ),
        ],
        const SizedBox(height: 8),
        ],
        StudioSelect(
          key: const ValueKey('spatial-model-entity-binding'),
          label: 'Élément du jeu lié',
          value: instance.entityId ?? '',
          options: {
            '': 'Aucun · décor simple',
            for (final entity in entities)
              entity.id: entity.name.trim().isEmpty
                  ? 'Élément en X ${entity.pos.x}, Y ${entity.pos.y}'
                  : entity.name,
          },
          onChanged: document.saving || obstacle != null
              ? null
              : (id) {
                  try {
                    final next = instance.copyWith(
                      entityId: id.isEmpty ? null : id,
                      clearEntityBinding: id.isEmpty,
                    );
                    document.commit(
                      const SpatialMapOperations().upsertInstance(
                        map,
                        next,
                        model: project.models3d
                            .where((model) => model.id == next.modelId)
                            .firstOrNull,
                      ),
                    );
                    document.error = null;
                  } on FormatException {
                    document.error = 'Choisissez un élément de cette carte qui n’est pas déjà lié à un autre décor.';
                  }
                  onChanged();
                },
        ),
        if (instance.entityId != null) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'Le décor et l’élément du jeu se déplacent ensemble. Si l’objet est ramassé, son modèle et sa collision disparaissent ensemble.',
          ),
        ],
      ],
    );
  }
}

class _SpatialModelVisibilityControls extends StatelessWidget {
  const _SpatialModelVisibilityControls({
    required this.document,
    required this.project,
    required this.instance,
    required this.onChanged,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final SpatialModelInstance instance;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final publish = document.configureSpatialModelVisibility;
    if (publish == null) {
      return const StudioNotice(
        'La publication ciblée des conditions de visibilité est indisponible dans cet atelier.',
      );
    }
    void apply(NarrativeEventConditionExpression? value) {
      unawaited(publish(instance.id, value).then((_) => onChanged()));
    }

    return AbsorbPointer(
      absorbing: document.saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StudioNotice(
            'La condition masque le modèle visuel et conserve son élément de jeu, son interaction et sa collision.',
          ),
          EventConditions(
            expression:
                instance.visibilityCondition ??
                NarrativeEventConditionExpression.all(const []),
            facts: project.facts,
            records: project.eventRegistry?.records ?? const [],
            mapId: document.current.id,
            entityId: instance.entityId,
            onChanged: (value) => apply(
              value is NarrativeEventConditionAll && value.children.isEmpty
                  ? null
                  : value,
            ),
          ),
          if (instance.visibilityCondition != null)
            StudioButton(
              label: 'Toujours afficher ce modèle',
              secondary: true,
              onPressed: () => apply(null),
            ),
        ],
      ),
    );
  }
}
