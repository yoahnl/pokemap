import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_resource_positions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/glb_fixture.dart';
import '../support/resource_index_fixture.dart';

void main() {
  test('model import and history preserve positions without prepared slots',
      () async {
    final base =
        Directory('/Users/karim/Library/Caches/AveluneQA/catalog-model-delete');
    await base.create(recursive: true);
    final root = await base.createTemp('import-slots-');
    final bytes = triangleGlb();
    final inspection = const GlbModel3dInspector().inspect(bytes);
    final project = ProjectManifest(
      name: 'Model slots',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()),
      pokemon: const ProjectPokemonConfig(
          enabled: false, ruleset: PokemonRulesetProfile.standardV1),
      maps: const [],
      tilesets: const [],
      models3d: [
        for (var i = 0; i < 80; i++)
          ProjectModel3dEntry(
              id: 'model-$i',
              name: 'Model $i',
              sourceAssetId: 'asset-$i',
              relativePath: 'assets/models3d/model-$i.glb',
              inspection: inspection),
      ],
    );
    final fixture = await ResourceIndexFixture.create(
        root: root, project: project, maps: const []);
    addTearDown(() async {
      await fixture.close();
      await root.delete(recursive: true);
    });
    final artifact = await fixture.api.artifacts
        .put(bytes, declaredMediaType: 'model/gltf-binary');
    fixture.reader.clear();
    final result = await fixture.mutate('model3d.import', {
      'modelId': 'new',
      'name': 'New',
      'artifactHandle': artifact.reference.handle,
    });
    const kind = CatalogDefinitionKind.model3d;
    expect(
        fixture.reader.decodedUnits.keys
            .where((key) => key.startsWith('model3d:model-')),
        isEmpty);
    Future<CatalogSnapshot> reopen() async =>
        (await fixture.store.openRoot((await fixture.store.readHead())!))
            .snapshot;

    expect(await CatalogResourcePositions.read(await reopen(), kind), 81);
    expect(
        (await (await reopen()).lookup(CatalogDefinitionKey(kind, 'new')))!
            .payload['position'],
        80);
    await fixture.api.undoMutation(fixture.opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'undo-model-import');
    expect(await CatalogResourcePositions.read(await reopen(), kind), 80);
    await fixture.api.redoMutation(fixture.opened.projectHandle,
        entryId: result.receipt.receiptId, idempotencyKey: 'redo-model-import');
    expect(await CatalogResourcePositions.read(await reopen(), kind), 81);
    expect(
        (await (await reopen()).lookup(CatalogDefinitionKey(kind, 'new')))!
            .payload['position'],
        80);
  });
}
