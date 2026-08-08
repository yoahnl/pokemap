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
          'gameplay_zone.set_hazard_payload',
          'gameplay_zone.delete',
        }),
      );
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
  });
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
