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
Matcher _failure(String code) => throwsA(
    isA<MapAuthoringException>().having((error) => error.code, 'code', code));

void main() {
  test(
      'canonical interactive encounter sets, rejects malformed payload and clears only its capability',
      () {
    final payload = MapEntityInteractiveEncounterData(
        trigger: InteractiveEncounterTrigger.headbutt,
        encounterTableId: 'trees',
        reusePolicy: InteractiveEncounterReusePolicy.oncePerMapInstance);
    final project = _project().copyWith(encounterTables: [
      const ProjectEncounterTable(
          id: 'trees',
          name: 'Trees',
          encounterKind: EncounterKind.headbutt,
          entries: [
            ProjectEncounterEntry(
                speciesId: 'test', minLevel: 2, maxLevel: 2, weight: 1)
          ])
    ]);
    final original = _map();
    final after = const EntityActions().setInteractiveEncounter(original,
        project: project, entityId: 'tree', interactiveEncounter: payload);
    expect(after.entities.single.interactiveEncounter, payload);
    expect(after.entities.single.copyWith(interactiveEncounter: null),
        original.entities.single);
    final planned = _result(_build(
        original,
        {
          'mapId': 'route',
          'entityId': 'tree',
          'interactiveEncounter': payload.toJson()
        },
        project: project,
        action: 'entity.set_interactive_encounter'));
    expect(planned, after);
    expect(
        () => _build(
            original,
            {
              'mapId': 'route',
              'entityId': 'tree',
              'interactiveEncounter': {...payload.toJson(), 'unknown': 1}
            },
            project: project,
            action: 'entity.set_interactive_encounter'),
        _failure('entity.interactive_encounter_invalid'));
    expect(
        const EntityActions().setInteractiveEncounter(after,
            project: project, entityId: 'tree', interactiveEncounter: null),
        original);
    expect(
        () => const EntityActions().setInteractiveEncounter(original,
            project: _project(),
            entityId: 'tree',
            interactiveEncounter: payload),
        _failure('entity.interactive_encounter_invalid'));
  });
  test(
      'Smash optional encounter coexists only with its native rock and generic edits retain safety',
      () {
    final project = _project().copyWith(encounterTables: [
      const ProjectEncounterTable(
          id: 'rocks',
          name: 'Rocks',
          encounterKind: EncounterKind.special,
          entries: [
            ProjectEncounterEntry(
                speciesId: 'test', minLevel: 2, maxLevel: 2, weight: 1)
          ])
    ]);
    final rock = _map().copyWith(entities: [
      _map().entities.single.copyWith(
          fieldObstacle: const MapEntityFieldObstacleData(
              kind: FieldObstacleKind.rockSmashRock))
    ]);
    final payload = MapEntityInteractiveEncounterData(
        trigger: InteractiveEncounterTrigger.afterRockSmash,
        encounterTableId: 'rocks');
    final after = const EntityActions().setInteractiveEncounter(rock,
        project: project, entityId: 'tree', interactiveEncounter: payload);
    expect(after.entities.single.fieldObstacle,
        rock.entities.single.fieldObstacle);
    expect(
        () => const EntityActions().setFieldObstacle(after,
            project: project, entityId: 'tree', fieldObstacle: null),
        throwsA(isA<ValidationException>()));
    expect(
        () => updateEntityOnMap(after, entityId: 'tree', blocksMovement: false),
        throwsA(isA<ValidationException>()));
    expect(
        () => const EntityActions().setInteractiveEncounter(_map(),
            project: project, entityId: 'tree', interactiveEncounter: payload),
        throwsA(isA<Object>()));
  });
}
