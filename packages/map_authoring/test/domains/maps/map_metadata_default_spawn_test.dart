import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_metadata_fixture.dart';

void main() {
  test('the default start of a map is chosen among its starting points',
      () async {
    final f = await MapMetadataFixture.create(entities: const [
      MapEntity(
        id: 'gate-start',
        name: 'Gate',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 2),
        blocksMovement: false,
        spawn: MapEntitySpawnData(),
      ),
      MapEntity(
        id: 'board',
        name: 'Board',
        kind: MapEntityKind.sign,
        pos: GridPos(x: 3, y: 1),
        sign: MapEntitySignData(title: 'Board'),
      ),
    ]);
    addTearDown(f.dispose);

    final actions =
        (await f.wire('describe', {})).data['mutationActions'] as List;
    final descriptor = actions
        .cast<Map>()
        .singleWhere((action) => action['id'] == 'map.update_metadata');
    final schema = (descriptor['extensions'] as Map)['inputSchema'] as Map;
    expect(schema['properties'] as Map, contains('defaultSpawnId'));

    await f.apply(await f.plan(
        parameters: {'mapId': 'town', 'defaultSpawnId': 'gate-start'}));
    expect((await f.map()).mapMetadata.defaultSpawnId, 'gate-start');

    for (final invalid in ['board', 'ghost', '', ' gate-start']) {
      await expectLater(
          () => f.plan(parameters: {'mapId': 'town', 'defaultSpawnId': invalid}),
          throwsA(isA<Exception>()),
          reason: invalid);
    }
    await expectLater(
        () => f.plan(
            parameters: {'mapId': 'town', 'defaultSpawnId': 'gate-start'}),
        throwsA(isA<Exception>()),
        reason: 'choosing the current default changes nothing');
    expect((await f.map()).mapMetadata.defaultSpawnId, 'gate-start');

    await f.apply(
        await f.plan(parameters: {'mapId': 'town', 'defaultSpawnId': null}));
    expect((await f.map()).mapMetadata.defaultSpawnId, isNull);
  });
}
