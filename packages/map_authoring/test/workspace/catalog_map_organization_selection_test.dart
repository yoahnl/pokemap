import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'catalog_map_lifecycle_fixture.dart';

void main() {
  test('moving maps and renaming folders reads no other map', () async {
    final f = await CatalogMapLifecycleFixture.open(40);
    addTearDown(f.close);
    f.reader.paths.clear();
    final groups = await f.groups();
    await f.apply('map.library.reorganize', {
      'groups': [
        for (final group in groups)
          (group.id == 'routes' ? group.copyWith(name: 'Chemins') : group)
              .toJson(),
        const ProjectMapGroup(
          id: 'caves',
          name: 'Grottes',
          type: MapGroupType.cave,
          parentGroupId: 'johto',
          sortOrder: 9,
        ).toJson(),
      ],
      'assignments': [
        {'mapId': 'source', 'groupId': 'routes'},
        {'mapId': 'other', 'groupId': 'caves'},
      ],
    });
    expect(
      f.reader.paths.where(
        (path) => path.startsWith('maps/') && !path.endsWith('source.json'),
      ),
      isEmpty,
    );
    final metadata = await f.metadata();
    final maps = {for (final map in metadata.maps) map.id: map};
    expect(maps['source']!.groupId, 'routes');
    expect(maps['other']!.groupId, 'caves');
    expect(maps['foreign-3']!.groupId, isNull);
    expect(maps.length, 42);
    final saved = {for (final group in metadata.groups) group.id: group};
    expect(saved['routes']!.name, 'Chemins');
    expect(saved['caves']!.parentGroupId, 'johto');
    expect(saved['johto']!.name, 'Johto');

    await f.apply('map.library.reorganize', {
      'assignments': [
        {'mapId': 'source', 'groupId': null},
      ],
    });
    expect(
      (await f.metadata()).maps.singleWhere((m) => m.id == 'source').groupId,
      isNull,
    );
  });

  test('the targeted organization refuses removals and name clashes', () async {
    final f = await CatalogMapLifecycleFixture.open(2);
    addTearDown(f.close);
    final groups = await f.groups();
    final head = await File('${f.root.path}/catalog/HEAD.json').readAsString();
    await expectLater(
      f.apply('map.library.reorganize', {
        'groups': [
          for (final group in groups)
            if (group.id != 'routes') group.toJson(),
        ],
        'assignments': const [],
      }),
      throwsA(anything),
    );
    await expectLater(
      f.apply('map.library.reorganize', {
        'groups': [
          for (final group in groups)
            (group.id == 'routes' ? group.copyWith(name: 'villes') : group)
                .toJson(),
        ],
        'assignments': const [],
      }),
      throwsA(anything),
    );
    await expectLater(
      f.apply('map.library.reorganize', {
        'assignments': [
          {'mapId': 'source', 'groupId': 'missing'},
        ],
      }),
      throwsA(anything),
    );
    expect(
      await File('${f.root.path}/catalog/HEAD.json').readAsString(),
      head,
    );
  });
}
