import 'package:avelune_studio/features/events/application/behaviour/behaviour_triggers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _npc = MapEntity(
  id: 'npc',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 1, y: 1),
  npc: MapEntityNpcData(characterId: 'actor'),
);
const _sign = MapEntity(
  id: 'sign',
  kind: MapEntityKind.sign,
  pos: GridPos(x: 2, y: 2),
);
const _eventZone = MapTrigger(
  id: 'zone',
  name: 'Zone',
  type: TriggerType.event,
  area: MapRect(pos: GridPos(x: 3, y: 3), size: GridSize(width: 1, height: 1)),
);
const _warpZone = MapTrigger(
  id: 'warp',
  name: 'Warp',
  type: TriggerType.warp,
  area: MapRect(pos: GridPos(x: 4, y: 4), size: GridSize(width: 1, height: 1)),
);

MapData _map() => MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 6, height: 6),
  entities: const [_npc, _sign],
  triggers: const [_eventZone, _warpZone],
);

ProjectManifest _project({
  ProjectDimension dimension = ProjectDimension.twoD,
}) => ProjectManifest(
  name: 'Triggers',
  tilesets: const [],
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  characters: const [
    ProjectCharacterEntry(
      id: 'actor',
      name: 'Actor',
      tilesetId: 'qa',
      frameHeight: 1,
    ),
  ],
  settings: ProjectSettings(dimension: dimension),
);

List<NarrativeEventSourceKind> _kinds(
  BehaviourOwner owner,
  String? ownerId, {
  ProjectManifest? project,
  MapData? map,
}) => behaviourTriggerKinds(
  project: project ?? _project(),
  map: map ?? _map(),
  owner: owner,
  ownerId: ownerId,
);

void main() {
  test('a blocking NPC on a 2D map offers talk, contact and autorun', () {
    expect(_kinds(BehaviourOwner.entity, 'npc'), [
      NarrativeEventSourceKind.entityInteract,
      NarrativeEventSourceKind.entityBump,
      NarrativeEventSourceKind.entityAutorun,
    ]);
  });

  test('contact is refused for an entity that cannot be bumped', () {
    expect(_kinds(BehaviourOwner.entity, 'sign'), [
      NarrativeEventSourceKind.entityInteract,
      NarrativeEventSourceKind.entityAutorun,
    ]);
  });

  test('contact and autorun are refused in a 3D project without a scene', () {
    final project = _project(dimension: ProjectDimension.threeD);
    expect(_kinds(BehaviourOwner.entity, 'npc', project: project), [
      NarrativeEventSourceKind.entityInteract,
    ]);
    expect(_kinds(BehaviourOwner.trigger, 'zone', project: project), [
      NarrativeEventSourceKind.triggerEnter,
    ]);
  });

  test('contact and autorun are refused on a spatial or v9 map', () {
    for (final map in [
      _map().copyWith(spatialScene: MapSpatialScene(width: 6, depth: 6)),
      _map().copyWith(version: ProjectVersion.v9),
    ]) {
      expect(_kinds(BehaviourOwner.entity, 'npc', map: map), [
        NarrativeEventSourceKind.entityInteract,
      ]);
    }
  });

  test('zone contact is refused for a non-event zone', () {
    expect(_kinds(BehaviourOwner.trigger, 'zone'), [
      NarrativeEventSourceKind.triggerEnter,
      NarrativeEventSourceKind.triggerBump,
    ]);
    expect(_kinds(BehaviourOwner.trigger, 'warp'), [
      NarrativeEventSourceKind.triggerEnter,
    ]);
  });

  test('a model instance needs to exist in the spatial scene', () {
    final spatial = _map().copyWith(
      spatialScene: MapSpatialScene(
        width: 6,
        depth: 6,
        instances: [
          SpatialModelInstance(
            id: 'statue',
            modelId: 'model',
            position: Model3dVector3.zero,
          ),
        ],
      ),
    );
    expect(_kinds(BehaviourOwner.model, 'statue', map: spatial), [
      NarrativeEventSourceKind.modelInteract,
    ]);
    expect(_kinds(BehaviourOwner.model, 'missing', map: spatial), isEmpty);
    expect(_kinds(BehaviourOwner.model, 'statue'), isEmpty);
  });

  test('missing owners offer nothing and the map always offers entering', () {
    expect(_kinds(BehaviourOwner.entity, 'ghost'), isEmpty);
    expect(_kinds(BehaviourOwner.trigger, 'ghost'), isEmpty);
    expect(_kinds(BehaviourOwner.map, null), [
      NarrativeEventSourceKind.mapEnter,
    ]);
    expect(
      behaviourTriggerSources(
        project: _project(),
        map: _map(),
        owner: BehaviourOwner.entity,
        ownerId: 'npc',
      ).first,
      NarrativeEventSourceRef.entityInteract('map', 'npc'),
    );
  });
}
