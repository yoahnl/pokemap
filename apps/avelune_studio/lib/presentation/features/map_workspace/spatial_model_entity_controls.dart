import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_editing.dart';
import 'package:map_core/map_core.dart' hide SpatialMapOperations;

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';

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
    final generated =
        instance.id.startsWith('smt_') ||
        map.layers.any(
          (layer) => switch (layer) {
            EnvironmentLayer() => layer.content.generatedPlacementIds.contains(
              instance.id,
            ),
            BorderLayer() => layer.content.features.any(
              (feature) => feature.generatedPlacementIds.contains(instance.id),
            ),
            _ => false,
          },
        );
    if (generated) return const SizedBox.shrink();
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
          onChanged: document.saving
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
