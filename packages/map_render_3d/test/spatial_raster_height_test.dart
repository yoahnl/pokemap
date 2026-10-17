import 'dart:typed_data';

import 'package:flame_3d/resources.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_ground.dart';

void main() {
  for (final followTerrain in [true, false]) {
    for (final animated in [false, true]) {
      test(
        'terrain preserves heights UVs batching and navigation (animated: $animated, follows terrain: $followTerrain)',
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
                if (!followTerrain) 'spatialFollowTerrain': false,
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
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 0,
                      row: 0,
                    ),
                    durationMs: 100,
                  ),
                  ProjectSmartTileAnimationFrame(
                    frame: SmartTileFrameRef(
                      atlasId: 'atlas',
                      column: 1,
                      row: 0,
                    ),
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
          if (!followTerrain) {
            expect(plan.paintedCells, isEmpty);
            expect(plan.underlaySupportsFor(plan.resolve(0)), isEmpty);
          }
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
            for (var vertex = 0; vertex < 12; vertex++) {
              expect(
                uploaded[vertex * 20 + 3],
                left + uploaded[vertex * 20] * .5,
              );
              expect(uploaded[vertex * 20 + 4], uploaded[vertex * 20 + 2]);
            }
            final heights = [
              for (var i = 1; i < surface.positions.length; i += 3)
                surface.positions[i],
            ];
            expect(
              heights,
              unorderedEquals([
                for (final y
                    in followTerrain ? [3.0, 2.0, .5] : [0.0, -1.0, -2.5])
                  ...List.filled(4, y),
              ]),
            );
            expect(surface.vertexCount, 12);
            expect(scene.heightLevels, [12]);
            expect(map.spatialScene!.navigation, scene.navigation);
          }
        },
      );
    }
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
