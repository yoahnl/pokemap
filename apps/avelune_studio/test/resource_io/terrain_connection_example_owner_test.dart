import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_example.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const _source = ProjectTilesetEntry(
  id: 'terrain',
  name: 'Chemin',
  relativePath: 'terrain.png',
  source: ProjectTilesetSource.regularAtlas(
    assetId: 'terrain',
    pixelWidth: 128,
    pixelHeight: 128,
    tileWidth: 32,
    tileHeight: 32,
  ),
);

ProjectManifest _terrainProject({
  SmartTileFrameRef Function(int mask)? frame,
  ProjectTilesetEntry source = _source,
}) {
  final preset = ProjectSmartTilePreset(
    id: 'path',
    name: 'Chemin',
    categoryId: 'nature',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.cardinal4,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'path',
    allowedMaterialIds: ['path'],
    rules: [
      for (var mask = 0; mask < 16; mask++)
        terrainConnectionRule(
          mask,
          frame?.call(mask) ??
              SmartTileFrameRef(atlasId: 'atlas', column: mask % 4, row: mask ~/ 4),
          'path',
        ),
    ],
  );
  return workspaceProject.copyWith(
    tilesets: [source],
    smartTileCatalog: ProjectSmartTileCatalog(
      categories: [
        const ProjectSmartTileCategory(id: 'nature', name: 'Nature'),
      ],
      atlases: [terrainAtlas(source, 'atlas')],
      materials: [
        const ProjectSmartTileMaterial(
          id: 'path',
          name: 'Chemin',
          connectionGroupId: 'path',
        ),
      ],
      presets: [preset],
    ),
  );
}

void main() {
  test('terrain example resolves distinct edges using real tile IDs', () {
    final project = _terrainProject();
    final preset = resourceCatalog(
      project,
    ).firstWhere((item) => item.terrain != null).terrain!;
    final tiles = terrainConnectionExample(project, preset)!;
    expect(tiles.map((tile) => tile.localTileId), [
      6,
      14,
      12,
      7,
      15,
      13,
      3,
      11,
      9,
    ]);
    expect(tiles.every((tile) => tile.tilesetId == 'terrain'), isTrue);
    expect(tiles.length, 9);
  });

  test('the tile id of a frame is its row times the source columns plus its column', () {
    final source = _source.source as ProjectRegularAtlasTilesetSource;
    expect(source.columns, 4);
    expect(
      regularAtlasLocalTileId(row: 0, column: 0, source: source),
      0,
    );
    expect(regularAtlasLocalTileId(row: 2, column: 3, source: source), 11);
    expect(regularAtlasLocalTileId(row: 3, column: 1, source: source), 13);
  });

  test('a connection example is not prepared when a part leaves its plain full frame', () {
    final project = _terrainProject(
      frame: (mask) => SmartTileFrameRef(
        atlasId: 'atlas',
        column: mask % 4,
        row: mask ~/ 4,
        columnSpan: 2,
      ),
    );
    final preset = project.smartTileCatalog.presets.single;
    expect(terrainConnectionExample(project, preset), isNull);
  });
}
