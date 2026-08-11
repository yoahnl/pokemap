import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/gameplay/items/item_studio_gateway.dart';

void main() {
  test('editor gateway creates queries simulates and undoes an item', () async {
    final root = await Directory.systemTemp.createTemp(
      'item-editor-transport-',
    );
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
    final gateway = CanonicalItemStudioGateway(
      queries: queries,
      mutations: mutations,
    );

    final initial = await gateway.load(root.path);
    expect(initial.definitions.map((definition) => definition.id), <String>[
      'potion',
    ]);

    final receipt = await gateway.save(
      root.path,
      definition: const ProjectItemDefinition(
        id: 'field-tonic',
        displayName: 'Field Tonic',
        pocketId: 'medicine',
        buyPrice: 300,
      ),
      snapshotRevision: initial.snapshotRevision,
    );
    final created = await gateway.load(root.path);
    final simulation = await gateway.simulate(
      root.path,
      itemId: 'field-tonic',
      context: ProjectItemUseContext.overworld,
    );

    expect(created.definitions.map((definition) => definition.id), <String>[
      'field-tonic',
      'potion',
    ]);
    expect(simulation, containsPair('context', 'overworld'));

    await gateway.undo(root.path, receiptId: receipt.receiptId);
    final undone = await gateway.load(root.path);
    expect(undone.definitions.map((definition) => definition.id), <String>[
      'potion',
    ]);
  });
}

final class _FixedProjectRootLocator implements EditorProjectRootLocator {
  const _FixedProjectRootLocator(this.root);

  final String root;

  @override
  Future<String> locateForResource(String resourcePath) async => root;
}

Future<void> _writeFixture(Directory root) async {
  await File('${root.path}/project.json').writeAsString(
    jsonEncode(
      const ProjectManifest(
        name: 'Item editor transport fixture',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
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
              id: 'potion',
              displayName: 'Potion',
              pocketId: 'medicine',
            ),
          ],
        ),
      ),
    ),
  );
}
