import 'dart:convert';
import 'dart:collection';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/spatial_map_actions.dart';
import 'package:map_authoring/src/domains/maps/entity_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';
import 'environment_spatial_actions_test.dart'
    show spatialEnvironmentFixture, generate, apply;
import 'package:map_authoring/map_authoring_editing.dart'
    show EnvironmentEditing;

void main() {
  for (final side in [4, 32]) {
    for (final unrelatedInstances in [0, 256]) {
      for (final entity in [false, true]) {
        test(
            'presentation diff excludes unchanged geometry side=$side instances=$unrelatedInstances entity=$entity',
            () {
          final map = MapData(
              id: 'map',
              name: 'Map',
              version: ProjectVersion.v9,
              size: GridSize(width: side, height: side),
              entities: [
                MapEntity(
                    id: 'anchor',
                    name: 'Anchor',
                    kind: MapEntityKind.custom,
                    pos: const GridPos(x: 0, y: 0))
              ],
              spatialScene: MapSpatialScene(
                  width: side,
                  depth: side,
                  heightLevels: List.filled(side * side, 0),
                  instances: [
                    SpatialModelInstance(
                        id: 'tree',
                        modelId: 'tree',
                        position: Model3dVector3.zero),
                    for (var i = 0; i < unrelatedInstances; i++)
                      SpatialModelInstance(
                          id: 'untouched-$i',
                          modelId: 'tree',
                          position: Model3dVector3.zero),
                  ]));
          final project = ProjectManifest(
              name: 'Test',
              maps: const [
                ProjectMapEntry(
                    id: 'map', name: 'Map', relativePath: 'maps/map.json')
              ],
              tilesets: const [],
              settings:
                  const ProjectSettings(dimension: ProjectDimension.threeD));
          final snapshot = catalogSnapshot([map], project: project);
          final condition = NarrativeEventConditionExpression.all(const []);
          final presentation = MapEntityPresentation(variants: [
            MapEntityPresentationVariant(
                id: 'gate', condition: condition, blocksMovement: false)
          ]);
          final context = catalogContext(
              snapshot,
              entity
                  ? 'entity.set_presentation'
                  : 'map3d.instance.visibility.set',
              {
                'mapId': 'map',
                if (entity) ...{
                  'entityId': 'anchor',
                  'presentation': presentation.toJson()
                } else ...{
                  'instanceId': 'tree',
                  'visibilityCondition': condition.toJson()
                },
              });
          final draft = entity
              ? const EntityActions().build(context)
              : const SpatialMapActions().build(context);
          final diff = jsonEncode(draft.changeSet.diff.toJson());
          expect(utf8.encode(diff).length, lessThan(1024));
          expect(diff, isNot(contains('heightLevels')));
          expect(diff, isNot(contains('untouched-')));
          final entry = draft.changeSet.diff.entries.single;
          expect(
              entry.path,
              endsWith(entity
                  ? '/entities/anchor/presentation'
                  : '/spatialScene/instances/tree/visibilityCondition'));
          expect(entry.before, isNull);
          expect(
              entry.after, entity ? presentation.toJson() : condition.toJson());
          expect(draft.changeSet.changes.single.beforeBytes,
              snapshot.resourceBytes('map:map'));
          final persisted = MapData.fromJson(jsonDecode(
                  utf8.decode(draft.changeSet.changes.single.afterBytes!))
              as Map<String, dynamic>);
          expect(
              persisted.spatialScene!.instances.length, unrelatedInstances + 1);
          if (entity)
            expect(persisted.entities.single.presentation, presentation);
          else
            expect(persisted.spatialScene!.instances.first.visibilityCondition,
                condition);
        });
      }
    }
  }
  for (final side in [4, 32]) {
    for (final foreign in [0, 80]) {
      for (final entity in [false, true]) {
        test(
            'condition finalization only encodes unchanged ground side=$side foreign=$foreign entity=$entity',
            () {
          final cells = _CountedGround(side * side);
          final map = MapData(
              id: 'map',
              name: 'Map',
              version: ProjectVersion.v9,
              size: GridSize(width: side, height: side),
              layers: [
                MapLayer.smartTile(
                    id: 'ground',
                    name: 'Ground',
                    presetId: 'ground',
                    usage: SmartTileUsage.terrain,
                    field: SmartTileField.cell(semanticCells: cells))
              ],
              entities: [
                MapEntity(
                    id: 'anchor',
                    name: 'Anchor',
                    kind: MapEntityKind.custom,
                    pos: const GridPos(x: 0, y: 0))
              ],
              spatialScene:
                  MapSpatialScene(width: side, depth: side, instances: [
                SpatialModelInstance(
                    id: 'tree', modelId: 'tree', position: Model3dVector3.zero),
              ]));
          final maps = [
            map,
            for (var i = 0; i < foreign; i++) catalogMap('foreign-$i')
          ];
          final project = ProjectManifest(
              name: 'Test',
              maps: [
                for (final item in maps)
                  ProjectMapEntry(
                      id: item.id,
                      name: item.name,
                      relativePath: 'maps/${item.id}.json')
              ],
              tilesets: const [],
              settings:
                  const ProjectSettings(dimension: ProjectDimension.threeD));
          final snapshot = catalogSnapshot(maps, project: project);
          final condition = NarrativeEventConditionExpression.all(const []);
          final action = entity
              ? 'entity.set_presentation'
              : 'map3d.instance.visibility.set';
          final context = catalogContext(snapshot, action, {
            'mapId': 'map',
            if (entity) ...{
              'entityId': 'anchor',
              'presentation': MapEntityPresentation(variants: [
                MapEntityPresentationVariant(
                    id: 'gate', condition: condition, blocksMovement: false)
              ]).toJson(),
            } else ...{
              'instanceId': 'tree',
              'visibilityCondition': condition.toJson(),
            },
          });
          cells.reads = 0;
          final draft = entity
              ? const EntityActions().build(context)
              : const SpatialMapActions().build(context);
          expect(cells.reads, side * side,
              reason:
                  'Only owning-document serialization may inspect unchanged ground.');
          expect(draft.preview['canPublish'], isNull);
          expect(draft.preview['inspectionScope'],
              {'projectWide': false, 'spatialGeometry': 'unchanged'});
        });
      }
    }
  }
  for (final batch in [false, true]) {
    test('upsert descriptor admits visibility roundtrips batch=$batch', () {
      final action = SpatialMapActions.descriptors.singleWhere((value) =>
          value.id ==
          (batch ? 'map3d.instance.upsert_batch' : 'map3d.instance.upsert'));
      final properties =
          (action.extensions['inputSchema'] as Map)['properties'] as Map;
      final instance = batch
          ? (properties['instances'] as Map)['items'] as Map
          : properties['instance'] as Map;
      final visibility = (instance['properties'] as Map)['visibilityCondition'];
      expect(visibility, isA<Map>());
      expect((visibility as Map)['type'], ['object', 'null']);
      expect(
          visibility['description'], contains('map3d.instance.visibility.set'));
      expect(visibility['description'], contains('omission preserves'));
    });
  }
  for (final batch in [false, true]) {
    for (final full in [false, true]) {
      test('instance upsert preserves visibility batch=$batch full=$full', () {
        final fixture = spatialEnvironmentFixture();
        final condition = NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.fact('gate', true));
        final instance = SpatialModelInstance(
            id: 'prop',
            modelId: 'tree',
            position: Model3dVector3(x: .5, y: 0, z: .5),
            visibilityCondition: condition);
        final map = fixture.map.copyWith(
            spatialScene:
                fixture.map.spatialScene!.copyWith(instances: [instance]));
        final project = fixture.project.copyWith(facts: [
          NarrativeFactDefinition(
              id: 'gate',
              label: 'Gate',
              initialValue: NarrativeValue.boolean(true))
        ]);
        final json = instance.copyWith(rotationDegrees: 23).toJson();
        if (!full) json.remove('visibilityCondition');
        final draft = const SpatialMapActions().build(catalogContext(
            catalogSnapshot([map], project: project),
            batch ? 'map3d.instance.upsert_batch' : 'map3d.instance.upsert', {
          'mapId': map.id,
          if (batch) 'instances': [json] else 'instance': json,
        }));
        final result = MapData.fromJson(
            jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
                as Map<String, dynamic>);
        expect(result.spatialScene!.instances.single.visibilityCondition,
            condition);
        expect(result.spatialScene!.instances.single.rotationDegrees, 23);
      });
    }
    for (final change in ['replace', 'clear', 'create']) {
      test(
          'instance upsert guides visibility change to setter batch=$batch $change',
          () {
        final fixture = spatialEnvironmentFixture();
        final condition = NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.fact('gate', true));
        final instance = SpatialModelInstance(
            id: 'prop',
            modelId: 'tree',
            position: Model3dVector3(x: .5, y: 0, z: .5),
            visibilityCondition: condition);
        final map = fixture.map.copyWith(
            spatialScene: fixture.map.spatialScene!
                .copyWith(instances: [if (change != 'create') instance]));
        final json = instance.toJson();
        json['visibilityCondition'] = change == 'clear'
            ? null
            : NarrativeEventConditionExpression.leaf(
                    NarrativeEventCondition.fact('gate', false))
                .toJson();
        expect(
            () => const SpatialMapActions().build(catalogContext(
                    catalogSnapshot([map], project: fixture.project),
                    batch
                        ? 'map3d.instance.upsert_batch'
                        : 'map3d.instance.upsert',
                    {
                      'mapId': map.id,
                      if (batch) 'instances': [json] else 'instance': json,
                    })),
            throwsA(isA<MapAuthoringException>().having(
                (error) => error.details['actionId'],
                'canonical setter',
                'map3d.instance.visibility.set')));
      });
    }
  }
  for (final manual in [false, true]) {
    test('Environment visibility keeps stable identity and pose manual=$manual',
        () {
      final fixture = spatialEnvironmentFixture();
      final map = manual
          ? const EnvironmentEditing().addGeneratedPlacement(
              fixture.project, fixture.map,
              layerId: 'env',
              areaId: 'forest',
              placementId: 'manual',
              modelId: 'tree',
              pos: const GridPos(x: 1, y: 1))
          : apply(fixture.project, fixture.map,
              generate(fixture.project, fixture.map));
      final original = map.spatialScene!.instances.first;
      final selected = original.copyWith(
          rotationDegrees: 23.5,
          position: Model3dVector3(
              x: original.position.x,
              y: original.position.y + .25,
              z: original.position.z));
      final before = map.copyWith(
          spatialScene: map.spatialScene!.copyWith(instances: [
        for (final value in map.spatialScene!.instances)
          if (value.id == selected.id) selected else value
      ]));
      final project = fixture.project.copyWith(facts: [
        NarrativeFactDefinition(
            id: 'gate',
            label: 'Gate',
            initialValue: NarrativeValue.boolean(true))
      ]);
      final condition = NarrativeEventConditionExpression.leaf(
          NarrativeEventCondition.fact('gate', true));
      final result = const SpatialMapActions().setInstanceVisibility(before,
          project: project, instanceId: selected.id, condition: condition);
      final draft = const SpatialMapActions().build(catalogContext(
          catalogSnapshot([before], project: project),
          'map3d.instance.visibility.set', {
        'mapId': before.id,
        'instanceId': selected.id,
        'visibilityCondition': condition.toJson(),
      }));
      expect(
          MapData.fromJson(jsonDecode(
                  utf8.decode(draft.changeSet.changes.single.afterBytes!))
              as Map<String, dynamic>),
          result);
      expect(draft.changeSet.diff.entries, hasLength(manual ? 1 : 2));
      expect(jsonEncode(draft.changeSet.diff.toJson()),
          isNot(contains('heightLevels')));
      if (!manual) {
        final ownership = draft.changeSet.diff.entries
            .singleWhere((entry) => entry.path.endsWith('/ownership'));
        expect(
            ownership.path, endsWith('/placements/${selected.id}/ownership'));
        expect((ownership.before as Map)['manual'], isFalse);
        expect((ownership.after as Map)['manual'], isTrue);
        expect((ownership.after as Map)['generationMaskCells'], hasLength(1));
        expect(
            ((ownership.after as Map)['generationMaskCells'] as List)
                .single['value'],
            isFalse);
      }
      final instance = result.spatialScene!.instances
          .singleWhere((value) => value.id == selected.id);
      expect(instance.copyWith(clearVisibilityCondition: true), selected);
      expect(result.entities, before.entities);
      final owner = result.layers
          .whereType<EnvironmentLayer>()
          .single
          .content
          .areas
          .single;
      expect(owner.manualPlacementIds, contains(selected.id));
      expect(owner.generatedPlacementIds, contains(selected.id));
      expect(
          result.spatialScene!.instances
              .where((value) => value.id != selected.id),
          before.spatialScene!.instances
              .where((value) => value.id != selected.id));
      final repeated = const SpatialMapActions().setInstanceVisibility(result,
          project: project, instanceId: selected.id, condition: null);
      expect(
          repeated.spatialScene!.instances
              .singleWhere((value) => value.id == selected.id),
          selected);
      expect(repeated.layers, result.layers);
    });
  }

  test('dedicated visibility setter preserves geometry, anchors and collision',
      () {
    final map = MapData(
        id: 'route',
        name: 'Route',
        version: ProjectVersion.v9,
        size: const GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(
            width: 8,
            depth: 8,
            heightLevels: List.filled(64, 0),
            instances: [
              SpatialModelInstance(
                  id: 'tree',
                  modelId: 'oak',
                  entityId: 'anchor',
                  blocksMovement: true,
                  position: Model3dVector3(x: 2.5, y: .25, z: 3.5)),
            ]),
        entities: [
          MapEntity(
              id: 'anchor',
              name: 'Anchor',
              kind: MapEntityKind.custom,
              pos: const GridPos(x: 2, y: 3))
        ]);
    final project = ProjectManifest(
        name: 'Test',
        version: ProjectVersion.v9,
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        tilesets: const [],
        maps: const [
          ProjectMapEntry(
              id: 'route', name: 'Route', relativePath: 'maps/route.json')
        ],
        facts: [
          NarrativeFactDefinition(
              id: 'gate',
              label: 'Gate',
              initialValue: NarrativeValue.boolean(true))
        ]);
    final condition = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('gate', true));
    final draft = const SpatialMapActions().build(catalogContext(
        catalogSnapshot([map], project: project),
        'map3d.instance.visibility.set', {
      'mapId': 'route',
      'instanceId': 'tree',
      'visibilityCondition': condition.toJson()
    }));
    final result = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>);
    final instance = result.spatialScene!.instances.single;
    expect(instance.visibilityCondition, condition);
    expect(instance.copyWith(clearVisibilityCondition: true),
        map.spatialScene!.instances.single);
    expect(result.entities, map.entities);
    expect(
        result.spatialScene!.copyWith(instances: map.spatialScene!.instances),
        map.spatialScene);
    expect(draft.preview['operation'], 'map3d.instance.visibility.set');
  });
}

class _CountedGround extends ListBase<int> {
  _CountedGround(int length) : values = List.filled(length, 0);
  final List<int> values;
  int reads = 0;
  @override
  int get length => values.length;
  @override
  set length(int value) => throw StateError('Immutable fixture');
  @override
  int operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, int value) =>
      throw StateError('Immutable fixture');
}
