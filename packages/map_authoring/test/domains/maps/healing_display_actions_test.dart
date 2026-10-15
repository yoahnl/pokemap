import 'dart:convert';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'map_catalog_fixture.dart';
import 'healing_display_fixture.dart';

AuthoringMutationDraft _build(MapData map, Map<String, Object?> parameters,
        {ProjectManifest? project,
        String action = 'entity.set_healing_display'}) =>
    const EntityActions().build(catalogContext(
        catalogSnapshot([map], project: project ?? healingProject()),
        action,
        parameters));
Map<String, Object?> _params(Object? value) =>
    {'mapId': 'route', 'entityId': 'balls', 'healingDisplay': value};
MapData _result(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);
Matcher _failure(String code) =>
    throwsA(isA<MapAuthoringException>().having((e) => e.code, 'code', code));
void main() {
  test(
      'typed authoring API preserves native object state and copies variant references',
      () {
    final map = healingMap();
    final ids = [for (var n = 1; n <= 6; n++) 'healing-$n'];
    final payload = MapEntityHealingDisplayData(variantElementIds: ids);
    final result = const EntityActions().setHealingDisplay(map,
        project: healingProject(), entityId: 'balls', healingDisplay: payload);
    ids[0] = 'changed';
    expect(result.entities.single.healingDisplay!.variantElementIds.first,
        'healing-1');
    expect(map.entities.single.healingDisplay, isNull);
    expect(result.entities.single.copyWith(healingDisplay: null),
        map.entities.single);
    expect(
        const EntityActions().setHealingDisplay(result,
            project: healingProject(), entityId: 'balls', healingDisplay: null),
        map);
  });
  test(
      'healing display semantic action is discoverable with six native element references',
      () {
    final descriptor = AuthoringMutationDispatcher.canonical()
        .descriptors
        .singleWhere((a) => a.id == 'entity.set_healing_display');
    expect(descriptor.extensions['healingDisplay'], {
      'variantCount': 6,
      'variantReference': 'projectElement',
      'entityKind': 'custom',
      'blocksMovement': false,
      'footprint': {'width': 1, 'height': 1},
      'mapMode': '2d',
      'clearValue': null,
      'parameters': ['mapId', 'entityId', 'healingDisplay'],
    });
  });
  test(
      'semantic action changes only display payload and generic update preserves it',
      () {
    final map = healingMap();
    final payload = healingPayload();
    final after = _result(_build(map, _params(payload.toJson())));
    expect(
        after,
        map.copyWith(
            entities: [map.entities.single.copyWith(healingDisplay: payload)]));
    final renamed = after.entities.single.copyWith(name: 'Renamed');
    final update = _result(_build(after,
        {'mapId': 'route', 'entityId': 'balls', 'entity': renamed.toJson()},
        action: 'entity.update'));
    expect(update.entities.single, renamed);
    expect(_result(_build(update, _params(null))).entities.single,
        renamed.copyWith(healingDisplay: null));
    expect(
        _result(_build(update, {'mapId': 'route', 'entityId': 'balls'},
                action: 'entity.clear_payload'))
            .entities
            .single
            .healingDisplay,
        isNull);
  });
  for (final value in [
    true,
    [],
    {},
    {
      'variantElementIds': ['one']
    },
    {'variantElementIds': List.filled(6, 'same')},
    {...healingPayload().toJson(), 'variableId': 6}
  ]) {
    test('semantic action refuses malformed display $value', () {
      expect(() => _build(healingMap(), _params(value)),
          _failure('entity.healing_display_invalid'));
    });
  }
  test('clear is explicit and unknown request suffix is refused', () {
    expect(() => _build(healingMap(), {'mapId': 'route', 'entityId': 'balls'}),
        _failure('map.request_invalid'));
    expect(() => _build(healingMap(), {..._params(null), 'unrecognized': true}),
        _failure('map.request_invalid'));
  });
  for (final mode in [
    'npc',
    'wide',
    'blocking',
    'collision',
    'visual',
    'spatial',
    'unknownElement',
    'outOfBoundsFrame'
  ]) {
    test('semantic action refuses unsupported target or asset $mode', () {
      var map = healingMap();
      var e = map.entities.single;
      var project = healingProject();
      if (mode == 'npc') {
        e = e.copyWith(kind: MapEntityKind.npc, npc: const MapEntityNpcData());
      }
      if (mode == 'wide') {
        e = e.copyWith(size: const GridSize(width: 2, height: 1));
      }
      if (mode == 'blocking') {
        e = e.copyWith(blocksMovement: true);
      }
      if (mode == 'collision') {
        e = e.copyWith(properties: {'collision.width': '1'});
      }
      if (mode == 'visual') {
        e = e.copyWith(
            editorVisual: const MapEntityEditorVisual(elementId: 'healing-1'));
      }
      map = map.copyWith(entities: [e]);
      if (mode == 'spatial') {
        map = map.copyWith(
            version: ProjectVersion.v9,
            spatialScene: MapSpatialScene(width: 6, depth: 5));
      }
      if (mode == 'unknownElement') {
        project = project.copyWith(elements: project.elements.sublist(1));
      }
      if (mode == 'outOfBoundsFrame') {
        project = project.copyWith(elements: [
          project.elements.first.copyWith(frames: [
            const TilesetVisualFrame(source: TilesetSourceRect(x: 99, y: 99))
          ]),
          ...project.elements.skip(1)
        ]);
      }
      expect(
          () =>
              _build(map, _params(healingPayload().toJson()), project: project),
          _failure('entity.healing_display_invalid'));
    });
  }
  test(
      'generic edits cannot leave an invalid display or silently add visual or collision',
      () {
    final map =
        _result(_build(healingMap(), _params(healingPayload().toJson())));
    for (final spec in [
      ('entity.set_blocks_movement', {'blocksMovement': true}),
      (
        'entity.set_visual',
        {
          'payload':
              const MapEntityEditorVisual(elementId: 'healing-1').toJson()
        }
      ),
      (
        'entity.patch_properties',
        {
          'patch': {'collision.width': '1'}
        }
      ),
    ]) {
      expect(
          () => _build(map, {'mapId': 'route', 'entityId': 'balls', ...spec.$2},
              action: spec.$1),
          throwsA(isA<MapAuthoringException>()));
    }
  });
}
