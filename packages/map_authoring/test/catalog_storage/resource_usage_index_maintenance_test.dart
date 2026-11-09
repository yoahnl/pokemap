import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_resource_usage_index.dart';
import 'package:map_authoring/src/catalog_storage/catalog_revert_merge.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_resource_positions.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_resource_index_snapshot.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/resource_index_fixture.dart';

void main() {
  test(
      'reserving a grouped map preserves its hierarchy without loading unrelated groups',
      () async {
    final fixture = await _fixture(grouped: true);
    addTearDown(() async {
      await fixture.close();
      await fixture.root.delete(recursive: true);
    });
    await fixture.prepare();
    await fixture.mutate('resource.classify', _reservation('alpha'));
    final reopened = await WorkingProjectCatalog.open(
        store: fixture.store,
        descriptor:
            WorkingProjectCatalogDescriptor.fromJson(fixture.descriptor));
    try {
      final project = await reopened.exportProject();
      expect(project.maps.singleWhere((map) => map.id == 'alpha').groupId,
          'region');
      expect(project.groups.single.id, 'region');
      expect(project.resourceLibraryCatalog.entryFor('tileset', 'sheet')?.mapId,
          'alpha');
    } finally {
      await reopened.close();
    }
  });
  test('preparation refuses a newly added media document before publishing',
      () async {
    final fixture = await _fixture(pokemon: true);
    addTearDown(() async {
      await fixture.close();
      await fixture.root.delete(recursive: true);
    });
    final selected = await CatalogResourceIndexSnapshot.read(
        catalog: await fixture.catalog(),
        store: fixture.store,
        projectHandle: fixture.opened.projectHandle);
    expect(await selected.currentRevision(), selected.snapshot.revision);
    final original =
        await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
    final file = File('${fixture.root.path}/data/pokemon/media/new.json');
    await file.parent.create(recursive: true);
    await file.writeAsString('{}');
    final editing = await CatalogEditingSession.open(
        store: fixture.store,
        projectId: 'resource-index-fixture',
        actorId: 'test-race');
    try {
      await expectLater(
          editing.prepareResourceIndexes(selected.snapshot,
              currentRevision: selected.currentRevision),
          throwsA(isA<CatalogStorageException>().having((error) => error.code,
              'code', 'catalog.project_revision_conflict')));
      expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
          original);
      expect(await file.readAsString(), '{}');
    } finally {
      await editing.close();
    }
  });
  test(
      'historical merges cannot restore preparation sources and safely invalidate legacy external usages',
      () async {
    final fixture = await _fixture();
    addTearDown(() async {
      await fixture.close();
      await fixture.root.delete(recursive: true);
    });
    final beforeLegacy = await fixture.catalog();
    await fixture.mutate('map.save', {'map': _map('alpha', 'other').toJson()});
    final legacyTarget = await fixture.catalog();
    await fixture.mutate('map.save', {'map': _map('alpha', 'sheet').toJson()});
    final beforePreparation = await fixture.catalog();
    await fixture.prepare();
    final prepared = await fixture.catalog();
    await fixture.mutate('map.save', {'map': _map('alpha', 'other').toJson()});
    final indexedTarget = await fixture.catalog();
    final preparationDelta = await CatalogRevertDelta.between(
        before: beforePreparation, after: prepared, current: indexedTarget);
    expect(preparationDelta.upserts, isEmpty);
    expect(preparationDelta.removals, isEmpty);
    await fixture.mutate('map.save', {'map': _map('alpha', 'sheet').toJson()});
    final current = await fixture.catalog();
    final indexed = await CatalogRevertDelta.between(
        before: prepared, after: indexedTarget, current: current);
    final indexedPatch = await current.patch(
        upserts: indexed.upserts, removals: indexed.removals);
    final projected = await indexedPatch.nextSnapshot(
        readObject: (ref) async =>
            indexedPatch.objects[ref.sha256] ??
            await fixture.store.readObject(ref));
    expect(
        await CatalogResourceUsageIndex.mapUsages(
            projected, 'tileset', 'sheet', ['alpha', 'beta']),
        isEmpty);
    final beforeRename = await fixture.catalog();
    await fixture.mutate('map.save', {
      'map': _map('alpha', 'sheet').copyWith(name: 'Historical name').toJson()
    });
    final renamed = await fixture.catalog();
    await fixture.mutate('map.save', {'map': _map('alpha', 'other').toJson()});
    final afterRename = await fixture.catalog();
    final renameDelta = await CatalogRevertDelta.between(
        before: beforeRename, after: renamed, current: afterRename);
    final renamePatch = await afterRename.patch(
        upserts: renameDelta.upserts, removals: renameDelta.removals);
    final restoredRename = await renamePatch.nextSnapshot(
        readObject: (ref) async =>
            renamePatch.objects[ref.sha256] ??
            await fixture.store.readObject(ref));
    expect(
        await CatalogResourceUsageIndex.mapUsages(
            restoredRename, 'tileset', 'sheet', ['alpha', 'beta']),
        {'alpha'});
    final legacy = await CatalogRevertDelta.between(
        before: beforeLegacy, after: legacyTarget, current: current);
    expect(legacy.removals, contains(CatalogResourceUsageIndex.marker));
    final legacyPatch =
        await current.patch(upserts: legacy.upserts, removals: legacy.removals);
    final invalidated = await legacyPatch.nextSnapshot(
        readObject: (ref) async =>
            legacyPatch.objects[ref.sha256] ??
            await fixture.store.readObject(ref));
    await expectLater(
        CatalogResourceUsageIndex.mapUsages(
            invalidated, 'tileset', 'sheet', ['alpha', 'beta']),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.resource_usage.preparation_required')));
  });

  test('restoring family creation maintains the position and slot indexes',
      () async {
    final fixture = await _fixture();
    addTearDown(() async {
      await fixture.close();
      await fixture.root.delete(recursive: true);
    });
    await fixture.prepare();
    final before = await fixture.catalog();
    await fixture.mutate(
        'resource.family.create', {'familyId': 'restored', 'name': 'Restored'});
    final created = await fixture.catalog();
    await fixture.mutate('resource.family.delete', {'familyId': 'restored'});
    final current = await fixture.catalog();
    final delta = await CatalogRevertDelta.between(
        before: before, after: created, current: current);
    final patch =
        await current.patch(upserts: delta.upserts, removals: delta.removals);
    final projected = await patch.nextSnapshot(
        readObject: (ref) async =>
            patch.objects[ref.sha256] ?? await fixture.store.readObject(ref));
    expect(
        await CatalogResourcePositions.read(
            projected, CatalogDefinitionKind.resourceFamily),
        1);
    expect(
        await CatalogResourcePositions.readSlot(
            projected, CatalogDefinitionKind.resourceFamily, 0),
        'restored');
  });

  test(
      'legacy catalogs require explicit preparation and reservation follows map edits undo and redo',
      () async {
    final fixture = await _fixture();
    addTearDown(() async {
      await fixture.close();
      await fixture.root.delete(recursive: true);
    });
    final original =
        await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
    await expectLater(
        fixture.mutate('resource.classify', _reservation('beta')),
        throwsA(isA<CatalogStorageException>().having((error) => error.code,
            'code', 'catalog.resource_usage.preparation_required')));
    expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
        original);
    await fixture.prepare();
    final prepared =
        await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
    await fixture.prepare();
    expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
        prepared);
    await expectLater(
        fixture.mutate('resource.classify', _reservation('beta')),
        throwsA(isA<VisualLibraryException>().having(
            (error) => error.code, 'code', 'resource_library.scope_conflict')));
    final before = _map('alpha', 'sheet');
    final changed = before.copyWith(tilesetId: 'other');
    final mutation =
        await fixture.mutate('map.save', {'map': changed.toJson()});
    Future<Set<String>> uses() async => CatalogResourceUsageIndex.mapUsages(
        await fixture.catalog(), 'tileset', 'sheet', ['alpha', 'beta']);
    expect(await uses(), isEmpty);
    await fixture.api.undo(fixture.opened.projectHandle,
        entryId: mutation.receipt.receiptId, idempotencyKey: 'undo-map');
    expect(await uses(), {'alpha'});
    await fixture.api.redo(fixture.opened.projectHandle,
        entryId: mutation.receipt.receiptId, idempotencyKey: 'redo-map');
    expect(await uses(), isEmpty);
    await fixture.mutate('resource.classify', _reservation('beta'));
    final reopened = await WorkingProjectCatalog.open(
        store: fixture.store,
        descriptor:
            WorkingProjectCatalogDescriptor.fromJson(fixture.descriptor));
    try {
      expect(
          (await reopened.exportProject())
              .resourceLibraryCatalog
              .entryFor('tileset', 'sheet')
              ?.mapId,
          'beta');
    } finally {
      await reopened.close();
    }
  });

  test(
      'family members and subfamilies remain protected after classification and history',
      () async {
    final fixture = await _fixture();
    addTearDown(() async {
      await fixture.close();
      await fixture.root.delete(recursive: true);
    });
    await fixture.prepare();
    await fixture.mutate(
        'resource.family.create', {'familyId': 'parent', 'name': 'Parent'});
    await fixture.mutate('resource.family.create',
        {'familyId': 'child', 'name': 'Child', 'parentId': 'parent'});
    Future<void> refused(String id) async {
      final bytes =
          await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes();
      await expectLater(
          fixture.mutate('resource.family.delete', {'familyId': id}),
          throwsA(isA<VisualLibraryException>().having((error) => error.code,
              'code', 'resource_library.family_not_empty')));
      expect(await File('${fixture.root.path}/catalog/HEAD.json').readAsBytes(),
          bytes);
    }

    await refused('parent');
    final classified = await fixture.mutate('resource.classify', {
      'resourceKind': 'tileset',
      'resourceId': 'sheet',
      'familyId': 'child',
    });
    await refused('child');
    await fixture.api.undo(fixture.opened.projectHandle,
        entryId: classified.receipt.receiptId, idempotencyKey: 'undo-member');
    expect(
        await CatalogResourceUsageIndex.familyHasMembers(
            await fixture.catalog(), 'child'),
        isFalse);
    await fixture.api.redo(fixture.opened.projectHandle,
        entryId: classified.receipt.receiptId, idempotencyKey: 'redo-member');
    await refused('child');
    await fixture.mutate('resource.classify',
        {'resourceKind': 'tileset', 'resourceId': 'sheet', 'familyId': null});
    await fixture.mutate('resource.family.delete', {'familyId': 'child'});
    await fixture.mutate('resource.family.delete', {'familyId': 'parent'});
  });

  test(
      'reservation and family deletion keep identical unit work with unrelated content',
      () async {
    final work = <List<Map<String, int>>>[];
    for (final count in [150, 450]) {
      final fixture = await _fixture(unrelated: count);
      try {
        await fixture.prepare();
        await fixture.mutate(
            'resource.family.create', {'familyId': 'empty', 'name': 'Empty'});
        fixture.reader.forbiddenPaths.addAll([
          for (var i = 0; i < count; i++) 'maps/foreign-$i.json',
        ]);
        final operations = <Map<String, int>>[];
        for (final operation in [
          ('resource.classify', _reservation('alpha')),
          ('resource.family.delete', <String, Object?>{'familyId': 'empty'}),
        ]) {
          fixture.reader.clear();
          await fixture.mutate(operation.$1, operation.$2);
          expect(fixture.reader.paths.where((path) => path.startsWith('maps/')),
              isEmpty);
          expect(
              fixture.reader.decodedUnits.keys
                  .where((key) => key.contains('foreign-')),
              isEmpty);
          operations.add(Map.of(fixture.reader.decodedUnits));
        }
        work.add(operations);
      } finally {
        await fixture.close();
        await fixture.root.delete(recursive: true);
      }
    }
    expect(work[1], work[0]);
  }, timeout: Timeout(Duration(minutes: 3)));
}

Map<String, Object?> _reservation(String id) => {
      'resourceKind': 'tileset',
      'resourceId': 'sheet',
      'mapId': id,
    };

MapData _map(String id, String sheet) => MapData(
    id: id,
    name: id,
    size: const GridSize(width: 4, height: 4),
    tilesetId: sheet);

Future<ResourceIndexFixture> _fixture(
    {int unrelated = 0, bool pokemon = false, bool grouped = false}) async {
  final base = Directory(
      '/Users/karim/Library/Caches/AveluneQA/resource-inverse-index/dart-tests');
  await base.create(recursive: true);
  final root = await base.createTemp('fixture-');
  final maps = [
    _map('alpha', 'sheet'),
    _map('beta', 'other'),
    for (var i = 0; i < unrelated; i++) _map('foreign-$i', 'foreign-$i')
  ];
  final project = ProjectManifest(
      name: 'Resource index',
      version: ProjectVersion.v8,
      pokemon: ProjectPokemonConfig(
          enabled: pokemon, ruleset: PokemonRulesetProfile.standardV1),
      groups: [
        if (grouped)
          const ProjectMapGroup(
              id: 'region', name: 'Region', type: MapGroupType.city)
      ],
      maps: [
        for (final map in maps)
          ProjectMapEntry(
              id: map.id,
              name: map.name,
              relativePath: 'maps/${map.id}.json',
              groupId: grouped ? 'region' : null)
      ],
      tilesets: [
        for (final id in [
          'sheet',
          'other',
          for (var i = 0; i < unrelated; i++) 'foreign-$i'
        ])
          ProjectTilesetEntry(id: id, name: id, relativePath: 'assets/$id.png')
      ]);
  return ResourceIndexFixture.create(root: root, project: project, maps: maps);
}
