import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../../../application/services/environment_layer_tile_layer_attachment_resolver.dart';

const mapLayerEnvironmentAttachmentDeletionReason =
    'Impossible de supprimer ce layer : un environnement lui est attaché.';

@immutable
final class MapLayerDeletionImpact {
  const MapLayerDeletionImpact({
    required this.layerId,
    required this.placedElementCount,
    required this.affectedMapEventIds,
    required this.environmentGeneratedCount,
    required this.environmentAttachmentCount,
    required this.blockingReasons,
  });

  final String layerId;
  final int placedElementCount;
  final List<String> affectedMapEventIds;
  final int environmentGeneratedCount;
  final int environmentAttachmentCount;
  final List<String> blockingReasons;

  bool get isBlocked => blockingReasons.isNotEmpty;
}

/// Computes every currently-known consequence of deleting one map layer.
///
/// The projector does not mutate the map and intentionally mirrors
/// `DeleteMapLayerUseCase`: only placements hosted by the deleted layer are
/// removed. Relationships that would survive with a dangling reference are
/// surfaced as blockers.
final class MapLayerDeletionImpactProjector {
  const MapLayerDeletionImpactProjector();

  MapLayerDeletionImpact project({
    required MapData map,
    required String layerId,
  }) {
    final normalizedLayerId = layerId.trim();
    final layerIndex = map.layers.indexWhere(
      (layer) => layer.id == normalizedLayerId,
    );
    if (layerIndex < 0) {
      throw ArgumentError.value(
        layerId,
        'layerId',
        'Layer does not exist in the map',
      );
    }

    final layer = map.layers[layerIndex];
    final removedPlacements = map.placedElements
        .where((placement) => placement.layerId == normalizedLayerId)
        .toList(growable: false);
    final removedPlacementIds = {
      for (final placement in removedPlacements) placement.id,
    };
    final placementsById = {
      for (final placement in map.placedElements) placement.id: placement,
    };
    final environmentLayers =
        map.layers.whereType<EnvironmentLayer>().toList(growable: false);
    final orphanedGeneratedIds = <String>{};

    for (final environment in environmentLayers) {
      final generatedIds = environment.content.generatedPlacementIds.toSet();
      if (environment.id == normalizedLayerId) {
        for (final generatedId in generatedIds) {
          final placement = placementsById[generatedId];
          if (placement == null ||
              removedPlacementIds.contains(generatedId) ||
              _hasSurvivingEnvironmentOwner(
                environmentLayers,
                deletedEnvironmentId: environment.id,
                generatedPlacementId: generatedId,
              )) {
            continue;
          }
          orphanedGeneratedIds.add(generatedId);
        }
        continue;
      }

      for (final generatedId in generatedIds) {
        if (removedPlacementIds.contains(generatedId)) {
          orphanedGeneratedIds.add(generatedId);
        }
      }
    }

    final affectedMapEventIds = map.events
        .where((event) => event.position.layerId == normalizedLayerId)
        .map((event) => event.id)
        .toSet()
        .toList(growable: false)
      ..sort();
    final attachments = layer is TileLayer
        ? validEnvironmentLayerAttachmentsForTileLayer(
            map,
            normalizedLayerId,
          )
        : const <EnvironmentLayer>[];

    final blockingReasons = <String>[
      if (attachments.isNotEmpty) mapLayerEnvironmentAttachmentDeletionReason,
      if (affectedMapEventIds.isNotEmpty)
        _mapEventDeletionReason(affectedMapEventIds.length),
      if (orphanedGeneratedIds.isNotEmpty)
        _generatedDependencyDeletionReason(orphanedGeneratedIds.length),
    ];

    return MapLayerDeletionImpact(
      layerId: normalizedLayerId,
      placedElementCount: removedPlacements.length,
      affectedMapEventIds: List<String>.unmodifiable(affectedMapEventIds),
      environmentGeneratedCount: orphanedGeneratedIds.length,
      environmentAttachmentCount: attachments.length,
      blockingReasons: List<String>.unmodifiable(blockingReasons),
    );
  }
}

bool _hasSurvivingEnvironmentOwner(
  List<EnvironmentLayer> environments, {
  required String deletedEnvironmentId,
  required String generatedPlacementId,
}) {
  return environments.any(
    (environment) =>
        environment.id != deletedEnvironmentId &&
        environment.content.generatedPlacementIds.contains(
          generatedPlacementId,
        ),
  );
}

String _mapEventDeletionReason(int count) {
  if (count == 1) {
    return 'Impossible de supprimer ce layer : '
        '1 événement de map y est attaché.';
  }
  return 'Impossible de supprimer ce layer : '
      '$count événements de map y sont attachés.';
}

String _generatedDependencyDeletionReason(int count) {
  if (count == 1) {
    return 'Impossible de supprimer ce layer : '
        '1 élément généré deviendrait orphelin.';
  }
  return 'Impossible de supprimer ce layer : '
      '$count éléments générés deviendraient orphelins.';
}
