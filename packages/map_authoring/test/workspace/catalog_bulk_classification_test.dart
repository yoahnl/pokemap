import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/glb_fixture.dart';
import '../support/resource_index_fixture.dart';

void main() {
  test('a thousand classifications persist together without changing unrelated data', () async {
    final parent = Directory('/Users/karim/Library/Caches/AveluneQA/hgss-library-dedup/dart-tests');
    await parent.create(recursive: true);
    final root = await parent.createTemp('bulk-');
    final inspection = const GlbModel3dInspector().inspect(triangleGlb());
    final map = MapData(id: 'field', name: 'Field',
        size: const GridSize(width: 4, height: 4), tilesetId: 'sheet');
    final project = ProjectManifest(
      name: 'Bulk classification',
      version: ProjectVersion.v8,
      pokemon: const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.standardV1),
      maps: const [ProjectMapEntry(id: 'field', name: 'Field', relativePath: 'maps/field.json')],
      tilesets: const [ProjectTilesetEntry(id: 'sheet', name: 'Sheet', relativePath: 'assets/sheet.png')],
      models3d: [
        for (var index = 0; index < 1001; index++)
          ProjectModel3dEntry(id: 'model-$index', name: 'Model $index',
              sourceAssetId: 'asset-$index', relativePath: 'assets/models3d/model-$index.glb',
              inspection: inspection),
      ],
    );
    final fixture = await ResourceIndexFixture.create(root: root, project: project, maps: [map]);
    addTearDown(() async {
      await fixture.close();
      await root.delete(recursive: true);
    });
    final mapBytes = await File('${root.path}/maps/field.json').readAsBytes();
    final descriptorBytes = await File('${root.path}/project.json').readAsBytes();
    final unrelatedKey = CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'model-1000');
    final before = (await (await fixture.catalog()).lookup(unrelatedKey))!.toJson();
    fixture.reader.clear();
    final result = await fixture.mutate('resource.classify_batch', {
      'entries': [
        for (var index = 0; index < 1000; index++)
          {'resourceKind': 'model3d', 'resourceId': 'model-$index', 'familyId': 'relief'},
      ],
    });
    expect(result.receipt.status, AuthoringReceiptStatus.applied);
    expect(fixture.reader.decodedUnits.containsKey('model3d:model-1000'), isFalse);
    final reopened = await ResourceIndexFixture.openExisting(root);
    try {
      final catalog = await reopened.catalog();
      for (final id in ['model-0', 'model-499', 'model-999']) {
        final entry = await catalog.lookup(CatalogDefinitionKey(
            CatalogDefinitionKind.resourceLibraryEntry, 'model3d:$id'));
        expect((entry!.payload['value'] as Map)['familyId'], 'relief');
      }
      expect((await catalog.lookup(unrelatedKey))!.toJson(), before);
      expect(await File('${root.path}/maps/field.json').readAsBytes(), mapBytes);
      expect(await File('${root.path}/project.json').readAsBytes(), descriptorBytes);
    } finally {
      await reopened.close();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
