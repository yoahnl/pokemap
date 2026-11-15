import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'catalog_map_lifecycle_fixture.dart';

void main() {
  test('a targeted duplicate copies one map without reading the others',
      () async {
    final source = CatalogMapLifecycleFixture.spatialMap('source').copyWith(
      name: 'Source',
      properties: const {'ambiance': 'brume'},
    );
    final f = await CatalogMapLifecycleFixture.open(40, source: source);
    addTearDown(f.close);
    f.reader.paths.clear();
    await f.apply('map.duplicate', {
      'sourceMapId': 'source',
      'targetMapId': 'source-bis',
      'name': 'Source bis',
      'groupId': 'routes',
    });
    expect(
      f.reader.paths.where(
        (path) => path.startsWith('maps/') && path != 'maps/source.json',
      ),
      isEmpty,
    );
    final copy = MapData.fromJson(
      jsonDecode(
              await File('${f.root.path}/maps/source-bis.json').readAsString())
          as Map<String, dynamic>,
    );
    expect(copy.id, 'source-bis');
    expect(copy.name, 'Source bis');
    expect(copy.properties, source.properties);
    expect(copy.spatialScene, isNotNull);
    final metadata = await f.metadata();
    final entry = metadata.maps.singleWhere((map) => map.id == 'source-bis');
    expect(entry.groupId, 'routes');
    expect(entry.relativePath, 'maps/source-bis.json');
    expect(metadata.maps, hasLength(43));
  });

  test('a targeted duplicate needs an explicit free identity', () async {
    final f = await CatalogMapLifecycleFixture.open(2);
    addTearDown(f.close);
    final head = await File('${f.root.path}/catalog/HEAD.json').readAsString();
    await expectLater(
      f.apply('map.duplicate', {'sourceMapId': 'source', 'name': 'Copie'}),
      throwsA(anything),
    );
    await expectLater(
      f.apply('map.duplicate', {
        'sourceMapId': 'source',
        'targetMapId': 'other',
        'name': 'Copie',
      }),
      throwsA(anything),
    );
    expect(
      await File('${f.root.path}/catalog/HEAD.json').readAsString(),
      head,
    );
    expect(File('${f.root.path}/maps/other.json').existsSync(), isTrue);
  });
}
