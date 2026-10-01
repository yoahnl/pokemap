import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  test('duplicate refuses authored fields unsupported by its codec', () {
    final snapshot = catalogSnapshot([
      catalogMap('source')
    ], extraMapFields: {
      'unsupportedFamily': {'important': true}
    });
    final analysis = const MapLifecycleActions().analyze(
        catalogContext(snapshot, 'map.duplicate', {'sourceMapId': 'source'}));
    expect(analysis.errorCode, 'map.duplicate_unsupported_data');
    expect(analysis.details['fields'], contains('/unsupportedFamily'));
  });

  test('duplicate assigns an explicit folder in the same two-file draft', () {
    final source = catalogMap('source');
    final snapshot = catalogSnapshot([source]);
    final project = snapshot.manifest.copyWith(groups: const [
      ProjectMapGroup(id: 'folder', name: 'Folder', type: MapGroupType.city)
    ]);
    final draft = const MapLifecycleActions().build(catalogContext(
        catalogSnapshot([source], project: project),
        'map.duplicate',
        {'sourceMapId': 'source', 'groupId': 'folder'}));
    expect(draft.changeSet.changes, hasLength(2));
    final manifest = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.last.afterBytes!))
            as Map<String, dynamic>);
    expect(manifest.maps.last.groupId, 'folder');
  });

  test('shrinking refuses incoming warp coordinates in a closed owner map', () {
    final target = catalogMap('target');
    final owner = catalogMap('owner').copyWith(warps: const [
      MapWarp(
          id: 'entry',
          pos: GridPos(x: 0, y: 0),
          targetMapId: 'target',
          targetPos: GridPos(x: 5, y: 1))
    ]);
    final context = catalogContext(catalogSnapshot([target, owner]),
        'map.resize_apply', {'mapId': 'target', 'width': 4, 'height': 5});
    expect(
        () => const MapLifecycleActions().build(context),
        throwsA(isA<MapAuthoringException>()
            .having((error) => error.code, 'code', 'map.resize_impacts')
            .having((error) => error.details['impacts'].toString(), 'owner',
                contains('owner'))));
  });

  test('shrinking refuses an incoming connection from a closed map', () {
    final target = catalogMap('target');
    final owner = catalogMap('owner').copyWith(connections: const [
      MapConnection(
          direction: MapConnectionDirection.east, targetMapId: 'target')
    ]);
    final context = catalogContext(catalogSnapshot([target, owner]),
        'map.resize_apply', {'mapId': 'target', 'width': 4, 'height': 5});
    expect(
        () => const MapLifecycleActions().build(context),
        throwsA(isA<MapAuthoringException>()
            .having((error) => error.code, 'code', 'map.resize_impacts')));
  });

  test('delete removes self-warp together with its owning map', () {
    final source = catalogMap('source').copyWith(warps: const [
      MapWarp(
          id: 'loop',
          pos: GridPos(x: 0, y: 0),
          targetMapId: 'source',
          targetPos: GridPos(x: 1, y: 1))
    ]);
    final draft = const MapLifecycleActions().build(catalogContext(
        catalogSnapshot([source]), 'map.delete_apply', {'mapId': 'source'}));
    expect(draft.changeSet.changes.first.afterBytes, isNull);
  });

  test('delete refuses missing maps in the project inventory', () {
    final source = catalogMap('source');
    final snapshot = catalogSnapshot([source]);
    final project = snapshot.manifest.copyWith(maps: [
      ...snapshot.manifest.maps,
      const ProjectMapEntry(
          id: 'missing', name: 'Missing', relativePath: 'maps/missing.json')
    ]);
    final context = catalogContext(catalogSnapshot([source], project: project),
        'map.delete_apply', {'mapId': 'source'});
    expect(
        () => const MapLifecycleActions().build(context),
        throwsA(isA<MapAuthoringException>().having(
            (error) => error.code, 'code', 'map.inventory_incomplete')));
  });
}
