import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('verified inventory must match both frozen catalog head revisions',
      () async {
    final key = CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'item');
    CatalogDefinitionUnit unit(int value) => CatalogDefinitionUnit(
        key: key, payload: {'name': 'Item', 'value': value});
    final built = CatalogStorageBuilder().build([unit(0)]);
    final objects = {...built.objects};
    final before = await CatalogSnapshot.open(
        root: built.root, readObject: (ref) async => objects[ref.sha256]!);
    await before.validate();
    final patch = await before.patch(upserts: [unit(1)]);
    objects.addAll(patch.objects);
    final after = await patch.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!);
    final otherPatch = await before.patch(upserts: [unit(2)]);
    objects.addAll(otherPatch.objects);
    final other = await otherPatch.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!);
    final valid = await after.deltaFrom(before);
    final wrong = await other.deltaFrom(before);
    final resource = AuthoringResourceRef(kind: 'catalogHead', id: 'catalog');
    final change = AuthoringResourceChange(
        resource: resource,
        storageKey: CatalogStorageStore.headStorageKey,
        beforeBytes: CatalogStorageStore.encodeHead(before.root),
        afterBytes: CatalogStorageStore.encodeHead(after.root));
    final now = DateTime.utc(2026, 10, 26);
    final plan = AuthoringPlan(
        planId: 'plan',
        receiptId: 'receipt',
        request: AuthoringRequest(
            requestId: 'request',
            actionId: 'catalog.units.patch',
            actionVersion: 1,
            workspaceHandle: 'workspace'),
        baseRevision: 'sha256:${before.root.sha256}',
        seed: 0,
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 10)),
        changeSet: AuthoringChangeSet(
            changes: [change],
            diff: AuthoringDiff([
              revisionHistoryDiff(resource,
                  beforeRevision: change.beforeRevision,
                  afterRevision: change.afterRevision)
            ])));
    expect(() => plan.bindCatalogDelta(wrong), throwsStateError);
    expect(plan.catalogDelta, isNull);
    plan.bindCatalogDelta(valid);
    expect(plan.catalogDelta, same(valid));
    plan.requireCatalogDelta();
    expect(() => valid.addedObjects.clear(), throwsUnsupportedError);
    await plan.releaseAppliedPayload();
    expect(plan.catalogDelta, isNull);
  });
}
