import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/path_pattern_runtime_render_resolution.dart';
import 'package:map_runtime/src/presentation/flame/runtime_path_autotile.dart';

void main() {
  group('resolvePathPatternRuntimeRenderResolution', () {
    test('sans PathPattern associé conserve le rendu legacy', () {
      final manifest = _manifest(pathPresets: [_basePresetNoVariants()]);
      final legacy = RuntimePathAutotileSet.fromPreset(
        const ProjectPathPreset(
          id: 'base',
          name: 'Base',
          tilesetId: 'tileset-main',
          variants: [
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cornerNE,
              frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 1))],
            ),
          ],
        ),
      );

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.legacy,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    });

    test('un seul PathPattern associé utilise la résolution PathPattern', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 6, y: 0));
    });

    test(
        'plusieurs PathPatterns associés tombent en fallback legacy sans crash',
        () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [
          _pattern2x2(id: 'p1', baseId: 'base'),
          _pattern2x2(id: 'p2', baseId: 'base'),
        ],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(
        const ProjectPathPreset(
          id: 'base',
          name: 'Base',
          tilesetId: 'tileset-main',
          variants: [
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cornerNE,
              frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 3, y: 1))],
            ),
          ],
        ),
      );

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerNE,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.ambiguousPathPatternFallback,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    });

    test('center-only 2x2 répète A B C D selon mapX mapY', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final a = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.isolated,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );
      final b = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.endNorth,
        mapX: 1,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );
      final c = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.teeSouth,
        mapX: 0,
        mapY: 1,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );
      final d = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerSW,
        mapX: 3,
        mapY: 1,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(a?.sourceRect, const TilesetSourceRect(x: 5, y: 0));
      expect(b?.sourceRect, const TilesetSourceRect(x: 6, y: 0));
      expect(c?.sourceRect, const TilesetSourceRect(x: 5, y: 1));
      expect(d?.sourceRect, const TilesetSourceRect(x: 6, y: 1));
    });

    test('center-only animé change selon elapsedMs', () {
      final manifest = _manifest(
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
                  frames: [
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
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final frame0 = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );
      final frame1 = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 0,
        mapY: 0,
        elapsedMs: 200,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(frame0?.sourceRect, const TilesetSourceRect(x: 1, y: 0));
      expect(frame1?.sourceRect, const TilesetSourceRect(x: 2, y: 0));
    });

    test('variant configuré conserve ses frames legacy', () {
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(
            id: 'base',
            name: 'Base',
            tilesetId: 'tileset-main',
            variants: [
              PathPresetVariantMapping(
                variant: TerrainPathVariant.endNorth,
                frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 11, y: 3))],
              ),
            ],
          ),
        ],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(manifest.pathPresets.first);

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.endNorth,
        mapX: 4,
        mapY: 4,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 11, y: 3));
    });

    test('variant manquant fallback sur centerPattern', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cornerSE,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 5, y: 0));
    });

    test('cross utilise toujours centerPattern', () {
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(
            id: 'base',
            name: 'Base',
            tilesetId: 'tileset-main',
            variants: [
              PathPresetVariantMapping(
                variant: TerrainPathVariant.cross,
                frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 77, y: 77))],
              ),
            ],
          ),
        ],
        pathPatterns: [_pattern2x2(baseId: 'base')],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(manifest.pathPresets.first);

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.cross,
        mapX: 1,
        mapY: 1,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(
        resolution?.source,
        PathPatternRuntimeRenderResolutionSource.pathPattern,
      );
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 6, y: 1));
    });

    test('frame tilesetId override est prioritaire', () {
      final manifest = _manifest(
        pathPresets: [_basePresetNoVariants()],
        pathPatterns: [
          ProjectPathPatternPreset(
            id: 'override',
            name: 'Override',
            basePathPresetId: 'base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 1, height: 1),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: [
                    TilesetVisualFrame(
                      tilesetId: 'water_fx_tileset',
                      source: TilesetSourceRect(x: 2, y: 2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
      final legacy = RuntimePathAutotileSet.fromPreset(_basePresetNoVariants());

      final resolution = resolvePathPatternRuntimeRenderResolution(
        manifest: manifest,
        basePathPresetId: 'base',
        variant: TerrainPathVariant.isolated,
        mapX: 0,
        mapY: 0,
        elapsedMs: 0,
        playback: const PathPatternRuntimePlayback.alwaysLoop(),
        legacyAutotileSet: legacy,
      );

      expect(resolution?.tilesetId, 'water_fx_tileset');
      expect(resolution?.sourceRect, const TilesetSourceRect(x: 2, y: 2));
    });
  });
}

ProjectManifest _manifest({
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
      ProjectTilesetEntry(
        id: 'water_fx_tileset',
        name: 'FX',
        relativePath: 'tilesets/fx.png',
      ),
    ],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatterns,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _basePresetNoVariants() {
  return const ProjectPathPreset(
    id: 'base',
    name: 'Base',
    tilesetId: 'tileset-main',
    variants: [],
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
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 0))],
        ),
        PathCenterPatternCell(
          localX: 1,
          localY: 0,
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 0))],
        ),
        PathCenterPatternCell(
          localX: 0,
          localY: 1,
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 1))],
        ),
        PathCenterPatternCell(
          localX: 1,
          localY: 1,
          frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 1))],
        ),
      ],
    ),
  );
}
