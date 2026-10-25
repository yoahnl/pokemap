import 'dart:math' as math;
import 'dart:ui';

import 'package:flame_3d/components.dart';
import 'package:flame_3d/core.dart';
import 'package:flame_3d/resources.dart';
import 'package:map_core/map_core.dart';

import 'spatial_actor_visual.dart';
import 'spatial_pixel_material.dart';

typedef SpatialActorOcclusionState = ({bool active, int elapsedMs});
typedef SpatialActorOcclusionStateForCell = SpatialActorOcclusionState Function(
  String mapId,
  String layerId,
  int cellX,
  int cellY,
  int elapsedMs,
);

final class SpatialActorOcclusionVisual {
  const SpatialActorOcclusionVisual({
    required this.id,
    required this.visual,
    required this.x,
    required this.y,
    required this.z,
    required this.width,
    required this.height,
    required this.opacity,
  });
  final String id;
  final SmartTileLayerVisual visual;
  final double x, y, z, width, height, opacity;
}

final class SpatialActorOcclusionPlan {
  SpatialActorOcclusionPlan(
    this.map,
    ProjectManifest project, {
    bool Function(String layerId)? includeLayer,
  }) {
    for (final layer in map.layers.whereType<SmartTileLayer>()) {
      if (!layer.isVisible ||
          layer.opacity <= 0 ||
          includeLayer?.call(layer.id) == false)
        continue;
      final preset = project.smartTileCatalog.presets
          .where((p) => p.id == layer.presetId)
          .firstOrNull;
      final patterns = project.smartTileCatalog.patterns.where(
        (p) => layer.patternStrokes.any((s) => s.patternId == p.id),
      );
      final hasParts =
          preset?.rules.any(
                (r) => r.candidates.any(
                  (c) => c.parts.any(
                    (p) => p.channel == SmartTileRenderChannel.actorOcclusion,
                  ),
                ),
              ) ==
              true ||
          patterns.any(
            (p) => p.cells.any(
              (c) => c.parts.any(
                (p) => p.channel == SmartTileRenderChannel.actorOcclusion,
              ),
            ),
          );
      if (!hasParts) continue;
      _layerIds.add(layer.id);
      _plans.add((
        layer: layer,
        plan: buildSmartTileLayerVisualPlan(
          map: map,
          layer: layer,
          catalog: project.smartTileCatalog,
          pass: SmartTileVisualPass.actorOcclusion,
          sourceCellWidth: project.settings.tileWidth.toDouble(),
          sourceCellHeight: project.settings.tileHeight.toDouble(),
          destinationCellWidth: 1,
          destinationCellHeight: 1,
        ),
      ));
    }
  }
  final MapData map;
  final _plans = <({SmartTileLayer layer, SmartTileLayerVisualPlan plan})>[];
  final _layerIds = <String>{};

  SpatialActorOcclusionPlan._visible(
    SpatialActorOcclusionPlan source,
    bool Function(String) includeLayer,
  ) : map = source.map {
    _plans.addAll(source._plans.where((entry) => includeLayer(entry.layer.id)));
    _layerIds.addAll(source._layerIds.where(includeLayer));
  }

  SpatialActorOcclusionPlan._reordered(
    SpatialActorOcclusionPlan source,
    this.map,
  ) {
    final byId = {for (final entry in source._plans) entry.layer.id: entry};
    for (final layer in map.layers) {
      final entry = byId[layer.id];
      if (entry == null) continue;
      _plans.add(entry);
      _layerIds.add(layer.id);
    }
  }

  SpatialActorOcclusionPlan reordered(MapData map) =>
      SpatialActorOcclusionPlan._reordered(this, map);

  SpatialActorOcclusionPlan withLayerVisibility(
    bool Function(String) includeLayer,
  ) => _plans.every((entry) => includeLayer(entry.layer.id))
      ? this
      : SpatialActorOcclusionPlan._visible(this, includeLayer);

  bool layersMatchVisibility(
    SpatialActorOcclusionPlan other,
    bool Function(String) includeLayer,
  ) =>
      identical(map, other.map) &&
      _layerIds.every((id) => includeLayer(id) == other._layerIds.contains(id));

  List<SpatialActorOcclusionVisual> resolve(
    int elapsedMs, {
    SpatialActorOcclusionState Function(
      String layerId,
      int cellX,
      int cellY,
      int elapsedMs,
    )?
    stateForCell,
  }) {
    final result = <SpatialActorOcclusionVisual>[];
    for (final entry in _plans) {
      if (entry.layer.animationActivation ==
              SmartTileAnimationActivation.onEnter &&
          stateForCell == null)
        continue;
      final states = <(int, int), SpatialActorOcclusionState>{};
      SpatialActorOcclusionState state(int x, int y) => states.putIfAbsent(
        (x, y),
        () =>
            entry.layer.animationActivation ==
                SmartTileAnimationActivation.always
            ? (active: true, elapsedMs: elapsedMs)
            : stateForCell?.call(entry.layer.id, x, y, elapsedMs) ??
                  (active: false, elapsedMs: 0),
      );
      final visuals = entry.plan
          .resolveBatch(
            elapsedMs: elapsedMs,
            animationElapsedMsForCell: ({
              required cellX,
              required cellY,
              required elapsedMs,
            }) => state(cellX, cellY).elapsedMs,
          )
          .visuals;
      for (var index = 0; index < visuals.length; index++) {
        final visual = visuals[index];
        final occupant = state(visual.cellX, visual.cellY);
        if (!occupant.active) continue;
        final rectangle = visual.geometry.visualBounds;
        result.add(
          SpatialActorOcclusionVisual(
            id: '${map.id}/${entry.layer.id}/${visual.cellX}/${visual.cellY}/$index',
            visual: visual,
            x: rectangle.left + rectangle.width / 2,
            y:
                (visual.spatialFollowTerrain
                    ? map.spatialScene?.worldHeightAt(
                            visual.cellX + .5,
                            visual.cellY + .5,
                          ) ??
                          0
                    : 0) +
                visual.spatialHeightOffset,
            z: rectangle.top + .5,
            width: rectangle.width,
            height: rectangle.height,
            opacity: entry.layer.opacity,
          ),
        );
      }
    }
    return result;
  }
}

final class SpatialActorOcclusionBillboards {
  final components = <String, MeshComponent>{};
  final materials = <String, SpatialPixelMaterial>{};
  final _geometry = <String, (double, double, SmartTileSpriteTransform)>{};

  ({List<MeshComponent> added, List<MeshComponent> removed}) sync(
    List<SpatialActorOcclusionVisual> visuals,
    Map<String, Texture> textures, {
    required SpatialCameraProfile camera,
    Offset offset = Offset.zero,
    bool topView = false,
  }) {
    final added = <MeshComponent>[], removed = <MeshComponent>[];
    final retained = visuals.map((v) => v.id).toSet();
    for (final id
        in components.keys.where((id) => !retained.contains(id)).toList()) {
      removed.add(components.remove(id)!);
      materials.remove(id);
      _geometry.remove(id);
    }
    final transform = spatialActorTransform(camera);
    for (final item in visuals) {
      final visual = item.visual;
      final texture = textures[visual.tilesetId];
      if (texture == null)
        throw StateError(
          'Actor occlusion texture missing: ${visual.tilesetId}',
        );
      final rectangle = visual.sourceRect;
      if (rectangle.x < 0 ||
          rectangle.y < 0 ||
          rectangle.x + rectangle.width > texture.width ||
          rectangle.y + rectangle.height > texture.height) {
        throw StateError(
          'Actor occlusion frame outside texture: ${visual.tilesetId}',
        );
      }
      final signature = (item.width, item.height, visual.transform);
      if (_geometry[item.id] != signature) {
        final previous = components.remove(item.id);
        if (previous != null) removed.add(previous);
        final material = SpatialPixelMaterial(
          texture,
          lightingRole: SpatialPixelLightingRole.actor,
        );
        final inverse = smartTileD4Transforms.firstWhere(
          (candidate) => isIdentitySmartTileTransform(
            composeSmartTileSpriteTransforms(
              first: visual.transform,
              second: candidate,
            ),
          ),
        );
        Vector2 uv(double x, double y) {
          final point = transformSmartTileVector(
            SmartTileGeometryPoint(x: x - .5, y: y - .5),
            inverse,
          );
          return Vector2(point.x + .5, point.y + .5);
        }

        final mesh = Mesh()
          ..addSurface(
            Surface(
              vertices: [
                Vertex(
                  position: Vector3(-item.width / 2, 0, 0),
                  texCoord: uv(0, 1),
                ),
                Vertex(
                  position: Vector3(item.width / 2, 0, 0),
                  texCoord: uv(1, 1),
                ),
                Vertex(
                  position: Vector3(item.width / 2, item.height, 0),
                  texCoord: uv(1, 0),
                ),
                Vertex(
                  position: Vector3(-item.width / 2, item.height, 0),
                  texCoord: uv(0, 0),
                ),
              ],
              indices: [0, 1, 2, 2, 3, 0],
              material: material,
            ),
          );
        final component = MeshComponent(mesh: mesh);
        components[item.id] = component;
        materials[item.id] = material;
        _geometry[item.id] = signature;
        added.add(component);
      }
      final component = components[item.id]!;
      component.position.setValues(
        item.x + offset.dx,
        item.y,
        item.z + offset.dy,
      );
      component.rotation.setFrom(
        topView
            ? Quaternion.axisAngle(Vector3(1, 0, 0), -math.pi / 2)
            : transform.rotation,
      );
      component.scale.setFrom(topView ? Vector3.all(1) : transform.scale);
      materials[item.id]!
        ..albedoTexture = texture
        ..albedoColor = Color.fromRGBO(255, 255, 255, item.opacity)
        ..uvRect.setValues(
          rectangle.x / texture.width,
          rectangle.y / texture.height,
          rectangle.width / texture.width,
          rectangle.height / texture.height,
        );
    }
    return (added: added, removed: removed);
  }

  void clear() {
    components.clear();
    materials.clear();
    _geometry.clear();
  }
}
