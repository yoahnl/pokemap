import 'dart:typed_data';

import 'package:flame_3d/resources.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';

void main() {
  test('asymmetric raster clipping follows all D4 transforms without stretching UVs', () {
    const bounds = [
      (.25, .0625, .875, .75),
      (.25, .25, .9375, .875),
      (.125, .25, .75, .9375),
      (.0625, .125, .75, .75),
      (.125, .0625, .75, .75),
      (.25, .125, .9375, .75),
      (.25, .25, .875, .9375),
      (.0625, .25, .75, .875),
    ];
    final scene = MapSpatialScene(
      width: 3,
      depth: 3,
      heightLevels: List.filled(9, 2),
      levelHeight: .25,
    );
    for (var index = 0; index < smartTileD4Transforms.length; index++) {
      final geometry = resolveSmartTileSpriteGeometry(
        cellX: 1,
        cellY: 1,
        destinationCellWidth: 1,
        destinationCellHeight: 1,
        sourceCellWidth: 16,
        sourceCellHeight: 16,
        offsetUnit: SmartTileOffsetUnit.pixel,
        offsetX: 0,
        offsetY: 0,
        atlasPixelOffsetX: 0,
        atlasPixelOffsetY: 0,
        footprintWidth: 1,
        footprintHeight: 1,
        anchorX: 0,
        anchorY: 0,
        transform: smartTileD4Transforms[index],
      );
      final vertices = spatialGroundVertices(
        geometry,
        scene: scene,
        height: -.125,
        spatialClip: SmartTileSpatialClip(
          left: .25,
          top: .0625,
          right: .875,
          bottom: .75,
        ),
      );
      expect(vertices, hasLength(4));
      final xs = vertices.map((vertex) => vertex.position.x).toList()..sort();
      final zs = vertices.map((vertex) => vertex.position.z).toList()..sort();
      expect(
        (xs.first, zs.first, xs.last, zs.last),
        (
          1 + bounds[index].$1,
          1 + bounds[index].$2,
          1 + bounds[index].$3,
          1 + bounds[index].$4,
        ),
        reason: 'D4 transform $index',
      );
      expect(
        vertices.map((vertex) => (vertex.texCoord.x, vertex.texCoord.y)),
        unorderedEquals([(.25, .0625), (.25, .75), (.875, .75), (.875, .0625)]),
      );
      expect(vertices.every((vertex) => vertex.position.y == .375), isTrue);
    }
  });

  test(
    'non-square raster clips retain UVs across quarter turns and mirrors',
    () {
      const cases = [
        (SmartTileSpriteTransform(quarterTurns: 1), (.5, .25, 1.875, .875)),
        (SmartTileSpriteTransform(quarterTurns: 3), (.125, .125, 1.5, .75)),
        (
          SmartTileSpriteTransform(quarterTurns: 1, flipX: true),
          (.5, .125, 1.875, .75),
        ),
        (
          SmartTileSpriteTransform(quarterTurns: 3, flipX: true),
          (.125, .25, 1.5, .875),
        ),
      ];
      final scene = MapSpatialScene(
        width: 4,
        depth: 4,
        heightLevels: List.filled(16, 2),
        levelHeight: .25,
      );
      for (final (transform, bounds) in cases) {
        final geometry = resolveSmartTileSpriteGeometry(
          cellX: 1,
          cellY: 1,
          destinationCellWidth: 1,
          destinationCellHeight: 1,
          sourceCellWidth: 16,
          sourceCellHeight: 16,
          offsetUnit: SmartTileOffsetUnit.pixel,
          offsetX: 0,
          offsetY: 0,
          atlasPixelOffsetX: 0,
          atlasPixelOffsetY: 0,
          footprintWidth: 1,
          footprintHeight: 2,
          anchorX: 0,
          anchorY: 0,
          transform: transform,
        );
        final vertices = spatialGroundVertices(
          geometry,
          scene: scene,
          height: -.125,
          spatialClip: SmartTileSpatialClip(
            left: .25,
            top: .0625,
            right: .875,
            bottom: .75,
          ),
        );
        final xs = vertices.map((vertex) => vertex.position.x).toList()..sort();
        final zs = vertices.map((vertex) => vertex.position.z).toList()..sort();
        expect(
          (xs.first, zs.first, xs.last, zs.last),
          (1 + bounds.$1, 1 + bounds.$2, 1 + bounds.$3, 1 + bounds.$4),
          reason: '$transform',
        );
        final uvs = vertices.map(
          (vertex) => (vertex.texCoord.x, vertex.texCoord.y),
        );
        for (final corner in [
          (.25, .0625),
          (.25, .75),
          (.875, .75),
          (.875, .0625),
        ]) {
          expect(uvs, contains(corner));
        }
        expect(
          vertices.every(
            (vertex) =>
                vertex.texCoord.x >= .25 &&
                vertex.texCoord.x <= .875 &&
                vertex.texCoord.y >= .0625 &&
                vertex.texCoord.y <= .75 &&
                vertex.position.y == .375,
          ),
          isTrue,
        );
        var area = 0.0;
        for (var index = 0; index < vertices.length; index += 4) {
          final a = vertices[index].position;
          final b = vertices[index + 1].position;
          final d = vertices[index + 3].position;
          area += ((b.x - a.x) * (d.z - a.z) - (b.z - a.z) * (d.x - a.x)).abs();
        }
        expect(area, closeTo(.859375, 1e-12));
      }
    },
  );

  for (final animated in [false, true]) {
    test(
      'terrain clipping preserves UV density heights batching and navigation (animated: $animated)',
      () {
        final backend = _RecordingBackend();
        final parts = [
          for (final height in [0.0, -1.0, -2.5])
            SmartTileVisualPart.fromJson({
              'source': animated
                  ? {'kind': 'animation', 'animationId': 'water'}
                  : {
                      'kind': 'frame',
                      'frame': {'atlasId': 'atlas', 'column': 0, 'row': 0},
                    },
              'spatialHeightOffset': height,
              'spatialClip': {
                'left': 0.0,
                'top': .0625,
                'right': 1.0,
                'bottom': 1.0,
              },
            }),
        ];
        final catalog = ProjectSmartTileCatalog(
          atlases: const [
            ProjectSmartTileAtlas(
              id: 'atlas',
              name: 'Grass',
              tilesetId: 'grass',
              cellWidth: 16,
              cellHeight: 16,
              columns: 2,
              rows: 1,
            ),
          ],
          animations: const [
            ProjectSmartTileAnimation(
              id: 'water',
              name: 'Water',
              frames: [
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
                  durationMs: 100,
                ),
                ProjectSmartTileAnimationFrame(
                  frame: SmartTileFrameRef(atlasId: 'atlas', column: 1, row: 0),
                  durationMs: 100,
                ),
              ],
            ),
          ],
          materials: const [
            ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'grass',
            ),
          ],
          presets: [
            ProjectSmartTilePreset(
              id: 'grass',
              name: 'Grass',
              usage: SmartTileUsage.terrain,
              topology: SmartTileTopology.uniform,
              templateHint: SmartTileTemplateHint.simple,
              defaultMaterialId: 'grass',
              allowedMaterialIds: ['grass'],
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              rules: [
                SmartTileRule(
                  id: 'ground',
                  centerMatch: SmartTileSlotMatch(
                    kind: SmartTileMatchKind.material,
                    materialId: 'grass',
                  ),
                  candidates: [SmartTileCandidate(id: 'base', parts: parts)],
                ),
              ],
            ),
          ],
        );
        final scene = MapSpatialScene(
          width: 1,
          depth: 1,
          heightLevels: [12],
          levelHeight: .25,
        );
        final map = MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v9,
          size: GridSize(width: 1, height: 1),
          spatialScene: scene,
          layers: [
            MapLayer.smartTile(
              id: 'terrain',
              name: 'Terrain',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              materialPalette: ['', 'grass'],
              field: SmartTileField.cell(semanticCells: [1]),
            ),
          ],
        );
        final project = ProjectManifest(
          name: 'Project',
          version: ProjectVersion.v9,
          maps: [],
          tilesets: [],
          smartTileCatalog: catalog,
          settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
          ),
        );
        final plan = SpatialGroundPlan(map, project);
        final texture = Texture(ByteData(32 * 16 * 4), width: 32, height: 16);
        for (final clock in [0, 100]) {
          final surface = spatialGroundMeshes(plan.resolve(clock), {
            'grass': texture,
          }, scene: scene).single.surfaces.single;
          surface.createResource();
          final uploaded = Float32List.view(
            backend.latest.bytes.buffer,
            0,
            surface.verticesBytes ~/ 4,
          );
          final left = animated && clock == 100 ? .5 : 0.0;
          final expectedUvs = [
            (left, .0625),
            (left, 1.0),
            (left + .5, 1.0),
            (left + .5, .0625),
          ];
          for (var vertex = 0; vertex < 12; vertex++) {
            expect(uploaded[vertex * 20 + 3], expectedUvs[vertex % 4].$1);
            expect(uploaded[vertex * 20 + 4], expectedUvs[vertex % 4].$2);
          }
          final heights = [
            for (var i = 1; i < surface.positions.length; i += 3)
              surface.positions[i],
          ];
          expect(
            heights,
            unorderedEquals([
              for (final y in [3.0, 2.0, .5]) ...List.filled(4, y),
            ]),
          );
          expect(surface.vertexCount, 12);
          expect(
            [
              for (var index = 2; index < surface.positions.length; index += 3)
                surface.positions[index],
            ],
            [
              for (var plane = 0; plane < 3; plane++) ...[
                .0625,
                1.0,
                1.0,
                .0625,
              ],
            ],
          );
          expect(scene.heightLevels, [12]);
          expect(map.spatialScene!.navigation, scene.navigation);
        }
      },
    );
  }
}

final class _RecordingBackend extends GpuBackend {
  late _RecordingBuffer latest;

  @override
  GpuBuffer createBuffer({
    required GpuStorageMode storageMode,
    required int sizeInBytes,
  }) => latest = _RecordingBuffer(sizeInBytes);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _RecordingBuffer implements GpuBuffer {
  _RecordingBuffer(int size) : bytes = Uint8List(size);
  final Uint8List bytes;

  @override
  void write(ByteData data, {int destinationOffsetInBytes = 0}) {
    bytes.setRange(
      destinationOffsetInBytes,
      destinationOffsetInBytes + data.lengthInBytes,
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}
