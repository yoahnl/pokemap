import 'dart:convert';

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

  test('ProjectManifest canonical JSON preserves explicit false Facts', () {
    final manifest = ProjectManifest(
      name: 'Fact canonical regression',
      maps: const [],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
          id: 'fact_explicit_false',
          label: 'Explicit false',
          defaultValue: false,
        ),
      ],
    );

    final canonical = canonicalizeNarrativeEventJson(manifest.toJson());
    final decoded = ProjectManifest.fromJson(
      jsonDecode(canonical) as Map<String, dynamic>,
    );

    expect(canonical, contains('"defaultValue":false'));
    expect(decoded.facts.single.defaultValue, isFalse);
    expect(decoded.facts.single.id, 'fact_explicit_false');
  });

  test('legacy absent false defaults safely and a broken Fact id is refused',
      () {
    final base = ProjectManifest(
      name: 'Fact legacy regression',
      maps: const [],
      tilesets: const [],
    ).toJson();
    final legacy = ProjectManifest.fromJson({
      ...base,
      'facts': [
        {'id': 'fact_legacy', 'label': 'Legacy Fact'},
      ],
    });

    expect(legacy.facts.single.defaultValue, isFalse);
    expect(
      () => ProjectManifest.fromJson({
        ...base,
        'facts': [
          {'id': '', 'label': 'Broken Fact'},
        ],
      }),
      throwsArgumentError,
    );
  });
}
