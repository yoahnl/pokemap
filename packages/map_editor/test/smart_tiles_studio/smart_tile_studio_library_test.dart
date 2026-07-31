import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_studio_library.dart';

void main() {
  test('unifies native and legacy Terrain, Path, and Surface records', () {
    final manifest = ProjectManifest(
      name: 'library',
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
      smartTileCatalog: ProjectSmartTileCatalog(
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'native-path',
            name: 'Native path',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.blob8,
            defaultMaterialId: 'dirt',
            allowedMaterialIds: <String>['dirt'],
            status: SmartTilePresetStatus.published,
          ),
        ],
      ),
    );

    final items = buildSmartTileStudioLibrary(manifest);

    expect(items, hasLength(4));
    expect(
      items.map((item) => item.origin),
      containsAll(<SmartTileLibraryOrigin>[
        SmartTileLibraryOrigin.native,
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
    expect(
      items
          .singleWhere((item) => item.origin == SmartTileLibraryOrigin.native)
          .statusLabel,
      'Publié',
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
