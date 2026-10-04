import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';
import 'resource_information_fixture.dart';
import 'resource_information_actions_test.dart' show informationFixture;

void main() {
  test(
      'JSONL metadata persists independently with source unknown fields retained',
      () async {
    final fixture =
        await ResourceInformationFixture.create(informationFixture());
    addTearDown(fixture.dispose);
    final path = File('${fixture.root.path}/project.json');
    final raw = jsonDecode(await path.readAsString()) as Map<String, dynamic>;
    (raw['tilesets'] as List).single['extensionData'] = {'author': 'preserve'};
    await path.writeAsString(jsonEncode(raw));
    await fixture.mutate('tileset.metadata.update', {
      'tilesetId': 'sheet',
      'name': 'Planche été',
      'folderId': 'child',
    });
    final reread = await fixture.read();
    expect(reread.tilesets.single.name, 'Planche été');
    expect(reread.tilesets.single.folderId, 'child');
    expect(reread.tilesets.single.source,
        informationFixture().tilesets.single.source);
    final finalRaw = jsonDecode(await path.readAsString()) as Map;
    expect((finalRaw['tilesets'] as List).single['extensionData'],
        {'author': 'preserve'});
    final independent = await ResourceInformationFixture.create(reread);
    addTearDown(independent.dispose);
    expect((await independent.read()).tilesets, reread.tilesets);
  });

  test('canonical stale transaction refuses metadata after external change',
      () async {
    final fixture =
        await ResourceInformationFixture.create(informationFixture());
    addTearDown(fixture.dispose);
    final plan = await fixture.plan('tileset.metadata.update', {
      'tilesetId': 'sheet',
      'name': 'Intention',
      'folderId': null,
    });
    expect(plan.status, AuthoringResultStatus.success);
    final external = informationFixture().copyWith(name: 'Autre auteur');
    final file = File('${fixture.root.path}/project.json');
    await file.writeAsString(jsonEncode(external.toJson()));
    final bytes = await file.readAsBytes();
    final result = await fixture.apply(plan);
    expect(result.status, AuthoringResultStatus.failure);
    expect(await file.readAsBytes(), bytes);
    expect((await fixture.read()).tilesets.single.name, 'Planche');
  });

  test('category taxonomies retain same identities independently', () async {
    final fixture =
        await ResourceInformationFixture.create(smartInformationFixture());
    addTearDown(fixture.dispose);
    await fixture.mutate('smart_tile.category.upsert', {
      'category': {'id': 'shared', 'name': ' Sols été ', 'sortOrder': 9},
    });
    final after = await fixture.read();
    expect(after.smartTileCatalog.categories.single.name, 'Sols été');
    expect(after.tilesetFolders.first.name, 'Images');
    expect(after.elementCategories.first.name, 'Décors');
    expect(after.smartTileCatalog.drafts,
        smartInformationFixture().smartTileCatalog.drafts);
    final blocked = await fixture
        .plan('smart_tile.category.delete', {'categoryId': 'shared'});
    expect(blocked.status, AuthoringResultStatus.failure);
    expect(blocked.error!.details['domainCode'],
        'smart_tile.category.references_blocking');
    await fixture.mutate('smart_tile.category.upsert', {
      'category': {'id': 'empty', 'name': 'Vide'},
    });
    final deletion = await fixture
        .plan('smart_tile.category.delete', {'categoryId': 'empty'});
    final confirmation = await fixture.command('confirm',
        {'projectHandle': fixture.project, 'planId': deletion.data['planId']});
    expect(confirmation.status, AuthoringResultStatus.success);
    final applied = await fixture.command('apply', {
      'projectHandle': fixture.project,
      'planId': deletion.data['planId'],
      'operationId': 'delete-empty',
      'confirmationToken': confirmation.data['confirmationToken']
    });
    expect(applied.status, AuthoringResultStatus.success);
    expect((await fixture.read()).smartTileCatalog.categories.map((e) => e.id),
        ['shared']);
  });

  test('terrain category move preserves published payload and isolated draft',
      () async {
    final original = smartInformationFixture();
    final fixture = await ResourceInformationFixture.create(original);
    addTearDown(fixture.dispose);
    await fixture.mutate('smart_tile.category.upsert', {
      'category': {'id': 'other', 'name': 'Autres'},
    });
    await fixture.mutate('smart_tile.preset.category.assign', {
      'presetId': 'ground',
      'categoryId': 'other',
    });
    final after = await fixture.read();
    expect(after.smartTileCatalog.presets.single,
        original.smartTileCatalog.presets.single.copyWith(categoryId: 'other'));
    expect(after.smartTileCatalog.drafts, original.smartTileCatalog.drafts);
    expect(after.tilesets, original.tilesets);
    expect(after.elements, original.elements);
    await fixture.mutate('smart_tile.preset.category.assign', {
      'presetId': 'ground',
      'categoryId': '',
    });
    expect(
        (await fixture.read()).smartTileCatalog.presets.single.categoryId, '');
  });

  test('pure preview shares dispatcher payload and creates no filesystem state',
      () {
    final snapshot = catalogSnapshot(const [], project: informationFixture());
    final context = catalogContext(snapshot, 'tileset.metadata.update', {
      'tilesetId': 'sheet',
      'name': 'Nouveau',
      'folderId': null,
    });
    final preview = const ResourceManagementActions().analyze(context);
    final direct = const ResourceInformationActions().build(context);
    expect(preview.changeSet.changes.single.afterBytes,
        direct.changeSet.changes.single.afterBytes);
    expect(
        () => const ResourceManagementActions().analyze(
            catalogContext(snapshot, 'asset.delete', {'assetId': 'image'})),
        throwsA(isA<VisualLibraryException>()));
  });
}
