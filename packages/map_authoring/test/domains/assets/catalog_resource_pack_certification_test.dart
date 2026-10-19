import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'resource_pack_import_fixture.dart';

void main() {
  for (final scenario in [
    'valid',
    'wrongGeneration',
    'missingOutput',
    'extraOutput',
    'noncanonicalHead'
  ]) {
    test('catalog import certification $scenario', () async {
      final fixture = await ResourcePackImportFixture.create();
      final plans = AuthoringPlanStore();
      AuthoringPlan? translated;
      try {
        final prepared = await fixture.prepare();
        final original = await AuthoringActionPlanner(store: plans).plan(
            request: fixture.request(prepared.preparedImportHandle!),
            snapshot: fixture.snapshot,
            build: MapMutationDispatcher.canonical(
                    preparedResourcePackImportResolver:
                        fixture.preparer.buildDraft)
                .build);
        final directory =
            await Directory('${fixture.directory.path}/project').create();
        final store =
            await CatalogStorageStore.open(projectRoot: directory.path);
        final before =
            PortableCatalogPublication.encodeProject(fixture.snapshot.manifest);
        await store.publish(before.storage, expectedRootRevision: null);
        final manifestChange = original.changeSet.changes
            .singleWhere((c) => c.storageKey == 'project.json');
        final next = ProjectManifest.fromJson(
            jsonDecode(utf8.decode(manifestChange.afterBytes!))
                as Map<String, dynamic>);
        final after = PortableCatalogPublication.encodeProject(
            scenario == 'wrongGeneration'
                ? next.copyWith(name: 'Untrusted')
                : next);
        await store.gateway.withExclusiveWriteLock(
            () => store.publishObjectsUnderLock(after.storage.objects));
        final headRef =
            AuthoringResourceRef(kind: 'catalogHead', id: 'catalog');
        final head = AuthoringResourceChange(
            resource: headRef,
            storageKey: CatalogStorageStore.headStorageKey,
            beforeBytes: CatalogStorageStore.encodeHead(before.storage.root),
            afterBytes: [
              ...CatalogStorageStore.encodeHead(after.storage.root),
              if (scenario == 'noncanonicalHead') 32,
            ]);
        final outputs = original.changeSet.changes
            .where((c) => c.storageKey != 'project.json')
            .toList();
        final removed =
            scenario == 'missingOutput' ? outputs.removeAt(0) : null;
        final extra = scenario == 'extraOutput'
            ? AuthoringResourceChange(
                resource: AuthoringResourceRef(kind: 'asset', id: 'foreign'),
                storageKey: 'assets/foreign.bin',
                beforeBytes: null,
                afterBytes: [7])
            : null;
        translated = original.reframeChangeSet(
            changeSet: AuthoringChangeSet(
                changes: [head, ...outputs, if (extra != null) extra],
                diff: AuthoringDiff([
                  for (final entry in original.changeSet.diff.entries)
                    if (entry.resource.kind != 'project' &&
                        (removed == null || entry.resource != removed.resource))
                      entry,
                  AuthoringDiffEntry(
                      operation: AuthoringDiffOperation.replace,
                      resource: headRef,
                      path: r'$',
                      before: before.storage.root.toJson(),
                      after: after.storage.root.toJson()),
                  if (extra != null)
                    AuthoringDiffEntry(
                        operation: AuthoringDiffOperation.add,
                        resource: extra.resource,
                        path: r'$',
                        after: true),
                ])));
        Future<void> certify() => fixture.preparer.certifyCatalogPlan(
            plan: translated!,
            actorId: 'actor',
            projectId: 'project',
            operationId: 'operation',
            store: store);
        if (scenario == 'valid') {
          await certify();
          expect(translated.bulkCapability, isNotNull);
          expect(
              translated.bulkCapability!
                  .roleFor(CatalogStorageStore.headStorageKey),
              'metadata');
          await fixture.preparer
              .requireCatalogPlanPreconditions(translated, store: store);
          await certify();
        } else {
          await expectLater(
              certify(),
              throwsA(isA<ResourcePackImportException>().having(
                  (e) => e.code, 'code', 'resource_pack.inventory_changed')));
          expect(translated.bulkCapability, isNull);
        }
        expect(await store.readHead(), before.storage.root);
      } finally {
        await translated?.releasePayloads();
        await plans.dispose();
        await fixture.dispose();
      }
    });
  }
}
