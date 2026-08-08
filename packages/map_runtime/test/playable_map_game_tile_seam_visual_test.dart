import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/pixel_perfect_overworld_camera.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Retina playable projection leaves no gaps at tile boundaries',
      () async {
    final fixtures = <_SeamFixture>[
      await _classicFixture(),
      await _smartFixture(kind: _SmartFixtureKind.uniform),
      await _smartFixture(kind: _SmartFixtureKind.tessellated),
      await _smartFixture(kind: _SmartFixtureKind.animated),
    ];
    addTearDown(() {
      for (final fixture in fixtures) {
        fixture.tileset.dispose();
      }
    });

    for (final fixture in fixtures) {
      final profiles = <MapLayersRenderProfile>[];
      final component = MapLayersComponent(
        bundle: fixture.bundle,
        tileImagesByTilesetId: <String, RuntimeTilesetImage>{
          fixture.tilesetId: fixture.tileset,
        },
        debugOnRenderProfile: profiles.add,
      );
      if (fixture.kind == _SmartFixtureKind.animated) {
        component.update(0.15);
      }

      final centered = await _renderRetinaFrame(
        component: component,
        displayScale: fixture.bundle.manifest.settings.displayScale,
        requestedPosition: Vector2(1280, 960),
      );
      addTearDown(centered.image.dispose);
      expect(centered.physicalPixelsPerSourcePixel, 2);
      expect(centered.zoom, closeTo(0.5, 1e-12));
      _expectNoBackgroundAtTileSeams(
        image: centered.image,
        physicalWorldOrigin: centered.physicalWorldOrigin,
        physicalCellWidth: 64,
        physicalCellHeight: 64,
        reason: '${fixture.label} centered',
      );

      final offset = await _renderRetinaFrame(
        component: component,
        displayScale: fixture.bundle.manifest.settings.displayScale,
        requestedPosition: Vector2(1280.25, 960.75),
      );
      addTearDown(offset.image.dispose);
      _expectNoBackgroundAtTileSeams(
        image: offset.image,
        physicalWorldOrigin: offset.physicalWorldOrigin,
        physicalCellWidth: 64,
        physicalCellHeight: 64,
        reason: '${fixture.label} offset',
      );

      expect(profiles, hasLength(2));
      expect(
        _candidateSignature(profiles.last),
        _candidateSignature(profiles.first),
        reason: '${fixture.label} camera projection must add no render work',
      );
    }
  });
}

const _logicalViewport = Size(469, 328.5);
const _physicalWidth = 938;
const _physicalHeight = 657;
const _dpr = 2.0;
const _sourceTileSize = 32;
const _mapWidth = 40;
const _mapHeight = 30;
const _magenta = <int>[255, 0, 255, 255];

enum _SmartFixtureKind { uniform, tessellated, animated }

final class _SeamFixture {
  const _SeamFixture({
    required this.label,
    required this.bundle,
    required this.tilesetId,
    required this.tileset,
    this.kind,
  });

  final String label;
  final RuntimeMapBundle bundle;
  final String tilesetId;
  final RuntimeTilesetImage tileset;
  final _SmartFixtureKind? kind;
}

final class _RenderedFrame {
  const _RenderedFrame({
    required this.image,
    required this.physicalWorldOrigin,
    required this.physicalPixelsPerSourcePixel,
    required this.zoom,
  });

  final ui.Image image;
  final Vector2 physicalWorldOrigin;
  final int physicalPixelsPerSourcePixel;
  final double zoom;
}

Future<_SeamFixture> _classicFixture() async {
  const tilesetId = 'classic-ground';
  final map = MapData(
    id: 'classic-seam-map',
    name: 'Classic seam map',
    size: const GridSize(width: _mapWidth, height: _mapHeight),
    layers: <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Ground',
        palette: const <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(tilesetId: tilesetId, localTileId: 0),
        ],
        cells: List<int>.filled(_mapWidth * _mapHeight, 1),
      ),
    ],
  );
  const manifest = ProjectManifest(
    name: 'Classic seam runtime',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: tilesetId,
        name: 'Classic ground',
        relativePath: 'tilesets/classic-ground.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: tilesetId,
          pixelWidth: _sourceTileSize,
          pixelHeight: _sourceTileSize,
          tileWidth: _sourceTileSize,
          tileHeight: _sourceTileSize,
        ),
      ),
    ],
    settings: ProjectSettings(
      tileWidth: _sourceTileSize,
      tileHeight: _sourceTileSize,
      displayScale: 2,
    ),
  );
  return _SeamFixture(
    label: 'classic TileLayer',
    bundle: _bundle(manifest, map),
    tilesetId: tilesetId,
    tileset: await _runtimeTilesetImage(
      columns: 1,
      rows: 1,
      colors: const <Color>[Color(0xFF309040)],
    ),
  );
}

Future<_SeamFixture> _smartFixture({
  required _SmartFixtureKind kind,
}) async {
  final tilesetId = 'smart-${kind.name}';
  final atlasId = 'atlas-${kind.name}';
  final presetId = 'preset-${kind.name}';
  final materialId = 'material-${kind.name}';
  final columns = kind == _SmartFixtureKind.uniform ? 1 : 2;
  final rows = kind == _SmartFixtureKind.tessellated ? 2 : 1;
  final frame = SmartTileFrameRef(
    atlasId: atlasId,
    column: 0,
    row: 0,
    columnSpan: kind == _SmartFixtureKind.tessellated ? 2 : 1,
    rowSpan: kind == _SmartFixtureKind.tessellated ? 2 : 1,
  );
  final source = kind == _SmartFixtureKind.animated
      ? const SmartTileVisualSource.animation(animationId: 'ground-animation')
      : SmartTileVisualSource.frame(frame: frame);
  final part = SmartTileVisualPart(
    source: source,
    frameSampling: kind == _SmartFixtureKind.tessellated
        ? SmartTileFrameSampling.tessellated
        : SmartTileFrameSampling.fullFrame,
  );
  final manifest = ProjectManifest(
    name: 'Smart seam runtime ${kind.name}',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: tilesetId,
        name: tilesetId,
        relativePath: 'tilesets/$tilesetId.png',
      ),
    ],
    settings: const ProjectSettings(
      tileWidth: _sourceTileSize,
      tileHeight: _sourceTileSize,
      displayScale: 2,
    ),
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: atlasId,
          name: atlasId,
          tilesetId: tilesetId,
          columns: columns,
          rows: rows,
        ),
      ],
      animations: kind == _SmartFixtureKind.animated
          ? <ProjectSmartTileAnimation>[
              ProjectSmartTileAnimation(
                id: 'ground-animation',
                name: 'Ground animation',
                frames: <ProjectSmartTileAnimationFrame>[
                  ProjectSmartTileAnimationFrame(
                    frame: SmartTileFrameRef(
                      atlasId: atlasId,
                      column: 0,
                      row: 0,
                    ),
                    durationMs: 100,
                  ),
                  ProjectSmartTileAnimationFrame(
                    frame: SmartTileFrameRef(
                      atlasId: atlasId,
                      column: 1,
                      row: 0,
                    ),
                    durationMs: 100,
                  ),
                ],
              ),
            ]
          : const <ProjectSmartTileAnimation>[],
      materials: <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: materialId,
          name: materialId,
          connectionGroupId: materialId,
        ),
      ],
      presets: <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: presetId,
          name: presetId,
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          templateHint: SmartTileTemplateHint.simple,
          status: SmartTilePresetStatus.published,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: const SmartTileTransformPolicy(),
          defaultMaterialId: materialId,
          allowedMaterialIds: <String>[materialId],
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'uniform',
              centerMatch: SmartTileSlotMatch.material(materialId),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'visual',
                  parts: <SmartTileVisualPart>[part],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
  final map = MapData(
    id: 'smart-${kind.name}-seam-map',
    name: 'Smart ${kind.name} seam map',
    version: ProjectVersion.v6,
    size: const GridSize(width: _mapWidth, height: _mapHeight),
    layers: <MapLayer>[
      SmartTileLayer(
        id: 'ground',
        name: 'Ground',
        presetId: presetId,
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', materialId],
        field: SmartTileField.cell(
          semanticCells: List<int>.filled(_mapWidth * _mapHeight, 1),
        ),
      ),
    ],
  );
  final colors = switch (kind) {
    _SmartFixtureKind.uniform => const <Color>[Color(0xFF308F42)],
    _SmartFixtureKind.tessellated => const <Color>[
        Color(0xFF2F8D40),
        Color(0xFF328F43),
        Color(0xFF349145),
        Color(0xFF379348),
      ],
    _SmartFixtureKind.animated => const <Color>[
        Color(0xFF2F9044),
        Color(0xFF38984C),
      ],
  };
  return _SeamFixture(
    label: 'SmartTileLayer ${kind.name}',
    bundle: _bundle(manifest, map),
    tilesetId: tilesetId,
    tileset: await _runtimeTilesetImage(
      columns: columns,
      rows: rows,
      colors: colors,
    ),
    kind: kind,
  );
}

RuntimeMapBundle _bundle(ProjectManifest manifest, MapData map) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: map,
    projectRootDirectory: '/tmp/tile-seam-visual',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage({
  required int columns,
  required int rows,
  required List<Color> colors,
}) async {
  final width = columns * _sourceTileSize;
  final height = rows * _sourceTileSize;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var row = 0; row < rows; row++) {
    for (var column = 0; column < columns; column++) {
      canvas.drawRect(
        Rect.fromLTWH(
          (column * _sourceTileSize).toDouble(),
          (row * _sourceTileSize).toDouble(),
          _sourceTileSize.toDouble(),
          _sourceTileSize.toDouble(),
        ),
        Paint()
          ..isAntiAlias = false
          ..color = colors[row * columns + column],
      );
    }
  }
  final image = await recorder.endRecording().toImage(width, height);
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: height, width: width),
    ],
    width: width,
    height: height,
  );
}

Future<_RenderedFrame> _renderRetinaFrame({
  required MapLayersComponent component,
  required double displayScale,
  required Vector2 requestedPosition,
}) async {
  final camera = CameraComponent();
  final controller = PixelPerfectOverworldCameraController(
    camera: camera,
    displayScale: displayScale,
    devicePixelRatioProvider: () => _dpr,
  )
    ..setRequestedVisibleGameSize(Vector2(960, 704))
    ..onViewportResize(
      Vector2(_logicalViewport.width, _logicalViewport.height),
    )
    ..setPosition(requestedPosition);
  final physicalCenter = Vector2(_physicalWidth / 2, _physicalHeight / 2);
  final worldToPhysical = controller.resolvedZoom! * _dpr;
  final physicalWorldOrigin =
      physicalCenter - controller.position * worldToPhysical;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 938, 657),
    Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFFF00FF),
  );
  canvas
    ..save()
    ..translate(physicalCenter.x, physicalCenter.y)
    ..scale(worldToPhysical)
    ..translate(-controller.position.x, -controller.position.y);
  component.render(canvas);
  canvas.restore();

  return _RenderedFrame(
    image: await recorder.endRecording().toImage(
          _physicalWidth,
          _physicalHeight,
        ),
    physicalWorldOrigin: physicalWorldOrigin,
    physicalPixelsPerSourcePixel: controller.physicalPixelsPerSourcePixel!,
    zoom: controller.resolvedZoom!,
  );
}

Future<void> _expectNoBackgroundAtTileSeams({
  required ui.Image image,
  required Vector2 physicalWorldOrigin,
  required int physicalCellWidth,
  required int physicalCellHeight,
  required String reason,
}) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  final verticalBoundaries = _interiorBoundaries(
    origin: physicalWorldOrigin.x,
    stride: physicalCellWidth,
    extent: image.width,
  );
  final horizontalBoundaries = _interiorBoundaries(
    origin: physicalWorldOrigin.y,
    stride: physicalCellHeight,
    extent: image.height,
  );
  expect(verticalBoundaries, isNotEmpty, reason: reason);
  expect(horizontalBoundaries, isNotEmpty, reason: reason);

  for (final boundaryX in verticalBoundaries.take(5)) {
    for (var y = 24; y < image.height - 24; y += 7) {
      for (var x = boundaryX - 1; x <= boundaryX + 1; x++) {
        _expectOpaqueNonMagenta(bytes, image.width, x, y, reason);
      }
    }
  }
  for (final boundaryY in horizontalBoundaries.take(5)) {
    for (var x = 24; x < image.width - 24; x += 7) {
      for (var y = boundaryY - 1; y <= boundaryY + 1; y++) {
        _expectOpaqueNonMagenta(bytes, image.width, x, y, reason);
      }
    }
  }
}

List<int> _interiorBoundaries({
  required double origin,
  required int stride,
  required int extent,
}) {
  final firstIndex = ((24 - origin) / stride).ceil();
  final lastIndex = ((extent - 24 - origin) / stride).floor();
  return <int>[
    for (var index = firstIndex; index <= lastIndex; index++)
      (origin + index * stride).round(),
  ];
}

void _expectOpaqueNonMagenta(
  List<int> bytes,
  int width,
  int x,
  int y,
  String reason,
) {
  final offset = (y * width + x) * 4;
  final pixel = <int>[
    bytes[offset],
    bytes[offset + 1],
    bytes[offset + 2],
    bytes[offset + 3],
  ];
  expect(pixel[3], 255, reason: '$reason at ($x, $y)');
  expect(pixel, isNot(orderedEquals(_magenta)), reason: '$reason at ($x, $y)');
}

Map<String, int> _candidateSignature(MapLayersRenderProfile profile) {
  return <String, int>{
    'tile': profile.tileCellVisits,
    'smartOwner': profile.smartTileOwnerCellVisits,
    'smartPattern': profile.smartTilePatternStrokeCellVisits,
    'smartVisual': profile.smartTileVisualCount,
    'objectCandidate': profile.objectTileCandidateVisits,
    'placedCandidate': profile.placedElementCandidateVisits,
    'entityCandidate': profile.entityCandidateVisits,
  };
}
