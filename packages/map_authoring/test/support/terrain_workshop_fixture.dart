import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> args) async {
  final root = Directory(args.single);
  await root.create();
  await writeTerrainWorkshopFixture(root);
}

const terrainWorkshopMapId = 'garden';
const terrainWorkshopPresetId = 'garden-water';

Future<Set<String>> writeTerrainWorkshopFixture(
  Directory root, {
  int unrelatedRecords = 0,
}) async {
  ProjectTilesetEntry sheet(String id) => ProjectTilesetEntry(
        id: id,
        name: id,
        relativePath: 'assets/$id.png',
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'asset-$id',
          pixelWidth: 128,
          pixelHeight: 128,
          tileWidth: 32,
          tileHeight: 32,
        ),
      );
  ProjectMapEntry entry(String id, String name) => ProjectMapEntry(
        id: id,
        name: name,
        relativePath: 'maps/$id.json',
      );
  final unrelated = [for (var i = 0; i < unrelatedRecords; i++) 'reserve-$i'];
  final map = entry(terrainWorkshopMapId, 'Jardin');
  final project = ProjectManifest(
    name: 'Atelier des terrains',
    maps: [map, for (final id in unrelated) entry(id, 'Réserve $id')],
    tilesets: [sheet('water'), ...unrelated.map(sheet)],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const [
        ProjectSmartTileAtlas(
          id: 'water-atlas',
          name: 'Planche d’eau',
          tilesetId: 'water',
          columns: 4,
          rows: 4,
        ),
      ],
      materials: const [
        ProjectSmartTileMaterial(
          id: 'water',
          name: 'Eau',
          connectionGroupId: 'water',
        ),
      ],
      presets: [
        ProjectSmartTilePreset(
          id: terrainWorkshopPresetId,
          name: 'Eau du jardin',
          usage: SmartTileUsage.path,
          status: SmartTilePresetStatus.published,
          topology: SmartTileTopology.cardinal4,
          templateHint: SmartTileTemplateHint.edge16,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: const SmartTileTransformPolicy(),
          defaultMaterialId: 'water',
          allowedMaterialIds: const ['water'],
          rules: [
            for (var mask = 0; mask < 16; mask++)
              smartTileAuthoringConnectionRule(
                mask,
                SmartTileFrameRef(
                    atlasId: 'water-atlas', column: mask % 4, row: mask ~/ 4),
                'water',
              ),
          ],
        ),
      ],
    ),
  );
  await Directory('${root.path}/maps').create();
  for (final entry in project.maps) {
    final data = MapData(
      id: entry.id,
      name: entry.name,
      size: const GridSize(width: 3, height: 3),
      layers: [
        if (entry.id == map.id)
          const SmartTileLayer(
            id: 'ground-water',
            name: 'Eau',
            presetId: terrainWorkshopPresetId,
            usage: SmartTileUsage.path,
            materialPalette: ['', 'water'],
            field:
                SmartTileField.cell(semanticCells: [1, 1, 1, 1, 1, 1, 1, 1, 1]),
          ),
      ],
    );
    await File('${root.path}/${entry.relativePath}')
        .writeAsString(jsonEncode(data.toJson()));
  }
  await Directory('${root.path}/assets').create();
  final tiles = image.Image(width: 128, height: 128);
  for (var y = 0; y < 128; y++) {
    for (var x = 0; x < 128; x++) {
      tiles.setPixelRgb(x, y, 8 + (x ~/ 32) * 56, 32 + (y ~/ 32) * 56, 189);
    }
  }
  await File('${root.path}/assets/water.png')
      .writeAsBytes(image.encodePng(tiles));
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  final working = await WorkingProjectCatalog.create(
    store: store,
    projectId: 'terrain-workshop-fixture',
    project: project,
  );
  return {
    for (final id in unrelated)
      'catalog/objects/${(await working.catalog.snapshot.indexEntry(CatalogDefinitionKey(CatalogDefinitionKind.tileset, id)))!.reference.sha256}.json',
  };
}
