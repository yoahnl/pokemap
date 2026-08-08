import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// Stable reasons why an editor rotation preview cannot be committed.
///
/// The enum is intentionally UI-agnostic: presentation layers translate these
/// values into human feedback without parsing validator exception text.
enum MapPlacedElementRotationRejection {
  mapUnavailable,
  projectUnavailable,
  instanceMissing,
  elementMissing,
  layerMissing,
  unsupportedLayer,
  environmentGenerated,
  tileIndexed,
  targetQuarterTurnsOutOfRange,
  destinationOutOfBounds,
  candidateInvalid,
}

/// Immutable projection of one absolute placed-element rotation request.
///
/// A plan keeps the source document and resolved footprints available to later
/// preview surfaces while preventing rejected or no-op requests from entering
/// editor history.
@immutable
final class MapPlacedElementRotationPlan {
  const MapPlacedElementRotationPlan._({
    required this.sourceMap,
    required this.instance,
    required this.sourceFootprint,
    required this.previewFootprint,
    required this.candidateMap,
    required this.rejection,
    required this.isNoOp,
  });

  factory MapPlacedElementRotationPlan.accepted({
    required MapData sourceMap,
    required MapPlacedElement instance,
    required QuarterTurnGridTransform sourceFootprint,
    required QuarterTurnGridTransform previewFootprint,
    required MapData candidateMap,
  }) =>
      MapPlacedElementRotationPlan._(
        sourceMap: sourceMap,
        instance: instance,
        sourceFootprint: sourceFootprint,
        previewFootprint: previewFootprint,
        candidateMap: candidateMap,
        rejection: null,
        isNoOp: false,
      );

  factory MapPlacedElementRotationPlan.rejected({
    required MapData? sourceMap,
    required MapPlacedElementRotationRejection rejection,
    MapPlacedElement? instance,
    QuarterTurnGridTransform? sourceFootprint,
    QuarterTurnGridTransform? previewFootprint,
  }) =>
      MapPlacedElementRotationPlan._(
        sourceMap: sourceMap,
        instance: instance,
        sourceFootprint: sourceFootprint,
        previewFootprint: previewFootprint,
        candidateMap: null,
        rejection: rejection,
        isNoOp: false,
      );

  factory MapPlacedElementRotationPlan.noOp({
    required MapData sourceMap,
    required MapPlacedElement instance,
    required QuarterTurnGridTransform footprint,
  }) =>
      MapPlacedElementRotationPlan._(
        sourceMap: sourceMap,
        instance: instance,
        sourceFootprint: footprint,
        previewFootprint: footprint,
        candidateMap: sourceMap,
        rejection: null,
        isNoOp: true,
      );

  final MapData? sourceMap;
  final MapPlacedElement? instance;
  final QuarterTurnGridTransform? sourceFootprint;
  final QuarterTurnGridTransform? previewFootprint;
  final MapData? candidateMap;
  final MapPlacedElementRotationRejection? rejection;
  final bool isNoOp;

  bool get canCommit => rejection == null && candidateMap != null && !isNoOp;
}

/// Projects an absolute rotation request without mutating editor state.
MapPlacedElementRotationPlan planMapPlacedElementRotation({
  required MapData? map,
  required ProjectManifest? project,
  required String instanceId,
  required int targetQuarterTurns,
}) {
  if (map == null) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: null,
      rejection: MapPlacedElementRotationRejection.mapUnavailable,
    );
  }
  if (project == null) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      rejection: MapPlacedElementRotationRejection.projectUnavailable,
    );
  }

  final normalizedInstanceId = instanceId.trim();
  final instance = _findById(
    map.placedElements,
    normalizedInstanceId,
    (entry) => entry.id,
  );
  if (instance == null) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      rejection: MapPlacedElementRotationRejection.instanceMissing,
    );
  }

  final element = _findById(
    project.elements,
    instance.elementId.trim(),
    (entry) => entry.id,
  );
  if (element == null) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      rejection: MapPlacedElementRotationRejection.elementMissing,
    );
  }

  final layer = _findById(
    map.layers,
    instance.layerId.trim(),
    (entry) => entry.id,
  );
  if (layer == null) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      rejection: MapPlacedElementRotationRejection.layerMissing,
    );
  }
  if (layer is! TileLayer) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      rejection: MapPlacedElementRotationRejection.unsupportedLayer,
    );
  }

  // Environment ownership is authoritative whether it is represented by the
  // current marker or by the generator's durable placement-id relationship.
  // Human-facing layer/element names must never grant this capability.
  if (_isEnvironmentGenerated(map, instance)) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      rejection: MapPlacedElementRotationRejection.environmentGenerated,
    );
  }
  if (instance.properties[pokemapPlacementOriginProperty]?.trim() ==
      pokemapPlacementOriginTileIndex) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      rejection: MapPlacedElementRotationRejection.tileIndexed,
    );
  }
  if (targetQuarterTurns < 0 || targetQuarterTurns > 3) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      rejection: MapPlacedElementRotationRejection.targetQuarterTurnsOutOfRange,
    );
  }

  QuarterTurnGridTransform sourceFootprint;
  QuarterTurnGridTransform previewFootprint;
  try {
    sourceFootprint = resolveMapPlacedElementFootprint(
      instance: instance,
      element: element,
    );
    previewFootprint = QuarterTurnGridTransform(
      sourceSize: sourceFootprint.sourceSize,
      quarterTurns: targetQuarterTurns,
    );
  } on Object {
    // Malformed legacy source geometry has no dedicated public rejection. It
    // is deliberately contained as candidateInvalid so editor previews never
    // crash while inspecting an uncommittable document.
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      rejection: MapPlacedElementRotationRejection.candidateInvalid,
    );
  }

  if (instance.quarterTurns == targetQuarterTurns) {
    return MapPlacedElementRotationPlan.noOp(
      sourceMap: map,
      instance: instance,
      footprint: sourceFootprint,
    );
  }
  if (!_fitsWithinMap(
    anchor: instance.pos,
    footprint: previewFootprint.destinationSize,
    mapSize: map.size,
  )) {
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      sourceFootprint: sourceFootprint,
      previewFootprint: previewFootprint,
      rejection: MapPlacedElementRotationRejection.destinationOutOfBounds,
    );
  }

  MapData candidate;
  try {
    candidate = setMapPlacedElementQuarterTurns(
      map,
      instanceId: normalizedInstanceId,
      quarterTurns: targetQuarterTurns,
    );
    MapValidator.validate(
      candidate,
      projectDialogueContext: project,
    );
  } on Object {
    // Whole-map validation is the final transaction boundary. An unrelated
    // invalid source datum also blocks the candidate without hiding the ghost
    // geometry that explains the requested rotation.
    return MapPlacedElementRotationPlan.rejected(
      sourceMap: map,
      instance: instance,
      sourceFootprint: sourceFootprint,
      previewFootprint: previewFootprint,
      rejection: MapPlacedElementRotationRejection.candidateInvalid,
    );
  }

  return MapPlacedElementRotationPlan.accepted(
    sourceMap: map,
    instance: instance,
    sourceFootprint: sourceFootprint,
    previewFootprint: previewFootprint,
    candidateMap: candidate,
  );
}

bool _isEnvironmentGenerated(
  MapData map,
  MapPlacedElement instance,
) {
  if (instance.properties[pokemapPlacementOriginProperty]?.trim() ==
      pokemapPlacementOriginEnvironment) {
    return true;
  }
  final instanceId = instance.id.trim();
  for (final layer in map.layers.whereType<EnvironmentLayer>()) {
    for (final area in layer.content.areas) {
      if (area.generatedPlacementIds.any(
        (candidate) => candidate.trim() == instanceId,
      )) {
        return true;
      }
    }
  }
  return false;
}

bool _fitsWithinMap({
  required GridPos anchor,
  required GridSize footprint,
  required GridSize mapSize,
}) {
  if (anchor.x < 0 ||
      anchor.y < 0 ||
      footprint.width <= 0 ||
      footprint.height <= 0 ||
      mapSize.width <= 0 ||
      mapSize.height <= 0 ||
      footprint.width > mapSize.width ||
      footprint.height > mapSize.height) {
    return false;
  }
  // Subtraction keeps the check overflow-safe for malformed large legacy
  // coordinates while retaining the map's top-left anchor convention.
  return anchor.x <= mapSize.width - footprint.width &&
      anchor.y <= mapSize.height - footprint.height;
}

T? _findById<T>(
  Iterable<T> entries,
  String id,
  String Function(T entry) readId,
) {
  for (final entry in entries) {
    if (readId(entry).trim() == id) {
      return entry;
    }
  }
  return null;
}
