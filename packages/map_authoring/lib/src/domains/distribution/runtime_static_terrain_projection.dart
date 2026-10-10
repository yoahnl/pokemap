import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

final class RuntimeStaticTerrainProjection {
  RuntimeStaticTerrainProjection({
    required this.project,
    required this.maps,
    required this.assets,
  });

  final ProjectManifest project;
  final List<MapData> maps;
  final Map<String, List<int>> assets;
}

Future<RuntimeStaticTerrainProjection> projectRuntimeStaticTerrain({
  required ProjectManifest project,
  required List<MapData> maps,
  required Future<List<int>> Function(String path) readAsset,
  int minimumRuleCount = 64,
}) async {
  final catalog = project.smartTileCatalog;
  final atlases = {for (final atlas in catalog.atlases) atlas.id: atlas};
  final tilesets = {
    for (final tileset in project.tilesets) tileset.id: tileset
  };
  final materials = {
    for (final material in catalog.materials) material.id: material
  };
  final materialIds = materials.keys.toSet();
  final externalProjectJson = project.toJson()..remove('smartTileCatalog');
  final protectedMaterials = <String>{
    ..._references(externalProjectJson, materialIds),
    ..._references(
        catalog.patterns.map((p) => p.toJson()).toList(), materialIds),
    ..._references(catalog.drafts.map((d) => d.toJson()).toList(), materialIds),
  };
  final paletteOwners = <String, Set<(String, String)>>{};
  for (final map in maps) {
    protectedMaterials
        .addAll(_references(map.toJson()..remove('layers'), materialIds));
    for (final layer in map.layers) {
      final metadata = layer.toJson();
      if (layer is SmartTileLayer) {
        metadata.remove('materialPalette');
        for (final id in layer.materialPalette) {
          paletteOwners.putIfAbsent(id, () => {}).add((map.id, layer.id));
        }
      }
      protectedMaterials.addAll(_references(metadata, materialIds));
    }
  }
  final owners = <String, List<(int, SmartTileLayer)>>{};
  for (var index = 0; index < maps.length; index++) {
    for (final layer in maps[index].layers.whereType<SmartTileLayer>()) {
      owners.putIfAbsent(layer.presetId, () => []).add((index, layer));
    }
  }
  final materialOwners = <String, Set<String>>{};
  for (final preset in catalog.presets) {
    for (final id in preset.allowedMaterialIds) {
      materialOwners.putIfAbsent(id, () => {}).add(preset.id);
    }
  }
  final projectedMaps = maps.toList();
  final projectedPresets = catalog.presets.toList();
  final projectedAtlases = catalog.atlases.toList();
  final projectedTilesets = project.tilesets.toList();
  final removedMaterials = <String>{};
  final assets = <String, List<int>>{};
  final decodedImages = <String, image.Image>{};
  for (var presetIndex = 0;
      presetIndex < catalog.presets.length;
      presetIndex++) {
    final preset = catalog.presets[presetIndex];
    final uses = owners[preset.id];
    if (uses == null ||
        uses.length != 1 ||
        preset.rules.length < minimumRuleCount ||
        !const {
          SmartTileTopology.uniform,
          SmartTileTopology.cardinal4,
          SmartTileTopology.blob8
        }.contains(preset.topology) ||
        preset.transformPolicy != const SmartTileTransformPolicy() ||
        preset.fallbackRuleId != null ||
        preset.rules.any((rule) => !_isStaticRule(rule))) {
      continue;
    }
    final (mapIndex, layer) = uses.single;
    final map = maps[mapIndex];
    if (layer.field is! SmartTileCellField ||
        layer.patternStrokes.isNotEmpty ||
        layer.candidateWeights.isNotEmpty ||
        layer.encounterBehavior != null) {
      continue;
    }
    final sourceIds = preset.allowedMaterialIds.toSet();
    if (sourceIds.any((id) => materialOwners[id]?.length != 1) ||
        sourceIds
            .any((id) => materials[id] == null || materials[id]!.isEmpty) ||
        sourceIds.any(protectedMaterials.contains) ||
        sourceIds.any((id) => (paletteOwners[id]?.length ?? 0) > 1)) {
      continue;
    }
    final rules = <String, SmartTileRule>{};
    var valid = true;
    for (final rule in preset.rules) {
      final id = rule.centerMatch.materialId!;
      if (!sourceIds.contains(id) || rules.containsKey(id)) {
        valid = false;
        break;
      }
      rules[id] = rule;
    }
    if (!valid ||
        !sourceIds.every(rules.containsKey) ||
        layer.materialPalette
            .any((id) => id.isNotEmpty && !sourceIds.contains(id))) {
      continue;
    }
    final firstPart = preset.rules.first.candidates.single.parts.single;
    final firstFrame = _frame(firstPart);
    final firstAtlas = atlases[firstFrame.atlasId];
    if (firstAtlas == null) continue;
    final width = map.size.width * firstAtlas.cellWidth;
    final height = map.size.height * firstAtlas.cellHeight;
    if (width > 8192 || height > 8192 || width * height > 16777216) continue;
    for (final rule in preset.rules) {
      final part = rule.candidates.single.parts.single;
      final atlas = atlases[_frame(part).atlasId];
      final tileset = atlas == null ? null : tilesets[atlas.tilesetId];
      if (atlas == null ||
          tileset == null ||
          atlas.cellWidth != firstAtlas.cellWidth ||
          atlas.cellHeight != firstAtlas.cellHeight ||
          atlas.pixelOffsetX != 0 ||
          atlas.pixelOffsetY != 0 ||
          part.copyWith(source: firstPart.source) != firstPart) {
        valid = false;
        break;
      }
    }
    if (!valid) continue;
    final cells = (layer.field as SmartTileCellField).semanticCells;
    if (cells.length != map.size.width * map.size.height ||
        cells.any(
            (index) => index < 0 || index >= layer.materialPalette.length)) {
      continue;
    }
    final token = sha256
        .convert(utf8.encode('${map.id}/${layer.id}'))
        .toString()
        .substring(0, 24);
    final atlasId = 'runtime-terrain-atlas-$token';
    final tilesetId = 'runtime-terrain-tileset-$token';
    final assetId = 'runtime-terrain-image-$token';
    final assetPath = 'assets/tilesets/runtime/$token.png';
    if (atlases.containsKey(atlasId) || tilesets.containsKey(tilesetId)) {
      continue;
    }
    final destination =
        image.Image(width: width, height: height, numChannels: 4);
    for (var index = 0; index < cells.length; index++) {
      final materialId = layer.materialPalette[cells[index]];
      if (materialId.isEmpty) continue;
      final frame = _frame(rules[materialId]!.candidates.single.parts.single);
      final atlas = atlases[frame.atlasId]!;
      final tileset = tilesets[atlas.tilesetId]!;
      var source = decodedImages[tileset.relativePath];
      if (source == null) {
        source = image.decodeImage(
            Uint8List.fromList(await readAsset(tileset.relativePath)));
        if (source == null) {
          throw FormatException('Cannot decode terrain atlas ${atlas.id}');
        }
        decodedImages[tileset.relativePath] = source;
      }
      if (source.maxChannelValue != 255 || source.numFrames != 1) {
        valid = false;
        break;
      }
      final rect = atlas.sourceRectFor(column: frame.column, row: frame.row);
      if (rect.x < 0 ||
          rect.y < 0 ||
          rect.x + rect.width > source.width ||
          rect.y + rect.height > source.height) {
        throw FormatException('Terrain frame escapes atlas ${atlas.id}');
      }
      final destinationX = index % map.size.width * firstAtlas.cellWidth;
      final destinationY = index ~/ map.size.width * firstAtlas.cellHeight;
      for (var y = 0; y < firstAtlas.cellHeight; y++) {
        for (var x = 0; x < firstAtlas.cellWidth; x++) {
          destination.setPixel(destinationX + x, destinationY + y,
              source.getPixel(rect.x + x, rect.y + y));
        }
      }
    }
    if (!valid) continue;
    final groupRepresentatives = <String, String>{};
    final replacements = <String, String>{};
    for (final id in preset.allowedMaterialIds) {
      final traits = materials[id]!.toJson()
        ..remove('id')
        ..remove('name')
        ..remove('sortOrder');
      final representative =
          groupRepresentatives.putIfAbsent(jsonEncode(traits), () => id);
      replacements[id] = representative;
      if (representative != id) removedMaterials.add(id);
    }
    final allowed = replacements.values.toSet().toList();
    final palette = <String>[''];
    final indices = <String, int>{'': 0};
    final remappedCells = <int>[];
    for (final index in cells) {
      final id = layer.materialPalette[index];
      final replacement = id.isEmpty ? '' : replacements[id]!;
      remappedCells.add(indices.putIfAbsent(replacement, () {
        palette.add(replacement);
        return palette.length - 1;
      }));
    }
    final fullFrame = SmartTileVisualSource.frame(
        frame: SmartTileFrameRef(
      atlasId: atlasId,
      column: 0,
      row: 0,
      columnSpan: map.size.width,
      rowSpan: map.size.height,
    ));
    projectedPresets[presetIndex] = preset.copyWith(
      defaultMaterialId: replacements[preset.defaultMaterialId]!,
      allowedMaterialIds: allowed,
      rules: [
        for (final id in allowed)
          rules[id]!.copyWith(candidates: [
            rules[id]!
                .candidates
                .single
                .copyWith(parts: [firstPart.copyWith(source: fullFrame)]),
          ])
      ],
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        requiredScenarios: [
          for (final id in allowed)
            SmartTileCoverageScenario(
              id: 'runtime-$id',
              centerMaterialId: id,
            )
        ],
      ),
    );
    final replacementLayer = layer.copyWith(
      materialPalette: palette,
      field: SmartTileField.cell(semanticCells: remappedCells),
    );
    projectedMaps[mapIndex] = projectedMaps[mapIndex].copyWith(layers: [
      for (final existing in projectedMaps[mapIndex].layers)
        existing.id == layer.id ? replacementLayer : existing,
    ]);
    projectedAtlases.add(firstAtlas.copyWith(
      id: atlasId,
      tilesetId: tilesetId,
      originX: 0,
      originY: 0,
      marginX: 0,
      marginY: 0,
      spacingX: 0,
      spacingY: 0,
      columns: map.size.width,
      rows: map.size.height,
    ));
    final tilesetJson = tilesets[firstAtlas.tilesetId]!.toJson();
    tilesetJson['id'] = tilesetId;
    tilesetJson['relativePath'] = assetPath;
    tilesetJson['source'] = {
      'kind': 'regular_atlas',
      'assetId': assetId,
      'pixelWidth': width,
      'pixelHeight': height,
      'tileWidth': firstAtlas.cellWidth,
      'tileHeight': firstAtlas.cellHeight,
      'tileProperties': <Object?>[],
    };
    projectedTilesets.add(ProjectTilesetEntry.fromJson(tilesetJson));
    assets[assetPath] = image.encodePng(destination);
  }
  if (assets.isEmpty) {
    return RuntimeStaticTerrainProjection(
        project: project, maps: maps, assets: assets);
  }
  return RuntimeStaticTerrainProjection(
    project: project.copyWith(
      tilesets: projectedTilesets,
      smartTileCatalog: ProjectSmartTileCatalog(
        categories: catalog.categories,
        atlases: projectedAtlases,
        materials: catalog.materials
            .where((m) => !removedMaterials.contains(m.id))
            .toList(),
        animations: catalog.animations,
        presets: projectedPresets,
        patterns: catalog.patterns,
        drafts: catalog.drafts,
      ),
    ),
    maps: projectedMaps,
    assets: assets,
  );
}

bool _isStaticRule(SmartTileRule rule) {
  if (rule.centerMatch.kind != SmartTileMatchKind.material ||
      rule.signature != const SmartTileSignature() ||
      rule.candidates.length != 1 ||
      rule.candidates.single.weight != 1 ||
      rule.candidates.single.parts.length != 1) {
    return false;
  }
  final part = rule.candidates.single.parts.single;
  return part.frameSampling == SmartTileFrameSampling.tessellated &&
      part.source.when(
          frame: (frame) => frame.columnSpan == 1 && frame.rowSpan == 1,
          animation: (_) => false);
}

SmartTileFrameRef _frame(SmartTileVisualPart part) => part.source.when(
      frame: (frame) => frame,
      animation: (_) => throw StateError('Static terrain cannot use animation'),
    );

Set<String> _references(Object? root, Set<String> ids) {
  final result = <String>{};
  final pending = <Object?>[root];
  while (pending.isNotEmpty) {
    final value = pending.removeLast();
    if (value is String && ids.contains(value)) {
      result.add(value);
    } else if (value is List) {
      pending.addAll(value);
    } else if (value is Map) {
      pending.addAll(value.values);
    }
  }
  return result;
}
