import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';

void main() {
  test('editor adapter applies a typed hidden item payload', () async {
    final root = await Directory.systemTemp.createTemp('hidden-item-editor-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    await _writeFixture(root);
    const reader = LocalProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: _FixedProjectRootLocator(root.path),
    );
    addTearDown(mutations.closeAll);
    addTearDown(queries.closeAll);

    final opened = await queries.open(root.path);
    final plan = await mutations.plan(
      root.path,
      actionId: 'entity.set_item_payload',
      parameters: <String, Object?>{
        'mapId': 'lab',
        'entityId': 'secret',
        'payload': const MapEntityItemData(
          gameItemId: 'tonic',
          visibility: MapEntityItemVisibility.hidden,
        ).toJson(),
      },
      idempotencyKey: 'editor-hidden-item',
      requestId: 'editor-hidden-item',
      expectedRevision: opened.snapshotRevision,
    );
    final applied = await mutations.apply(
      plan,
      operationId: 'editor-hidden-item',
    );
    final map = MapData.fromJson(
      jsonDecode(await File('${root.path}/maps/lab.json').readAsString())
          as Map<String, dynamic>,
    );

    expect(applied.receipt.actionId, 'entity.set_item_payload');
    expect(applied.receipt.status, AuthoringReceiptStatus.applied);
    expect(
      map.entities.single.item?.visibility,
      MapEntityItemVisibility.hidden,
    );
  });
}

final class _FixedProjectRootLocator implements EditorProjectRootLocator {
  const _FixedProjectRootLocator(this.root);

  final String root;

  @override
  Future<String> locateForResource(String resourcePath) async => root;
}

Future<void> _writeFixture(Directory root) async {
  await Directory('${root.path}/maps').create(recursive: true);
  await File('${root.path}/project.json').writeAsString(
    jsonEncode(
      const ProjectManifest(
        name: 'Hidden item editor fixture',
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'lab',
            name: 'Lab',
            relativePath: 'maps/lab.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
      ).toJson(),
    ),
  );
  await File('${root.path}/maps/lab.json').writeAsString(
    jsonEncode(
      const MapData(
        id: 'lab',
        name: 'Lab',
        size: GridSize(width: 3, height: 3),
        entities: <MapEntity>[
          MapEntity(
            id: 'secret',
            kind: MapEntityKind.item,
            pos: GridPos(x: 1, y: 1),
            item: MapEntityItemData(gameItemId: 'tonic'),
          ),
        ],
      ).toJson(),
    ),
  );
  final catalogFile = File('${root.path}/data/pokemon/catalogs/items.json');
  await catalogFile.parent.create(recursive: true);
  await catalogFile.writeAsString(
    jsonEncode(
      encodeProjectItemCatalog(
        const ProjectItemCatalog(
          schemaVersion: 1,
          entries: <ProjectItemDefinition>[
            ProjectItemDefinition(
              id: 'tonic',
              displayName: 'Tonic',
              pocketId: 'items',
            ),
          ],
        ),
      ),
    ),
  );
}
