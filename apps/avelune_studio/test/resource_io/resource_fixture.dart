import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

final class ResourceFixture {
  ResourceFixture(
    this.root,
    this.source,
    this.session,
    this.maps,
    this.resources,
  );

  final Directory root;
  final File source;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final LocalResourceAdapter resources;

  static const entry = ProjectMapEntry(
    id: 'garden',
    name: 'Jardin',
    relativePath: 'garden.json',
  );

  File get manifestFile => File('${root.path}/project.json');
  File get mapFile => File('${root.path}/garden.json');

  static Future<ResourceFixture> create() async {
    final temporary = await Directory.systemTemp.createTemp(
      'studio_resources_',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    final source = File(
      '${root.parent.path}/${root.uri.pathSegments[root.uri.pathSegments.length - 2]}_source.png',
    );
    final pixels = image.Image(width: 64, height: 48);
    image.fill(pixels, color: image.ColorRgb8(80, 150, 200));
    await source.writeAsBytes(image.encodePng(pixels));
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(
        ProjectManifest(
          name: 'Ressources',
          maps: [entry],
          tilesets: [],
        ).toJson(),
      ),
    );
    await File('${root.path}/garden.json').writeAsBytes(
      encodeMapDocumentBytes(
        MapData(
          id: entry.id,
          name: entry.name,
          size: const GridSize(width: 4, height: 4),
          visualStack: MapVisualStackConfig.canonicalV1,
          layers: [
            TileLayer(id: 'ground', name: 'Sol', cells: List.filled(16, 0)),
          ],
        ),
      ),
    );
    final session = ProjectSession(
      sessionId: root.path,
      name: 'Ressources',
      directoryPath: root.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadProject(session);
    return ResourceFixture(
      root,
      source,
      session,
      maps,
      LocalResourceAdapter(session: session, mapAdapter: maps),
    );
  }

  Future<ResourceMutationReceipt> import({int tileWidth = 16}) =>
      resources.importImage(
        ResourceImageImport(
          sourcePath: source.path,
          name: 'Arbres',
          tileWidth: tileWidth,
          tileHeight: 24,
        ),
      );

  Future<MapWorkspaceDocument> loadMap() => maps.loadMap(session, entry);

  ProjectElementEntry element(String tilesetId, {String id = 'tree'}) =>
      ProjectElementEntry(
        id: id,
        name: 'Arbre',
        tilesetId: tilesetId,
        categoryId: '',
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 1, y: 0, width: 2, height: 2),
          ),
        ],
      );

  Future<void> dispose() async {
    await resources.dispose();
    await root.delete(recursive: true);
    await source.delete();
  }
}
