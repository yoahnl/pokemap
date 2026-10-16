import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';
import 'map_metadata_fixture.dart';

void main() {
  test(
      'bicycle restriction is semantic, discoverable and undoable through API and JSONL',
      () async {
    final f = await MapMetadataFixture.create();
    addTearDown(f.dispose);
    final before = await f.map();
    final result = await f.apply(
        await f.plan(parameters: {'mapId': 'town', 'allowBicycle': false}));
    expect((await f.map()).mapMetadata.allowBicycle, isFalse);
    final actions =
        (await f.wire('describe', {})).data['mutationActions'] as List;
    final descriptor = actions
        .cast<Map>()
        .singleWhere((action) => action['id'] == 'map.update_metadata');
    final schema = ((descriptor['extensions'] as Map)['inputSchema'] as Map);
    expect(schema['properties'] as Map, contains('allowBicycle'));
    await f.api.undo(f.opened.projectHandle,
        entryId: (result['receipt'] as Map)['receiptId'] as String,
        idempotencyKey: 'bicycle-undo');
    expect(await f.map(), before);
    final request =
        await f.request(parameters: {'mapId': 'town', 'allowBicycle': false});
    final plan = await f.wire('plan', {
      'projectHandle': f.opened.projectHandle.value,
      'request': request.toJson()
    });
    expect(plan.status, AuthoringResultStatus.success);
    final applied = await f.wire('apply', {
      'projectHandle': f.opened.projectHandle.value,
      'planId': plan.data['planId'],
      'operationId': 'bicycle-wire'
    });
    expect(applied.status, AuthoringResultStatus.success);
    expect((await f.map()).mapMetadata.allowBicycle, isFalse);
    await expectLater(
        () => f.plan(parameters: {'mapId': 'town', 'allowBicycle': 'yes'}),
        throwsA(isA<Exception>()));
    expect((await f.map()).mapMetadata.allowBicycle, isFalse);
  });
}
