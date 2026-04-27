import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('LegacyProjectSurfaceCatalogView', () {
    test('catalog is empty when the manifest has no legacy surface presets',
        () {
      // The future Surface Engine needs an inventory entry point that can
      // safely handle projects before any terrain/path presets exist. An empty
      // catalog must mean "nothing to migrate", not "invalid manifest".
      final catalog = createLegacyProjectSurfaceCatalogView(projectManifest());

      expect(catalog.terrainSurfaces, isEmpty);
      expect(catalog.pathSurfaces, isEmpty);
      expect(catalog.hasTerrainSurfaces, isFalse);
      expect(catalog.hasPathSurfaces, isFalse);
      expect(catalog.isEmpty, isTrue);
    });

    test('catalog preserves terrain and path preset order separately', () {
      // The manifest stores terrain presets and path presets as separate
      // ordered lists. The catalog is only an inventory view, so it must keep
      // both collections separate and keep their authoring order intact.
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(id: 'grass-a', terrainType: TerrainType.grass),
          terrainPreset(id: 'sand-a', terrainType: TerrainType.sand),
        ],
        pathPresets: [
          pathPreset(id: 'water-a', surfaceKind: PathSurfaceKind.water),
          pathPreset(
              id: 'grass-path-a', surfaceKind: PathSurfaceKind.tallGrass),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(catalog.terrainSurfaces, hasLength(2));
      expect(catalog.pathSurfaces, hasLength(2));
      expect(catalog.terrainSurfaces.map((surface) => surface.id), [
        'grass-a',
        'sand-a',
      ]);
      expect(catalog.pathSurfaces.map((surface) => surface.id), [
        'water-a',
        'grass-path-a',
      ]);
      expect(catalog.terrainSurfaces.map((surface) => surface.terrainType), [
        TerrainType.grass,
        TerrainType.sand,
      ]);
      expect(catalog.pathSurfaces.map((surface) => surface.surfaceKind), [
        PathSurfaceKind.water,
        PathSurfaceKind.tallGrass,
      ]);
      expect(catalog.hasTerrainSurfaces, isTrue);
      expect(catalog.hasPathSurfaces, isTrue);
      expect(catalog.isEmpty, isFalse);
    });

    test('delegates terrain and path data to the existing legacy adapters', () {
      // The catalog must not reinterpret frames, weights, or per-frame tileset
      // overrides. It should simply delegate to the Lot 4 and Lot 5 adapters so
      // migration reports see the same data from individual and project views.
      final terrainOverrideFrame = visualFrame(
        5,
        tilesetId: 'animated-terrain-atlas',
        durationMs: 180,
      );
      final pathOverrideFrame = visualFrame(
        8,
        tilesetId: 'animated-water-atlas',
        durationMs: 140,
      );
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(
            id: 'animated-grass',
            variants: [
              terrainVariant(
                [visualFrame(0, durationMs: 90), terrainOverrideFrame],
                weight: 4,
              ),
            ],
          ),
        ],
        pathPresets: [
          pathPreset(
            id: 'animated-water',
            surfaceKind: PathSurfaceKind.water,
            variants: [
              pathMapping(
                TerrainPathVariant.cross,
                [visualFrame(2, durationMs: 70), pathOverrideFrame],
              ),
            ],
          ),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);
      final terrainSurface = catalog.terrainSurfaces.single;
      final pathSurface = catalog.pathSurfaces.single;

      expect(terrainSurface.hasAnimatedVariants, isTrue);
      expect(terrainSurface.variants.single.weight, 4);
      expect(
        terrainSurface.variants.single.frames.last,
        same(terrainOverrideFrame),
      );
      expect(
        terrainSurface.variants.single.frames.last.tilesetId,
        'animated-terrain-atlas',
      );
      expect(pathSurface.hasAnimatedVariants, isTrue);
      expect(pathSurface.framesForVariant(TerrainPathVariant.cross), [
        visualFrame(2, durationMs: 70),
        pathOverrideFrame,
      ]);
      expect(
        pathSurface.framesForVariant(TerrainPathVariant.cross).last,
        same(pathOverrideFrame),
      );
      expect(
        pathSurface.framesForVariant(TerrainPathVariant.cross).last.tilesetId,
        'animated-water-atlas',
      );
    });

    test('terrainSurfaceById returns an existing terrain or null', () {
      // ID lookup is intentionally a convenience over the ordered terrain list.
      // It does not validate the manifest or require globally unique ids.
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(id: 'grass-a', terrainType: TerrainType.grass),
          terrainPreset(id: 'sand-a', terrainType: TerrainType.sand),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(
          catalog.terrainSurfaceById('sand-a')?.terrainType, TerrainType.sand);
      expect(catalog.terrainSurfaceById('missing'), isNull);
    });

    test('pathSurfaceById returns an existing path or null', () {
      // Path lookup mirrors terrain lookup but stays in the path collection.
      // This keeps legacy PathSurfaceKind data separate from TerrainType data.
      final manifest = projectManifest(
        pathPresets: [
          pathPreset(id: 'water-a', surfaceKind: PathSurfaceKind.water),
          pathPreset(id: 'road-a', surfaceKind: PathSurfaceKind.road),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(
          catalog.pathSurfaceById('road-a')?.surfaceKind, PathSurfaceKind.road);
      expect(catalog.pathSurfaceById('missing'), isNull);
    });

    test('duplicate terrain ids are kept and lookup returns the first match',
        () {
      // Legacy data may contain duplicate ids. V0 documents that the catalog
      // does not fix or reject them; it preserves the list and returns the
      // first matching entry for convenience lookups.
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(
            id: 'duplicate',
            name: 'First Terrain',
            terrainType: TerrainType.grass,
          ),
          terrainPreset(
            id: 'duplicate',
            name: 'Second Terrain',
            terrainType: TerrainType.sand,
          ),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(catalog.terrainSurfaces, hasLength(2));
      expect(catalog.terrainSurfaceById('duplicate'),
          same(catalog.terrainSurfaces.first));
      expect(catalog.terrainSurfaceById('duplicate')?.name, 'First Terrain');
    });

    test('duplicate path ids are kept and lookup returns the first match', () {
      // Path duplicates follow the same list-first rule as terrain duplicates.
      // Migration tooling can report duplicates later without this read-only
      // catalog changing or hiding authored legacy data.
      final manifest = projectManifest(
        pathPresets: [
          pathPreset(
            id: 'duplicate',
            name: 'First Path',
            surfaceKind: PathSurfaceKind.water,
          ),
          pathPreset(
            id: 'duplicate',
            name: 'Second Path',
            surfaceKind: PathSurfaceKind.tallGrass,
          ),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(catalog.pathSurfaces, hasLength(2));
      expect(catalog.pathSurfaceById('duplicate'),
          same(catalog.pathSurfaces.first));
      expect(catalog.pathSurfaceById('duplicate')?.name, 'First Path');
    });

    test('terrainSurfacesByType filters terrain surfaces in manifest order',
        () {
      // Filters are read-only projections over the catalog. They preserve the
      // manifest order so migration previews can stay aligned with authoring UI
      // order instead of using a hidden sort.
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(id: 'grass-a', terrainType: TerrainType.grass),
          terrainPreset(id: 'sand-a', terrainType: TerrainType.sand),
          terrainPreset(id: 'grass-b', terrainType: TerrainType.grass),
          terrainPreset(id: 'rock-a', terrainType: TerrainType.rock),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(
        catalog.terrainSurfacesByType(TerrainType.grass).map((s) => s.id),
        ['grass-a', 'grass-b'],
      );
      expect(
        catalog.terrainSurfacesByType(TerrainType.sand).map((s) => s.id),
        ['sand-a'],
      );
      expect(catalog.terrainSurfacesByType(TerrainType.indoor), isEmpty);
    });

    test('pathSurfacesByKind filters path surfaces in manifest order', () {
      // Path kind filters stay separate from terrain type filters. A future
      // unified Surface model may add cross-kind queries, but this compatibility
      // catalog deliberately avoids that step.
      final manifest = projectManifest(
        pathPresets: [
          pathPreset(id: 'water-a', surfaceKind: PathSurfaceKind.water),
          pathPreset(
              id: 'tall-grass-a', surfaceKind: PathSurfaceKind.tallGrass),
          pathPreset(id: 'water-b', surfaceKind: PathSurfaceKind.water),
          pathPreset(id: 'road-a', surfaceKind: PathSurfaceKind.road),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(
        catalog.pathSurfacesByKind(PathSurfaceKind.water).map((s) => s.id),
        ['water-a', 'water-b'],
      );
      expect(
        catalog.pathSurfacesByKind(PathSurfaceKind.tallGrass).map((s) => s.id),
        ['tall-grass-a'],
      );
      expect(catalog.pathSurfacesByKind(PathSurfaceKind.lava), isEmpty);
    });

    test('catalog and filter result lists are unmodifiable', () {
      // The project-level view is read-only just like the individual adapters.
      // Callers can inspect and filter legacy surface candidates, but cannot
      // mutate the catalog as if it were the manifest source of truth.
      final catalog = createLegacyProjectSurfaceCatalogView(
        projectManifest(
          terrainPresets: [
            terrainPreset(id: 'grass-a', terrainType: TerrainType.grass),
          ],
          pathPresets: [
            pathPreset(id: 'water-a', surfaceKind: PathSurfaceKind.water),
          ],
        ),
      );

      expect(
        () => catalog.terrainSurfaces.add(
          createLegacyTerrainSurfaceView(terrainPreset(id: 'new-terrain')),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => catalog.pathSurfaces.add(
          createLegacyPathSurfaceView(pathPreset(id: 'new-path')),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => catalog.terrainSurfacesByType(TerrainType.grass).add(
              createLegacyTerrainSurfaceView(terrainPreset(id: 'new-grass')),
            ),
        throwsUnsupportedError,
      );
      expect(
        () => catalog.pathSurfacesByKind(PathSurfaceKind.water).add(
              createLegacyPathSurfaceView(pathPreset(id: 'new-water')),
            ),
        throwsUnsupportedError,
      );
    });

    test('does not mutate the source ProjectManifest or source presets', () {
      // ProjectManifest remains the source of truth. Creating the catalog must
      // not alter preset lists, variant lists, frame lists, or authored weights.
      final terrainFrames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 120),
      ];
      final pathFrames = [
        visualFrame(2, durationMs: 80),
        visualFrame(3, durationMs: 160),
      ];
      final terrainVariants = [terrainVariant(terrainFrames, weight: 6)];
      final pathVariants = [
        pathMapping(TerrainPathVariant.horizontal, pathFrames),
      ];
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(id: 'terrain-source', variants: terrainVariants),
        ],
        pathPresets: [
          pathPreset(id: 'path-source', variants: pathVariants),
        ],
      );
      final beforeTerrainPresets = List<ProjectTerrainPreset>.from(
        manifest.terrainPresets,
      );
      final beforePathPresets = List<ProjectPathPreset>.from(
        manifest.pathPresets,
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(manifest.terrainPresets, beforeTerrainPresets);
      expect(manifest.pathPresets, beforePathPresets);
      expect(manifest.terrainPresets.single.variants, terrainVariants);
      expect(manifest.pathPresets.single.variants, pathVariants);
      expect(
          manifest.terrainPresets.single.variants.single.frames, terrainFrames);
      expect(manifest.pathPresets.single.variants.single.frames, pathFrames);
      expect(catalog.terrainSurfaces.single.variants.single.weight, 6);
      expect(catalog.pathSurfaces.single.variants.single.frames, pathFrames);
    });

    test('keeps terrain and path surfaces separate even when ids match', () {
      // This is the boundary test for Lot 6: the catalog is not a unified
      // Surface list. A terrain and a path can share an id and still be looked
      // up independently through their own collection.
      final manifest = projectManifest(
        terrainPresets: [
          terrainPreset(
            id: 'shared',
            name: 'Shared Terrain',
            terrainType: TerrainType.grass,
          ),
        ],
        pathPresets: [
          pathPreset(
            id: 'shared',
            name: 'Shared Path',
            surfaceKind: PathSurfaceKind.water,
          ),
        ],
      );

      final catalog = createLegacyProjectSurfaceCatalogView(manifest);

      expect(catalog.terrainSurfaces, hasLength(1));
      expect(catalog.pathSurfaces, hasLength(1));
      expect(catalog.terrainSurfaceById('shared')?.name, 'Shared Terrain');
      expect(catalog.pathSurfaceById('shared')?.name, 'Shared Path');
      expect(catalog.terrainSurfaceById('shared'),
          isNot(same(catalog.pathSurfaceById('shared'))));
    });
  });
}

ProjectManifest projectManifest({
  List<ProjectTerrainPreset> terrainPresets = const [],
  List<ProjectPathPreset> pathPresets = const [],
}) {
  return ProjectManifest(
    name: 'Legacy Surface Catalog',
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
  List<TerrainPresetVariant> variants = const [],
}) {
  return ProjectTerrainPreset(
    id: id,
    name: name,
    terrainType: terrainType,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants,
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
  List<PathPresetVariantMapping> variants = const [],
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants,
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
