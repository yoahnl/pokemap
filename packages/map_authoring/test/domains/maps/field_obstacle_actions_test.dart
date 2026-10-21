import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

MapData _map() => catalogMap('route').copyWith(entities: [
      const MapEntity(
          id: 'tree',
          name: 'Tree',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 2, y: 1),
          editorVisual: MapEntityEditorVisual(elementId: 'tree-visual'),
          properties: {'preserved': 'yes'}),
    ]);
ProjectManifest _project() =>
    const ProjectManifest(name: 'Cut authoring', maps: [
      ProjectMapEntry(
          id: 'route', name: 'Route', relativePath: 'maps/route.json')
    ], tilesets: [
      ProjectTilesetEntry(
          id: 'trees', name: 'Trees', relativePath: 'assets/trees.png')
    ], elementCategories: [
      ProjectElementCategory(id: 'props', name: 'Props')
    ], elements: [
      ProjectElementEntry(
          id: 'tree-visual',
          name: 'Tree',
          tilesetId: 'trees',
          categoryId: 'props',
          frames: [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1))
          ])
    ]);
Map<String, Object?> _parameters(Object? value) => {
      'mapId': 'route',
      'entityId': 'tree',
      'fieldObstacle': value,
    };
AuthoringMutationDraft _build(MapData map, Map<String, Object?> parameters,
        {ProjectManifest? project,
        String action = 'entity.set_field_obstacle'}) =>
    const EntityActions().build(catalogContext(
        catalogSnapshot([map], project: project ?? _project()),
        action,
        parameters));
MapData _result(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);
const _cut = {'kind': 'cutTree', 'resetPolicy': 'mapInstance'};
Matcher _failure(String code) => throwsA(
    isA<MapAuthoringException>().having((error) => error.code, 'code', code));

void main() {
  for (final kind in FieldObstacleKind.values) {
    test('semantic field obstacle action supports ${kind.name}', () {
      final after = _result(_build(_map(),
          _parameters({'kind': kind.name, 'resetPolicy': 'mapInstance'})));
      expect(after.entities.single.fieldObstacle,
          MapEntityFieldObstacleData(kind: kind));
    });
  }

  test('Cut action exposes its closed payload and explicit clear contract', () {
    final action = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((action) => action.id == 'entity.set_field_obstacle');
    expect(action.extensions['fieldObstacle'], {
      'kinds': ['cutTree', 'strengthBoulder', 'rockSmashRock', 'iceBlock'],
      'resetPolicies': ['mapInstance'],
      'entityKind': 'custom',
      'blocksMovement': true,
      'footprint': {'width': 1, 'height': 1},
      'mapMode': '2d',
      'visual': 'existingProjectElement',
      'clearValue': null,
      'parameters': ['mapId', 'entityId', 'fieldObstacle'],
      'iceBlock': {
        'trigger': 'movementContact',
        'requiresFieldAbility': false,
        'playerFollows': false,
        'ordinaryPushCells': 1,
        'slideZone': 'movementEffect.slide',
        'slideDirection': 'push',
        'stops': ['obstacle', 'zoneExit'],
        'savedPosition': 'lastCommittedCell',
        'saveDuringTraversal': false,
        'checkpointDuringTraversal': false,
        'reload': 'stationary',
      },
      'strengthBoulder': {
        'ordinaryPushCells': 1,
        'slideZone': 'movementEffect.slide',
        'slideDirection': 'push',
        'stops': ['obstacle', 'zoneExit'],
        'savedPosition': 'lastCommittedCell',
        'saveDuringTraversal': false,
        'checkpointDuringTraversal': false,
        'reload': 'stationary',
      },
    });
  });
  test('Cut action changes only the typed field obstacle payload', () {
    final map = _map();
    final after = _result(_build(map, _parameters(_cut)));
    expect(
        after,
        map.copyWith(entities: [
          map.entities.single
              .copyWith(fieldObstacle: const MapEntityFieldObstacleData())
        ]));
    expect(map.entities.single.fieldObstacle, isNull);
  });
  for (final value in [
    true,
    'cutTree',
    [],
    {},
    {'kind': 'cutTree'},
    {'kind': 'surf', 'resetPolicy': 'mapInstance'},
    {'kind': 'cutTree', 'resetPolicy': 'permanent'},
    {..._cut, 'unknown': true}
  ]) {
    test('Cut action rejects malformed or unrecognized payload $value', () {
      expect(() => _build(_map(), _parameters(value)),
          _failure('entity.field_obstacle_invalid'));
    });
  }
  test(
      'Cut clear requires the explicit nullable field and refuses suffix parameters',
      () {
    expect(() => _build(_map(), {'mapId': 'route', 'entityId': 'tree'}),
        _failure('map.request_invalid'));
    expect(() => _build(_map(), {..._parameters(_cut), 'unrecognized': true}),
        _failure('map.request_invalid'));
  });
  for (final mode in [
    'npc',
    'wide',
    'nonblocking',
    'missingVisual',
    'unknownVisual',
    'spatial'
  ]) {
    test('Cut action refuses an unsupported current entity $mode', () {
      var map = _map();
      var entity = map.entities.single;
      if (mode == 'npc') {
        entity = entity.copyWith(
            kind: MapEntityKind.npc,
            npc: const MapEntityNpcData(displayName: 'Nurse'));
      }
      if (mode == 'wide') {
        entity = entity.copyWith(size: const GridSize(width: 2, height: 1));
      }
      if (mode == 'nonblocking') {
        entity = entity.copyWith(blocksMovement: false);
      }
      if (mode == 'missingVisual') entity = entity.copyWith(editorVisual: null);
      if (mode == 'unknownVisual') {
        entity = entity.copyWith(
            editorVisual: const MapEntityEditorVisual(elementId: 'missing'));
      }
      map = map.copyWith(entities: [entity]);
      if (mode == 'spatial') {
        map = map.copyWith(
            version: ProjectVersion.v9,
            spatialScene:
                MapSpatialScene(width: map.size.width, depth: map.size.height));
      }
      expect(() => _build(map, _parameters(_cut)),
          _failure('entity.field_obstacle_invalid'));
    });
  }
  test(
      'explicit null clears only Cut and generic entity update preserves the typed block',
      () {
    final map = _map();
    final set = _result(_build(map, _parameters(_cut)));
    final replacement = set.entities.single.copyWith(name: 'Renamed');
    final updated = _result(_build(set,
        {'mapId': 'route', 'entityId': 'tree', 'entity': replacement.toJson()},
        action: 'entity.update'));
    expect(updated.entities.single, replacement);
    final cleared = _result(_build(updated, _parameters(null)));
    expect(cleared.entities.single, replacement.copyWith(fieldObstacle: null));
    final clearPayload = _result(_build(
        updated, {'mapId': 'route', 'entityId': 'tree'},
        action: 'entity.clear_payload'));
    expect(clearPayload.entities.single.fieldObstacle, isNull);
  });
  test('generic entity commands cannot leave an invisible Cut obstacle', () {
    final set = _result(_build(_map(), _parameters(_cut)));
    expect(
        () => _build(set, {'mapId': 'route', 'entityId': 'tree'},
            action: 'entity.clear_visual'),
        _failure('entity.field_obstacle_invalid'));
    final invisible = set.entities.single.copyWith(editorVisual: null);
    expect(
        () => _build(
            set,
            {
              'mapId': 'route',
              'entityId': 'tree',
              'entity': invisible.toJson()
            },
            action: 'entity.update'),
        _failure('entity.field_obstacle_invalid'));
    expect(
        () => _build(_map().copyWith(entities: []),
            {'mapId': 'route', 'entity': invisible.toJson()},
            action: 'entity.create'),
        _failure('entity.field_obstacle_invalid'));
  });

  test(
      'Cut authoring preserves clamped metadata while retaining one collision cell',
      () {
    for (final properties in const [
      {'collision.width': '2', 'collision.height': '2'},
      {'collision.offsetX': '1', 'collision.offsetY': '1'},
    ]) {
      final map = _map().copyWith(
          entities: [_map().entities.single.copyWith(properties: properties)]);
      final after = _result(_build(map, _parameters(_cut)));
      expect(after.entities.single.properties, properties);
      expect(resolveEntityCollisionCells(after.entities.single),
          [map.entities.single.pos]);
    }
  });

  test(
      'Cut parity evidence records executed API, JSONL, Studio and MCP transports',
      () {
    final action = AuthoringFullParityCatalog.canonical()
        .mutationActions
        .singleWhere(
            (action) => action.actionId == 'entity.set_field_obstacle');
    expect(action.contractTestPath,
        'test/domains/maps/field_obstacle_actions_test.dart');
    expect(action.endToEndEvidence, {
      AuthoringTransport.directApi:
          'test/domains/maps/slide_zone_transport_test.dart',
      AuthoringTransport.cli:
          'test/domains/maps/slide_zone_transport_test.dart',
      AuthoringTransport.editor:
          '../../apps/avelune_studio/test/map_workspace/slide_zone_editing_test.dart',
      AuthoringTransport.mcp:
          '../../tools/pokemap_mcp/test/sliding_block_stdio.test.ts',
    });
  });
}
