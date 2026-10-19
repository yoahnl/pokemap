import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/gameplay/items/item_studio_gateway.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test(
    'Editor canonical gateway sets capacity, reloads, clears and undoes',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'editor-bag-capacity-',
      );
      addTearDown(() => root.delete(recursive: true));
      final project = const ProjectManifest(
        name: 'Bag',
        maps: [],
        tilesets: [],
        pokemon: ProjectPokemonConfig(
          ruleset: PokemonRulesetProfile.pokeMapBetaV1,
        ),
      );
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      final itemFile = File('${root.path}/data/pokemon/catalogs/items.json');
      await itemFile.parent.create(recursive: true);
      await itemFile.writeAsString(
        jsonEncode(
          const ProjectItemCatalog(
            schemaVersion: 1,
            entries: [
              ProjectItemDefinition(
                id: 'test_item',
                displayName: 'Test item',
                pocketId: 'medicine',
              ),
            ],
          ).toJson(),
        ),
      );
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      final gateway = CanonicalItemStudioGateway(
        queries: queries,
        mutations: mutations,
      );
      final before = await gateway.load(root.path);
      expect(before.bagCapacity.isUnlimited, true);
      const capacity = ProjectBagCapacity(
        pockets: {
          'medicine': BagPocketCapacity(
            maxDistinctItems: 2,
            maxQuantityPerItem: 99,
          ),
        },
      );
      final receipt = await gateway.saveBagCapacity(
        root.path,
        capacity: capacity,
        snapshotRevision: before.snapshotRevision,
      );
      final loaded = await gateway.load(root.path);
      expect(loaded.bagCapacity, capacity);
      expect(loaded.definitions.single.id, 'test_item');
      await expectLater(
        gateway.saveBagCapacity(
          root.path,
          capacity: const ProjectBagCapacity.unlimited(),
          snapshotRevision: before.snapshotRevision,
        ),
        throwsA(anything),
      );
      await gateway.undo(root.path, receiptId: receipt.receiptId);
      expect((await gateway.load(root.path)).bagCapacity.isUnlimited, true);
      final updated = await gateway.load(root.path);
      await gateway.saveBagCapacity(
        root.path,
        capacity: capacity,
        snapshotRevision: updated.snapshotRevision,
      );
      final next = await gateway.load(root.path);
      await gateway.saveBagCapacity(
        root.path,
        capacity: const ProjectBagCapacity.unlimited(),
        snapshotRevision: next.snapshotRevision,
      );
      expect((await gateway.load(root.path)).bagCapacity.isUnlimited, true);
      final finalJson = jsonDecode(
        await File('${root.path}/project.json').readAsString(),
      ) as Map;
      expect(finalJson.containsKey('bagCapacity'), false);
    },
  );
}
