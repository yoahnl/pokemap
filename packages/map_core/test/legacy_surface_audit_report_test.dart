// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest projectManifest({
  List<ProjectTerrainPreset> terrainPresets = const [],
  List<ProjectPathPreset> pathPresets = const [],
}) {
  return ProjectManifest(
    name: 'Legacy Surface Audit Report Test',
    maps: const [],
    tilesets: const [],
    terrainPresets: terrainPresets,
    pathPresets: pathPresets,
  );
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

LegacySurfaceAuditReport audit({
  required ProjectManifest manifest,
  required Iterable<MapData> maps,
}) {
  return createLegacySurfaceAuditReport(
    manifest: manifest,
    maps: maps,
  );
}

List<LegacySurfaceCatalogDiagnosticCode> catalogCodes(
  Iterable<LegacySurfaceCatalogDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.code).toList();
}

List<LegacySurfaceUsageDiagnosticCode> usageCodes(
  Iterable<LegacySurfaceUsageDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.code).toList();
}

void main() {
  group('LegacySurfaceAuditReport', () {
    test('creates an empty report for an empty manifest and no maps', () {
      // This is the pre-migration baseline: a project can have no legacy
      // terrain/path presets and no analyzed maps. The audit report should
      // represent that as an empty read-only snapshot, not as invalid input.
      final report = audit(
        manifest: projectManifest(),
        maps: const [],
      );

      expect(report.catalog.terrainSurfaces, isEmpty);
      expect(report.catalog.pathSurfaces, isEmpty);
      expect(report.usage.terrainUsages, isEmpty);
      expect(report.usage.pathUsages, isEmpty);
      expect(report.usage.missingPathSurfaceUsages, isEmpty);
      expect(report.catalogDiagnostics, isEmpty);
      expect(report.usageDiagnostics, isEmpty);
      expect(report.summary.terrainSurfaceCount, 0);
      expect(report.summary.pathSurfaceCount, 0);
      expect(report.summary.terrainUsageCount, 0);
      expect(report.summary.pathUsageCount, 0);
      expect(report.summary.missingPathUsageCount, 0);
      expect(report.summary.catalogDiagnosticCount, 0);
      expect(report.summary.catalogWarningCount, 0);
      expect(report.summary.usageDiagnosticCount, 0);
      expect(report.summary.usageWarningCount, 0);
      expect(report.hasDiagnostics, isFalse);
      expect(report.hasWarnings, isFalse);
      expect(report.hasUsage, isFalse);
    });

    test('creates a healthy report with declared and used surfaces', () {
      // The report should simply assemble the existing catalog and usage
      // bricks. A declared grass terrain and a declared water path, both used
      // in maps, should produce usage counts without diagnostics.
      final report = audit(
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
                id: 'terrain',
                name: 'Terrain',
                terrains: [TerrainType.grass, TerrainType.none],
              ),
              MapLayer.path(
                id: 'water-layer',
                name: 'Water Layer',
                presetId: 'water',
                cells: [true, false],
              ),
            ],
          ),
        ],
      );

      expect(report.catalog.terrainSurfaces, hasLength(1));
      expect(report.catalog.pathSurfaces, hasLength(1));
      expect(report.usage.terrainUsages, hasLength(1));
      expect(report.usage.pathUsages, hasLength(1));
      expect(report.usage.missingPathSurfaceUsages, isEmpty);
      expect(report.catalogDiagnostics, isEmpty);
      expect(report.usageDiagnostics, isEmpty);
      expect(report.summary.terrainSurfaceCount, 1);
      expect(report.summary.pathSurfaceCount, 1);
      expect(report.summary.terrainUsageCount, 1);
      expect(report.summary.pathUsageCount, 1);
      expect(report.summary.missingPathUsageCount, 0);
      expect(report.summary.catalogDiagnosticCount, 0);
      expect(report.summary.catalogWarningCount, 0);
      expect(report.summary.usageDiagnosticCount, 0);
      expect(report.summary.usageWarningCount, 0);
      expect(report.hasDiagnostics, isFalse);
      expect(report.hasWarnings, isFalse);
      expect(report.hasUsage, isTrue);
    });

    test('includes catalog and unused declaration diagnostics', () {
      // Catalog diagnostics are kept in the report instead of being hidden by
      // the aggregate layer. With no maps analyzed, usage diagnostics should
      // still report declared surfaces that have no matching real usage.
      final report = audit(
        manifest: projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'empty-grass',
              terrainType: TerrainType.grass,
              variants: const [],
            ),
          ],
          pathPresets: [
            pathPreset(id: 'duplicate-water'),
            pathPreset(id: 'duplicate-water', name: 'Duplicate Water 2'),
          ],
        ),
        maps: const [],
      );

      expect(
        catalogCodes(report.catalogDiagnostics),
        containsAll([
          LegacySurfaceCatalogDiagnosticCode.duplicatePathSurfaceId,
          LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithoutVariants,
        ]),
      );
      expect(
        usageCodes(report.usageDiagnostics),
        containsAll([
          LegacySurfaceUsageDiagnosticCode
              .declaredTerrainSurfaceWithoutMatchingUsage,
          LegacySurfaceUsageDiagnosticCode.declaredPathSurfaceWithoutUsage,
        ]),
      );
      expect(report.hasDiagnostics, isTrue);
      expect(report.hasWarnings, isTrue);
      expect(
        report.summary.catalogDiagnosticCount,
        report.catalogDiagnostics.length,
      );
      expect(
        report.summary.usageDiagnosticCount,
        report.usageDiagnostics.length,
      );
    });

    test('includes usage diagnostics for missing declared surfaces', () {
      // Usage diagnostics are the map-facing half of the audit. They should
      // expose both terrain types with no declared candidate and active path
      // layers whose preset id cannot be resolved.
      final report = audit(
        manifest: projectManifest(),
        maps: [
          mapData(
            id: 'route-1',
            name: 'Route 1',
            layers: [
              MapLayer.terrain(
                id: 'terrain',
                name: 'Terrain',
                terrains: [TerrainType.grass],
              ),
              MapLayer.path(
                id: 'missing-water-layer',
                name: 'Missing Water Layer',
                presetId: 'missing-water',
                cells: [true, true],
              ),
            ],
          ),
        ],
      );

      expect(
        usageCodes(report.usageDiagnostics),
        containsAll([
          LegacySurfaceUsageDiagnosticCode
              .usedTerrainTypeWithoutDeclaredSurface,
          LegacySurfaceUsageDiagnosticCode.missingPathSurfaceUsage,
        ]),
      );
      expect(report.summary.terrainUsageCount, 1);
      expect(report.summary.pathUsageCount, 0);
      expect(report.summary.missingPathUsageCount, 1);
      expect(report.hasDiagnostics, isTrue);
      expect(report.hasWarnings, isTrue);
    });

    test('exposes non-mutable diagnostic lists', () {
      // The audit report is a snapshot intended for later UI/reporting layers.
      // Callers must not be able to mutate its diagnostic lists in place.
      final report = audit(
        manifest: projectManifest(),
        maps: const [],
      );

      expect(
        () => report.catalogDiagnostics.add(
          const LegacySurfaceCatalogDiagnostic(
            severity: LegacySurfaceCatalogDiagnosticSeverity.info,
            code: LegacySurfaceCatalogDiagnosticCode.sharedTerrainAndPathId,
            family: LegacySurfaceCatalogDiagnosticFamily.crossFamily,
            message: 'Synthetic catalog diagnostic.',
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => report.usageDiagnostics.add(
          const LegacySurfaceUsageDiagnostic(
            severity: LegacySurfaceUsageDiagnosticSeverity.info,
            code: LegacySurfaceUsageDiagnosticCode
                .declaredPathSurfaceWithoutUsage,
            family: LegacySurfaceUsageDiagnosticFamily.path,
            message: 'Synthetic usage diagnostic.',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('does not mutate manifest, maps, layers, or cells', () {
      // The report is an audit snapshot. Producing it must not rewrite legacy
      // manifest presets or map layers, because migration and correction will
      // be handled by later explicit lots.
      final terrain = terrainPreset(
        id: 'grass',
        terrainType: TerrainType.grass,
      );
      final path = pathPreset(
        id: 'water',
        surfaceKind: PathSurfaceKind.water,
      );
      final manifest = projectManifest(
        terrainPresets: [terrain],
        pathPresets: [path],
      );
      final terrainLayer = MapLayer.terrain(
        id: 'terrain',
        name: 'Terrain',
        terrains: [TerrainType.grass, TerrainType.none],
      ) as TerrainLayer;
      final pathLayer = MapLayer.path(
        id: 'water-layer',
        name: 'Water Layer',
        presetId: 'water',
        cells: [true, false, true],
      ) as PathLayer;
      final map = mapData(layers: [terrainLayer, pathLayer]);

      final report = audit(manifest: manifest, maps: [map]);

      expect(report.hasUsage, isTrue);
      expect(manifest.terrainPresets, [terrain]);
      expect(manifest.pathPresets, [path]);
      expect(map.layers, [terrainLayer, pathLayer]);
      expect(terrainLayer.terrains, [TerrainType.grass, TerrainType.none]);
      expect(pathLayer.cells, [true, false, true]);
      expect(pathLayer.presetId, 'water');
    });

    test('summary counts catalog warnings separately from usage warnings', () {
      // Catalog and usage diagnostics use different severity enums. The
      // summary must count each family independently and still expose the
      // combined hasWarnings convenience flag.
      final report = audit(
        manifest: projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'empty-grass',
              terrainType: TerrainType.grass,
              variants: const [],
            ),
          ],
          pathPresets: [
            pathPreset(id: 'unused-road', surfaceKind: PathSurfaceKind.road),
          ],
        ),
        maps: [
          mapData(
            layers: [
              MapLayer.terrain(
                id: 'terrain',
                name: 'Terrain',
                terrains: [TerrainType.grass],
              ),
              MapLayer.path(
                id: 'missing-water-layer',
                name: 'Missing Water Layer',
                presetId: 'missing-water',
                cells: [true],
              ),
            ],
          ),
        ],
      );

      expect(report.summary.catalogDiagnosticCount, 1);
      expect(report.summary.catalogWarningCount, 1);
      expect(report.summary.usageDiagnosticCount, 3);
      expect(report.summary.usageWarningCount, 2);
      expect(
        usageCodes(report.usageDiagnostics),
        contains(
            LegacySurfaceUsageDiagnosticCode.declaredPathSurfaceWithoutUsage),
      );
      expect(report.hasWarnings, isTrue);
    });

    test('reuses the catalog, usage, and diagnostic helper outputs', () {
      // Lot 10 should assemble existing bricks, not reimplement their logic.
      // Compare observable ids, counts, and diagnostic codes against the
      // standalone Lot 6, Lot 8, Lot 7, and Lot 9 functions.
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(id: 'grass', terrainType: TerrainType.grass),
        ],
        pathPresets: [
          pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
        ],
      );
      final maps = [
        mapData(
          layers: [
            MapLayer.terrain(
              id: 'terrain',
              name: 'Terrain',
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
      ];
      final standaloneCatalog = createLegacyProjectSurfaceCatalogView(manifest);
      final standaloneUsage = createLegacyProjectSurfaceUsageView(
        catalog: standaloneCatalog,
        maps: maps,
      );
      final standaloneCatalogDiagnostics =
          diagnoseLegacySurfaceCatalog(standaloneCatalog);
      final standaloneUsageDiagnostics = diagnoseLegacySurfaceUsage(
        catalog: standaloneCatalog,
        usage: standaloneUsage,
      );

      final report = audit(manifest: manifest, maps: maps);

      expect(
        report.catalog.terrainSurfaces.map((surface) => surface.id),
        standaloneCatalog.terrainSurfaces.map((surface) => surface.id),
      );
      expect(
        report.catalog.pathSurfaces.map((surface) => surface.id),
        standaloneCatalog.pathSurfaces.map((surface) => surface.id),
      );
      expect(
        report.usage.terrainUsages.map((usage) => usage.terrainType),
        standaloneUsage.terrainUsages.map((usage) => usage.terrainType),
      );
      expect(
        report.usage.pathUsages.map((usage) => usage.presetId),
        standaloneUsage.pathUsages.map((usage) => usage.presetId),
      );
      expect(
        catalogCodes(report.catalogDiagnostics),
        catalogCodes(standaloneCatalogDiagnostics),
      );
      expect(
        usageCodes(report.usageDiagnostics),
        usageCodes(standaloneUsageDiagnostics),
      );
    });
  });
}
