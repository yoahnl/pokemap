import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:path/path.dart' as p;

const String kPortVisualMapId = 'map_port_brisants';
const int kPortVisualCellPixels = 32;
const String _outputDirectoryEnvironmentKey =
    'SELBRUME_PORT_VISUAL_CAPTURE_OUTPUT_DIR';

final class PortVisualRegion {
  const PortVisualRegion({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final String id;
  final int left;
  final int top;
  final int width;
  final int height;

  int get pixelWidth => width * kPortVisualCellPixels;
  int get pixelHeight => height * kPortVisualCellPixels;
}

const PortVisualRegion kPortVisualOverviewRegion = PortVisualRegion(
  id: 'overview',
  left: 0,
  top: 0,
  width: 45,
  height: 34,
);

/// Regions mirror the six user review captures while staying snapped to map
/// cells. C1 intentionally repeats the complete map: the historical C1 was the
/// editor overview, while the dedicated `overview` artifact is the canonical
/// dimension contract consumed by tooling.
const List<PortVisualRegion> kPortVisualReviewRegions = <PortVisualRegion>[
  PortVisualRegion(
    id: 'c1_full_map',
    left: 0,
    top: 0,
    width: 45,
    height: 34,
  ),
  PortVisualRegion(
    id: 'c2_west_orange_house',
    left: 4,
    top: 2,
    width: 18,
    height: 16,
  ),
  PortVisualRegion(
    id: 'c3_harbor_master_blue_house',
    left: 17,
    top: 0,
    width: 28,
    height: 18,
  ),
  PortVisualRegion(
    id: 'c4_south_east_coast',
    left: 29,
    top: 16,
    width: 16,
    height: 18,
  ),
  PortVisualRegion(
    id: 'c5_east_pier',
    left: 24,
    top: 12,
    width: 21,
    height: 18,
  ),
  PortVisualRegion(
    id: 'c6_central_steps_quay',
    left: 12,
    top: 12,
    width: 21,
    height: 18,
  ),
];

final class PortVisualScene {
  const PortVisualScene({
    required this.bundle,
    required this.tileImagesByTilesetId,
  });

  final RuntimeMapBundle bundle;
  final Map<String, RuntimeTilesetImage> tileImagesByTilesetId;
}

Future<PortVisualScene> loadPortVisualScene({String? repositoryRoot}) async {
  final root = repositoryRoot == null
      ? _resolveRepositoryRoot()
      : Directory(p.normalize(p.absolute(repositoryRoot)));
  final projectRoot = p.join(root.path, 'selbrume');
  final projectFile = File(p.join(projectRoot, 'project.json'));
  final projectJson = await _readJsonObject(projectFile);
  final manifest = ProjectManifest.fromJson(projectJson);
  final mapEntry = manifest.maps.singleWhere(
    (entry) => entry.id == kPortVisualMapId,
    orElse: () => throw StateError(
      'Project does not register $kPortVisualMapId.',
    ),
  );
  final mapFile = File(p.join(projectRoot, mapEntry.relativePath));
  final mapJson = await _readJsonObject(mapFile);

  // Decode a visual projection rather than the gameplay document. Only layer
  // kinds painted by this runner are copied, and entities are removed so the
  // captures contain no labels, selection affordances or actor sprites.
  final visualMapJson = Map<String, dynamic>.from(mapJson)
    ..['layers'] = <Map<String, dynamic>>[
      for (final rawLayer in _jsonObjectList(mapJson['layers']))
        if (_visualLayerRuntimeTypes.contains(rawLayer['runtimeType']))
          rawLayer,
    ]
    ..['entities'] = <Map<String, dynamic>>[];
  final map = MapData.fromJson(visualMapJson);

  final tilesetIds = _collectVisualTilesetIds(map, manifest);
  final tilesetById = <String, ProjectTilesetEntry>{
    for (final tileset in manifest.tilesets) tileset.id: tileset,
  };
  final paths = <String, String>{};
  final transparentColors = <String, TilesetTransparentColor>{};
  for (final tilesetId in tilesetIds) {
    final tileset = tilesetById[tilesetId];
    if (tileset == null) {
      throw StateError('Visual tileset is not registered: $tilesetId');
    }
    final relativePath = tileset.relativePath.trim();
    if (relativePath.isEmpty) {
      throw StateError('Visual tileset has no file: $tilesetId');
    }
    paths[tilesetId] = p.normalize(p.join(projectRoot, relativePath));
    final transparentColor = tileset.transparentColor;
    if (transparentColor != null) {
      transparentColors[tilesetId] = transparentColor;
    }
  }

  final images = await loadTilesetImagesById(
    paths,
    transparentColorByTilesetId: transparentColors,
  );
  return PortVisualScene(
    bundle: RuntimeMapBundle(
      manifest: manifest,
      map: map,
      projectRootDirectory: projectRoot,
      tilesetAbsolutePathsById: paths,
    ),
    tileImagesByTilesetId: images,
  );
}

Future<ui.Image> renderPortVisualRegion(
  PortVisualScene scene,
  PortVisualRegion region,
) async {
  final map = scene.bundle.map;
  if (region.left < 0 ||
      region.top < 0 ||
      region.width <= 0 ||
      region.height <= 0 ||
      region.left + region.width > map.size.width ||
      region.top + region.height > map.size.height) {
    throw ArgumentError.value(
        region.id, 'region', 'Region is outside the map.');
  }

  final worldRect = ui.Rect.fromLTWH(
    region.left * scene.bundle.cellWidth,
    region.top * scene.bundle.cellHeight,
    region.width * scene.bundle.cellWidth,
    region.height * scene.bundle.cellHeight,
  );
  final background = MapLayersComponent(
    bundle: scene.bundle,
    tileImagesByTilesetId: scene.tileImagesByTilesetId,
    renderPass: MapLayerRenderPass.background,
  )..setVisibleLocalRect(worldRect);
  final foreground = MapLayersComponent(
    bundle: scene.bundle,
    tileImagesByTilesetId: scene.tileImagesByTilesetId,
    renderPass: MapLayerRenderPass.foreground,
  )..setVisibleLocalRect(worldRect);
  background.update(0);
  foreground.update(0);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.save();
  canvas.scale(
    kPortVisualCellPixels / scene.bundle.cellWidth,
    kPortVisualCellPixels / scene.bundle.cellHeight,
  );
  canvas.translate(
    -region.left * scene.bundle.cellWidth,
    -region.top * scene.bundle.cellHeight,
  );
  // Rendering the two map passes directly produces neutral-light source art.
  // No editor chrome, grid, annotation component or lighting overlay exists in
  // this runner.
  background.render(canvas);
  foreground.render(canvas);
  canvas.restore();
  return recorder.endRecording().toImage(
        region.pixelWidth,
        region.pixelHeight,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('captures the dedicated Selbrume Port visual review set', () async {
    final outputPath =
        Platform.environment[_outputDirectoryEnvironmentKey]?.trim();
    if (outputPath == null || outputPath.isEmpty) {
      throw StateError(
        '$_outputDirectoryEnvironmentKey must point to the capture directory.',
      );
    }
    final outputDirectory = Directory(p.normalize(p.absolute(outputPath)));
    await outputDirectory.create(recursive: true);

    final scene = await loadPortVisualScene();
    expect(scene.bundle.map.id, kPortVisualMapId);
    expect(scene.bundle.map.size, const GridSize(width: 45, height: 34));

    await _renderAndWrite(
      scene: scene,
      region: kPortVisualOverviewRegion,
      outputFile: File(
        p.join(outputDirectory.path, '${kPortVisualMapId}__overview.png'),
      ),
    );
    for (final region in kPortVisualReviewRegions) {
      await _renderAndWrite(
        scene: scene,
        region: region,
        outputFile: File(
          p.join(
            outputDirectory.path,
            '${kPortVisualMapId}__${region.id}.png',
          ),
        ),
      );
    }
  });
}

const Set<Object?> _visualLayerRuntimeTypes = <Object?>{
  'terrain',
  'path',
  'tile',
};

Future<Map<String, dynamic>> _readJsonObject(File file) async {
  if (!await file.exists()) {
    throw StateError('Required visual input does not exist: ${file.path}');
  }
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map<String, dynamic>) {
    throw StateError('Expected a JSON object at ${file.path}');
  }
  return decoded;
}

List<Map<String, dynamic>> _jsonObjectList(Object? raw) {
  if (raw is! List) {
    throw StateError('Expected a JSON object list for visual map layers.');
  }
  return <Map<String, dynamic>>[
    for (final entry in raw)
      if (entry is Map<String, dynamic>) entry,
  ];
}

Directory _resolveRepositoryRoot() {
  var candidate = Directory.current.absolute;
  while (true) {
    if (File(p.join(candidate.path, 'selbrume', 'project.json')).existsSync() &&
        File(p.join(candidate.path, 'packages', 'map_runtime', 'pubspec.yaml'))
            .existsSync()) {
      return candidate;
    }
    final parent = candidate.parent;
    if (parent.path == candidate.path) {
      throw StateError(
        'Could not resolve the repository root from ${Directory.current.path}.',
      );
    }
    candidate = parent;
  }
}

Set<String> _collectVisualTilesetIds(
  MapData map,
  ProjectManifest manifest,
) {
  final ids = <String>{};
  void addId(String? raw) {
    final id = raw?.trim() ?? '';
    if (id.isNotEmpty) ids.add(id);
  }

  void addFrames(String baseTilesetId, List<TilesetVisualFrame> frames) {
    addId(baseTilesetId);
    for (final frame in frames) {
      addId(frame.tilesetId);
    }
  }

  addId(map.tilesetId);
  for (final layer in map.layers) {
    if (layer is TileLayer) {
      addId(layer.tilesetId ?? map.tilesetId);
      continue;
    }
    if (layer is TerrainLayer) {
      final terrainTypes = layer.terrains.toSet();
      for (final preset in manifest.terrainPresets) {
        if (!terrainTypes.contains(preset.terrainType)) continue;
        addId(preset.tilesetId);
        for (final variant in preset.variants) {
          addFrames(preset.tilesetId, variant.frames);
        }
      }
      continue;
    }
    if (layer is PathLayer) {
      for (final preset in manifest.pathPresets) {
        if (preset.id != layer.presetId) continue;
        addId(preset.tilesetId);
        for (final variant in preset.variants) {
          addFrames(preset.tilesetId, variant.frames);
        }
        for (final pattern in manifest.pathPatternPresets) {
          if (pattern.basePathPresetId != preset.id) continue;
          for (final cell in pattern.centerPattern.cells) {
            addFrames(preset.tilesetId, cell.frames);
          }
        }
      }
    }
  }

  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  for (final placed in map.placedElements) {
    final element = elementById[placed.elementId];
    if (element == null) continue;
    addFrames(element.tilesetId, element.frames);
  }
  return ids;
}

Future<void> _renderAndWrite({
  required PortVisualScene scene,
  required PortVisualRegion region,
  required File outputFile,
}) async {
  final image = await renderPortVisualRegion(scene, region);
  try {
    expect(
        (image.width, image.height), (region.pixelWidth, region.pixelHeight));
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Could not encode visual capture ${region.id}.');
    }
    await outputFile.writeAsBytes(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
  } finally {
    image.dispose();
  }
}
