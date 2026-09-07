import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const groups = [
  ProjectMapGroup(id: 'region', name: 'Region', type: MapGroupType.village),
  ProjectMapGroup(
      id: 'inside',
      name: 'Interiors',
      type: MapGroupType.facility,
      parentGroupId: 'region'),
];

ProjectManifest fixture() =>
    ProjectManifest(name: 'Folders', tilesets: const [], maps: const [
      ProjectMapEntry(id: 'town', name: 'Town', relativePath: 'maps/town.json'),
      ProjectMapEntry(
          id: 'house',
          name: 'House',
          relativePath: 'maps/house.json',
          role: MapRole.interior),
    ]);

void main() {
  test('groups nested maps without changing identity, role, path or catalogs',
      () {
    final before = fixture();
    final after = const MapLibraryActions()
        .reorganize(before, groups: groups, assignments: [
      {'mapId': 'town', 'groupId': 'region', 'sortOrder': 1},
      {'mapId': 'house', 'groupId': 'inside', 'sortOrder': 0},
    ]);
    expect(after.groups.last.parentGroupId, 'region');
    expect(after.maps.map((m) => m.groupId), ['region', 'inside']);
    for (var i = 0; i < before.maps.length; i++) {
      expect(
          after.maps[i].copyWith(groupId: null, sortOrder: 0), before.maps[i]);
    }
    expect(after.copyWith(groups: [], maps: before.maps), before);
    expect(before.groups, isEmpty);
    expect(ProjectManifest.fromJson(after.toJson()), after);
  });

  test('partial placements preserve other maps and support moving to root', () {
    final before = fixture().copyWith(groups: groups, maps: [
      fixture().maps.first.copyWith(groupId: 'region', sortOrder: 3),
      fixture().maps.last.copyWith(groupId: 'inside'),
    ]);
    final after = const MapLibraryActions().reorganize(before, assignments: [
      {'mapId': 'town', 'groupId': null},
    ]);
    expect(after.maps.first.groupId, isNull);
    expect(after.maps.first.sortOrder, 3);
    expect(after.maps.last, before.maps.last);
    expect(after.groups, before.groups);
  });

  for (final entry in {
    'unknown map': [
      {'mapId': 'missing', 'groupId': 'region'}
    ],
    'unknown group': [
      {'mapId': 'town', 'groupId': 'missing'}
    ],
    'duplicate placement': [
      {'mapId': 'town', 'groupId': 'region'},
      {'mapId': 'town', 'groupId': null}
    ],
    'missing destination': [
      {'mapId': 'town'}
    ],
    'negative order': [
      {'mapId': 'town', 'groupId': null, 'sortOrder': -1}
    ],
    'content editing': [
      {'mapId': 'town', 'groupId': null, 'role': 'interior'}
    ],
  }.entries) {
    test('rejects ${entry.key}', () {
      expect(
          () => const MapLibraryActions()
              .reorganize(fixture(), groups: groups, assignments: entry.value),
          throwsA(isA<Exception>()));
    });
  }

  test('rejects duplicate, missing parent and cyclic folders', () {
    for (final invalid in [
      [...groups, groups.first],
      [groups.last],
      [groups.first.copyWith(parentGroupId: 'inside'), groups.last],
    ]) {
      expect(
          () => const MapLibraryActions()
              .reorganize(fixture(), groups: invalid, assignments: []),
          throwsA(isA<Exception>()));
    }
  });

  test('rejects removing a folder still used by an unchanged map', () {
    final before = fixture().copyWith(
        groups: groups,
        maps: [fixture().maps.first.copyWith(groupId: 'region')]);
    expect(
        () => const MapLibraryActions()
            .reorganize(before, groups: [], assignments: []),
        throwsA(isA<Exception>()));
  });
}
