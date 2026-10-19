import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/security/resource_pack_bulk_capability.dart';
import 'package:test/test.dart';

void main() {
  ResourcePackBulkInventoryEntry entry(String path,
          {String kind = 'catalogHead',
          String id = 'catalog',
          String role = 'metadata'}) =>
      ResourcePackBulkInventoryEntry(
        resource: AuthoringResourceRef(kind: kind, id: id),
        storageKey: path,
        beforeRevision: 'sha256:${'a' * 64}',
        afterRevision: 'sha256:${'b' * 64}',
        role: role,
      );

  test('only the canonical catalog head may occupy a bulk metadata slot', () {
    expect(entry('catalog/HEAD.json').role, 'metadata');
    for (final path in [
      'catalog/head.json',
      'Catalog/HEAD.json',
      'catalog/IDENTITY.json',
      'catalog/objects/a.json',
      'catalog/leases/one.json'
    ]) {
      for (final role in ['logical', 'blob', 'metadata']) {
        expect(() => entry(path, role: role), throwsArgumentError,
            reason: '$path $role');
      }
    }
    for (final role in ['logical', 'blob']) {
      expect(() => entry('catalog/HEAD.json', role: role), throwsArgumentError);
    }
    expect(
        () => entry('catalog/HEAD.json', kind: 'asset'), throwsArgumentError);
    expect(() => entry('catalog/HEAD.json', id: 'other'), throwsArgumentError);
    expect(() => entry('assets/ordinary.png', role: 'logical'),
        throwsArgumentError);
  });

  test('bulk publication cannot mix a manifest with a mutable catalog head',
      () {
    final now = DateTime.utc(2026, 10, 18);
    final changes = [
      for (final path in ['project.json', 'catalog/HEAD.json'])
        AuthoringResourceChange(
            resource: AuthoringResourceRef(
                kind: path == 'project.json' ? 'project' : 'catalogHead',
                id: path == 'project.json' ? 'project' : 'catalog'),
            storageKey: path,
            beforeBytes: [1],
            afterBytes: [2]),
    ];
    final plan = AuthoringPlan(
        planId: 'plan_catalog',
        receiptId: 'receipt_catalog',
        request: AuthoringRequest(
            requestId: 'request_catalog',
            actionId: 'resource_pack.import',
            actionVersion: 1,
            workspaceHandle: 'workspace_catalog',
            expectedRevision: 'sha256:${'a' * 64}',
            idempotencyKey: 'key_catalog'),
        baseRevision: 'sha256:${'a' * 64}',
        seed: 1,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 1)),
        changeSet: AuthoringChangeSet(
            changes: changes,
            diff: AuthoringDiff([
              for (final change in changes)
                AuthoringDiffEntry(
                    operation: AuthoringDiffOperation.replace,
                    resource: change.resource,
                    path: r'$',
                    before: change.beforeRevision,
                    after: change.afterRevision)
            ])));
    expect(
        () => ResourcePackBulkAuthority.certifyImport(
            plan: plan,
            actorId: 'actor_catalog',
            projectId: 'project_catalog',
            operationId: 'operation_catalog',
            logicalStorageKeys: const [],
            contentBlobStorageKeys: const []),
        throwsArgumentError);
  });
}
