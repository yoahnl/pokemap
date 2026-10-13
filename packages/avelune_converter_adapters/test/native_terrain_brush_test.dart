import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'package:avelune_converter_adapters/src/native_terrain_brush.dart';

void main() {
  test('sixteen cardinal forms preserve every source quadrant RGBA sample', () {
    final source = _source();
    final brush = _compile(image.encodePng(source));
    final output = image.decodePng(brush.imageBytes)!;
    expect((output.width, output.height, output.numChannels), (128, 128, 4));
    const sourceCells = <List<int>>[
      [0, 2, 6, 8],
      [3, 5, 6, 8],
      [0, 1, 6, 7],
      [3, 4, 6, 7],
      [0, 2, 3, 5],
      [3, 5, 3, 5],
      [0, 1, 3, 4],
      [3, 4, 3, 4],
      [1, 2, 7, 8],
      [4, 5, 7, 8],
      [1, 1, 7, 7],
      [4, 4, 7, 7],
      [1, 2, 4, 5],
      [4, 5, 4, 5],
      [1, 1, 4, 4],
      [4, 4, 4, 4],
    ];
    for (var mask = 0; mask < 16; mask++) {
      for (var quadrant = 0; quadrant < 4; quadrant++) {
        final sourceCell = sourceCells[mask][quadrant];
        final halfX = (quadrant % 2) * 16;
        final halfY = (quadrant ~/ 2) * 16;
        for (var y = 0; y < 16; y++) {
          for (var x = 0; x < 16; x++) {
            expect(
              _rgba(output.getPixel(
                (mask % 4) * 32 + halfX + x,
                (mask ~/ 4) * 32 + halfY + y,
              )),
              _rgba(source.getPixel(
                (sourceCell % 3) * 32 + halfX + x,
                (sourceCell ~/ 3) * 32 + halfY + y,
              )),
              reason: 'mask $mask quadrant $quadrant pixel $x,$y',
            );
          }
        }
      }
    }
  });

  test('the fully connected form preserves the entire source center tile', () {
    final source = _source();
    final output =
        image.decodePng(_compile(image.encodePng(source)).imageBytes)!;
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        expect(
          _rgba(output.getPixel(96 + x, 96 + y)),
          _rgba(source.getPixel(32 + x, 32 + y)),
        );
      }
    }
  });

  test('native catalog validation and coverage resolve every form exactly', () {
    final brush = _compile(image.encodePng(_source()));
    final catalog = _catalog(brush);
    expect(
        validateProjectSmartTileCatalog(
          catalog: catalog,
          projectTilesetIds: [brush.atlas.tilesetId],
        ),
        isEmpty);
    final report = analyzeSmartTileCoverage(
      preset: brush.preset,
      materials: catalog.materials,
      atlases: catalog.atlases,
      animations: catalog.animations,
    );
    expect(report.isExact, isTrue);
    expect(report.exactCount, 16);
    expect(report.fallbackCount, 0);
    expect(report.transformedCount, 0);
    expect(brush.preset.topology, SmartTileTopology.cardinal4);
    expect(brush.preset.templateHint, SmartTileTemplateHint.edge16);
    expect(brush.preset.usage, SmartTileUsage.path);
    expect(brush.preset.status, SmartTilePresetStatus.published);
    expect(brush.preset.coveragePolicy, SmartTileCoveragePolicy.sparse);
    expect(brush.preset.fallbackRuleId, isNull);
    expect(brush.material.pathSurfaceKind, PathSurfaceKind.path);
    for (final result in runSmartTileTemplateBench(
      preset: brush.preset,
      materials: catalog.materials,
      materialId: brush.material.id,
    )) {
      expect(result.resolution.status, SmartTileResolutionStatus.resolved);
      expect(result.resolution.usedFallback, isFalse);
      expect(result.resolution.transform, const SmartTileSpriteTransform());
      final frame =
          (result.resolution.parts.single.source as SmartTileFrameSource).frame;
      expect((frame.column, frame.row), (result.mask % 4, result.mask ~/ 4));
      expect(result.resolution.parts.single.channel,
          SmartTileRenderChannel.ground);
      expect(result.resolution.parts.single.frameSampling,
          SmartTileFrameSampling.fullFrame);
    }
  });

  test(
      'native layer starts empty and neighboring paint changes the resolved form',
      () {
    final brush = _compile(image.encodePng(_source()));
    final catalog = _catalog(brush);
    const map = MapData(
        id: 'route',
        name: 'Route',
        version: ProjectVersion.v8,
        size: GridSize(width: 5, height: 5));
    final manifest = ProjectManifest(
        name: 'Brush fixture',
        version: ProjectVersion.v8,
        maps: const [
          ProjectMapEntry(
              id: 'route', name: 'Route', relativePath: 'maps/route.json')
        ],
        tilesets: [
          ProjectTilesetEntry(
              id: brush.atlas.tilesetId,
              name: 'Brush',
              relativePath: 'assets/brush.png',
              source: ProjectTilesetSource.regularAtlas(
                  assetId: 'brush-image',
                  pixelWidth: 128,
                  pixelHeight: 128,
                  tileWidth: 32,
                  tileHeight: 32))
        ],
        smartTileCatalog: catalog);
    final creation = planNativeSmartTileLayerCreationForMap(
        map: map,
        manifest: manifest,
        preset: brush.preset,
        layerId: 'path',
        layerName: 'Path');
    expect(creation, isA<SmartTileLayerCreationSuccess>());
    final created = (creation as SmartTileLayerCreationSuccess).map;
    var layer = created.layers.single as SmartTileLayer;
    expect(smartTileSemanticCells(layer), List<int>.filled(25, 0));
    layer = applySmartTileMaterialGesture(layer,
        mapSize: map.size,
        cells: const [GridPos(x: 2, y: 2)],
        materialId: brush.material.id);
    expect(_centerRect(created, layer, catalog),
        const SmartTileSourceRect(x: 0, y: 0, width: 32, height: 32));
    layer = applySmartTileMaterialGesture(layer,
        mapSize: map.size,
        cells: const [GridPos(x: 3, y: 2)],
        materialId: brush.material.id);
    expect(_centerRect(created, layer, catalog),
        const SmartTileSourceRect(x: 64, y: 0, width: 32, height: 32));
    layer = applySmartTileMaterialGesture(layer,
        mapSize: map.size,
        cells: const [GridPos(x: 3, y: 2)],
        materialId: null);
    expect(_centerRect(created, layer, catalog),
        const SmartTileSourceRect(x: 0, y: 0, width: 32, height: 32));
    final reloaded =
        MapData.fromJson(replaceSmartTileLayer(created, layer: layer).toJson());
    expect(
        _centerRect(reloaded, reloaded.layers.single as SmartTileLayer,
            ProjectSmartTileCatalog.fromJson(catalog.toJson())),
        const SmartTileSourceRect(x: 0, y: 0, width: 32, height: 32));
  });

  test('diagonal-only neighbors do not imply Blob47 support', () {
    final brush = _compile(image.encodePng(_source()));
    final result = resolveSmartTile(
        preset: brush.preset,
        materials: [brush.material],
        context: SmartTileCellContext(
            centerMaterialId: brush.material.id,
            observed: SmartTileObservedSignature(
                northWestCorner:
                    SmartTileObservedSlot.inside(materialId: brush.material.id),
                northEastCorner:
                    SmartTileObservedSlot.inside(materialId: brush.material.id),
                southWestCorner:
                    SmartTileObservedSlot.inside(materialId: brush.material.id),
                southEastCorner: SmartTileObservedSlot.inside(
                    materialId: brush.material.id))),
        x: 0,
        y: 0);
    expect((result.parts.single.source as SmartTileFrameSource).frame,
        SmartTileFrameRef(atlasId: brush.atlas.id, column: 0, row: 0));
  });

  test('equivalent PNG encodings produce identical immutable artifacts', () {
    final source = _source();
    final firstInput = image.encodePng(source, level: 0);
    final savedInput = Uint8List.fromList(firstInput);
    final first = _compile(firstInput);
    final second = _compile(image.encodePng(source, level: 9));
    expect(first.imageBytes, second.imageBytes);
    expect(first.preset, second.preset);
    expect(firstInput, savedInput);
    expect(() => first.imageBytes[0] = 0, throwsUnsupportedError);
    firstInput[0] = 0;
    expect(first.imageBytes, second.imageBytes);
  });

  test('rejects invalid PNG and non-96-square geometry', () {
    expect(() => _compile([1, 2, 3]), throwsFormatException);
    expect(() => _compile(image.encodePng(image.Image(width: 96, height: 64))),
        throwsFormatException);
    expect(() => _compile(image.encodeJpg(_source())), throwsFormatException);
  });

  test('rejects source bytes above the bounded PNG budget', () {
    expect(
        () => _compile(
            List<int>.filled(NativeTerrainBrush.maximumSourcePngBytes + 1, 0)),
        throwsFormatException);
    final bytes = image.encodePng(_source()).toList()..[0] = 256;
    expect(() => _compile(bytes), throwsFormatException);
  });

  test('rejects noncanonical identities and blank names', () {
    final bytes = image.encodePng(_source());
    expect(
        () => NativeTerrainBrush.compile(
            sourcePngBytes: bytes,
            tilesetId: ' tileset',
            atlasId: 'atlas',
            materialId: 'material',
            presetId: 'preset',
            name: 'Path'),
        throwsFormatException);
    expect(
        () => NativeTerrainBrush.compile(
            sourcePngBytes: bytes,
            tilesetId: 'tileset',
            atlasId: 'atlas',
            materialId: 'material',
            presetId: '',
            name: 'Path'),
        throwsFormatException);
    expect(
        () => NativeTerrainBrush.compile(
            sourcePngBytes: bytes,
            tilesetId: 'tileset',
            atlasId: 'atlas',
            materialId: 'material',
            presetId: 'preset',
            name: '  '),
        throwsFormatException);
  });
}

NativeTerrainBrush _compile(List<int> bytes) => NativeTerrainBrush.compile(
    sourcePngBytes: bytes,
    tilesetId: 'path-tileset',
    atlasId: 'path-atlas',
    materialId: 'path-material',
    presetId: 'path-preset',
    name: 'Original path');

image.Image _source() {
  final source = image.Image(width: 96, height: 96, numChannels: 4);
  for (var y = 0; y < 96; y++) {
    for (var x = 0; x < 96; x++) {
      source.setPixelRgba(
          x,
          y,
          (x * 7 + y * 3) % 256,
          (x * 5 + y * 11) % 256,
          (x * 13 + y * 17) % 256,
          (x + y) % 4 == 0 ? 0 : (x * 19 + y * 23) % 256);
    }
  }
  return source;
}

List<int> _rgba(image.Pixel pixel) =>
    [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt()];

ProjectSmartTileCatalog _catalog(NativeTerrainBrush brush) =>
    ProjectSmartTileCatalog(
        atlases: [brush.atlas],
        materials: [brush.material],
        presets: [brush.preset]);

SmartTileSourceRect _centerRect(
        MapData map, SmartTileLayer layer, ProjectSmartTileCatalog catalog) =>
    resolveSmartTileLayerVisuals(
            map: replaceSmartTileLayer(map, layer: layer),
            layer: layer,
            catalog: catalog,
            pass: SmartTileVisualPass.background)
        .singleWhere((visual) => visual.cellX == 2 && visual.cellY == 2)
        .sourceRect;
