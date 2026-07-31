import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('validateProjectSmartTileCatalog', () {
    test('reports duplicate ids', () {
      final catalog = _catalog(
        categories: const <ProjectSmartTileCategory>[
          ProjectSmartTileCategory(id: 'nature', name: 'Nature'),
          ProjectSmartTileCategory(id: 'nature', name: 'Nature duplicate'),
        ],
      );

      expect(_codes(catalog), contains('smart_tiles.id.duplicate'));
    });

    test('reports missing references', () {
      final catalog = _catalog(
        tilesetId: 'missing-tileset',
        preset: _pathPreset(
          defaultMaterialId: 'missing-material',
          allowedMaterialIds: const <String>['missing-material'],
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'references',
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'references',
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'missing-atlas',
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.animation(
                        animationId: 'missing-animation',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        _codes(catalog),
        containsAll(<String>[
          'smart_tiles.reference.tileset_missing',
          'smart_tiles.reference.atlas_missing',
          'smart_tiles.reference.material_missing',
          'smart_tiles.reference.animation_missing',
        ]),
      );
    });

    test('reports out-of-bounds frames, weights, and animations', () {
      final catalog = _catalog(
        animations: const <ProjectSmartTileAnimation>[
          ProjectSmartTileAnimation(
            id: 'invalid-animation',
            name: 'Invalid animation',
            frames: <ProjectSmartTileAnimationFrame>[
              ProjectSmartTileAnimationFrame(
                frame: SmartTileFrameRef(
                  atlasId: 'atlas',
                  column: 0,
                  row: 0,
                ),
                durationMs: 0,
              ),
            ],
          ),
        ],
        preset: _pathPreset(
          rules: const <SmartTileRule>[
            SmartTileRule(
              id: 'invalid-candidate',
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'bad-weight',
                  weight: 0,
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'atlas',
                          column: 2,
                          row: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      expect(
        _codes(catalog),
        containsAll(<String>[
          'smart_tiles.atlas.frame_out_of_bounds',
          'smart_tiles.weight.invalid',
          'smart_tiles.animation.invalid',
        ]),
      );
    });

    test('reports incompatible usage and Terrain material count', () {
      final catalog = _catalog(
        preset: const ProjectSmartTilePreset(
          id: 'bad-terrain',
          name: 'Bad terrain',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.wang8,
          defaultMaterialId: 'grass',
          allowedMaterialIds: <String>['grass', 'dirt'],
        ),
      );

      expect(
        _codes(catalog),
        containsAll(<String>[
          'smart_tiles.topology.usage_mismatch',
          'smart_tiles.terrain.material_count',
        ]),
      );
    });

    test('accepts a valid Terrain preset and Wang Path preset', () {
      final terrain = _catalog(
        preset: const ProjectSmartTilePreset(
          id: 'grass-terrain',
          name: 'Grass terrain',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.cardinal4,
          defaultMaterialId: 'grass',
          allowedMaterialIds: <String>['grass'],
        ),
      );
      final path = _catalog(
        preset: _pathPreset(),
      );

      expect(
        validateProjectSmartTileCatalog(
          catalog: terrain,
          projectTilesetIds: const <String>['tileset'],
        ).where((diagnostic) => diagnostic.isError),
        isEmpty,
      );
      expect(
        validateProjectSmartTileCatalog(
          catalog: path,
          projectTilesetIds: const <String>['tileset'],
        ).where((diagnostic) => diagnostic.isError),
        isEmpty,
      );
    });
  });
}

Set<String> _codes(ProjectSmartTileCatalog catalog) {
  return validateProjectSmartTileCatalog(
    catalog: catalog,
    projectTilesetIds: const <String>['tileset'],
  ).map((diagnostic) => diagnostic.code).toSet();
}

ProjectSmartTileCatalog _catalog({
  String tilesetId = 'tileset',
  List<ProjectSmartTileCategory> categories =
      const <ProjectSmartTileCategory>[],
  List<ProjectSmartTileAnimation> animations =
      const <ProjectSmartTileAnimation>[],
  ProjectSmartTilePreset? preset,
}) {
  return ProjectSmartTileCatalog(
    categories: categories,
    atlases: <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: tilesetId,
        columns: 2,
        rows: 2,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'ground',
      ),
      ProjectSmartTileMaterial(
        id: 'dirt',
        name: 'Dirt',
        connectionGroupId: 'ground',
      ),
    ],
    animations: animations,
    presets: <ProjectSmartTilePreset>[
      preset ?? _pathPreset(),
    ],
  );
}

ProjectSmartTilePreset _pathPreset({
  String defaultMaterialId = 'dirt',
  List<String> allowedMaterialIds = const <String>['grass', 'dirt'],
  List<SmartTileRule> rules = const <SmartTileRule>[],
}) {
  return ProjectSmartTilePreset(
    id: 'path',
    name: 'Path',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.wang8,
    defaultMaterialId: defaultMaterialId,
    allowedMaterialIds: allowedMaterialIds,
    rules: rules,
  );
}
