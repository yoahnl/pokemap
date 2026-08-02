import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_studio_library.dart';

void main() {
  test('lists native v5 records without requiring legacy project data', () {
    final manifest = ProjectManifest(
      name: 'native library',
      version: ProjectVersion.v5,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'dirt',
            name: 'Dirt',
            connectionGroupId: 'dirt',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'native-path',
            name: 'Native path',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.blob8,
            coveragePolicy: SmartTileCoveragePolicy.sparse,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.explicit,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'dirt',
            allowedMaterialIds: <String>['dirt'],
            status: SmartTilePresetStatus.published,
          ),
        ],
      ),
    );

    final items = buildSmartTileStudioLibrary(manifest);

    expect(items, hasLength(1));
    expect(items.single.origin, SmartTileLibraryOrigin.native);
    expect(items.single.statusLabel, 'Publié');
  });

  test('lists pre-v5 legacy Terrain, Path, and Surface records separately', () {
    final manifest = ProjectManifest(
      name: 'legacy library',
      version: ProjectVersion.v4,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      terrainPresets: <ProjectTerrainPreset>[
        _terrainPreset(),
      ],
      pathPresets: <ProjectPathPreset>[
        _pathPreset(),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(
        presets: <ProjectSurfacePreset>[
          _surfacePreset(),
        ],
      ),
    );

    final items = buildSmartTileStudioLibrary(manifest);

    expect(items, hasLength(3));
    expect(
      items.map((item) => item.origin),
      containsAll(<SmartTileLibraryOrigin>[
        SmartTileLibraryOrigin.legacyTerrain,
        SmartTileLibraryOrigin.legacyPath,
        SmartTileLibraryOrigin.legacySurface,
      ]),
    );
    expect(
      items
          .singleWhere(
            (item) => item.origin == SmartTileLibraryOrigin.legacySurface,
          )
          .usage,
      isNull,
    );
  });
}

ProjectTerrainPreset _terrainPreset() {
  return const ProjectTerrainPreset(
    id: 'legacy-terrain',
    name: 'Legacy terrain',
    terrainType: TerrainType.grass,
    tilesetId: 'tileset',
  );
}

ProjectPathPreset _pathPreset() {
  return const ProjectPathPreset(
    id: 'legacy-path',
    name: 'Legacy path',
    tilesetId: 'tileset',
  );
}

ProjectSurfacePreset _surfacePreset() {
  return ProjectSurfacePreset(
    id: 'legacy-surface',
    name: 'Legacy surface',
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: <SurfaceVariantAnimationRef>[
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: 'animation',
        ),
      ],
    ),
  );
}
