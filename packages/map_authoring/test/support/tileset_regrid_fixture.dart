import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<void> main(List<String> args) async {
  await writeTilesetRegridFixture(Directory(args.single));
}

Future<Set<String>> writeTilesetRegridFixture(Directory root) async {
  ProjectTilesetEntry atlas(String id,
          {List<VisualTileProperty> properties = const []}) =>
      ProjectTilesetEntry(
          id: id,
          name: id,
          relativePath: 'assets/$id.png',
          source: ProjectTilesetSource.regularAtlas(
              assetId: 'asset-$id',
              pixelWidth: 64,
              pixelHeight: 64,
              tileWidth: 32,
              tileHeight: 32,
              tileProperties: properties));
  final foreign = [for (var index = 0; index < 40; index++) 'foreign-$index'];
  final manifest = ProjectManifest(
    name: 'Regrid fixture',
    version: ProjectVersion.v8,
    maps: const [
      ProjectMapEntry(
          id: 'garden', name: 'Jardin', relativePath: 'maps/garden.json')
    ],
    tilesets: [
      atlas('sheet'),
      atlas('used'),
      atlas('linked'),
      atlas('tagged', properties: const [VisualTileProperty(tileId: 0)]),
      const ProjectTilesetEntry(
          id: 'legacy', name: 'Historique', relativePath: 'legacy.png'),
      ...foreign.map(atlas),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: const [
        ProjectSmartTileAtlas(
          id: 'dallage',
          name: 'dallage',
          tilesetId: 'linked',
          columns: 2,
          rows: 2,
        ),
        ProjectSmartTileAtlas(
          id: 'garden-atlas',
          name: 'Dallage du jardin',
          tilesetId: 'linked',
          columns: 2,
          rows: 2,
        ),
      ],
    ),
  );
  final map = MapData(
    id: 'garden',
    name: 'Jardin',
    tilesetId: 'used',
    size: const GridSize(width: 8, height: 8),
    layers: const [],
  );
  await Directory('${root.path}/maps').create();
  await File('${root.path}/maps/garden.json')
      .writeAsString(jsonEncode(map.toJson()));
  await Directory('${root.path}/assets').create();
  final atlasBytes = encodePng(Image(width: 64, height: 64));
  await File('${root.path}/assets/sheet.png').writeAsBytes(atlasBytes);
  await File('${root.path}/assets/used.png').writeAsBytes(atlasBytes);
  await File('${root.path}/assets/linked.png').writeAsBytes(atlasBytes);
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  final working = await WorkingProjectCatalog.create(
      store: store, projectId: 'regrid-fixture', project: manifest);
  final paths = <String>{};
  for (final id in foreign) {
    final key = CatalogDefinitionKey(CatalogDefinitionKind.tileset, id);
    final index = (await working.catalog.snapshot.indexEntry(key))!;
    paths.add('catalog/objects/${index.reference.sha256}.json');
  }
  return paths;
}
