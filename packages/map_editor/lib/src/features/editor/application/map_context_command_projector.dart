import 'package:map_core/map_core.dart';

import '../../../application/services/narrative_event_legacy_authoring_guard.dart';
import '../../../application/services/narrative_event_source_dependency_guard.dart';
import 'map_canvas_object_hit_test.dart';
import 'map_canvas_object_move_planner.dart';
import 'map_context_command.dart';
import 'map_context_target.dart';
import 'map_layer_deletion_impact.dart';
import 'map_layer_grouping.dart';
import 'map_placed_element_rotation_planner.dart';
import 'world_map_target_editor_intent.dart';

final class MapContextCommandProjector {
  const MapContextCommandProjector({
    this.eventDependencyGuard = const NarrativeEventSourceDependencyGuard(),
    this.targetEditorResolver = const WorldMapTargetEditorIntentResolver(),
    this.movePlanner = const MapCanvasObjectMovePlanner(),
  });

  final NarrativeEventSourceDependencyGuard eventDependencyGuard;
  final WorldMapTargetEditorIntentResolver targetEditorResolver;
  final MapCanvasObjectMovePlanner movePlanner;

  MapContextCommandProjection project({
    required MapContextTarget target,
    required MapData map,
    required ProjectManifest? project,
    required NarrativeEventBuilderProjectReadModel? eventBuilderReadModel,
    String? activeLayerId,
  }) {
    return switch (target) {
      MapObjectContextTarget() => _projectObject(
          target,
          map: map,
          project: project,
          eventBuilderReadModel: eventBuilderReadModel,
        ),
      MapCellContextTarget() => _projectCell(
          target,
          map: map,
          activeLayerId: activeLayerId,
        ),
      MapLayerContextTarget() => _projectLayer(
          target,
          map: map,
          activeLayerId: activeLayerId,
        ),
    };
  }

  MapContextCommandProjection _projectObject(
    MapObjectContextTarget contextTarget, {
    required MapData map,
    required ProjectManifest? project,
    required NarrativeEventBuilderProjectReadModel? eventBuilderReadModel,
  }) {
    final target = contextTarget.target;
    final moveCapability = movePlanner.canStartMove(
      map: map,
      project: project,
      target: target,
    );
    final legacyMoveBlock = target.kind == MapCanvasObjectKind.mapEvent
        ? narrativeEventLegacyAuthoringBlockReason(
            project,
            kind: NarrativeEventLegacyAuthoringKind.mapEvent,
          )
        : null;
    final targetEditorResolution = targetEditorResolver.resolve(
      target: target,
      map: map,
      project: project,
      eventBuilderReadModel: eventBuilderReadModel,
    );
    final entries = <MapContextCommandEntry>[
      MapContextCommandEntry(
        command: MapContextCommand.move,
        label: 'Déplacer',
        enabled: moveCapability.allowed && legacyMoveBlock == null,
        disabledReason: legacyMoveBlock ?? moveCapability.reason,
      ),
      ..._projectRotations(
        target,
        map: map,
        project: project,
      ),
      MapContextCommandEntry(
        command: MapContextCommand.openTargetEditor,
        label: _openTargetLabel(target.kind),
        enabled: targetEditorResolution is WorldMapTargetEditorReady,
        disabledReason: switch (targetEditorResolution) {
          WorldMapTargetEditorBlocked(:final reason) => reason,
          WorldMapTargetEditorReady() => null,
        },
        startsSection: target.kind == MapCanvasObjectKind.placedElement,
      ),
      _projectObjectDelete(
        target,
        map: map,
        project: project,
      ),
    ];
    return MapContextCommandProjection(
      entries: List<MapContextCommandEntry>.unmodifiable(entries),
      targetEditorResolution: targetEditorResolution,
    );
  }

  Iterable<MapContextCommandEntry> _projectRotations(
    MapCanvasObjectTarget target, {
    required MapData map,
    required ProjectManifest? project,
  }) sync* {
    if (target.kind != MapCanvasObjectKind.placedElement) {
      return;
    }
    final instance = _findPlacedElement(map, target.id);
    if (instance == null) {
      return;
    }
    final requests = <_RotationRequest>[
      (
        command: MapContextCommand.rotateClockwise,
        label: 'Rotation 90° horaire',
        shortcutLabel: 'R',
        targetQuarterTurns: (instance.quarterTurns + 1) % 4,
      ),
      (
        command: MapContextCommand.rotateCounterClockwise,
        label: 'Rotation 90° antihoraire',
        shortcutLabel: 'Shift+R',
        targetQuarterTurns: (instance.quarterTurns + 3) % 4,
      ),
      (
        command: MapContextCommand.rotateHalfTurn,
        label: 'Rotation 180°',
        shortcutLabel: null,
        targetQuarterTurns: (instance.quarterTurns + 2) % 4,
      ),
      (
        command: MapContextCommand.resetRotation,
        label: 'Réinitialiser la rotation',
        shortcutLabel: null,
        targetQuarterTurns: 0,
      ),
    ];
    final planned = <({
      _RotationRequest request,
      MapPlacedElementRotationPlan plan,
    })>[
      for (final request in requests)
        (
          request: request,
          plan: planMapPlacedElementRotation(
            map: map,
            project: project,
            instanceId: target.id,
            targetQuarterTurns: request.targetQuarterTurns,
          ),
        ),
    ];
    if (planned.any(
      (entry) =>
          entry.plan.rejection ==
              MapPlacedElementRotationRejection.environmentGenerated ||
          entry.plan.rejection == MapPlacedElementRotationRejection.tileIndexed,
    )) {
      return;
    }
    for (final entry in planned) {
      yield MapContextCommandEntry(
        command: entry.request.command,
        label: entry.request.label,
        shortcutLabel: entry.request.shortcutLabel,
        enabled: entry.plan.canCommit,
        disabledReason: entry.plan.isNoOp
            ? 'Cette orientation est déjà appliquée.'
            : entry.plan.rejection == null
                ? null
                : _rotationRejectionReason(entry.plan.rejection!),
      );
    }
  }

  MapContextCommandEntry _projectObjectDelete(
    MapCanvasObjectTarget target, {
    required MapData map,
    required ProjectManifest? project,
  }) {
    String? reason;
    switch (target.kind) {
      case MapCanvasObjectKind.placedElement:
        if (!_containsId(map.placedElements, target.id, (entry) => entry.id)) {
          reason = 'Cet élément placé n’existe plus.';
        }
      case MapCanvasObjectKind.entity:
        if (!_containsId(map.entities, target.id, (entry) => entry.id)) {
          reason = 'Cette entité n’existe plus.';
        } else {
          final decision = eventDependencyGuard.inspectEntityDelete(
            registry: project?.eventRegistry,
            mapId: map.id,
            entityId: target.id,
          );
          reason = decision.isAllowed ? null : decision.message;
        }
      case MapCanvasObjectKind.mapEvent:
        if (!_containsId(map.events, target.id, (entry) => entry.id)) {
          reason = 'Cet événement n’existe plus.';
        } else {
          reason = narrativeEventLegacyAuthoringBlockReason(
            project,
            kind: NarrativeEventLegacyAuthoringKind.mapEvent,
          );
        }
      case MapCanvasObjectKind.gameplayZone:
        if (!_containsId(map.gameplayZones, target.id, (entry) => entry.id)) {
          reason = 'Cette zone n’existe plus.';
        }
      case MapCanvasObjectKind.trigger:
        if (!_containsId(map.triggers, target.id, (entry) => entry.id)) {
          reason = 'Ce déclencheur n’existe plus.';
        } else {
          final decision = eventDependencyGuard.inspectTriggerDelete(
            registry: project?.eventRegistry,
            mapId: map.id,
            triggerId: target.id,
          );
          reason = decision.isAllowed ? null : decision.message;
        }
      case MapCanvasObjectKind.warp:
        if (!_containsId(map.warps, target.id, (entry) => entry.id)) {
          reason = 'Ce téléporteur n’existe plus.';
        }
    }
    return MapContextCommandEntry(
      command: MapContextCommand.delete,
      label: _deleteTargetLabel(target.kind),
      enabled: reason == null,
      disabledReason: reason,
      destructive: true,
      startsSection: true,
    );
  }

  MapContextCommandProjection _projectCell(
    MapCellContextTarget target, {
    required MapData map,
    required String? activeLayerId,
  }) {
    final layer = _findLayer(map, target.layerId);
    final layerAvailable = layer != null && _isCellPaintLayer(layer);
    final activationReason = !layerAvailable
        ? 'Aucun calque compatible n’est disponible pour cette case.'
        : activeLayerId == layer.id
            ? 'Ce calque est déjà actif.'
            : null;
    final entries = <MapContextCommandEntry>[
      if (target.isPainted)
        MapContextCommandEntry(
          command: MapContextCommand.eraseCell,
          label: 'Effacer cette case',
          enabled: layerAvailable,
          disabledReason: layerAvailable
              ? null
              : 'Le calque de cette case est indisponible.',
          destructive: true,
        ),
      MapContextCommandEntry(
        command: MapContextCommand.activateLayer,
        label: 'Activer le calque',
        enabled: activationReason == null,
        disabledReason: activationReason,
      ),
      const MapContextCommandEntry(
        command: MapContextCommand.copyCoordinates,
        label: 'Copier les coordonnées',
        enabled: true,
      ),
    ];
    return MapContextCommandProjection(
      entries: List<MapContextCommandEntry>.unmodifiable(entries),
    );
  }

  MapContextCommandProjection _projectLayer(
    MapLayerContextTarget target, {
    required MapData map,
    required String? activeLayerId,
  }) {
    final layer = _findLayer(map, target.layerId);
    final groups = const MapLayerGroupService().groupsTopFirst(map);
    final groupIndex = groups.indexWhere(
      (group) => group.containsLayerId(target.layerId),
    );
    final exists = layer != null && groupIndex >= 0;
    final activationReason = !exists
        ? 'Ce calque n’existe plus.'
        : activeLayerId == target.layerId
            ? 'Ce calque est déjà actif.'
            : null;
    String? deleteReason;
    if (!exists) {
      deleteReason = 'Ce calque n’existe plus.';
    } else {
      final impact = const MapLayerDeletionImpactProjector().project(
        map: map,
        layerId: target.layerId,
      );
      if (impact.isBlocked) {
        deleteReason = impact.blockingReasons.join(' ');
      }
    }
    final entries = <MapContextCommandEntry>[
      MapContextCommandEntry(
        command: MapContextCommand.activateLayer,
        label: 'Activer le calque',
        enabled: activationReason == null,
        disabledReason: activationReason,
      ),
      MapContextCommandEntry(
        command: MapContextCommand.renameLayer,
        label: 'Renommer le calque',
        enabled: exists,
        disabledReason: exists ? null : 'Ce calque n’existe plus.',
      ),
      MapContextCommandEntry(
        command: MapContextCommand.moveLayerUp,
        label: 'Monter le calque',
        enabled: exists && groupIndex > 0,
        disabledReason: !exists
            ? 'Ce calque n’existe plus.'
            : groupIndex == 0
                ? 'Ce calque est déjà au premier plan.'
                : null,
      ),
      MapContextCommandEntry(
        command: MapContextCommand.moveLayerDown,
        label: 'Descendre le calque',
        enabled: exists && groupIndex < groups.length - 1,
        disabledReason: !exists
            ? 'Ce calque n’existe plus.'
            : groupIndex == groups.length - 1
                ? 'Ce calque est déjà à l’arrière-plan.'
                : null,
      ),
      MapContextCommandEntry(
        command: MapContextCommand.deleteLayer,
        label: 'Supprimer le calque',
        enabled: deleteReason == null,
        disabledReason: deleteReason,
        destructive: true,
        startsSection: true,
      ),
    ];
    return MapContextCommandProjection(
      entries: List<MapContextCommandEntry>.unmodifiable(entries),
    );
  }
}

typedef _RotationRequest = ({
  MapContextCommand command,
  String label,
  String? shortcutLabel,
  int targetQuarterTurns,
});

String _openTargetLabel(MapCanvasObjectKind kind) {
  return switch (kind) {
    MapCanvasObjectKind.placedElement => 'Propriétés',
    MapCanvasObjectKind.entity => 'Ouvrir l’entité',
    MapCanvasObjectKind.mapEvent => 'Ouvrir dans Event Builder',
    MapCanvasObjectKind.warp => 'Modifier la destination',
    MapCanvasObjectKind.trigger => 'Modifier le déclencheur',
    MapCanvasObjectKind.gameplayZone => 'Modifier la zone',
  };
}

String _deleteTargetLabel(MapCanvasObjectKind kind) {
  return switch (kind) {
    MapCanvasObjectKind.placedElement => 'Supprimer l’élément',
    MapCanvasObjectKind.entity => 'Supprimer l’entité',
    MapCanvasObjectKind.mapEvent => 'Supprimer l’événement',
    MapCanvasObjectKind.gameplayZone => 'Supprimer la zone',
    MapCanvasObjectKind.trigger => 'Supprimer le déclencheur',
    MapCanvasObjectKind.warp => 'Supprimer le téléporteur',
  };
}

String _rotationRejectionReason(MapPlacedElementRotationRejection rejection) {
  return switch (rejection) {
    MapPlacedElementRotationRejection.mapUnavailable =>
      'La carte n’est plus disponible.',
    MapPlacedElementRotationRejection.projectUnavailable =>
      'Le projet n’est plus disponible.',
    MapPlacedElementRotationRejection.instanceMissing =>
      'Cet élément placé n’existe plus.',
    MapPlacedElementRotationRejection.elementMissing =>
      'La définition de cet élément est introuvable.',
    MapPlacedElementRotationRejection.layerMissing =>
      'Le calque de cet élément est introuvable.',
    MapPlacedElementRotationRejection.unsupportedLayer =>
      'Ce type de calque ne prend pas en charge la rotation.',
    MapPlacedElementRotationRejection.environmentGenerated =>
      'Cet élément est généré par une zone Environment.',
    MapPlacedElementRotationRejection.tileIndexed =>
      'Cet élément est piloté par les tuiles de son calque.',
    MapPlacedElementRotationRejection.targetQuarterTurnsOutOfRange =>
      'La rotation demandée est invalide.',
    MapPlacedElementRotationRejection.destinationOutOfBounds =>
      'La rotation dépasserait les limites de la carte.',
    MapPlacedElementRotationRejection.candidateInvalid =>
      'La carte ne permet pas cette rotation.',
  };
}

MapPlacedElement? _findPlacedElement(MapData map, String id) {
  for (final instance in map.placedElements) {
    if (instance.id == id) {
      return instance;
    }
  }
  return null;
}

MapLayer? _findLayer(MapData map, String? id) {
  if (id == null) {
    return null;
  }
  for (final layer in map.layers) {
    if (layer.id == id) {
      return layer;
    }
  }
  return null;
}

bool _isCellPaintLayer(MapLayer layer) {
  return layer is TileLayer ||
      layer is CollisionLayer ||
      layer is SmartTileLayer;
}

bool _containsId<T>(
  List<T> entries,
  String id,
  String Function(T entry) readId,
) {
  return entries.any((entry) => readId(entry) == id);
}
