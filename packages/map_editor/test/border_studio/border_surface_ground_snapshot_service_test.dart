import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_studio/application/border_surface_ground_snapshot_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('BorderSurfaceGroundSnapshotService', () {
    late Directory projectRoot;

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'pokemap_border_surface_ground_',
      );
    });

    tearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
    });

    test('prepares exactly every canonical Surface role in stable order',
        () async {
      await _writeAtlas(projectRoot, _roleAtlas());
      final result =
          await const BorderSurfaceGroundSnapshotService().prepareAllRoles(
        manifest: _manifest(surfaceCatalog: _completeCatalog()),
        projectRootPath: projectRoot.path,
        sourceSurfacePresetId: 'shore',
      );

      expect(result.keys, orderedEquals(standardSurfaceVariantRoleOrder));
      expect(result, hasLength(standardSurfaceVariantRoleOrder.length));
      for (var index = 0;
          index < standardSurfaceVariantRoleOrder.length;
          index += 1) {
        final role = standardSurfaceVariantRoleOrder[index];
        final preparation = result[role]!;
        expect(preparation.sourceElementId, 'shore');
        expect(
          preparation.metrics.pixelSize,
          const GridSize(width: 2, height: 1),
        );
        expect(preparation.snapshot.frames, hasLength(1));
        expect(preparation.snapshot.frames.single.durationMs, 40 + index);
        expect(
          preparation.snapshot.frames.single.transparentColorArgb,
          0xffff00ff,
        );
        expect(
          preparation.snapshot.frames.single.sourceRectPx,
          BorderPixelRect(x: 0, y: 0, width: 2, height: 1),
        );

        final normalized = img.decodePng(preparation.files.single.bytes)!;
        expect(normalized.width, 2);
        expect(normalized.height, 1);
        expect(normalized.getPixel(0, 0).r.toInt(), index + 1);
        expect(normalized.getPixel(1, 0).a.toInt(), 0);
      }
      expect(
        () => result.remove(SurfaceVariantRole.isolated),
        throwsUnsupportedError,
      );
    });

    test('preserves an ordered multi-frame animation and its timings',
        () async {
      await _writeAtlas(projectRoot, _twoTileAtlas());
      final catalog = _catalog(
        refs: <SurfaceVariantAnimationRef>[
          _ref(SurfaceVariantRole.isolated, 'animated'),
        ],
        animations: <ProjectSurfaceAnimation>[
          _animation(
            'animated',
            <SurfaceAnimationFrame>[
              _frame(column: 0, durationMs: 65),
              _frame(column: 1, durationMs: 95),
            ],
          ),
        ],
        atlasColumns: 2,
      );

      final result =
          await const BorderSurfaceGroundSnapshotService().prepareAllRoles(
        manifest: _manifest(surfaceCatalog: catalog),
        projectRootPath: projectRoot.path,
        sourceSurfacePresetId: 'shore',
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
      expect(
        result.values.map((value) => value.snapshot.id).toSet(),
        hasLength(1),
      );
    });

    test('falls back to isolated, then to the first authored reference',
        () async {
      await _writeAtlas(projectRoot, _twoTileAtlas());
      final withIsolated = _catalog(
        refs: <SurfaceVariantAnimationRef>[
          _ref(SurfaceVariantRole.horizontal, 'horizontal'),
          _ref(SurfaceVariantRole.isolated, 'isolated'),
        ],
        animations: <ProjectSurfaceAnimation>[
          _animation('horizontal', <SurfaceAnimationFrame>[
            _frame(column: 0, durationMs: 50),
          ]),
          _animation('isolated', <SurfaceAnimationFrame>[
            _frame(column: 1, durationMs: 60),
          ]),
        ],
        atlasColumns: 2,
      );
      final isolatedResult =
          await const BorderSurfaceGroundSnapshotService().prepareAllRoles(
        manifest: _manifest(surfaceCatalog: withIsolated),
        projectRootPath: projectRoot.path,
        sourceSurfacePresetId: 'shore',
      );

      expect(
        isolatedResult[SurfaceVariantRole.endNorth]!.snapshot.id,
        isolatedResult[SurfaceVariantRole.isolated]!.snapshot.id,
      );
      expect(
        isolatedResult[SurfaceVariantRole.horizontal]!.snapshot.id,
        isNot(isolatedResult[SurfaceVariantRole.isolated]!.snapshot.id),
      );

      final withoutIsolated = _catalog(
        refs: <SurfaceVariantAnimationRef>[
          _ref(SurfaceVariantRole.horizontal, 'horizontal'),
          _ref(SurfaceVariantRole.cornerNE, 'corner'),
        ],
        animations: <ProjectSurfaceAnimation>[
          _animation('horizontal', <SurfaceAnimationFrame>[
            _frame(column: 0, durationMs: 50),
          ]),
          _animation('corner', <SurfaceAnimationFrame>[
            _frame(column: 1, durationMs: 60),
          ]),
        ],
        atlasColumns: 2,
      );
      final firstRefResult =
          await const BorderSurfaceGroundSnapshotService().prepareAllRoles(
        manifest: _manifest(surfaceCatalog: withoutIsolated),
        projectRootPath: projectRoot.path,
        sourceSurfacePresetId: 'shore',
      );

      expect(
        firstRefResult[SurfaceVariantRole.endNorth]!.snapshot.id,
        firstRefResult[SurfaceVariantRole.horizontal]!.snapshot.id,
      );
      expect(
        firstRefResult[SurfaceVariantRole.cornerNE]!.snapshot.id,
        isNot(firstRefResult[SurfaceVariantRole.horizontal]!.snapshot.id),
      );
    });

    test('rejects a missing Surface preset with a user-facing error', () async {
      await expectLater(
        const BorderSurfaceGroundSnapshotService().prepareAllRoles(
          manifest: const ProjectManifest(
            name: 'Missing Surface',
            maps: <ProjectMapEntry>[],
            tilesets: <ProjectTilesetEntry>[],
          ),
          projectRootPath: projectRoot.path,
          sourceSurfacePresetId: 'missing',
        ),
        throwsA(
          isA<BorderSurfaceGroundSnapshotException>()
              .having(
                (error) => error.code,
                'code',
                BorderSurfaceGroundSnapshotErrorCode.missingSurfacePreset,
              )
              .having(
                (error) => error.sourceSurfacePresetId,
                'sourceSurfacePresetId',
                'missing',
              )
              .having(
                (error) => error.userMessage,
                'userMessage',
                isNotEmpty,
              ),
        ),
      );
    });

    test('rejects a selected reference whose animation is absent', () async {
      final catalog = _catalog(
        refs: <SurfaceVariantAnimationRef>[
          _ref(SurfaceVariantRole.isolated, 'missing-animation'),
        ],
        animations: const <ProjectSurfaceAnimation>[],
      );

      await expectLater(
        const BorderSurfaceGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(surfaceCatalog: catalog),
          projectRootPath: projectRoot.path,
          sourceSurfacePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSurfaceGroundSnapshotException>()
              .having(
                (error) => error.code,
                'code',
                BorderSurfaceGroundSnapshotErrorCode.missingAnimation,
              )
              .having(
                (error) => error.animationId,
                'animationId',
                'missing-animation',
              )
              .having(
                (error) => error.surfaceRole,
                'surfaceRole',
                SurfaceVariantRole.isolated,
              ),
        ),
      );
    });

    test('rejects a missing atlas and an out-of-bounds atlas frame', () async {
      final missingAtlas = _catalog(
        refs: <SurfaceVariantAnimationRef>[
          _ref(SurfaceVariantRole.isolated, 'isolated'),
        ],
        animations: <ProjectSurfaceAnimation>[
          _animation('isolated', <SurfaceAnimationFrame>[
            _frame(atlasId: 'missing-atlas', durationMs: 50),
          ]),
        ],
        includeAtlas: false,
      );
      await expectLater(
        const BorderSurfaceGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(surfaceCatalog: missingAtlas),
          projectRootPath: projectRoot.path,
          sourceSurfacePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSurfaceGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSurfaceGroundSnapshotErrorCode.missingAtlas,
          ),
        ),
      );

      final outsideAtlas = _catalog(
        refs: <SurfaceVariantAnimationRef>[
          _ref(SurfaceVariantRole.isolated, 'isolated'),
        ],
        animations: <ProjectSurfaceAnimation>[
          _animation('isolated', <SurfaceAnimationFrame>[
            _frame(column: 1, durationMs: 50),
          ]),
        ],
      );
      await expectLater(
        const BorderSurfaceGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(surfaceCatalog: outsideAtlas),
          projectRootPath: projectRoot.path,
          sourceSurfacePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSurfaceGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSurfaceGroundSnapshotErrorCode.atlasFrameOutOfBounds,
          ),
        ),
      );
    });

    test('rejects a missing tileset entry and a missing PNG file', () async {
      final catalog = _singleRoleCatalog();
      await expectLater(
        const BorderSurfaceGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            surfaceCatalog: catalog,
            tilesets: const <ProjectTilesetEntry>[],
          ),
          projectRootPath: projectRoot.path,
          sourceSurfacePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSurfaceGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSurfaceGroundSnapshotErrorCode.missingTileset,
          ),
        ),
      );

      await expectLater(
        const BorderSurfaceGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(surfaceCatalog: catalog),
          projectRootPath: projectRoot.path,
          sourceSurfacePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSurfaceGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSurfaceGroundSnapshotErrorCode.missingTilesetFile,
          ),
        ),
      );
    });

    test('rejects lexical and symlink paths that escape the project', () async {
      final catalog = _singleRoleCatalog();
      await expectLater(
        const BorderSurfaceGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(
            surfaceCatalog: catalog,
            tilesetPath: '../outside.png',
          ),
          projectRootPath: projectRoot.path,
          sourceSurfacePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSurfaceGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSurfaceGroundSnapshotErrorCode.unsafeTilesetPath,
          ),
        ),
      );

      final outside = await Directory.systemTemp.createTemp(
        'pokemap_border_surface_outside_',
      );
      addTearDown(() async {
        if (await outside.exists()) await outside.delete(recursive: true);
      });
      final outsideFile = File(p.join(outside.path, 'surface.png'));
      await outsideFile.writeAsBytes(_twoTileAtlas(), flush: true);
      final assets = Directory(p.join(projectRoot.path, 'assets', 'tilesets'));
      await assets.create(recursive: true);
      await Link(p.join(assets.path, 'surface.png')).create(outsideFile.path);

      await expectLater(
        const BorderSurfaceGroundSnapshotService().prepareAllRoles(
          manifest: _manifest(surfaceCatalog: catalog),
          projectRootPath: projectRoot.path,
          sourceSurfacePresetId: 'shore',
        ),
        throwsA(
          isA<BorderSurfaceGroundSnapshotException>().having(
            (error) => error.code,
            'code',
            BorderSurfaceGroundSnapshotErrorCode.unsafeTilesetPath,
          ),
        ),
      );
    });

    test('is deterministic for identical project bytes and catalog data',
        () async {
      await _writeAtlas(projectRoot, _roleAtlas());
      final manifest = _manifest(surfaceCatalog: _completeCatalog());
      const service = BorderSurfaceGroundSnapshotService();

      final first = await service.prepareAllRoles(
        manifest: manifest,
        projectRootPath: projectRoot.path,
        sourceSurfacePresetId: 'shore',
      );
      final second = await service.prepareAllRoles(
        manifest: manifest,
        projectRootPath: projectRoot.path,
        sourceSurfacePresetId: 'shore',
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
  required ProjectSurfaceCatalog surfaceCatalog,
  List<ProjectTilesetEntry>? tilesets,
  String tilesetPath = 'assets/tilesets/surface.png',
}) =>
    ProjectManifest(
      name: 'Surface ground snapshots',
      maps: const <ProjectMapEntry>[],
      tilesets: tilesets ??
          <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'surface-tiles',
              name: 'Surface tiles',
              relativePath: tilesetPath,
              transparentColor: TilesetTransparentColor(
                red: 255,
                green: 0,
                blue: 255,
              ),
            ),
          ],
      surfaceCatalog: surfaceCatalog,
    );

ProjectSurfaceCatalog _completeCatalog() {
  final refs = <SurfaceVariantAnimationRef>[];
  final animations = <ProjectSurfaceAnimation>[];
  for (var index = 0;
      index < standardSurfaceVariantRoleOrder.length;
      index += 1) {
    final role = standardSurfaceVariantRoleOrder[index];
    final animationId = 'animation-${role.name}';
    refs.add(_ref(role, animationId));
    animations.add(
      _animation(animationId, <SurfaceAnimationFrame>[
        _frame(column: index, durationMs: 40 + index),
      ]),
    );
  }
  return _catalog(
    refs: refs,
    animations: animations,
    atlasColumns: standardSurfaceVariantRoleOrder.length,
  );
}

ProjectSurfaceCatalog _singleRoleCatalog() => _catalog(
      refs: <SurfaceVariantAnimationRef>[
        _ref(SurfaceVariantRole.isolated, 'isolated'),
      ],
      animations: <ProjectSurfaceAnimation>[
        _animation('isolated', <SurfaceAnimationFrame>[
          _frame(durationMs: 50),
        ]),
      ],
    );

ProjectSurfaceCatalog _catalog({
  required List<SurfaceVariantAnimationRef> refs,
  required List<ProjectSurfaceAnimation> animations,
  int atlasColumns = 1,
  bool includeAtlas = true,
}) =>
    ProjectSurfaceCatalog(
      atlases: includeAtlas
          ? <ProjectSurfaceAtlas>[
              ProjectSurfaceAtlas(
                id: 'surface-atlas',
                name: 'Surface atlas',
                tilesetId: 'surface-tiles',
                geometry: SurfaceAtlasGeometry(
                  tileSize: SurfaceAtlasTileSize(width: 2, height: 1),
                  gridSize: SurfaceAtlasGridSize(
                    columns: atlasColumns,
                    rows: 1,
                  ),
                ),
              ),
            ]
          : const <ProjectSurfaceAtlas>[],
      animations: animations,
      presets: <ProjectSurfacePreset>[
        ProjectSurfacePreset(
          id: 'shore',
          name: 'Shore',
          variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
        ),
      ],
    );

SurfaceVariantAnimationRef _ref(
  SurfaceVariantRole role,
  String animationId,
) =>
    SurfaceVariantAnimationRef(role: role, animationId: animationId);

ProjectSurfaceAnimation _animation(
  String id,
  List<SurfaceAnimationFrame> frames,
) =>
    ProjectSurfaceAnimation(
      id: id,
      name: id,
      timeline: SurfaceAnimationTimeline(frames: frames),
    );

SurfaceAnimationFrame _frame({
  String atlasId = 'surface-atlas',
  int column = 0,
  required int durationMs,
}) =>
    SurfaceAnimationFrame(
      tileRef: SurfaceAtlasTileRef(
        atlasId: atlasId,
        column: column,
        row: 0,
      ),
      durationMs: durationMs,
    );

Future<void> _writeAtlas(Directory root, Uint8List bytes) async {
  final file = File(p.join(root.path, 'assets', 'tilesets', 'surface.png'));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

Uint8List _roleAtlas() {
  final image = img.Image(
    width: standardSurfaceVariantRoleOrder.length * 2,
    height: 1,
    numChannels: 4,
  );
  for (var index = 0;
      index < standardSurfaceVariantRoleOrder.length;
      index += 1) {
    image
      ..setPixelRgba(index * 2, 0, index + 1, 50, 60, 255)
      ..setPixelRgba(index * 2 + 1, 0, 255, 0, 255, 255);
  }
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _twoTileAtlas() {
  final image = img.Image(width: 4, height: 1, numChannels: 4);
  image
    ..setPixelRgba(0, 0, 10, 50, 60, 255)
    ..setPixelRgba(1, 0, 255, 0, 255, 255)
    ..setPixelRgba(2, 0, 20, 50, 60, 255)
    ..setPixelRgba(3, 0, 255, 0, 255, 255);
  return Uint8List.fromList(img.encodePng(image));
}
