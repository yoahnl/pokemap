import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/path_pattern_runtime_render_resolution.dart';
import 'package:map_runtime/src/presentation/flame/runtime_path_autotile.dart';

void main() {
  test('resolver runtime consomme un manifest roundtrippé JSON', () {
    final manifest = _roundtripManifest(_buildManifest());
    final legacy = RuntimePathAutotileSet.fromPreset(manifest.pathPresets.single);

    final centerA = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.isolated,
      mapX: 0,
      mapY: 0,
      elapsedMs: 0,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );
    final cross = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 0,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );
    final animated0 = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 0,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );
    final animated1 = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.cross,
      mapX: 1,
      mapY: 1,
      elapsedMs: 250,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );
    final variantConfigured = resolvePathPatternRuntimeRenderResolution(
      manifest: manifest,
      basePathPresetId: 'water-base',
      variant: TerrainPathVariant.endNorth,
      mapX: 8,
      mapY: 8,
      elapsedMs: 0,
      playback: const PathPatternRuntimePlayback.alwaysLoop(),
      legacyAutotileSet: legacy,
    );

    expect(centerA?.source, PathPatternRuntimeRenderResolutionSource.pathPattern);
    expect(centerA?.sourceRect, const TilesetSourceRect(x: 0, y: 0));
    expect(cross?.sourceRect, const TilesetSourceRect(x: 3, y: 0));

    expect(animated0?.sourceRect, const TilesetSourceRect(x: 3, y: 0));
    expect(animated1?.sourceRect, const TilesetSourceRect(x: 3, y: 1));
    expect(animated1?.tilesetId, 'tileset-water-fx');

    expect(
      variantConfigured?.source,
      PathPatternRuntimeRenderResolutionSource.pathPattern,
    );
    expect(variantConfigured?.sourceRect, const TilesetSourceRect(x: 9, y: 4));
  });
}

ProjectManifest _roundtripManifest(ProjectManifest manifest) {
  return ProjectManifest.fromJson(
    jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
  );
}

ProjectManifest _buildManifest() {
  return ProjectManifest(
    name: 'Runtime Reload',
    maps: const [],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'tileset-main',
        name: 'Main',
        relativePath: 'tilesets/main.png',
      ),
      ProjectTilesetEntry(
        id: 'tileset-water-fx',
        name: 'Water FX',
        relativePath: 'tilesets/water_fx.png',
      ),
    ],
    pathPresets: [
      const ProjectPathPreset(
        id: 'water-base',
        name: 'Water Base',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'tileset-main',
        variants: [
          PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 9, y: 4),
                durationMs: 120,
              ),
            ],
          ),
          PathPresetVariantMapping(
            variant: TerrainPathVariant.cross,
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 77, y: 77)),
            ],
          ),
        ],
      ),
    ],
    pathPatternPresets: [
      ProjectPathPatternPreset(
        id: 'water-pattern',
        name: 'Water Pattern',
        basePathPresetId: 'water-base',
        centerPattern: PathCenterPattern(
          size: PathCenterPatternSize(width: 2, height: 2),
          cells: [
            PathCenterPatternCell(
              localX: 0,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 0,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 0),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 1),
                  durationMs: 150,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 0,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 2, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
            PathCenterPatternCell(
              localX: 1,
              localY: 1,
              frames: const [
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 3, y: 0),
                  durationMs: 200,
                ),
                TilesetVisualFrame(
                  tilesetId: 'tileset-water-fx',
                  source: TilesetSourceRect(x: 3, y: 1),
                  durationMs: 250,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}
