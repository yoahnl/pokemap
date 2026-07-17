import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('ProjectManifest path preset output is deep JSON for Event V2 hashes',
      () {
    final manifest = ProjectManifest(
      name: 'Narrative snapshot regression',
      maps: const [],
      tilesets: const [],
      terrainPresets: const <ProjectTerrainPreset>[
        ProjectTerrainPreset(
          id: 'terrain',
          name: 'Terrain',
          terrainType: TerrainType.grass,
          variants: <TerrainPresetVariant>[
            TerrainPresetVariant(
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0),
                ),
              ],
            ),
          ],
        ),
      ],
      pathPresets: const <ProjectPathPreset>[
        ProjectPathPreset(
          id: 'path',
          name: 'Path',
          variants: <PathPresetVariantMapping>[
            PathPresetVariantMapping(
              variant: TerrainPathVariant.cross,
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 1, y: 2),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      () => canonicalizeNarrativeEventJson(manifest.toJson()),
      returnsNormally,
    );
  });
}
