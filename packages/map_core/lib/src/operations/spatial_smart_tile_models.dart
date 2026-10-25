import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/map_data.dart';
import '../models/geometry.dart';
import '../models/map_layer.dart';
import '../models/map_spatial_scene.dart';
import '../models/project_model3d.dart';
import '../models/smart_tile.dart';
import 'map_visual_composition.dart';
import 'smart_tile_layer_context.dart';
import 'smart_tile_resolver.dart';
import 'smart_tile_sprite_geometry.dart';

MapData projectSpatialSmartTileModels({
  required MapData map,
  required ProjectSmartTileCatalog catalog,
  int projectSeed = 0,
  int sourceCellWidth = 32,
  int sourceCellHeight = 32,
}) {
  final scene = map.spatialScene;
  if (scene == null) return map;
  final instances = <SpatialModelInstance>[
    for (final instance in scene.instances)
      if (!instance.id.startsWith('smt_')) instance,
    ...resolveSpatialSmartTileInstances(
      map: map,
      catalog: catalog,
      projectSeed: projectSeed,
      sourceCellWidth: sourceCellWidth,
      sourceCellHeight: sourceCellHeight,
    ),
  ];
  if (_sameInstances(instances, scene.instances)) return map;
  return map.copyWith(spatialScene: scene.copyWith(instances: instances));
}

List<SpatialModelInstance> resolveSpatialSmartTileInstances({
  required MapData map,
  required ProjectSmartTileCatalog catalog,
  int projectSeed = 0,
  int sourceCellWidth = 32,
  int sourceCellHeight = 32,
}) => resolveSpatialSmartTileModelProjection(
  map: map,
  catalog: catalog,
  projectSeed: projectSeed,
  sourceCellWidth: sourceCellWidth,
  sourceCellHeight: sourceCellHeight,
).instances;

typedef SpatialSmartTileModelProjection = ({
  List<SpatialModelInstance> instances,
  Map<String, Set<(int, int)>> groundReplacements,
  Map<String, ({String layerId, GridPos cell})> cellOrigins,
  Set<String> paintHeightInstanceIds,
});

const spatialSmartTileLayerPaintStep = .001;

Map<String, int> spatialSmartTileLayerPaintRanks(MapData map) {
  final paintedLayers =
      (mapPaintsFirstLayerInFront(map) ? map.layers.reversed : map.layers)
          .whereType<SmartTileLayer>()
          .where((layer) => layer.isVisible && layer.opacity > 0)
          .toList();
  return Map.unmodifiable({
    for (var index = 0; index < paintedLayers.length; index++)
      paintedLayers[index].id: index,
  });
}

SpatialSmartTileModelProjection resolveSpatialSmartTileModelProjection({
  required MapData map,
  required ProjectSmartTileCatalog catalog,
  int projectSeed = 0,
  int sourceCellWidth = 32,
  int sourceCellHeight = 32,
}) {
  final scene = map.spatialScene;
  if (scene == null) {
    return (
      instances: const [],
      groundReplacements: const {},
      cellOrigins: const {},
      paintHeightInstanceIds: const {},
    );
  }
  if (sourceCellWidth <= 0 || sourceCellHeight <= 0) {
    throw ArgumentError('Source cell dimensions must be positive.');
  }
  final presets = {for (final preset in catalog.presets) preset.id: preset};
  final patterns = {
    for (final pattern in catalog.patterns) pattern.id: pattern,
  };
  final result = <SpatialModelInstance>[];
  final groundReplacements = <String, Set<(int, int)>>{};
  final cellOrigins = <String, ({String layerId, GridPos cell})>{};
  final paintHeightInstanceIds = <String>{};
  final layerRanks = spatialSmartTileLayerPaintRanks(map);
  for (final layer in map.layers.whereType<SmartTileLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) continue;
    final preset = presets[layer.presetId];
    if (preset == null || preset.usage != layer.usage) continue;
    final owners =
        <
          int,
          ({ProjectSmartTilePattern pattern, SmartTilePatternStroke stroke})
        >{};
    final cells = <String, Map<int, SmartTilePatternCell>>{};
    for (final stroke in layer.patternStrokes) {
      final pattern = patterns[stroke.patternId];
      if (pattern == null || pattern.usage != layer.usage) continue;
      cells.putIfAbsent(
        pattern.id,
        () => {
          for (final cell in pattern.cells)
            cell.y * pattern.width + cell.x: cell,
        },
      );
      for (final cell in stroke.cells) {
        if (cell.x >= 0 &&
            cell.y >= 0 &&
            cell.x < scene.width &&
            cell.y < scene.depth) {
          owners[cell.y * scene.width + cell.x] = (
            pattern: pattern,
            stroke: stroke,
          );
        }
      }
    }
    final hasModels = preset.rules.any(
      (rule) => rule.candidates.any(
        (candidate) => candidate.parts.any(
          (part) => part.source is SmartTileModel3dSource,
        ),
      ),
    );
    if (hasModels) {
      final resolver = PreparedSmartTileResolver(
        preset: preset,
        materials: catalog.materials,
        mapId: map.id,
        layerId: layer.id,
        projectSeed: projectSeed,
        layerSeed: layer.layerSeed,
        candidateWeights: layer.candidateWeights,
      );
      for (var z = 0; z < scene.depth; z++) {
        for (var x = 0; x < scene.width; x++) {
          final owner = owners[z * scene.width + x];
          if (owner != null) {
            final pattern = owner.pattern;
            final px = (x + owner.stroke.phaseX) % pattern.width;
            final pz = (z + owner.stroke.phaseY) % pattern.height;
            final patterned = cells[pattern.id]![pz * pattern.width + px];
            if (patterned?.parts.any(
                  (part) => part.source is SmartTileModel3dSource,
                ) ??
                false) {
              continue;
            }
          }
          final resolved = resolver.resolve(
            context: smartTileCellContextForLayerCell(
              layer: layer,
              map: map,
              preset: preset,
              x: x,
              y: z,
            ),
            x: x,
            y: z,
          );
          final paintHeights = _partPaintHeights(
            resolved.parts,
            layerRanks[layer.id]!,
          );
          for (var index = 0; index < resolved.parts.length; index++) {
            final part = resolved.parts[index];
            _addModel(
              result,
              groundReplacements: groundReplacements,
              cellOrigins: cellOrigins,
            paintHeightInstanceIds: paintHeightInstanceIds,
              map: map,
              layer: layer,
              part: part,
              x: x,
              z: z,
              key: 'rule-$index',
              paintHeight: paintHeights[index],
              transform: composeSmartTileSpriteTransforms(
                first: part.transform,
                second: resolved.transform,
              ),
              sourceCellWidth: sourceCellWidth,
              sourceCellHeight: sourceCellHeight,
            );
          }
        }
      }
    }
    final orderedOwners = owners.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    for (final entry in orderedOwners) {
      final x = entry.key % scene.width, z = entry.key ~/ scene.width;
      final pattern = entry.value.pattern, stroke = entry.value.stroke;
      final px = (x + stroke.phaseX) % pattern.width;
      final pz = (z + stroke.phaseY) % pattern.height;
      final cell = cells[pattern.id]![pz * pattern.width + px];
      if (cell == null) continue;
      final paintHeights = _partPaintHeights(cell.parts, layerRanks[layer.id]!);
      for (var index = 0; index < cell.parts.length; index++) {
        final part = cell.parts[index];
        _addModel(
          result,
          groundReplacements: groundReplacements,
          cellOrigins: cellOrigins,
          paintHeightInstanceIds: paintHeightInstanceIds,
          map: map,
          layer: layer,
          part: part,
          x: x,
          z: z,
          key: 'pattern-$index',
          paintHeight: paintHeights[index],
          transform: part.transform,
          sourceCellWidth: sourceCellWidth,
          sourceCellHeight: sourceCellHeight,
        );
      }
    }
  }
  return (
    instances: List<SpatialModelInstance>.unmodifiable(result),
    groundReplacements: Map.unmodifiable({
      for (final entry in groundReplacements.entries)
        entry.key: Set<(int, int)>.unmodifiable(entry.value),
    }),
    cellOrigins: Map.unmodifiable(cellOrigins),
    paintHeightInstanceIds: Set.unmodifiable(paintHeightInstanceIds),
  );
}

List<double> _partPaintHeights(List<SmartTileVisualPart> parts, int layerRank) {
  final ordered = List<int>.generate(parts.length, (index) => index)
    ..sort((a, b) {
      final order = parts[a].drawOrder.compareTo(parts[b].drawOrder);
      return order == 0 ? a.compareTo(b) : order;
    });
  final heights = List<double>.filled(parts.length, 0);
  for (var rank = 0; rank < ordered.length; rank++) {
    heights[ordered[rank]] = spatialSmartTileLayerPaintStep * (layerRank + 1 + rank / ordered.length);
  }
  return heights;
}

void _addModel(
  List<SpatialModelInstance> result, {
  required Map<String, Set<(int, int)>> groundReplacements,
  required Map<String, ({String layerId, GridPos cell})> cellOrigins,
  required Set<String> paintHeightInstanceIds,
  required MapData map,
  required SmartTileLayer layer,
  required SmartTileVisualPart part,
  required int x,
  required int z,
  required String key,
  required double paintHeight,
  required SmartTileSpriteTransform transform,
  required int sourceCellWidth,
  required int sourceCellHeight,
}) {
  final source = part.source;
  if (source is! SmartTileModel3dSource) return;
  final clip = part.spatialClip;
  if (clip != null &&
      (!const {
            SmartTileRenderChannel.ground,
            SmartTileRenderChannel.understory,
            SmartTileRenderChannel.canopy,
          }.contains(part.channel) ||
          source.animationIndex != null ||
          (source.replacesGround &&
              (clip.left != 0 ||
                  clip.top != 0 ||
                  clip.right != 1 ||
                  clip.bottom != 1)))) {
    throw const FormatException(
      'Model clipping requires static ground, understory or canopy visuals and complete ground replacements.',
    );
  }
  if (transform.flipX) {
    throw const FormatException('3D Smart Tiles cannot mirror models.');
  }
  if (!source.offsetX.isFinite ||
      !source.offsetY.isFinite ||
      !source.offsetZ.isFinite) {
    throw const FormatException('3D Smart Tile source offsets must be finite.');
  }
  final pixel = part.offsetUnit == SmartTileOffsetUnit.pixel;
  final dx =
      (part.footprintWidth - 1) / 2 -
      part.anchorX +
      part.offsetX / (pixel ? sourceCellWidth : 1) +
      source.offsetX;
  final dz =
      (part.footprintHeight - 1) / 2 -
      part.anchorY +
      part.offsetY / (pixel ? sourceCellHeight : 1) +
      source.offsetZ;
  final rotated = switch (transform.quarterTurns % 4) {
    0 => (dx, dz),
    1 => (-dz, dx),
    2 => (-dx, -dz),
    _ => (dz, -dx),
  };
  final worldX = x + .5 + rotated.$1;
  final worldZ = z + .5 + rotated.$2;
  final supportDx = clip == null
      ? dx
      : dx -
            source.offsetX +
            ((clip.left + clip.right) / 2 - .5) * part.footprintWidth;
  final supportDz = clip == null
      ? dz
      : dz -
            source.offsetZ +
            ((clip.top + clip.bottom) / 2 - .5) * part.footprintHeight;
  final supportRotated = switch (transform.quarterTurns % 4) {
    0 => (supportDx, supportDz),
    1 => (-supportDz, supportDx),
    2 => (-supportDx, -supportDz),
    _ => (supportDz, -supportDx),
  };
  final supportX = x + .5 + supportRotated.$1;
  final supportZ = z + .5 + supportRotated.$2;
  final scene = map.spatialScene!;
  if (supportX < 0 ||
      supportZ < 0 ||
      supportX >= scene.width ||
      supportZ >= scene.depth) {
    throw const FormatException('A 3D Smart Tile anchor is outside the map.');
  }
  if (source.replacesGround) {
    if (part.footprintWidth != 1 ||
        part.footprintHeight != 1 ||
        part.channel != SmartTileRenderChannel.ground) {
      throw const FormatException(
        'Ground replacement requires a one-cell ground model.',
      );
    }
    groundReplacements.putIfAbsent(layer.id, () => {}).add((x, z));
  }
  final digest = sha256.convert(
    utf8.encode('${map.id}|${layer.id}|$x|$z|$key'),
  );
  final instanceId = 'smt_$digest';
  cellOrigins[instanceId] = (layerId: layer.id, cell: GridPos(x: x, y: z));
  final receivesPaintHeight = source.followTerrain &&
      !source.replacesGround &&
      (part.channel == SmartTileRenderChannel.ground || part.channel == SmartTileRenderChannel.understory);
  if (receivesPaintHeight) paintHeightInstanceIds.add(instanceId);
  result.add(
    SpatialModelInstance(
      id: instanceId,
      modelId: source.modelId,
      position: Model3dVector3(
        x: worldX,
        z: worldZ,
        y:
            (source.followTerrain
                ? scene.worldHeightAt(supportX, supportZ)
                : 0) +
            source.offsetY +
            (receivesPaintHeight ? paintHeight : 0),
      ),
      rotationDegrees: -(transform.quarterTurns % 4) * 90.0,
      scale: source.scale,
      animationIndex: source.animationIndex,
      blocksMovement: false,
      clip: clip == null
          ? null
          : SpatialModelClip(
              left:
                  clip.left * part.footprintWidth -
                  part.footprintWidth / 2 -
                  source.offsetX,
              top:
                  clip.top * part.footprintHeight -
                  part.footprintHeight / 2 -
                  source.offsetZ,
              right:
                  clip.right * part.footprintWidth -
                  part.footprintWidth / 2 -
                  source.offsetX,
              bottom:
                  clip.bottom * part.footprintHeight -
                  part.footprintHeight / 2 -
                  source.offsetZ,
            ),
    ),
  );
}

bool _sameInstances(
  List<SpatialModelInstance> first,
  List<SpatialModelInstance> second,
) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
