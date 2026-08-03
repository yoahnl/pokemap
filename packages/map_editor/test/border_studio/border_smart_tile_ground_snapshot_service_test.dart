import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_smart_tile_ground_snapshot_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('BorderSmartTileGroundSnapshotService', () {
    late Directory projectRoot;

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'pokemap_border_smart_tile_ground_',
      );
    });

    tearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
    });

    test('freezes every canonical Border role from one published Smart Tile',
        () async {
      await _writeAtlas(projectRoot, _twoCellAtlas());

      final result =
          await const BorderSmartTileGroundSnapshotService().prepareAllRoles(
        manifest: _manifest(
          smartTileCatalog: _catalog(
            parts: const <SmartTileVisualPart>[
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'smart-atlas',
                    column: 0,
                    row: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        projectRootPath: projectRoot.path,
        sourceSmartTilePresetId: 'shore',
      );

      expect(result.keys, orderedEquals(standardSurfaceVariantRoleOrder));
      expect(result, hasLength(standardSurfaceVariantRoleOrder.length));
      for (final preparation in result.values) {
        expect(preparation.sourceElementId, 'shore');
        expect(
          preparation.metrics.pixelSize,
          const GridSize(width: 2, height: 1),
        );
        expect(preparation.snapshot.frames, hasLength(1));
        final pixels = img.decodePng(preparation.files.single.bytes)!;
        expect(pixels.width, 2);
        expect(pixels.height, 1);
        expect(pixels.getPixel(0, 0).r.toInt(), 10);
      }
      expect(
        () => result.remove(SurfaceVariantRole.isolated),
        throwsUnsupportedError,
      );
    });

    test('composites ordered multipart ground visuals before freezing',
        () async {
      await _writeAtlas(projectRoot, _compositeAtlas());

      final result =
          await const BorderSmartTileGroundSnapshotService().prepareAllRoles(
        manifest: _manifest(
          smartTileCatalog: _catalog(
            parts: const <SmartTileVisualPart>[
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'smart-atlas',
                    column: 0,
                    row: 0,
                  ),
                ),
              ),
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'smart-atlas',
                    column: 1,
                    row: 0,
                  ),
                ),
                channel: SmartTileRenderChannel.understory,
                drawOrder: 1,
              ),
            ],
          ),
        ),
        projectRootPath: projectRoot.path,
        sourceSmartTilePresetId: 'shore',
      );

      final pixels = img.decodePng(
        result[SurfaceVariantRole.isolated]!.files.single.bytes,
      )!;
      expect(pixels.getPixel(0, 0).r.toInt(), 10);
      expect(pixels.getPixel(1, 0).b.toInt(), 220);
    });

    test('preserves a repeat animation and its frame timings', () async {
      await _writeAtlas(projectRoot, _twoCellAtlas());
      final catalog = _catalog(
        parts: const <SmartTileVisualPart>[
          SmartTileVisualPart(
            source: SmartTileVisualSource.animation(animationId: 'water'),
          ),
        ],
        animations: <ProjectSmartTileAnimation>[
          _animation(
            'water',
            const <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'smart-atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 65,
              ),
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'smart-atlas',
                  column: 1,
                  row: 0,
                ),
                durationMs: 95,
              ),
            ],
          ),
        ],
      );

      final result =
          await const BorderSmartTileGroundSnapshotService().prepareAllRoles(
        manifest: _manifest(smartTileCatalog: catalog),
        projectRootPath: projectRoot.path,
        sourceSmartTilePresetId: 'shore',
      );

      final prepared = result[SurfaceVariantRole.cornerSE]!;
      expect(
        prepared.snapshot.frames.map((frame) => frame.durationMs),
        orderedEquals(<int>[65, 95]),
      );
      expect(prepared.files, hasLength(2));
      expect(
        img.decodePng(prepared.files[0].bytes)!.getPixel(0, 0).r.toInt(),
        10,
      );
      expect(
        img.decodePng(prepared.files[1].bytes)!.getPixel(0, 0).r.toInt(),
        20,
      );
    });

    test('rejects a missing or unpublished Smart Tile preset', () async {
      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: const ProjectManifest(
            name: 'Missing Smart Tile',
            maps: <ProjectMapEntry>[],
            tilesets: <ProjectTilesetEntry>[],
          ),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'missing',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>()
              .having(
                (error) => error.code,
                'code',
                BorderSmartTileGroundSnapshotErrorCode.missingSmartTilePreset,
              )
              .having(
                (error) => error.sourceSmartTilePresetId,
                'sourceSmartTilePresetId',
                'missing',
              ),
        ),
      );

      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            smartTileCatalog: _catalog(
              status: SmartTilePresetStatus.draft,
              parts: <SmartTileVisualPart>[
                const SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'smart-atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSmartTileGroundSnapshotErrorCode.unpublishedSmartTilePreset,
          ),
        ),
      );
    });

    test('rejects a preset with no background visual', () async {
      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            smartTileCatalog: _catalog(
              parts: <SmartTileVisualPart>[
                const SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'smart-atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.foreground,
                ),
              ],
            ),
          ),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>()
              .having(
                (error) => error.code,
                'code',
                BorderSmartTileGroundSnapshotErrorCode.unresolvedSmartTileRole,
              )
              .having(
                (error) => error.surfaceRole,
                'surfaceRole',
                SurfaceVariantRole.isolated,
              ),
        ),
      );
    });

    test('rejects missing and incompatible animation timelines', () async {
      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            smartTileCatalog: _catalog(
              parts: <SmartTileVisualPart>[
                const SmartTileVisualPart(
                  source: SmartTileVisualSource.animation(
                    animationId: 'missing-animation',
                  ),
                ),
              ],
            ),
          ),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>()
              .having(
                (error) => error.code,
                'code',
                BorderSmartTileGroundSnapshotErrorCode.missingAnimation,
              )
              .having(
                (error) => error.animationId,
                'animationId',
                'missing-animation',
              ),
        ),
      );

      final incompatible = _catalog(
        parts: const <SmartTileVisualPart>[
          SmartTileVisualPart(
            source: SmartTileVisualSource.animation(animationId: 'a'),
          ),
          SmartTileVisualPart(
            source: SmartTileVisualSource.animation(animationId: 'b'),
            channel: SmartTileRenderChannel.shadow,
          ),
        ],
        animations: <ProjectSmartTileAnimation>[
          _animation('a', <ProjectSmartTileAnimationFrame>[_animatedFrame(40)]),
          _animation('b', <ProjectSmartTileAnimationFrame>[_animatedFrame(50)]),
        ],
      );
      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(smartTileCatalog: incompatible),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSmartTileGroundSnapshotErrorCode
                .incompatibleAnimationTimelines,
          ),
        ),
      );
    });

    test('rejects missing atlases and out-of-bounds frames', () async {
      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            smartTileCatalog: _catalog(
              includeAtlas: false,
              parts: <SmartTileVisualPart>[
                const SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'missing-atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSmartTileGroundSnapshotErrorCode.missingAtlas,
          ),
        ),
      );

      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            smartTileCatalog: _catalog(
              atlasColumns: 1,
              parts: <SmartTileVisualPart>[
                const SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'smart-atlas',
                      column: 1,
                      row: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSmartTileGroundSnapshotErrorCode.atlasFrameOutOfBounds,
          ),
        ),
      );
    });

    test('rejects missing tilesets, missing files, and escaping paths',
        () async {
      final catalog = _catalog(
        parts: const <SmartTileVisualPart>[
          SmartTileVisualPart(
            source: SmartTileVisualSource.frame(
              frame: SmartTileFrameRef(
                atlasId: 'smart-atlas',
                column: 0,
                row: 0,
              ),
            ),
          ),
        ],
      );
      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            smartTileCatalog: catalog,
            tilesets: <ProjectTilesetEntry>[],
          ),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSmartTileGroundSnapshotErrorCode.missingTileset,
          ),
        ),
      );

      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(smartTileCatalog: catalog),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSmartTileGroundSnapshotErrorCode.missingTilesetFile,
          ),
        ),
      );

      await expectLater(
        const BorderSmartTileGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            smartTileCatalog: catalog,
            tilesetPath: '../outside.png',
          ),
          projectRootPath: projectRoot.path,
          sourceSmartTilePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSmartTileGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSmartTileGroundSnapshotErrorCode.unsafeTilesetPath,
          ),
        ),
      );
    });

    test('is deterministic for identical project bytes and catalog data',
        () async {
      await _writeAtlas(projectRoot, _twoCellAtlas());
      final manifest = _manifest(
        smartTileCatalog: _catalog(
          parts: const <SmartTileVisualPart>[
            SmartTileVisualPart(
              source: SmartTileVisualSource.frame(
                frame: SmartTileFrameRef(
                  atlasId: 'smart-atlas',
                  column: 0,
                  row: 0,
                ),
              ),
            ),
          ],
        ),
      );
      const service = BorderSmartTileGroundSnapshotService();

      final first = await service.prepareAllRoles(
        manifest: manifest,
        projectRootPath: projectRoot.path,
        sourceSmartTilePresetId: 'shore',
      );
      final second = await service.prepareAllRoles(
        manifest: manifest,
        projectRootPath: projectRoot.path,
        sourceSmartTilePresetId: 'shore',
      );

      expect(first.keys, orderedEquals(second.keys));
      for (final role in standardSurfaceVariantRoleOrder) {
        expect(first[role]!.snapshot, second[role]!.snapshot);
        expect(first[role]!.metrics, second[role]!.metrics);
        expect(first[role]!.files, orderedEquals(second[role]!.files));
      }
    });
  });
}

ProjectManifest _manifest({
  required ProjectSmartTileCatalog smartTileCatalog,
  List<ProjectTilesetEntry>? tilesets,
  String tilesetPath = 'assets/tilesets/smart-tiles.png',
}) =>
    ProjectManifest(
      name: 'Smart Tile ground snapshots',
      maps: const <ProjectMapEntry>[],
      settings: const ProjectSettings(tileWidth: 2, tileHeight: 1),
      tilesets: tilesets ??
          <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'smart-tiles',
              name: 'Smart Tiles',
              relativePath: tilesetPath,
              transparentColor: TilesetTransparentColor(
                red: 255,
                green: 0,
                blue: 255,
              ),
            ),
          ],
      smartTileCatalog: smartTileCatalog,
    );

ProjectSmartTileCatalog _catalog({
  required List<SmartTileVisualPart> parts,
  List<ProjectSmartTileAnimation> animations =
      const <ProjectSmartTileAnimation>[],
  SmartTilePresetStatus status = SmartTilePresetStatus.published,
  int atlasColumns = 2,
  bool includeAtlas = true,
}) =>
    ProjectSmartTileCatalog(
      atlases: includeAtlas
          ? <ProjectSmartTileAtlas>[
              ProjectSmartTileAtlas(
                id: 'smart-atlas',
                name: 'Smart atlas',
                tilesetId: 'smart-tiles',
                cellWidth: 2,
                cellHeight: 1,
                columns: atlasColumns,
                rows: 1,
              ),
            ]
          : const <ProjectSmartTileAtlas>[],
      animations: animations,
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'ground',
          name: 'Ground',
          connectionGroupId: 'ground',
        ),
      ],
      presets: <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'shore',
          name: 'Shore',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          status: status,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
            allowFallback: true,
          ),
          transformPolicy: const SmartTileTransformPolicy(),
          defaultMaterialId: 'ground',
          allowedMaterialIds: const <String>['ground'],
          fallbackRuleId: 'all',
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'all',
              centerMatch: const SmartTileSlotMatch.any(),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(id: 'visual', parts: parts),
              ],
            ),
          ],
        ),
      ],
    );

ProjectSmartTileAnimation _animation(
  String id,
  List<ProjectSmartTileAnimationFrame> frames,
) =>
    ProjectSmartTileAnimation(id: id, name: id, frames: frames);

ProjectSmartTileAnimationFrame _animatedFrame(int durationMs) =>
    ProjectSmartTileAnimationFrame(
      frame: const SmartTileFrameRef(
        atlasId: 'smart-atlas',
        column: 0,
        row: 0,
      ),
      durationMs: durationMs,
    );

Future<void> _writeAtlas(Directory root, Uint8List bytes) async {
  final file = File(
    p.join(root.path, 'assets', 'tilesets', 'smart-tiles.png'),
  );
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

Uint8List _twoCellAtlas() {
  final image = img.Image(width: 4, height: 1, numChannels: 4);
  image
    ..setPixelRgba(0, 0, 10, 50, 60, 255)
    ..setPixelRgba(1, 0, 10, 50, 60, 255)
    ..setPixelRgba(2, 0, 20, 50, 60, 255)
    ..setPixelRgba(3, 0, 20, 50, 60, 255);
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _compositeAtlas() {
  final image = img.Image(width: 4, height: 1, numChannels: 4);
  image
    ..setPixelRgba(0, 0, 10, 50, 60, 255)
    ..setPixelRgba(1, 0, 10, 50, 60, 255)
    ..setPixelRgba(2, 0, 255, 0, 255, 255)
    ..setPixelRgba(3, 0, 30, 40, 220, 255);
  return Uint8List.fromList(img.encodePng(image));
}
