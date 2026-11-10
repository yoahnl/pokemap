import 'package:map_core/map_core.dart';

import 'editable_map_document.dart';
import 'map_workspace_editing_state.dart';
import 'spatial_terrain_surface_editing_commands.dart';

class SpatialTerrainSurfaceEditingSession {
  SpatialTerrainSurfaceEditingSession(this.document, this.view) {
    load();
  }

  final EditableMapDocument document;
  final MapWorkspaceEditingState view;
  bool _disposed = false;
  MapData? source;
  SpatialTerrainSurface? surface;
  SpatialTerrainSurfaceEditingPreview? _ownPreview;
  final values = <String, String>{};
  String? error;
  String? notice;

  void clearPreview(MapWorkspaceEditingState view) {
    if (identical(view.terrainSurfacePreview, _ownPreview)) {
      view.terrainSurfacePreview = null;
    }
    _ownPreview = null;
  }

  void load() {
    if (_disposed) return;
    final map = document.current;
    final scene = map.spatialScene!;
    final sameMap = source == null || source!.id == map.id;
    final id = sameMap ? view.spatialSurfaceId : null;
    source = map;
    this.surface = scene.terrainSurfaces.surfaces
        .where((surface) => surface.id == id)
        .firstOrNull;
    view.spatialSurfaceId = this.surface?.id;
    error = null;
    notice = null;
    final surface = this.surface;
    if (surface == null) {
      values.clear();
      return;
    }
    values.addAll({
      'x': '${surface.x}',
      'z': '${surface.z}',
      'height': '${surface.height / scene.levelHeight}',
      'width': '${surface.bounds.right - surface.bounds.left}',
      'depth': '${surface.bounds.bottom - surface.bounds.top}',
      'rise-x': '${surface.gradientX / scene.levelHeight}',
      'rise-z': '${surface.gradientZ / scene.levelHeight}',
    });
  }

  void edit(void Function() change) {
    if (_disposed) return;
    clearPreview(view);
    error = null;
    notice = null;
    change();
  }

  void preview() {
    if (_disposed) return;
    clearPreview(view);
    try {
      if (!identical(source, document.current)) {
        throw StateError('La carte a changé. Choisissez à nouveau la surface.');
      }
      final surface = this.surface!;
      final width = terrainSurfaceNumber(values['width']!, 'La largeur');
      final depth = terrainSurfaceNumber(values['depth']!, 'La profondeur');
      if (width <= 0 || depth <= 0) {
        throw StateError('Les dimensions doivent être strictement positives.');
      }
      final scaleX = width / (surface.bounds.right - surface.bounds.left);
      final scaleZ = depth / (surface.bounds.bottom - surface.bounds.top);
      final step = document.current.spatialScene!.levelHeight;
      final changed = surface.copyWith(
        x: terrainSurfaceNumber(values['x']!, 'X'),
        z: terrainSurfaceNumber(values['z']!, 'Y'),
        height: terrainSurfaceNumber(values['height']!, 'La hauteur') * step,
        gradientX:
            terrainSurfaceNumber(
              values['rise-x']!,
              'La montée vers la droite',
            ) *
            step,
        gradientZ:
            terrainSurfaceNumber(values['rise-z']!, 'La montée vers le bas') *
            step,
        footprints: scaleX == 1 && scaleZ == 1
            ? surface.footprints
            : [
                for (final footprint in surface.footprints)
                  BorderGroundFootprint(
                    points: [
                      for (final point in footprint.points)
                        BorderGroundPoint(
                          x: point.x * scaleX,
                          z: point.z * scaleZ,
                        ),
                    ],
                  ),
              ],
      );
      _ownPreview = SpatialTerrainSurfaceEditingCommands(document).preview(
        changed,
        reanchorInstances: view.spatialSurfaceReanchorInstances,
      );
      view.terrainSurfacePreview = _ownPreview;
      error = null;
    } on Object catch (failure) {
      error = terrainSurfaceFailureMessage(failure);
    }
  }

  void apply() {
    if (_disposed) return;
    final preview = _ownPreview;
    if (preview == null) return;
    if (!identical(view.terrainSurfacePreview, preview)) {
      error = 'L’aperçu a changé. Préparez un nouvel aperçu de la surface.';
      return;
    }
    try {
      SpatialTerrainSurfaceEditingCommands(document).apply(preview);
      clearPreview(view);
      load();
      notice = 'Surface appliquée. Une seule annulation restaure la carte.';
    } on Object catch (failure) {
      error = terrainSurfaceFailureMessage(failure);
    }
  }

  void delete() {
    if (_disposed) return;
    try {
      if (!identical(source, document.current)) {
        throw StateError('La carte a changé. Choisissez à nouveau la surface.');
      }
      SpatialTerrainSurfaceEditingCommands(document).delete(
        surface!.id,
        reanchorInstances: view.spatialSurfaceReanchorInstances,
      );
      clearPreview(view);
      load();
      notice = 'Surface supprimée. Annuler permet de la retrouver.';
    } on Object catch (failure) {
      error = terrainSurfaceFailureMessage(failure);
    }
  }

  void dispose() {
    _disposed = true;
    clearPreview(view);
  }
}
