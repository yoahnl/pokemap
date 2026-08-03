import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_studio_library.dart';

void main() {
  test('lists native v6 records without any legacy project data', () {
    final manifest = ProjectManifest(
      name: 'native library',
      version: ProjectVersion.v6,
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
    expect(items.single.id, 'native-path');
    expect(items.single.usage, SmartTileUsage.path);
    expect(items.single.statusLabel, 'Publié');
  });

  test('an empty v6 catalog exposes no synthetic legacy entries', () {
    const manifest = ProjectManifest(
      name: 'empty library',
      version: ProjectVersion.v6,
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    );

    final items = buildSmartTileStudioLibrary(manifest);

    expect(items, isEmpty);
  });
}
