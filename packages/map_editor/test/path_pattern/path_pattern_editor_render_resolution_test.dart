import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/features/path_pattern/path_pattern_editor_render_resolution.dart';

void main() {
  group('resolvePathPatternEditorRenderResolution', () {
    test('sans PathPattern associé conserve le rendu legacy', () {
      final project = _project(pathPresets: [_basePresetNoVariants()]);
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.legacy,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    });

    test('un seul PathPattern associé utilise la résolution PathPattern', () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 6, y: 0));
    });

    test(
        'plusieurs PathPatterns associés tombent en fallback legacy sans crash',
        () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [
          _pattern2x2(id: 'p1', baseId: 'base'),
          _pattern2x2(id: 'p2', baseId: 'base'),
        ],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.ambiguousPathPatternFallback,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    });

    test('center-only 2x2 répète A B C D selon mapX mapY', () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final a = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.isolated,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );
      final b = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.endNorth,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );
      final c = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.teeSouth,
        mapX: 0,
        mapY: 1,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );
      final d = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerSW,
        mapX: 3,
        mapY: 1,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(a?.sourceRect, const TilesetSourceRect(x: 5, y: 0));
      expect(b?.sourceRect, const TilesetSourceRect(x: 6, y: 0));
      expect(c?.sourceRect, const TilesetSourceRect(x: 5, y: 1));
      expect(d?.sourceRect, const TilesetSourceRect(x: 6, y: 1));
    });

    test('variant configuré conserve ses frames legacy', () {
      final project = _project(
        pathPresets: [
          _basePreset(
            variants: [
              const PathPresetVariantMapping(
                variant: TerrainPathVariant.endNorth,
                frames: [
                  TilesetVisualFrame(source: TilesetSourceRect(x: 11, y: 3)),
                ],
              ),
            ],
          ),
        ],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.endNorth,
        mapX: 4,
        mapY: 4,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 11, y: 3));
    });

    test('variant manquant fallback sur centerPattern', () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerSE,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 5, y: 0));
    });

    test('cross utilise toujours centerPattern', () {
      final project = _project(
        pathPresets: [
          _basePreset(
            variants: [
              const PathPresetVariantMapping(
                variant: TerrainPathVariant.cross,
                frames: [
                  TilesetVisualFrame(source: TilesetSourceRect(x: 77, y: 77)),
                ],
              ),
            ],
          ),
        ],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final resolution = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 1,
        mapY: 1,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );

      expect(
        resolution?.source,
        PathPatternEditorRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 6, y: 1));
    });

    test('centerPattern multi-frame change selon elapsedMs', () {
      final project = _project(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [
          ProjectPathPatternPreset(
            id: 'animated',
            name: 'Animated',
            basePathPresetId: 'base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: const [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 1, y: 0),
                      durationMs: 200,
                    ),
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 2, y: 0),
                      durationMs: 200,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
      final legacySet = PathAutotileSet.defaultForTileset('tileset-main');

      final frame0 = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        legacyAutotileSet: legacySet,
      );
      final frame1 = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 0,
        mapY: 0,
        elapsedMs: 200,
        legacyAutotileSet: legacySet,
      );
      final frameLoop = resolvePathPatternEditorRenderResolution(
        project: project,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 0,
        mapY: 0,
        elapsedMs: 400,
        legacyAutotileSet: legacySet,
      );

      expect(frame0?.sourceRect, const TilesetSourceRect(x: 1, y: 0));
      expect(frame1?.sourceRect, const TilesetSourceRect(x: 2, y: 0));
      expect(frameLoop?.sourceRect, const TilesetSourceRect(x: 1, y: 0));
    });
  });
}

ProjectManifest _project({
  required List<ProjectPathPreset> pathPresets,
  List<ProjectPathPatternPreset> pathPatterns = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tileset-main',
        name: 'Main',
        relativePath: 'tilesets/main.png',
      ),
    ],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatterns,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _basePresetNoVariants() {
  return _basePreset(variants: const []);
}

ProjectPathPreset _basePreset({
  required List<PathPresetVariantMapping> variants,
}) {
  return ProjectPathPreset(
    id: 'base',
    name: 'Base',
    tilesetId: 'tileset-main',
    variants: variants,
  );
}

ProjectPathPatternPreset _pattern2x2({
  String id = 'pattern',
  required String baseId,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: 'Pattern',
    basePathPresetId: baseId,
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 2, height: 2),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 0)),
          ],
        ),
        PathCenterPatternCell(
          localX: 1,
          localY: 0,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 0)),
          ],
        ),
        PathCenterPatternCell(
          localX: 0,
          localY: 1,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 1)),
          ],
        ),
        PathCenterPatternCell(
          localX: 1,
          localY: 1,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 1)),
          ],
        ),
      ],
    ),
  );
}
