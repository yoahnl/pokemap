part of 'environment_editing.dart';

/// Bounded map-space region used by deterministic Environment generation.
final class EnvironmentGenerationRegion {
  const EnvironmentGenerationRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;

  bool contains(GridPos pos) =>
      pos.x >= x && pos.x < right && pos.y >= y && pos.y < bottom;

  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentGenerationRegion &&
          x == other.x &&
          y == other.y &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(x, y, width, height);
}

/// Renderer-neutral generated placement included in an optimistic preview.
final class EnvironmentGeneratedPlacement {
  EnvironmentGeneratedPlacement({
    required this.id,
    required this.layerId,
    required this.elementId,
    required this.pos,
    required this.applyCollision,
  });

  final String id;
  final String layerId;
  final String elementId;
  final GridPos pos;
  final bool applyCollision;

  Map<String, Object?> toJson() => {
        'id': id,
        'layerId': layerId,
        'elementId': elementId,
        'x': pos.x,
        'y': pos.y,
        'applyCollision': applyCollision,
      };
}

/// Immutable Environment preview bound to the exact map revision and area seed.
final class EnvironmentGenerationPreview {
  EnvironmentGenerationPreview._({
    required this.mapId,
    required this.layerId,
    required this.areaId,
    required this.projectRevision,
    required this.seed,
    required this.requestedRegion,
    required this.resolutionRegion,
    required this.haloCells,
    required Iterable<EnvironmentGeneratedPlacement> placements,
  }) : placements = List.unmodifiable(placements) {
    fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'environment-generation-preview.json',
        bytes: utf8.encode(jsonEncode(_fingerprintPayload())),
      ),
    ]);
  }

  final String mapId;
  final String layerId;
  final String areaId;
  final String projectRevision;
  final int seed;
  final EnvironmentGenerationRegion requestedRegion;
  final EnvironmentGenerationRegion resolutionRegion;
  final int haloCells;
  final List<EnvironmentGeneratedPlacement> placements;
  late final String fingerprint;

  Map<String, Object?> _fingerprintPayload() => {
        'schema': 'pokemap.environment-generation-preview.v1',
        'mapId': mapId,
        'layerId': layerId,
        'areaId': areaId,
        'projectRevision': projectRevision,
        'seed': seed,
        'requestedRegion': requestedRegion.toJson(),
        'resolutionRegion': resolutionRegion.toJson(),
        'haloCells': haloCells,
        'placements': placements.map((value) => value.toJson()).toList(),
      };

  Map<String, Object?> toJson() => {
        ..._fingerprintPayload(),
        'placementCount': placements.length,
        'fingerprint': fingerprint,
      };
}
