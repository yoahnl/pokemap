import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../domains/assets/resource_pack_import_fixture.dart';

void main() {
  test(
      'catalog pack revert validates the complete projected project and preserves an independent map',
      () async {
    final fixture = await NativeResourcePackImportFixture.create();
    try {
      final project =
          (await fixture.loader.load(fixture.opened.projectHandle)).manifest;
      await fixture.close();
      final store =
          await CatalogStorageStore.open(projectRoot: fixture.root.path);
      await WorkingProjectCatalog.create(
          store: store,
          projectId: 'direct-revert',
          project: project,
          expectedProjectRevision:
              await store.gateway.readResourceRevision('project.json'));
      await fixture.open();
      await fixture.stage();
      final import = await fixture.plan(await fixture.prepare());
      final applied = await fixture.apply(import);
      final library = await fixture.readApi.queryProject(
          fixture.opened.projectHandle,
          AuthoringQueryRequest(
              resourceKind: 'element',
              operation: AuthoringQueryOperation.list));
      final element = library.items.first;
      final rename = await fixture.mutations.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
              requestId: 'rename',
              actionId: 'catalog.definition.update',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: library.snapshotRevision,
              idempotencyKey: 'rename',
              parameters: {
                'resourceKind': 'element',
                'id': element['id'],
                'name': 'Changed'
              }));
      await fixture.mutations.applyMutation(fixture.opened.projectHandle,
          planId: rename.planId, operationId: 'rename');
      final beforeCreate =
          await fixture.loader.load(fixture.opened.projectHandle);
      final create = await fixture.mutations.planMutation(
          fixture.opened.projectHandle,
          AuthoringRequest(
              requestId: 'create-map',
              actionId: 'map.create',
              actionVersion: 1,
              workspaceHandle: fixture.opened.workspaceHandle.value,
              expectedRevision: beforeCreate.revision,
              idempotencyKey: 'create-map',
              parameters: const {
                'mapId': 'independent',
                'name': 'Independent',
                'width': 8,
                'height': 6
              }));
      final created = await fixture.mutations.applyMutation(
          fixture.opened.projectHandle,
          planId: create.planId,
          operationId: 'create-map');
      final current = await fixture.loader.load(fixture.opened.projectHandle);
      final reverted = await fixture.mutations.resourcePackHistory(
          fixture.opened.projectHandle,
          operation: 'revert',
          entryId: applied.receipt.receiptId,
          operationId: 'revert-pack',
          expectedRevision: current.revision,
          expectedHeadEntryId: created.receipt.receiptId);
      expect(reverted.receipt.actionId, 'history.revert');
      final after = await fixture.loader.load(fixture.opened.projectHandle);
      expect(after.maps.single.id, 'independent');
      expect(
          after.manifest.elements
              .singleWhere((value) => value.id == element['id'])
              .name,
          element['name']);
    } finally {
      await fixture.dispose();
    }
  });
}
