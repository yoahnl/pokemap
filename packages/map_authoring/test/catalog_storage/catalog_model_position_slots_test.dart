import 'package:map_authoring/src/workspace/catalog/catalog_resource_positions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('model positions support a bounded deletion across slot chunks',
      () async {
    const kind = CatalogDefinitionKind.model3d;
    final models = [
      for (var i = 0; i < 300; i++)
        CatalogDefinitionUnit(
          key: CatalogDefinitionKey(kind, 'model-$i'),
          payload: {
            'position': i,
            'value': {'id': 'model-$i'}
          },
        ),
    ];
    final storage = CatalogStorageBuilder().build([
      ...models,
      ...CatalogResourcePositions.initialize(models),
      ...CatalogResourcePositions.initializeSlots(models, kinds: {kind}),
    ]);
    final objects = {...storage.objects};
    final before = await CatalogSnapshot.open(
        root: storage.root, readObject: (ref) async => objects[ref.sha256]!);

    expect(await CatalogResourcePositions.readSlot(before, kind, 0), 'model-0');
    expect(await CatalogResourcePositions.readSlot(before, kind, 299),
        'model-299');
    final moved = CatalogDefinitionUnit(
        key: models.last.key,
        payload: {...models.last.payload, 'position': 30});
    final indexChanges = await CatalogResourcePositions.maintain(
        lookup: before.lookup, upserts: [moved], removals: [models[30].key]);
    expect(indexChanges.length, 4);
    final patch = await before
        .patch(upserts: [moved, ...indexChanges], removals: [models[30].key]);
    objects.addAll(patch.objects);
    final after = await patch.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!);

    expect(await CatalogResourcePositions.read(after, kind), 299);
    expect(
        await CatalogResourcePositions.readSlot(after, kind, 30), 'model-299');
    expect(
        await CatalogResourcePositions.readSlot(after, kind, 298), 'model-298');
    expect(await after.lookup(models[30].key), isNull);
    expect((await after.lookup(models[100].key))!.payload['position'], 100);

    final restoredIndex = await CatalogResourcePositions.maintain(
        lookup: after.lookup,
        upserts: [models[30], models.last],
        removals: const []);
    final restoredPatch =
        await after.patch(upserts: [models[30], models.last, ...restoredIndex]);
    objects.addAll(restoredPatch.objects);
    final restored = await restoredPatch.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!);
    expect(await CatalogResourcePositions.read(restored, kind), 300);
    expect(await CatalogResourcePositions.readSlot(restored, kind, 30),
        'model-30');
    expect(await CatalogResourcePositions.readSlot(restored, kind, 299),
        'model-299');
  });

  test('legacy model slots require explicit preparation', () async {
    const kind = CatalogDefinitionKind.model3d;
    final models = [
      for (var i = 0; i < 3; i++)
        CatalogDefinitionUnit(
          key: CatalogDefinitionKey(kind, 'model-$i'),
          payload: {
            'position': i,
            'value': {'id': 'model-$i'}
          },
        ),
    ];
    final storage = CatalogStorageBuilder().build([
      ...models,
      ...CatalogResourcePositions.initialize(models),
    ]);
    final objects = {...storage.objects};
    final before = await CatalogSnapshot.open(
        root: storage.root, readObject: (ref) async => objects[ref.sha256]!);

    expect(
        await CatalogResourcePositions.prepare(before, kinds: {kind}), isEmpty);
    await expectLater(
        CatalogResourcePositions.readSlot(before, kind, 0),
        throwsA(isA<FormatException>().having(
            (error) => error.message,
            'message',
            'catalog.resource_positions.slots_preparation_required')));
    final units =
        await CatalogResourcePositions.prepareSlots(before, kinds: {kind});
    final patch = await before.patch(upserts: units);
    objects.addAll(patch.objects);
    final after = await patch.nextSnapshot(
        readObject: (ref) async => objects[ref.sha256]!);
    expect(await CatalogResourcePositions.readSlot(after, kind, 2), 'model-2');
    expect(await CatalogResourcePositions.prepareSlots(after, kinds: {kind}),
        isEmpty);
  });
}
