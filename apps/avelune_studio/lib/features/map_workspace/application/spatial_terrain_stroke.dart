import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import 'spatial_terrain_surface_editing_commands.dart';

enum SpatialTerrainMode { ground, relief, ramp }

class SpatialTerrainStroke {
  SpatialTerrainStroke({
    required this.source,
    required this.mode,
    required this.level,
    required this.erase,
    required this.origin,
    this.models = const [],
    this.surfaceBrush,
    this.reanchorInstances = true,
  }) : preview = source {
    paint(origin);
  }

  final MapData source;
  final SpatialTerrainMode mode;
  final int level;
  final bool erase;
  final GridPos origin;
  final Iterable<ProjectModel3dEntry> models;
  final SpatialTerrainSurfaceBrush? surfaceBrush;
  final bool reanchorInstances;
  String? surfaceId;
  final cells = <GridPos>{};
  MapData preview;
  String? error;
  GridPos? _previous;
  GridPos? _end;
  GridPos get end => _end ?? origin;
  static const _operations = SpatialMapOperations();

  void paint(GridPos cell) {
    final scene = source.spatialScene!;
    if (cell.x < 0 ||
        cell.y < 0 ||
        cell.x >= scene.width ||
        cell.y >= scene.depth) {
      _previous = null;
      return;
    }
    final previous = _previous ?? cell;
    final steps = math.max(
      (cell.x - previous.x).abs(),
      (cell.y - previous.y).abs(),
    );
    for (var step = 0; step <= steps; step++) {
      final t = steps == 0 ? 0.0 : step / steps;
      cells.add(
        GridPos(
          x: (previous.x + (cell.x - previous.x) * t).round(),
          y: (previous.y + (cell.y - previous.y) * t).round(),
        ),
      );
    }
    _previous = cell;
    _end = cell;
    if (surfaceBrush != null) {
      cells.clear();
      for (
        var z = math.min(origin.y, cell.y);
        z <= math.max(origin.y, cell.y);
        z++
      ) {
        for (
          var x = math.min(origin.x, cell.x);
          x <= math.max(origin.x, cell.x);
          x++
        ) {
          cells.add(GridPos(x: x, y: z));
        }
      }
    }
    error = null;
    try {
      if (surfaceBrush != null) {
        if (erase) {
          final ids = [
            for (final surface in scene.terrainSurfaces.surfaces)
              if (cells.any((cell) => surface.overlapsCell(cell.x, cell.y)))
                surface.id,
          ];
          preview = ids.isEmpty
              ? source
              : _operations.deleteTerrainSurfaces(
                  source,
                  ids,
                  reanchorInstances: reanchorInstances,
                );
        } else {
          final surface = surfaceBrush!.rectangle(
            id: nextTerrainSurfaceId(scene),
            scene: scene,
            start: origin,
            end: cell,
          );
          surfaceId = surface.id;
          preview = _operations.upsertTerrainSurfaces(source, [
            surface,
          ], reanchorInstances: reanchorInstances);
        }
      } else if (mode == SpatialTerrainMode.relief) {
        preview = _operations.setLevels(source, [
          for (final cell in cells)
            SpatialCellLevel(x: cell.x, z: cell.y, level: erase ? 0 : level),
        ]);
      } else if (erase) {
        final removed = scene.navigation.ramps
            .where(
              (ramp) => cells.any(
                (cell) =>
                    ramp.x < cell.x + 1 &&
                    ramp.x + ramp.width > cell.x &&
                    ramp.z < cell.y + 1 &&
                    ramp.z + ramp.depth > cell.y,
              ),
            )
            .toList();
        final automaticModels = models
            .where((model) => model.rampProfile != null)
            .map((model) => model.id)
            .toSet();
        final automaticInstances = scene.instances
            .where((instance) => automaticModels.contains(instance.modelId))
            .map((instance) => instance.id)
            .toSet();
        if (removed.any(
          (ramp) => automaticInstances.contains(ramp.surfaceInstanceId),
        )) {
          error = 'Cette pente suit son escalier. Supprimez l’escalier pour retirer aussi sa pente.';
          preview = source;
          return;
        }
        preview = _operations.configureNavigation(
          source,
          scene.navigation.copyWith(
            ramps: scene.navigation.ramps.where(
              (ramp) => !removed.contains(ramp),
            ),
          ),
          models: models,
        );
      } else if (cell != origin) {
        final ramp = _ramp(scene, cell);
        preview = _operations.configureNavigation(
          source,
          scene.navigation.copyWith(ramps: [...scene.navigation.ramps, ramp]),
          models: models,
        );
      }
    } on Object catch (failure) {
      error = surfaceBrush != null
          ? terrainSurfaceFailureMessage(failure)
          : failure is ValidationException &&
                failure.code == 'spatial.terrain.surface_grid_conflict'
          ? 'Cette zone appartient à une surface de terrain. Modifiez cette surface plutôt que la grille en dessous.'
          : mode == SpatialTerrainMode.relief
          ? 'Cette hauteur couperait une pente. Retirez la pente avec sa gomme avant de changer le relief.'
          : 'La pente doit relier un sol bas à un sol haut, sans croiser une autre pente ou une zone bloquée.';
      preview = source;
    }
  }

  SpatialRamp _ramp(MapSpatialScene scene, GridPos end) {
    final alongZ = (end.y - origin.y).abs() >= (end.x - origin.x).abs();
    final negativeHigh = alongZ ? end.y < origin.y : end.x < origin.x;
    final x = math.min(origin.x, end.x), z = math.min(origin.y, end.y);
    final width = (origin.x - end.x).abs() + 1,
        depth = (origin.y - end.y).abs() + 1;
    final low = <int>{}, high = <int>{};
    for (var offset = 0; offset < (alongZ ? width : depth); offset++) {
      final negativeX = alongZ ? x + offset : x - 1;
      final negativeZ = alongZ ? z - 1 : z + offset;
      final positiveX = alongZ ? x + offset : x + width;
      final positiveZ = alongZ ? z + depth : z + offset;
      if (negativeX < 0 ||
          negativeZ < 0 ||
          positiveX >= scene.width ||
          positiveZ >= scene.depth) {
        throw StateError('La pente doit rester à l’intérieur de la carte.');
      }
      final negative = scene.heightLevels[negativeZ * scene.width + negativeX];
      final positive = scene.heightLevels[positiveZ * scene.width + positiveX];
      high.add(negativeHigh ? negative : positive);
      low.add(negativeHigh ? positive : negative);
    }
    if (low.length != 1 || high.length != 1 || low.single >= high.single) {
      throw StateError('Glissez du terrain bas vers le terrain haut.');
    }
    var index = 1;
    while (scene.navigation.ramps.any((ramp) => ramp.id == 'slope_$index')) {
      index++;
    }
    return SpatialRamp(
      id: 'slope_$index',
      x: x.toDouble(),
      z: z.toDouble(),
      width: width.toDouble(),
      depth: depth.toDouble(),
      lowLevel: low.single,
      highLevel: high.single,
      direction: alongZ
          ? (negativeHigh
                ? SpatialRampDirection.north
                : SpatialRampDirection.south)
          : (negativeHigh
                ? SpatialRampDirection.west
                : SpatialRampDirection.east),
    );
  }

  MapData commit() {
    if (error != null) throw StateError(error!);
    if (mode == SpatialTerrainMode.ramp && !erase && _end == origin) {
      throw StateError('Glissez du bas vers le haut pour dessiner une pente.');
    }
    return preview;
  }
}
