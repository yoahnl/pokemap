import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_asset_diagnostics.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_diagnostics.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_tileset_image_info_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  group('effectivePathPatternFrameTilesetId', () {
    test('empty frame.tilesetId uses base path preset tileset', () {
      const base = ProjectPathPreset(
        id: 'b',
        name: 'b',
        tilesetId: 'base-ts',
        surfaceKind: PathSurfaceKind.water,
        variants: [],
      );
      const frame = TilesetVisualFrame(
        tilesetId: '',
        source: TilesetSourceRect(x: 0, y: 0),
      );
      expect(
        effectivePathPatternFrameTilesetId(frame: frame, basePathPreset: base),
        'base-ts',
      );
    });

    test('non-empty override uses frame tilesetId', () {
      const base = ProjectPathPreset(
        id: 'b',
        name: 'b',
        tilesetId: 'base-ts',
        surfaceKind: PathSurfaceKind.water,
        variants: [],
      );
      const frame = TilesetVisualFrame(
        tilesetId: 'override-ts',
        source: TilesetSourceRect(x: 0, y: 0),
      );
      expect(
        effectivePathPatternFrameTilesetId(frame: frame, basePathPreset: base),
        'override-ts',
      );
    });
  });

  group('createPathPatternAssetDiagnostics', () {
    test('empty override does not require missingFrameTileset path in asset layer',
        () {
      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'TS', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'ts'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );
      final info = {
        'ts': PathPatternTilesetImageInfo(
          tilesetId: 'ts',
          status: PathPatternTilesetImageStatus.ok,
          widthPx: 256,
          heightPx: 256,
        ),
      };
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: info,
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );
      expect(
        list.where(
          (d) => d.code == PathPatternDiagnosticCode.missingFrameTileset,
        ),
        isEmpty,
      );
    });

    test('override tileset unknown to manifest is skipped by asset layer', () {
      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'TS', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'ts'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: 'ghost',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: {
          'ts': PathPatternTilesetImageInfo(
            tilesetId: 'ts',
            status: PathPatternTilesetImageStatus.ok,
            widthPx: 256,
            heightPx: 256,
          ),
        },
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );
      expect(list, isEmpty);
    });

    test('missingTilesetImageFile when entry exists but file missing on disk',
        () async {
      final tmp = await Directory.systemTemp.createTemp('path41_asset_');
      addTearDown(() => tmp.delete(recursive: true));

      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'deep_water', name: 'deep_water', path: 'assets/tilesets/deep_water.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'deep_water'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );

      final loaded = _loadFromDisk(tmp.path, manifest);
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: loaded,
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );

      expect(
        list.map((e) => e.code),
        contains(PathPatternDiagnosticCode.missingTilesetImageFile),
      );
      expect(
        list.singleWhere(
          (d) => d.code == PathPatternDiagnosticCode.missingTilesetImageFile,
        ).title,
        'Image de tileset introuvable',
      );
    });

    test('unreadableTilesetImageFile when bytes are not an image', () async {
      final tmp = await Directory.systemTemp.createTemp('path41_asset_');
      addTearDown(() => tmp.delete(recursive: true));

      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'Bad', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'ts'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );

      final abs = p.join(tmp.path, manifest.tilesets.single.relativePath);
      File(abs).createSync(recursive: true);
      File(abs).writeAsBytesSync([0, 1, 2, 3, 4]);

      final loaded = _loadFromDisk(tmp.path, manifest);
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: loaded,
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );

      expect(
        list.map((e) => e.code),
        contains(PathPatternDiagnosticCode.unreadableTilesetImageFile),
      );
    });

    test('in-bounds source produces no frameSourceOutOfBounds', () {
      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'TS', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'ts'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: {
          'ts': PathPatternTilesetImageInfo(
            tilesetId: 'ts',
            status: PathPatternTilesetImageStatus.ok,
            widthPx: 64,
            heightPx: 64,
          ),
        },
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );
      expect(
        list.where(
          (d) => d.code == PathPatternDiagnosticCode.frameSourceOutOfBounds,
        ),
        isEmpty,
      );
    });

    test('frameSourceOutOfBounds when source exceeds image width', () {
      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'TS', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'ts'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 9, y: 0),
              ),
            ],
          ),
        ],
      );
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: {
          'ts': PathPatternTilesetImageInfo(
            tilesetId: 'ts',
            status: PathPatternTilesetImageStatus.ok,
            widthPx: 32,
            heightPx: 32,
          ),
        },
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );
      expect(
        list.map((e) => e.code),
        contains(PathPatternDiagnosticCode.frameSourceOutOfBounds),
      );
    });

    test('frameSourceOutOfBounds when source exceeds image height', () {
      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'TS', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'ts'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 0, y: 9),
              ),
            ],
          ),
        ],
      );
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: {
          'ts': PathPatternTilesetImageInfo(
            tilesetId: 'ts',
            status: PathPatternTilesetImageStatus.ok,
            widthPx: 32,
            heightPx: 32,
          ),
        },
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );
      expect(
        list.map((e) => e.code),
        contains(PathPatternDiagnosticCode.frameSourceOutOfBounds),
      );
    });

    test('unsupportedPathPatternFrameSize when width height not 1', () {
      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'TS', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'ts'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
              ),
            ],
          ),
        ],
      );
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: {
          'ts': PathPatternTilesetImageInfo(
            tilesetId: 'ts',
            status: PathPatternTilesetImageStatus.ok,
            widthPx: 256,
            heightPx: 256,
          ),
        },
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );
      expect(
        list.map((e) => e.code),
        contains(PathPatternDiagnosticCode.unsupportedPathPatternFrameSize),
      );
      expect(
        list
            .singleWhere(
              (d) =>
                  d.code ==
                  PathPatternDiagnosticCode.unsupportedPathPatternFrameSize,
            )
            .severity,
        PathPatternDiagnosticSeverity.warning,
      );
    });

    test('variant frames are validated', () {
      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'TS', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          ProjectPathPreset(
            id: 'base',
            name: 'base',
            tilesetId: 'ts',
            surfaceKind: PathSurfaceKind.water,
            variants: [
              PathPresetVariantMapping(
                variant: TerrainPathVariant.endNorth,
                frames: [
                  const TilesetVisualFrame(
                    tilesetId: '',
                    source: TilesetSourceRect(x: 99, y: 0),
                  ),
                ],
              ),
            ],
          ),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: {
          'ts': PathPatternTilesetImageInfo(
            tilesetId: 'ts',
            status: PathPatternTilesetImageStatus.ok,
            widthPx: 32,
            heightPx: 32,
          ),
        },
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: false,
      );
      expect(
        list.any(
          (d) =>
              d.code == PathPatternDiagnosticCode.frameSourceOutOfBounds &&
              d.description.contains('variant'),
        ),
        isTrue,
      );
    });

    test('emitAssetValidationUnavailable when map null', () {
      final manifest = _manifest(
        tilesets: [
          _tilesetEntry(id: 'ts', name: 'TS', path: 'tilesets/ts.png'),
        ],
        pathPresets: [
          _basePreset(id: 'base', tilesetId: 'ts'),
        ],
        pathPatternPresets: [
          _pathPattern(
            id: 'pp',
            centerFrames: [
              const TilesetVisualFrame(
                tilesetId: '',
                source: TilesetSourceRect(x: 0, y: 0),
              ),
            ],
          ),
        ],
      );
      final list = createPathPatternAssetDiagnostics(
        manifest: manifest,
        pathPatternPreset: manifest.pathPatternPresets.single,
        basePathPreset: manifest.pathPresets.single,
        tilesetImageInfoById: null,
        tileWidth: 16,
        tileHeight: 16,
        emitAssetValidationUnavailable: true,
      );
      expect(
        list.single.code,
        PathPatternDiagnosticCode.assetValidationUnavailable,
      );
    });
  });
}

/// Réutilise le loader production pour les tests disque.
Map<String, PathPatternTilesetImageInfo> _loadFromDisk(
  String root,
  ProjectManifest manifest,
) {
  return loadPathPatternTilesetImageInfoMap(
    projectRootPath: root,
    manifest: manifest,
  );
}

ProjectManifest _manifest({
  required List<ProjectTilesetEntry> tilesets,
  required List<ProjectPathPreset> pathPresets,
  required List<ProjectPathPatternPreset> pathPatternPresets,
  ProjectSettings settings = const ProjectSettings(tileWidth: 16, tileHeight: 16),
}) {
  return ProjectManifest(
    name: 'P',
    settings: settings,
    maps: const [],
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

ProjectTilesetEntry _tilesetEntry({
  required String id,
  required String name,
  required String path,
}) {
  return ProjectTilesetEntry(
    id: id,
    name: name,
    relativePath: path,
  );
}

ProjectPathPreset _basePreset({
  required String id,
  required String tilesetId,
}) {
  return ProjectPathPreset(
    id: id,
    name: id,
    tilesetId: tilesetId,
    surfaceKind: PathSurfaceKind.water,
    variants: const [],
  );
}

ProjectPathPatternPreset _pathPattern({
  required String id,
  required List<TilesetVisualFrame> centerFrames,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: id,
    basePathPresetId: 'base',
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: centerFrames,
        ),
      ],
    ),
  );
}
