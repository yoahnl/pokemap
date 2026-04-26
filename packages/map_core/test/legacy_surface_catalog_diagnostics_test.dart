import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('LegacySurfaceCatalogDiagnostics', () {
    test('returns no diagnostics for a healthy legacy surface catalog', () {
      // A healthy catalog is not a promise that the future Surface Engine can
      // migrate everything automatically. It only means the legacy presets have
      // none of the structural risks diagnosed by this V0 audit helper.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(id: 'grass', terrainType: TerrainType.grass),
          ],
          pathPresets: [
            pathPreset(id: 'water', surfaceKind: PathSurfaceKind.water),
          ],
        ),
      );

      expect(diagnostics, isEmpty);
    });

    test('warns once for duplicate terrain surface ids', () {
      // Duplicate terrain ids are a migration risk because future persistent
      // Surface definitions will likely need stable ids. V0 reports the fact
      // without changing the legacy list or throwing.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(id: 'duplicate'),
            terrainPreset(id: 'duplicate', name: 'Duplicate 2'),
            terrainPreset(id: 'duplicate', name: 'Duplicate 3'),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.duplicateTerrainSurfaceId,
      );
      expect(
          diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.terrain);
      expect(diagnostic.surfaceId, 'duplicate');
      expect(diagnostic.detail, contains('3'));
    });

    test('warns once for duplicate path surface ids', () {
      // Path ids follow the same legacy list behavior as terrain ids. The
      // diagnostic is scoped to the path family and does not de-duplicate.
      final diagnostics = diagnose(
        projectManifest(
          pathPresets: [
            pathPreset(id: 'duplicate'),
            pathPreset(id: 'duplicate', name: 'Duplicate 2'),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.duplicatePathSurfaceId,
      );
      expect(
          diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.path);
      expect(diagnostic.surfaceId, 'duplicate');
      expect(diagnostic.detail, contains('2'));
    });

    test('reports shared terrain and path ids as cross-family info', () {
      // A shared id across terrain and path is useful to know for migration
      // planning, but Lot 6 explicitly keeps those collections separate. This
      // should not be treated as a structural error.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(id: 'shared'),
          ],
          pathPresets: [
            pathPreset(id: 'shared'),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.sharedTerrainAndPathId,
      );
      expect(diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.info);
      expect(
          diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.crossFamily);
      expect(diagnostic.surfaceId, 'shared');
    });

    test('warns for a terrain surface without variants', () {
      // Empty terrain presets can exist as authoring placeholders, but a future
      // surface migration needs to flag them because they carry no visual
      // variant to migrate.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'empty-terrain',
              name: 'Empty Terrain',
              variants: const [],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithoutVariants,
      );
      expect(
          diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.terrain);
      expect(diagnostic.surfaceId, 'empty-terrain');
      expect(diagnostic.surfaceName, 'Empty Terrain');
    });

    test('warns for a path surface without variants', () {
      // A path preset without mappings cannot describe current autotile visuals.
      // The diagnostic records that gap without inventing fallback mappings.
      final diagnostics = diagnose(
        projectManifest(
          pathPresets: [
            pathPreset(
              id: 'empty-path',
              name: 'Empty Path',
              variants: const [],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.pathSurfaceWithoutVariants,
      );
      expect(
          diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.path);
      expect(diagnostic.surfaceId, 'empty-path');
      expect(diagnostic.surfaceName, 'Empty Path');
    });

    test('warns for a terrain variant without frames', () {
      // Terrain variants are weighted visual candidates. A variant with no
      // frames cannot be rendered or migrated as visual surface data.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'terrain-empty-variant',
              variants: [
                terrainVariant(const []),
              ],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.terrainVariantWithoutFrames,
      );
      expect(
          diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.terrain);
      expect(diagnostic.surfaceId, 'terrain-empty-variant');
      expect(diagnostic.detail, contains('0'));
    });

    test('warns for a path variant mapping without frames', () {
      // Path mappings bind a TerrainPathVariant to visual frames. Empty mappings
      // are especially important for future autotile migration audits.
      final diagnostics = diagnose(
        projectManifest(
          pathPresets: [
            pathPreset(
              id: 'path-empty-mapping',
              variants: [
                pathMapping(TerrainPathVariant.cross, const []),
              ],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.pathVariantWithoutFrames,
      );
      expect(
          diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.path);
      expect(diagnostic.surfaceId, 'path-empty-mapping');
      expect(diagnostic.detail, contains('cross'));
      expect(diagnostic.detail, contains('0'));
    });

    test('warns for duplicate path variant mappings', () {
      // Duplicate mappings already have a "first match" meaning in
      // LegacyPathSurfaceView. Diagnostics should expose that ambiguity without
      // choosing a different merge or fallback rule.
      final diagnostics = diagnose(
        projectManifest(
          pathPresets: [
            pathPreset(
              id: 'path-duplicate-mapping',
              variants: [
                pathMapping(TerrainPathVariant.cross, [visualFrame(0)]),
                pathMapping(TerrainPathVariant.cross, [visualFrame(1)]),
              ],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.duplicatePathVariantMapping,
      );
      expect(
          diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.warning);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.path);
      expect(diagnostic.surfaceId, 'path-duplicate-mapping');
      expect(diagnostic.detail, contains('cross'));
      expect(diagnostic.detail, contains('0'));
      expect(diagnostic.detail, contains('1'));
    });

    test('reports weighted terrain variants as info', () {
      // Weighted terrain variants are valid legacy authoring data. They are
      // informational for migration because a future Surface model must decide
      // whether and how to preserve weighted variant selection.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'weighted-terrain',
              variants: [
                terrainVariant([visualFrame(0)], weight: 1),
                terrainVariant([visualFrame(1)], weight: 3),
              ],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithWeightedVariants,
      );
      expect(diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.info);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.terrain);
      expect(diagnostic.surfaceId, 'weighted-terrain');
    });

    test('reports animated terrain variants as info', () {
      // Animation is not an error. It is a useful migration fact because the
      // future Surface Engine must preserve time-based visual frames.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'animated-terrain',
              variants: [
                terrainVariant([visualFrame(0), visualFrame(1)]),
              ],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithAnimatedVariants,
      );
      expect(diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.info);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.terrain);
      expect(diagnostic.surfaceId, 'animated-terrain');
    });

    test('reports animated path variants as info', () {
      // Animated path mappings are expected for water-like surfaces. The
      // diagnostic records the fact without invoking any runtime animation
      // timeline.
      final diagnostics = diagnose(
        projectManifest(
          pathPresets: [
            pathPreset(
              id: 'animated-path',
              variants: [
                pathMapping(TerrainPathVariant.cross, [
                  visualFrame(0),
                  visualFrame(1),
                ]),
              ],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.pathSurfaceWithAnimatedVariants,
      );
      expect(diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.info);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.path);
      expect(diagnostic.surfaceId, 'animated-path');
    });

    test('reports terrain frame tileset overrides as info', () {
      // In the current frame model, tilesetId == '' means no override. A
      // non-empty value is important for future multi-atlas surface migration.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'terrain-override',
              variants: [
                terrainVariant([
                  visualFrame(0, tilesetId: 'terrain-atlas-override'),
                ]),
              ],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.frameTilesetOverrideUsed,
      );
      expect(diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.info);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.terrain);
      expect(diagnostic.surfaceId, 'terrain-override');
      expect(diagnostic.detail, contains('terrain-atlas-override'));
    });

    test('reports path frame tileset overrides as info', () {
      // Path frame overrides use the same empty-string sentinel as terrain
      // frames. Diagnostics should report the first override per surface.
      final diagnostics = diagnose(
        projectManifest(
          pathPresets: [
            pathPreset(
              id: 'path-override',
              variants: [
                pathMapping(TerrainPathVariant.cross, [
                  visualFrame(0, tilesetId: 'path-atlas-override'),
                ]),
              ],
            ),
          ],
        ),
      );

      final diagnostic = expectSingleDiagnostic(
        diagnostics,
        LegacySurfaceCatalogDiagnosticCode.frameTilesetOverrideUsed,
      );
      expect(diagnostic.severity, LegacySurfaceCatalogDiagnosticSeverity.info);
      expect(diagnostic.family, LegacySurfaceCatalogDiagnosticFamily.path);
      expect(diagnostic.surfaceId, 'path-override');
      expect(diagnostic.detail, contains('path-atlas-override'));
    });

    test('emits diagnostics in deterministic migration-audit order', () {
      // The order is part of the diagnostic contract so reports and tests stay
      // stable: global terrain, global path, cross-family, then per-surface
      // terrain details, then per-surface path details.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(id: 'dup-terrain'),
            terrainPreset(id: 'dup-terrain', name: 'Duplicate Terrain 2'),
            terrainPreset(id: 'shared'),
            terrainPreset(id: 'empty-terrain', variants: const []),
            terrainPreset(
              id: 'empty-terrain-variant',
              variants: [
                terrainVariant(const []),
              ],
            ),
            terrainPreset(
              id: 'weighted-animated-override-terrain',
              variants: [
                terrainVariant([
                  visualFrame(0),
                  visualFrame(1, tilesetId: 'terrain-atlas-override'),
                ], weight: 2),
              ],
            ),
          ],
          pathPresets: [
            pathPreset(id: 'dup-path'),
            pathPreset(id: 'dup-path', name: 'Duplicate Path 2'),
            pathPreset(id: 'shared'),
            pathPreset(id: 'empty-path', variants: const []),
            pathPreset(
              id: 'empty-path-mapping',
              variants: [
                pathMapping(TerrainPathVariant.cross, const []),
              ],
            ),
            pathPreset(
              id: 'duplicate-animated-override-path',
              variants: [
                pathMapping(TerrainPathVariant.cross, [visualFrame(0)]),
                pathMapping(TerrainPathVariant.cross, [
                  visualFrame(1),
                  visualFrame(2, tilesetId: 'path-atlas-override'),
                ]),
              ],
            ),
          ],
        ),
      );

      expect(diagnostics.map((diagnostic) => diagnostic.code), [
        LegacySurfaceCatalogDiagnosticCode.duplicateTerrainSurfaceId,
        LegacySurfaceCatalogDiagnosticCode.duplicatePathSurfaceId,
        LegacySurfaceCatalogDiagnosticCode.sharedTerrainAndPathId,
        LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithoutVariants,
        LegacySurfaceCatalogDiagnosticCode.terrainVariantWithoutFrames,
        LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithWeightedVariants,
        LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithAnimatedVariants,
        LegacySurfaceCatalogDiagnosticCode.frameTilesetOverrideUsed,
        LegacySurfaceCatalogDiagnosticCode.pathSurfaceWithoutVariants,
        LegacySurfaceCatalogDiagnosticCode.pathVariantWithoutFrames,
        LegacySurfaceCatalogDiagnosticCode.duplicatePathVariantMapping,
        LegacySurfaceCatalogDiagnosticCode.pathSurfaceWithAnimatedVariants,
        LegacySurfaceCatalogDiagnosticCode.frameTilesetOverrideUsed,
      ]);
      expect(diagnostics[0].surfaceId, 'dup-terrain');
      expect(diagnostics[1].surfaceId, 'dup-path');
      expect(diagnostics[2].surfaceId, 'shared');
      expect(diagnostics[8].surfaceId, 'empty-path');
    });

    test('returns an unmodifiable diagnostic list', () {
      // Diagnostics are audit output, not an editable model. Callers that want
      // to transform them should create their own list.
      final diagnostics = diagnose(
        projectManifest(
          terrainPresets: [
            terrainPreset(id: 'empty-terrain', variants: const []),
          ],
        ),
      );

      expect(
        () => diagnostics.add(
          const LegacySurfaceCatalogDiagnostic(
            severity: LegacySurfaceCatalogDiagnosticSeverity.info,
            code: LegacySurfaceCatalogDiagnosticCode.sharedTerrainAndPathId,
            family: LegacySurfaceCatalogDiagnosticFamily.crossFamily,
            message: 'extra',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('does not mutate the source catalog or its adapted frames', () {
      // Diagnostics must remain read-only. They can point out risks, but they
      // must not alter catalog order, variants, frame lists, or frame objects.
      final terrainFrame = visualFrame(0, tilesetId: 'terrain-override');
      final pathFrame = visualFrame(1, tilesetId: 'path-override');
      final catalog = createLegacyProjectSurfaceCatalogView(
        projectManifest(
          terrainPresets: [
            terrainPreset(
              id: 'terrain-source',
              variants: [
                terrainVariant([terrainFrame], weight: 5),
              ],
            ),
          ],
          pathPresets: [
            pathPreset(
              id: 'path-source',
              variants: [
                pathMapping(TerrainPathVariant.cross, [pathFrame]),
              ],
            ),
          ],
        ),
      );
      final beforeTerrainSurfaces =
          List<LegacyTerrainSurfaceView>.from(catalog.terrainSurfaces);
      final beforePathSurfaces =
          List<LegacyPathSurfaceView>.from(catalog.pathSurfaces);

      final diagnostics = diagnoseLegacySurfaceCatalog(catalog);

      expect(diagnostics, hasLength(3));
      expect(
        diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          LegacySurfaceCatalogDiagnosticCode.terrainSurfaceWithWeightedVariants,
        ),
      );
      expect(catalog.terrainSurfaces, beforeTerrainSurfaces);
      expect(catalog.pathSurfaces, beforePathSurfaces);
      expect(catalog.terrainSurfaces.single.variants.single.weight, 5);
      expect(
        catalog.terrainSurfaces.single.variants.single.frames.single,
        same(terrainFrame),
      );
      expect(
        catalog.pathSurfaces.single.variants.single.frames.single,
        same(pathFrame),
      );
    });
  });
}

List<LegacySurfaceCatalogDiagnostic> diagnose(ProjectManifest manifest) {
  return diagnoseLegacySurfaceCatalog(
    createLegacyProjectSurfaceCatalogView(manifest),
  );
}

LegacySurfaceCatalogDiagnostic expectSingleDiagnostic(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
  LegacySurfaceCatalogDiagnosticCode code,
) {
  final matches = diagnostics
      .where((diagnostic) => diagnostic.code == code)
      .toList(growable: false);
  expect(matches, hasLength(1));
  return matches.single;
}

ProjectManifest projectManifest({
  List<ProjectTerrainPreset> terrainPresets = const [],
  List<ProjectPathPreset> pathPresets = const [],
}) {
  return ProjectManifest(
    name: 'Legacy Surface Diagnostics',
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
          terrainVariant([visualFrame(0)])
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
