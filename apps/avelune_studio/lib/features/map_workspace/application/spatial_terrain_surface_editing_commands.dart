import 'package:map_core/map_core.dart';

import 'editable_map_document.dart';

final class SpatialTerrainSurfaceBrush {
  const SpatialTerrainSurfaceBrush({
    required this.lowLevel,
    required this.highLevel,
    required this.direction,
  });

  factory SpatialTerrainSurfaceBrush.parse({
    required String lowLevel,
    required String highLevel,
    required SpatialRampDirection direction,
  }) => SpatialTerrainSurfaceBrush(
    lowLevel: terrainSurfaceNumber(lowLevel, 'La hauteur basse'),
    highLevel: terrainSurfaceNumber(highLevel, 'La hauteur haute'),
    direction: direction,
  );

  final double lowLevel, highLevel;
  final SpatialRampDirection direction;

  SpatialTerrainSurface rectangle({
    required String id,
    required MapSpatialScene scene,
    required GridPos start,
    required GridPos end,
  }) {
    if (!lowLevel.isFinite ||
        !highLevel.isFinite ||
        lowLevel < 0 ||
        highLevel < lowLevel) {
      throw StateError(
        'La hauteur haute doit être supérieure ou égale à la hauteur basse, sans hauteur négative.',
      );
    }
    final x = start.x < end.x ? start.x : end.x;
    final z = start.y < end.y ? start.y : end.y;
    final width = (start.x - end.x).abs() + 1.0;
    final depth = (start.y - end.y).abs() + 1.0;
    final low = lowLevel * scene.levelHeight;
    final high = highLevel * scene.levelHeight;
    final alongX =
        direction == SpatialRampDirection.east ||
        direction == SpatialRampDirection.west;
    final negativeHigh =
        direction == SpatialRampDirection.north ||
        direction == SpatialRampDirection.west;
    final gradient =
        (high - low) / (alongX ? width : depth) * (negativeHigh ? -1 : 1);
    return SpatialTerrainSurface(
      id: id,
      x: x.toDouble(),
      z: z.toDouble(),
      height: negativeHigh ? high : low,
      gradientX: alongX ? gradient : 0,
      gradientZ: alongX ? 0 : gradient,
      footprints: [
        BorderGroundFootprint(
          points: [
            BorderGroundPoint(x: 0, z: 0),
            BorderGroundPoint(x: width, z: 0),
            BorderGroundPoint(x: width, z: depth),
            BorderGroundPoint(x: 0, z: depth),
          ],
        ),
      ],
    );
  }
}

double terrainSurfaceNumber(String value, String label) {
  final number = double.tryParse(value.trim().replaceAll(',', '.'));
  if (number == null || !number.isFinite) {
    throw StateError('$label doit être un nombre fini, par exemple 1,25.');
  }
  return number;
}

String nextTerrainSurfaceId(MapSpatialScene scene) {
  final ids = scene.terrainSurfaces.surfaces
      .map((surface) => surface.id)
      .toSet();
  var index = 1;
  while (ids.contains('terrain_surface_$index')) {
    index++;
  }
  return 'terrain_surface_$index';
}

final class SpatialTerrainSurfaceEditingPreview {
  const SpatialTerrainSurfaceEditingPreview({
    required this.source,
    required this.result,
    required this.surface,
  });
  final MapData source, result;
  final SpatialTerrainSurface surface;
  bool validFor(MapData map) => identical(source, map);
  bool get hasChanges => source != result;
}

final class SpatialTerrainSurfaceEditingCommands {
  const SpatialTerrainSurfaceEditingCommands(this.document);
  final EditableMapDocument document;

  SpatialTerrainSurfaceEditingPreview preview(
    SpatialTerrainSurface surface, {
    bool reanchorInstances = true,
  }) {
    _requireEditable(surface.id);
    return SpatialTerrainSurfaceEditingPreview(
      source: document.current,
      result: const SpatialMapOperations().upsertTerrainSurfaces(
        document.current,
        [surface],
        reanchorInstances: reanchorInstances,
      ),
      surface: surface,
    );
  }

  void apply(SpatialTerrainSurfaceEditingPreview preview) {
    _requireEditable(preview.surface.id);
    if (!preview.validFor(document.current)) {
      throw StateError(
        'La carte a changé. Préparez un nouvel aperçu de la surface.',
      );
    }
    document.commit(preview.result);
  }

  void delete(String id, {bool reanchorInstances = true}) {
    _requireEditable(id);
    document.commit(
      const SpatialMapOperations().deleteTerrainSurfaces(document.current, [
        id,
      ], reanchorInstances: reanchorInstances),
    );
  }

  void _requireEditable(String id) {
    if (document.saving) {
      throw StateError('Attendez la fin de l’enregistrement de la carte.');
    }
    if (!(document.current.spatialScene?.terrainSurfaces.surfaces.any(
          (surface) => surface.id == id,
        ) ??
        false)) {
      throw StateError(
        'Cette surface n’existe plus. Choisissez une autre surface.',
      );
    }
  }
}

String terrainSurfaceFailureMessage(Object failure) {
  if (failure is StateError) return failure.message.toString();
  if (failure is FormatException || failure is ValidationException) {
    return 'La surface doit rester dans la carte, avec une hauteur comprise entre 0 et 1024 cases. Vérifiez sa position, ses dimensions et sa pente.';
  }
  return 'Impossible de préparer cette surface. Votre carte reste inchangée.';
}
