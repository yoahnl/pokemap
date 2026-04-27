// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest projectManifest({
  List<ProjectTerrainPreset> terrainPresets = const [],
  List<ProjectPathPreset> pathPresets = const [],
}) {
  return ProjectManifest(
    name: 'Legacy Surface Usage Diagnostics Test',
    maps: const [],
    tilesets: const [],
    terrainPresets: terrainPresets,
    pathPresets: pathPresets,
        surfaceCatalog: ProjectSurfaceCatalog(),);
}

ProjectTerrainPreset terrainPreset({
  String id = 'legacy-terrain',
  String name = 'Legacy Terrain',
  TerrainType terrainType = TerrainType.grass,
  String tilesetId = '',
  String? categoryId,
  int sortOrder = 0,
  List<TerrainPresetVariant>? variants,
}) {
  return ProjectTerrainPreset(
    id: id,
    name: name,
    terrainType: terrainType,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants ??
        [
          terrainVariant([visualFrame(0)]),
        ],
  );
}

TerrainPresetVariant terrainVariant(
  List<TilesetVisualFrame> frames, {
  int weight = 1,
}) {
  return TerrainPresetVariant(
    frames: frames,
    weight: weight,
  );
}

ProjectPathPreset pathPreset({
  String id = 'legacy-path',
  String name = 'Legacy Path',
  PathSurfaceKind surfaceKind = PathSurfaceKind.path,
  String tilesetId = '',
  String? categoryId,
  int sortOrder = 0,
  List<PathPresetVariantMapping>? variants,
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants ??
        [
          pathMapping(TerrainPathVariant.cross, [visualFrame(0)]),
        ],
  );
}

PathPresetVariantMapping pathMapping(
  TerrainPathVariant variant,
  List<TilesetVisualFrame> frames,
) {
  return PathPresetVariantMapping(
    variant: variant,
    frames: frames,
  );
}

TilesetVisualFrame visualFrame(
  int x, {
  String tilesetId = '',
  int? durationMs,
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: x, y: 0),
    durationMs: durationMs,
  );
}

MapData mapData({
  String id = 'test-map',
  String name = 'Test Map',
  GridSize size = const GridSize(width: 10, height: 10),
  List<MapLayer> layers = const [],
}) {
  return MapData(
    id: id,
    name: name,
    size: size,
    layers: layers,
  );
}

List<LegacySurfaceUsageDiagnostic> diagnose({
  required ProjectManifest manifest,
  required List<MapData> maps,
}) {
  final catalog = createLegacyProjectSurfaceCatalogView(manifest);
  final usage = createLegacyProjectSurfaceUsageView(
    catalog: catalog,
    maps: maps,
  );
  return diagnoseLegacySurfaceUsage(
    catalog: catalog,
    usage: usage,
  );
}

LegacySurfaceUsageDiagnostic expectSingleDiagnostic(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacySurfaceUsageDiagnosticCode code,
) {
  final matches = diagnostics.where((diagnostic) => diagnostic.code == code);
  expect(matches, hasLength(1));
  return matches.single;
}

void expectNoDiagnostic(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacySurfaceUsageDiagnosticCode code,
) {
  expect(
    diagnostics.where((diagnostic) => diagnostic.code == code),
    isEmpty,
  );
}

void main() {
  group('LegacySurfaceUsageDiagnostics', () {
    test('returns no diagnostics for healthy declared and used surfaces', () {
      // This is the baseline for the migration audit: declared terrain/path
      // candidates exist, maps actually use them, no duplicate path ids are
      // involved, and every used candidate carries at least one visual variant.
      final diagnostics = diagnose(
        manifest: projectManifest(
          terrainPresets: [
            terrainPreset(id: 'grass', terrainType: TerrainType.grass),
          ],
          pathPresets: [
            pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
          ],
        ),
        maps: [
          mapData(
            layers: [
              MapLayer.terrain(
                id: 'ground',
                name: 'Ground',
                terrains: [TerrainType.grass, TerrainType.grass],
              ),
              MapLayer.path(
                id: 'water-layer',
                name: 'Water Layer',
                presetId: 'water',
                cells: [true, false, true],
              ),
            ],
          ),
        ],
      );

      expect(diagnostics, isEmpty);
    });

    test('warns when a used TerrainType has no declared terrain surface', () {
      // Terrain usages are by TerrainType, not preset id. If a type appears in
      // maps but no declared terrain preset matches it, a future Surface
      // migration has no declared visual candidate for that terrain type.
      final diagnostics = diagnose(
        manifest: projectManifest(),
        maps: [
          mapData(
            id: 'route-1',
            name: 'Route 1',
            layers: [
              MapLayer.terrain(
                id: 'ground',
                name: 'Ground',
                terrains: [TerrainType.grass],
              ),
            ],
          ),
        ],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode.usedTerrainTypeWithoutDeclaredSurface,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.terrain);
      expect(diagnostic.terrainType, TerrainType.grass);
      expect(diagnostic.mapId, 'route-1');
      expect(diagnostic.mapName, 'Route 1');
      expect(diagnostic.layerIndex, 0);
      expect(diagnostic.layerId, 'ground');
      expect(diagnostic.layerName, 'Ground');
    });

    test('warns when a used TerrainType has multiple declared candidates', () {
      // The legacy TerrainLayer only stores TerrainType values. Multiple
      // declared presets for the same type are therefore ambiguous for future
      // migrations: the usage does not say which preset authored the cells.
      final diagnostics = diagnose(
        manifest: projectManifest(
          terrainPresets: [
            terrainPreset(id: 'grass-a', terrainType: TerrainType.grass),
            terrainPreset(id: 'grass-b', terrainType: TerrainType.grass),
          ],
        ),
        maps: [
          mapData(
            layers: [
              MapLayer.terrain(
                id: 'ground',
                name: 'Ground',
                terrains: [TerrainType.grass],
              ),
            ],
          ),
        ],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode
            .usedTerrainTypeWithMultipleDeclaredSurfaces,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.terrain);
      expect(diagnostic.terrainType, TerrainType.grass);
      expect(diagnostic.detail, contains('2'));
    });

    test('reports declared terrain surfaces without matching usage as info',
        () {
      // Unused declared surfaces are not broken data. They are useful migration
      // facts because a future Surface catalog may still need to preserve them
      // even when no current map paints their TerrainType.
      final diagnostics = diagnose(
        manifest: projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'sand',
              name: 'Sand',
              terrainType: TerrainType.sand,
            ),
          ],
        ),
        maps: const [],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode
            .declaredTerrainSurfaceWithoutMatchingUsage,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.info);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.terrain);
      expect(diagnostic.surfaceId, 'sand');
      expect(diagnostic.surfaceName, 'Sand');
      expect(diagnostic.terrainType, TerrainType.sand);
    });

    test('warns when a used terrain candidate has no variants', () {
      // Catalog diagnostics already report empty declared terrain surfaces.
      // Usage diagnostics add the extra fact that this empty candidate is tied
      // to a TerrainType actually present in maps.
      final diagnostics = diagnose(
        manifest: projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'rock-empty',
              name: 'Rock Empty',
              terrainType: TerrainType.rock,
              variants: const [],
            ),
          ],
        ),
        maps: [
          mapData(
            layers: [
              MapLayer.terrain(
                id: 'cliffs',
                name: 'Cliffs',
                terrains: [TerrainType.rock],
              ),
            ],
          ),
        ],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode
            .usedTerrainSurfaceCandidateWithoutVariants,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.terrain);
      expect(diagnostic.terrainType, TerrainType.rock);
      expect(diagnostic.surfaceId, 'rock-empty');
      expect(diagnostic.surfaceName, 'Rock Empty');
    });

    test('warns for non-empty missing path preset usage', () {
      // Lot 8 already separates missing path usages. Lot 9 turns each one into
      // an explicit migration warning with map/layer context and active count.
      final diagnostics = diagnose(
        manifest: projectManifest(),
        maps: [
          mapData(
            id: 'lake-map',
            name: 'Lake Map',
            layers: [
              MapLayer.path(
                id: 'missing-water-layer',
                name: 'Missing Water',
                presetId: 'missing-water',
                cells: [true, true, false],
              ),
            ],
          ),
        ],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode.missingPathSurfaceUsage,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.path);
      expect(diagnostic.pathPresetId, 'missing-water');
      expect(diagnostic.mapId, 'lake-map');
      expect(diagnostic.mapName, 'Lake Map');
      expect(diagnostic.layerIndex, 0);
      expect(diagnostic.layerId, 'missing-water-layer');
      expect(diagnostic.layerName, 'Missing Water');
      expect(diagnostic.detail, contains('2'));
    });

    test('warns for active path usage with an empty preset id', () {
      // Empty preset ids are a distinct migration problem from unknown ids.
      // The layer is active, but there is no id to resolve to any declared path
      // surface candidate.
      final diagnostics = diagnose(
        manifest: projectManifest(),
        maps: [
          mapData(
            layers: [
              MapLayer.path(
                id: 'empty-id-layer',
                name: 'Empty Id Layer',
                presetId: '',
                cells: [true],
              ),
            ],
          ),
        ],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode.emptyPathPresetIdUsage,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.path);
      expect(diagnostic.pathPresetId, '');
      expect(diagnostic.layerId, 'empty-id-layer');
      expect(diagnostic.detail, contains('1'));
    });

    test('reports declared path surfaces without usage as info', () {
      // Declared-but-unused path presets can be legitimate library entries. The
      // diagnostic is informational and id-based, not a command to delete data.
      final diagnostics = diagnose(
        manifest: projectManifest(
          pathPresets: [
            pathPreset(
              id: 'unused-road',
              name: 'Unused Road',
              surfaceKind: PathSurfaceKind.road,
            ),
          ],
        ),
        maps: const [],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode.declaredPathSurfaceWithoutUsage,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.info);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.path);
      expect(diagnostic.pathPresetId, 'unused-road');
      expect(diagnostic.surfaceId, 'unused-road');
      expect(diagnostic.surfaceName, 'Unused Road');
    });

    test('warns when a used path id has multiple declared candidates', () {
      // The Lot 6 catalog lookup returns the first path surface for duplicate
      // ids. Usage diagnostics expose the ambiguity without changing that
      // first-match behavior.
      final diagnostics = diagnose(
        manifest: projectManifest(
          pathPresets: [
            pathPreset(id: 'water', name: 'Water A'),
            pathPreset(id: 'water', name: 'Water B'),
          ],
        ),
        maps: [
          mapData(
            layers: [
              MapLayer.path(
                id: 'water-layer',
                name: 'Water Layer',
                presetId: 'water',
                cells: [true],
              ),
            ],
          ),
        ],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode
            .usedPathPresetWithMultipleDeclaredSurfaces,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.path);
      expect(diagnostic.pathPresetId, 'water');
      expect(diagnostic.detail, contains('2'));
    });

    test('warns when a used path surface has no variants', () {
      // Catalog diagnostics can identify every empty path preset. Usage
      // diagnostics narrow that down to an empty preset that is actively used
      // by a map layer.
      final diagnostics = diagnose(
        manifest: projectManifest(
          pathPresets: [
            pathPreset(
              id: 'empty-water',
              name: 'Empty Water',
              surfaceKind: PathSurfaceKind.water,
              variants: const [],
            ),
          ],
        ),
        maps: [
          mapData(
            layers: [
              MapLayer.path(
                id: 'empty-water-layer',
                name: 'Empty Water Layer',
                presetId: 'empty-water',
                cells: [true, true],
              ),
            ],
          ),
        ],
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode.usedPathSurfaceWithoutVariants,
      );
      expect(diagnostic.severity, LegacySurfaceUsageDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceUsageDiagnosticFamily.path);
      expect(diagnostic.pathPresetId, 'empty-water');
      expect(diagnostic.surfaceId, 'empty-water');
      expect(diagnostic.surfaceName, 'Empty Water');
      expect(diagnostic.layerId, 'empty-water-layer');
    });

    test('keeps global diagnostic order deterministic', () {
      // The order is intentionally grouped so reports are stable and readable:
      // terrain usage risks, unused declared terrain, missing path usage,
      // duplicate used path candidates, used empty path surfaces, then unused
      // declared path surfaces.
      final diagnostics = diagnose(
        manifest: projectManifest(
          terrainPresets: [
            terrainPreset(id: 'sand-a', terrainType: TerrainType.sand),
            terrainPreset(id: 'sand-b', terrainType: TerrainType.sand),
            terrainPreset(
              id: 'rock-empty',
              terrainType: TerrainType.rock,
              variants: const [],
            ),
            terrainPreset(id: 'indoor-unused', terrainType: TerrainType.indoor),
          ],
          pathPresets: [
            pathPreset(id: 'water', name: 'Water A'),
            pathPreset(id: 'water', name: 'Water B'),
            pathPreset(
              id: 'empty-used',
              name: 'Empty Used',
              variants: const [],
            ),
            pathPreset(id: 'unused-road', name: 'Unused Road'),
          ],
        ),
        maps: [
          mapData(
            layers: [
              MapLayer.terrain(
                id: 'ground',
                name: 'Ground',
                terrains: [
                  TerrainType.grass,
                  TerrainType.sand,
                  TerrainType.rock,
                ],
              ),
              MapLayer.path(
                id: 'missing-path',
                name: 'Missing Path',
                presetId: 'missing-water',
                cells: [true],
              ),
              MapLayer.path(
                id: 'empty-id-path',
                name: 'Empty Id Path',
                presetId: '',
                cells: [true],
              ),
              MapLayer.path(
                id: 'water-path',
                name: 'Water Path',
                presetId: 'water',
                cells: [true],
              ),
              MapLayer.path(
                id: 'empty-used-path',
                name: 'Empty Used Path',
                presetId: 'empty-used',
                cells: [true],
              ),
            ],
          ),
        ],
      );

      expect(
        diagnostics.map((diagnostic) => diagnostic.code),
        [
          LegacySurfaceUsageDiagnosticCode
              .usedTerrainTypeWithoutDeclaredSurface,
          LegacySurfaceUsageDiagnosticCode
              .usedTerrainTypeWithMultipleDeclaredSurfaces,
          LegacySurfaceUsageDiagnosticCode
              .usedTerrainSurfaceCandidateWithoutVariants,
          LegacySurfaceUsageDiagnosticCode
              .declaredTerrainSurfaceWithoutMatchingUsage,
          LegacySurfaceUsageDiagnosticCode.missingPathSurfaceUsage,
          LegacySurfaceUsageDiagnosticCode.emptyPathPresetIdUsage,
          LegacySurfaceUsageDiagnosticCode
              .usedPathPresetWithMultipleDeclaredSurfaces,
          LegacySurfaceUsageDiagnosticCode.usedPathSurfaceWithoutVariants,
          LegacySurfaceUsageDiagnosticCode.declaredPathSurfaceWithoutUsage,
        ],
      );
    });

    test('returns an unmodifiable diagnostics list', () {
      // Diagnostic output is read-only just like the catalog and usage views.
      // Report builders can copy it, but they must not mutate the returned
      // list in place.
      final diagnostics = diagnose(
        manifest: projectManifest(),
        maps: const [],
      );

      expect(
        () => diagnostics.add(
          const LegacySurfaceUsageDiagnostic(
            severity: LegacySurfaceUsageDiagnosticSeverity.info,
            code: LegacySurfaceUsageDiagnosticCode
                .declaredPathSurfaceWithoutUsage,
            family: LegacySurfaceUsageDiagnosticFamily.path,
            message: 'Synthetic diagnostic.',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('does not mutate catalog or usage inputs', () {
      // The diagnostics layer is an audit view over read-only inputs. Running it
      // must not alter the catalog, usage lists, surfaces, or nested variants.
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(id: 'grass', terrainType: TerrainType.grass),
        ],
        pathPresets: [
          pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
        ],
      );
      final catalog = createLegacyProjectSurfaceCatalogView(manifest);
      final usage = createLegacyProjectSurfaceUsageView(
        catalog: catalog,
        maps: [
          mapData(
            layers: [
              MapLayer.terrain(
                id: 'ground',
                name: 'Ground',
                terrains: [TerrainType.grass],
              ),
              MapLayer.path(
                id: 'water-layer',
                name: 'Water Layer',
                presetId: 'water',
                cells: [true],
              ),
            ],
          ),
        ],
      );

      final terrainSurface = catalog.terrainSurfaces.single;
      final pathSurface = catalog.pathSurfaces.single;
      final terrainUsages = usage.terrainUsages;
      final pathUsages = usage.pathUsages;

      diagnoseLegacySurfaceUsage(catalog: catalog, usage: usage);

      expect(catalog.terrainSurfaces.single, same(terrainSurface));
      expect(catalog.pathSurfaces.single, same(pathSurface));
      expect(catalog.terrainSurfaces.single.variants, hasLength(1));
      expect(catalog.pathSurfaces.single.variants, hasLength(1));
      expect(usage.terrainUsages, same(terrainUsages));
      expect(usage.pathUsages, same(pathUsages));
      expect(usage.terrainUsages.single.terrainType, TerrainType.grass);
      expect(usage.pathUsages.single.presetId, 'water');
    });

    test('does not report duplicated used path ids as unused', () {
      // Lot 9 remains id-based for declared path usage. If an id is used, every
      // declared path surface with that id is considered used enough for this
      // diagnostic, while the duplicate candidate warning captures ambiguity.
      final diagnostics = diagnose(
        manifest: projectManifest(
          pathPresets: [
            pathPreset(id: 'water', name: 'Water A'),
            pathPreset(id: 'water', name: 'Water B'),
          ],
        ),
        maps: [
          mapData(
            layers: [
              MapLayer.path(
                id: 'water-layer',
                name: 'Water Layer',
                presetId: 'water',
                cells: [true],
              ),
            ],
          ),
        ],
      );

      expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode
            .usedPathPresetWithMultipleDeclaredSurfaces,
      );
      expectNoDiagnostic(
        diagnostics,
        LegacySurfaceUsageDiagnosticCode.declaredPathSurfaceWithoutUsage,
      );
    });

    test('reports one unused terrain diagnostic per declared surface', () {
      // Multiple declared terrain surfaces can share the same unused
      // TerrainType. Because these are declared presets, not usages, the audit
      // keeps each candidate visible instead of collapsing them by type.
      final diagnostics = diagnose(
        manifest: projectManifest(
          terrainPresets: [
            terrainPreset(id: 'sand-a', terrainType: TerrainType.sand),
            terrainPreset(id: 'sand-b', terrainType: TerrainType.sand),
          ],
        ),
        maps: const [],
      );

      final unusedTerrainDiagnostics = diagnostics
          .where(
            (diagnostic) =>
                diagnostic.code ==
                LegacySurfaceUsageDiagnosticCode
                    .declaredTerrainSurfaceWithoutMatchingUsage,
          )
          .toList();

      expect(unusedTerrainDiagnostics, hasLength(2));
      expect(
        unusedTerrainDiagnostics.map((diagnostic) => diagnostic.surfaceId),
        ['sand-a', 'sand-b'],
      );
    });
  });
}
