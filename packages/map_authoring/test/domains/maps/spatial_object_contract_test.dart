import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('spatial object contracts', () {
    test('entity payload incompatible with kind is refused', () {
      const entity = MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 0, y: 0),
        sign: MapEntitySignData(plainText: 'wrong payload'),
      );

      expect(
        () => const EntityActions().create(_emptyMap(), entity),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'entity.payload_kind_mismatch',
          ),
        ),
      );
    });

    test('batch move is atomic when one entity would leave map bounds', () {
      final map = _emptyMap().copyWith(
        entities: const [
          MapEntity(
            id: 'first',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 0, y: 0),
          ),
          MapEntity(
            id: 'second',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      );

      expect(
        () => const EntityActions().moveBatch(
          map,
          const {
            'first': GridPos(x: 1, y: 1),
            'second': GridPos(x: 4, y: 4),
          },
        ),
        throwsA(isA<MapAuthoringException>()),
      );
      expect(map.entities[0].pos, const GridPos(x: 0, y: 0));
      expect(map.entities[1].pos, const GridPos(x: 2, y: 2));
    });

    test('typed item payload authors hidden world presentation', () {
      final draft = const EntityActions().build(
        _entityItemPayloadContext(
          const MapEntityItemData(
            gameItemId: 'hidden-tonic',
            quantity: 2,
            visibility: MapEntityItemVisibility.hidden,
          ),
        ),
      );
      final updated = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>,
      );

      expect(
        updated.entities.single.item?.visibility,
        MapEntityItemVisibility.hidden,
      );
    });

    test('dispatcher exposes placed, entity, NPC, trigger and zone actions',
        () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'placed_element.place',
          'placed_element.move',
          'placed_element.delete',
          'entity.create',
          'entity.batch_move',
          'entity.delete',
          'npc.set_dialogue',
          'npc.set_visibility_rule',
          'npc.set_movement_mode',
          'npc.waypoint_add',
          'trigger.create',
          'trigger.delete_apply',
          'gameplay_zone.create',
          'gameplay_zone.smart_tile.sync',
          'gameplay_zone.set_hazard_payload',
          'gameplay_zone.delete',
        }),
      );
    });

    test('Smart Tile gameplay zones synchronize atomically', () {
      const provenance = SmartTileGameplayZoneProvenance(
        smartTileLayerId: 'paths',
        smartTilePresetId: 'tall-grass',
        materialId: 'grass',
        behaviorKey: 'encounter.walk',
      );
      const replacement = MapGameplayZone(
        id: 'grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 2),
        ),
        encounter: EncounterZonePayload(encounterTableId: 'route-grass'),
        smartTileProvenance: provenance,
      );
      final draft = const TriggerZoneActions().build(
        _gameplayZoneSyncContext(replacement),
      );
      final updated = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>,
      );

      expect(updated.gameplayZones, hasLength(2));
      expect(updated.gameplayZones.first, replacement);
      expect(updated.gameplayZones.last.id, 'manual');
    });

    test('places a 128 by 128 building as one logical instance', () {
      final context = _largePlacementContext(
        pos: const GridPos(x: 64, y: 64),
      );

      final draft = const PlacedElementActions().build(context);
      final updated = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>,
      );

      expect(updated.placedElements, hasLength(1));
      expect(updated.placedElements.single.elementId, 'large_building');
      expect(updated.placedElements.single.pos, const GridPos(x: 64, y: 64));
      expect(updated.layers.whereType<TileLayer>().single.palette, isEmpty);
      expect(
        updated.layers.whereType<TileLayer>().single.cells,
        everyElement(0),
      );
    });

    test('rejects a large building footprint outside map bounds', () {
      final context = _largePlacementContext(
        pos: const GridPos(x: 129, y: 0),
      );

      expect(
        () => const PlacedElementActions().build(context),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'placed_element.footprint_out_of_bounds',
          ),
        ),
      );
      expect(context.snapshot.maps.single.placedElements, isEmpty);
    });

    test('authors an animated entrance through the canonical behavior action',
        () {
      final context = _animatedEntranceBehaviorContext();

      final draft = const PlacedElementActions().build(context);
      final updated = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>,
      );
      final behavior = updated.placedElements.single.behaviors.single;

      expect(behavior.trigger, MapPlacedElementTriggerType.onBump);
      expect(behavior.effect.type, MapPlacedElementEffectType.traverseWarp);
      expect(behavior.effect.targetMapId, 'interior');
      expect(behavior.effect.targetPos, const GridPos(x: 2, y: 3));
    });

    test('rejects an animated entrance on a static element', () {
      final context = _animatedEntranceBehaviorContext(animatedElement: false);

      expect(
        () => const PlacedElementActions().build(context),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'placed_element.behavior.traverse_warp_requires_animation',
              )
              .having(
                (error) => error.details['elementId'],
                'elementId',
                'door-element',
              ),
        ),
      );
    });
  });
}

AuthoringPlanningContext _animatedEntranceBehaviorContext({
  bool animatedElement = true,
}) {
  const map = MapData(
    id: 'exterior',
    name: 'Exterior',
    size: GridSize(width: 8, height: 8),
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'objects',
        name: 'Objects',
        cells: <int>[
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
    ],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'door',
        layerId: 'objects',
        elementId: 'door-element',
        pos: GridPos(x: 3, y: 3),
      ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Animated entrance project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'exterior',
        name: 'Exterior',
        relativePath: 'maps/exterior.json',
      ),
      ProjectMapEntry(
        id: 'interior',
        name: 'Interior',
        relativePath: 'maps/interior.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    elementCategories: const <ProjectElementCategory>[
      ProjectElementCategory(id: 'doors', name: 'Doors'),
    ],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'door-element',
        name: 'Door',
        tilesetId: 'doors',
        categoryId: 'doors',
        frames: <TilesetVisualFrame>[
          const TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1),
            durationMs: 100,
          ),
          if (animatedElement)
            const TilesetVisualFrame(
              source: TilesetSourceRect(x: 2, y: 0, width: 2, height: 1),
              durationMs: 100,
            ),
        ],
      ),
    ],
  );
  final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final mapBytes = utf8.encode(jsonEncode(map.toJson()));
  final revision = computeNarrativeProjectFingerprint(
    <NarrativeProjectFingerprintEntry>[
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/exterior.json',
        bytes: mapBytes,
      ),
    ],
  );
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('animated_entrance'),
    revision: revision,
    manifest: manifest,
    maps: const <MapData>[map],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        manifestBytes,
        logicalName: 'project.json',
      ),
      'map:exterior': computeAuthoringBytesFingerprint(
        mapBytes,
        logicalName: 'maps/exterior.json',
      ),
    },
    resourceBytes: <String, List<int>>{
      'project': manifestBytes,
      'map:exterior': mapBytes,
    },
  );
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: AuthoringRequest(
      requestId: 'add-animated-entrance',
      actionId: 'placed_element.behavior_add',
      actionVersion: 1,
      workspaceHandle: 'workspace',
      parameters: <String, Object?>{
        'mapId': 'exterior',
        'instanceId': 'door',
        'behavior': const MapPlacedElementBehavior(
          id: 'enter',
          trigger: MapPlacedElementTriggerType.onBump,
          effect: MapPlacedElementEffect(
            type: MapPlacedElementEffectType.traverseWarp,
            targetMapId: 'interior',
            targetPos: GridPos(x: 2, y: 3),
          ),
        ).toJson(),
      },
      expectedRevision: revision,
      idempotencyKey: 'add-animated-entrance',
      dryRun: false,
    ),
    planId: 'plan-animated-entrance',
    seed: 42,
  );
}

AuthoringPlanningContext _largePlacementContext({required GridPos pos}) {
  final map = MapData(
    id: 'large_map',
    name: 'Large map',
    size: const GridSize(width: 256, height: 256),
    version: ProjectVersion.v6,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'objects',
        name: 'Objects',
        cells: List<int>.filled(256 * 256, 0),
      ),
    ],
  );
  const manifest = ProjectManifest(
    name: 'Large placement project',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'large_map',
        name: 'Large map',
        relativePath: 'maps/large_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    elements: <ProjectElementEntry>[
      ProjectElementEntry(
        id: 'large_building',
        name: 'Large building',
        tilesetId: 'buildings',
        categoryId: 'building',
        frames: <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 128, height: 128),
          ),
        ],
      ),
    ],
  );
  final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final mapBytes = utf8.encode(jsonEncode(map.toJson()));
  final projectRevision = computeAuthoringBytesFingerprint(
    manifestBytes,
    logicalName: 'project.json',
  );
  final mapRevision = computeAuthoringBytesFingerprint(
    mapBytes,
    logicalName: 'maps/large_map.json',
  );
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_large_placement'),
    revision:
        computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/large_map.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: manifest,
    maps: <MapData>[map],
    resourceFingerprints: <String, String>{
      'project': projectRevision,
      'map:large_map': mapRevision,
    },
    resourceBytes: <String, List<int>>{
      'project': manifestBytes,
      'map:large_map': mapBytes,
    },
  );
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: AuthoringRequest(
      requestId: 'request_large_placement',
      actionId: 'placed_element.place',
      actionVersion: 1,
      workspaceHandle: 'workspace_large_placement',
      parameters: <String, Object?>{
        'mapId': 'large_map',
        'instance': MapPlacedElement(
          id: 'objects::${pos.x}::${pos.y}',
          layerId: 'objects',
          elementId: 'large_building',
          pos: pos,
          properties: const <String, String>{
            'pokemapPlacementOrigin': 'authored',
          },
        ).toJson(),
      },
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_large_placement_${pos.x}_${pos.y}',
      dryRun: false,
    ),
    planId: 'plan_large_placement',
    seed: 128,
  );
}

MapData _emptyMap() => const MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 4, height: 4),
    );

AuthoringPlanningContext _entityItemPayloadContext(MapEntityItemData item) {
  const map = MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 4, height: 4),
    entities: <MapEntity>[
      MapEntity(
        id: 'item',
        kind: MapEntityKind.item,
        pos: GridPos(x: 1, y: 1),
        item: MapEntityItemData(gameItemId: 'potion'),
      ),
    ],
  );
  const manifest = ProjectManifest(
    name: 'Project',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
  );
  final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final mapBytes = utf8.encode(jsonEncode(map.toJson()));
  final revision = computeNarrativeProjectFingerprint(
    <NarrativeProjectFingerprintEntry>[
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/map.json',
        bytes: mapBytes,
      ),
    ],
  );
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('project'),
    revision: revision,
    manifest: manifest,
    maps: const <MapData>[map],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        manifestBytes,
        logicalName: 'project.json',
      ),
      'map:map': computeAuthoringBytesFingerprint(
        mapBytes,
        logicalName: 'maps/map.json',
      ),
    },
    resourceBytes: <String, List<int>>{
      'project': manifestBytes,
      'map:map': mapBytes,
    },
  );
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: AuthoringRequest(
      requestId: 'set-hidden-item',
      actionId: 'entity.set_item_payload',
      actionVersion: 1,
      workspaceHandle: 'workspace',
      parameters: <String, Object?>{
        'mapId': 'map',
        'entityId': 'item',
        'payload': item.toJson(),
      },
      expectedRevision: revision,
      idempotencyKey: 'set-hidden-item',
      dryRun: false,
    ),
    planId: 'set-hidden-item-plan',
    seed: 1,
  );
}

AuthoringPlanningContext _gameplayZoneSyncContext(
  MapGameplayZone replacement,
) {
  const provenance = SmartTileGameplayZoneProvenance(
    smartTileLayerId: 'paths',
    smartTilePresetId: 'tall-grass',
    materialId: 'grass',
    behaviorKey: 'encounter.walk',
  );
  const map = MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 4, height: 4),
    gameplayZones: <MapGameplayZone>[
      MapGameplayZone(
        id: 'grass-old',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        smartTileProvenance: provenance,
      ),
      MapGameplayZone(
        id: 'manual',
        kind: GameplayZoneKind.custom,
        area: MapRect(
          pos: GridPos(x: 3, y: 3),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
  );
  const manifest = ProjectManifest(
    name: 'Project',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'route-grass',
        name: 'Route grass',
        encounterKind: EncounterKind.walk,
        chancePerStep: 0.1,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'fixture-species',
            minLevel: 3,
            maxLevel: 5,
            weight: 1,
          ),
        ],
      ),
    ],
  );
  final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final mapBytes = utf8.encode(jsonEncode(map.toJson()));
  final revision = computeNarrativeProjectFingerprint(
    <NarrativeProjectFingerprintEntry>[
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/map.json',
        bytes: mapBytes,
      ),
    ],
  );
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('project'),
    revision: revision,
    manifest: manifest,
    maps: const <MapData>[map],
    resourceFingerprints: <String, String>{
      'project': computeAuthoringBytesFingerprint(
        manifestBytes,
        logicalName: 'project.json',
      ),
      'map:map': computeAuthoringBytesFingerprint(
        mapBytes,
        logicalName: 'maps/map.json',
      ),
    },
    resourceBytes: <String, List<int>>{
      'project': manifestBytes,
      'map:map': mapBytes,
    },
  );
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: AuthoringRequest(
      requestId: 'sync',
      actionId: 'gameplay_zone.smart_tile.sync',
      actionVersion: 1,
      workspaceHandle: 'workspace',
      parameters: <String, Object?>{
        'mapId': 'map',
        'zones': <Object?>[
          jsonDecode(jsonEncode(replacement.toJson())),
        ],
      },
      expectedRevision: snapshot.revision,
      idempotencyKey: 'sync-idempotency',
      dryRun: false,
    ),
    planId: 'sync-plan',
    seed: 1,
  );
}
