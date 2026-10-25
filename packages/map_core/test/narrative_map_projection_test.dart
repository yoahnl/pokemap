import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  _additionalProjectionTests();
  test('partial map inventory preserves unavailable sources without blocking local metadata', () {
    final project = _project.copyWith(maps: [
      ..._project.maps,
      const ProjectMapEntry(id: 'unread', name: 'Unread', relativePath: 'maps/unread.json'),
    ]);
    final complete = buildNarrativeEventProjectCatalog(project: project, maps: [_map]);
    final partial = buildNarrativeEventProjectCatalog(
      project: project, maps: [_map], mapInventoryComplete: false,
    );
    expect(complete.diagnostics.singleWhere((value) => value.code == 'spatial.missingMapData').severity,
        NarrativeEventProjectDiagnosticSeverity.error);
    expect(partial.diagnostics.singleWhere((value) => value.code == 'spatial.missingMapData').severity,
        NarrativeEventProjectDiagnosticSeverity.warning);
    expect(partial.resolveSource(NarrativeEventSourceRef.mapEnter('unread')).status,
        NarrativeEventProjectResolutionStatus.unavailable);
    final ambiguous = buildNarrativeEventProjectCatalog(
      project: project, maps: [_map, _map], mapInventoryComplete: false,
    );
    expect(ambiguous.diagnostics.any((value) => value.code == 'spatial.duplicateMapData' &&
        value.severity == NarrativeEventProjectDiagnosticSeverity.error), isTrue);
  });
  test(
    'a full map implements the narrative view without losing its layers',
    () {
      final NarrativeMapView view = _map;
      expect(narrativeMapLayerIds(view), ['terrain', 'blocked']);
      expect(_map.layers, hasLength(2));
      expect((_map.layers.first as TileLayer).cells, hasLength(16));
    },
  );

  test('the projection omits render layers and preserves the source hash', () {
    final projection = NarrativeMapProjection.fromMapData(_map);
    final json = projection.toJson();
    expect(json.containsKey('layers'), isFalse);
    expect(json.containsKey('collisions'), isFalse);
    expect(projection.layerIds, ['terrain', 'blocked']);
    expect(
      projection.sourceMapFingerprint,
      'sha256:${narrativeEventCanonicalSha256(jsonDecode(jsonEncode(_map.toJson())))}',
    );
    expect(projection.entities, _map.entities);
    expect(projection.warps, _map.warps);
    final restored = NarrativeMapProjection.fromJson(json);
    expect(restored.toJson(), json);
    expect(() => restored.entities.clear(), throwsUnsupportedError);
    expect(() => restored.layerIds.clear(), throwsUnsupportedError);
  });

  test('catalog semantics and canonical fingerprints match the full map', () {
    final full = buildNarrativeEventProjectCatalog(
      project: _project,
      maps: [_map],
    );
    final projected = buildNarrativeEventProjectCatalog(
      project: _project,
      maps: [NarrativeMapProjection.fromMapData(_map)],
    );
    expect(projected.toDebugJson(), full.toDebugJson());
    expect(
      projected.resolveMapEventInstanceOwner('map', 'owner').status,
      full.resolveMapEventInstanceOwner('map', 'owner').status,
    );
  });

  test('projection decoding rejects unknown, missing and malformed fields', () {
    final json = NarrativeMapProjection.fromMapData(_map).toJson();
    for (final invalid in [
      {...json, 'formatVersion': 2},
      {...json, 'formatVersion': 1.0},
      {...json, 'sourceMapFingerprint': 'sha256:wrong'},
      {...json, 'layers': []},
      {
        ...json,
        'layerIds': ['terrain', 0],
      },
      {...json}..remove('entities'),
      {
        ...json,
        'entities': [true],
      },
    ]) {
      expect(
        () => NarrativeMapProjection.fromJson(invalid),
        throwsFormatException,
      );
    }
  });

  test(
    'passive placements are excluded without changing narrative options',
    () {
      final map = _map.copyWith(
        placedElements: [
          const MapPlacedElement(
            id: 'passive',
            layerId: 'terrain',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
          MapPlacedElement(
            id: 'active',
            layerId: 'terrain',
            elementId: 'sign',
            pos: const GridPos(x: 1, y: 0),
            behaviors: [
              MapPlacedElementBehavior(
                id: 'message',
                effect: const MapPlacedElementEffect(
                  type: MapPlacedElementEffectType.showMessage,
                  message: 'Hello',
                ),
              ),
            ],
          ),
        ],
      );
      final projection = NarrativeMapProjection.fromMapData(map);
      expect(projection.placedElements.map((value) => value.id), ['active']);
      expect(
        buildNarrativeEventProjectCatalog(
          project: _project,
          maps: [projection],
        ).toDebugJson(),
        buildNarrativeEventProjectCatalog(
          project: _project,
          maps: [map],
        ).toDebugJson(),
      );
    },
  );

  test(
    'legacy evidence preserves layer identities and missing-layer failures',
    () {
      for (final layer in ['terrain', 'missing']) {
        final event = MapEventDefinition(
          id: 'legacy',
          type: MapEventType.actor,
          position: EventPosition(layerId: layer, x: 1, y: 1),
          pages: const [
            MapEventPage(
              pageNumber: 0,
              sceneTarget: MapEventSceneTarget(sceneId: 'scene'),
            ),
          ],
          metadata: const {
            LegacyMapEventCompatibilityMetadataKeys.entityId: 'owner',
          },
        );
        final map = _map.copyWith(events: [event]);
        final claimIndex = buildValidatedLegacyClaimIndex(
          NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.legacyOnly,
            records: const [],
            legacyClaims: const [],
          ),
        );
        final full = projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: map,
          event: event,
          claimIndex: claimIndex,
        );
        final projected = projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: NarrativeMapProjection.fromMapData(map),
          event: event,
          claimIndex: claimIndex,
        );
        expect(projected.toJson(), full.toJson());
      }
    },
  );

  test(
    'global scene references retain cross-map validity and missing targets',
    () {
      final event = MapEventDefinition(
        id: 'remote-event',
        position: const EventPosition(layerId: 'events', x: 1, y: 1),
        pages: const [MapEventPage(pageNumber: 0)],
      );
      final remote = _map.copyWith(id: 'remote', events: [event]);
      final scene = SceneAsset(
        id: 'remote-scene',
        name: 'Remote',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'action',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.markEventConsumed(
                  mapId: 'remote',
                  eventId: 'remote-event',
                ),
              ),
            ),
            SceneNode(
              id: 'end',
              kind: SceneNodeKind.end,
              payload: SceneEndPayload(),
            ),
          ],
          edges: [
            SceneEdge(
              id: 'first',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'action',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'second',
              fromNodeId: 'action',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final project = _project.copyWith(
        maps: [
          ..._project.maps,
          const ProjectMapEntry(
            id: 'remote',
            name: 'Remote',
            relativePath: 'remote.json',
          ),
        ],
        scenes: [scene],
      );
      for (final maps in [
        [_map, remote],
        [_map],
      ]) {
        final full = buildNarrativeEventProjectCatalog(
          project: project,
          maps: maps,
        );
        final projected = buildNarrativeEventProjectCatalog(
          project: project,
          maps: maps.map(NarrativeMapProjection.fromMapData).toList(),
        );
        expect(projected.toDebugJson(), full.toDebugJson());
        expect(projected.hasBlockingDiagnostics, maps.length != 2);
      }
    },
  );
}

void _additionalProjectionTests() {
  test('spatial scene definitions survive projection round trips', () {
    final map = _map.copyWith(
      version: ProjectVersion.v9,
      layers: const [],
      spatialScene: MapSpatialScene(width: 4, depth: 4),
    );
    final captured = NarrativeMapProjection.fromMapData(map);
    final restored = NarrativeMapProjection.fromJson(captured.toJson());
    expect(restored.version, map.version);
    expect(restored.spatialScene!.toJson(), map.spatialScene!.toJson());
    expect(restored.sourceMapFingerprint, captured.sourceMapFingerprint);
  });

  test('projection input is detached from later nested edits', () {
    final properties = <String, String>{'label': 'before'};
    final map = _map.copyWith(
      entities: [_map.entities.single.copyWith(properties: properties)],
    );
    final captured = NarrativeMapProjection.fromMapData(map);
    final json =
        jsonDecode(jsonEncode(captured.toJson())) as Map<String, dynamic>;
    final restored = NarrativeMapProjection.fromJson(json);
    properties['label'] = 'source-edited';
    final entity = (json['entities']! as List).single as Map;
    (entity['properties'] as Map)['label'] = 'json-edited';
    expect(restored.entities.single.properties['label'], 'before');
    expect(captured.entities.single.properties['label'], 'before');
  });
}

final _map = MapData(
  id: 'map',
  name: 'Map',
  size: const GridSize(width: 4, height: 4),
  layers: [
    MapLayer.tile(id: 'terrain', name: 'Terrain', cells: List.filled(16, 0)),
    MapLayer.collision(
      id: 'blocked',
      name: 'Blocked',
      collisions: List.filled(16, false),
    ),
  ],
  entities: const [
    MapEntity(
      id: 'owner',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 1),
    ),
  ],
  warps: [
    MapWarp(
      id: 'arrival',
      pos: const GridPos(x: 2, y: 2),
      targetMapId: 'map',
      targetPos: const GridPos(x: 2, y: 2),
    ),
  ],
);

final _project = ProjectManifest(
  name: 'Narrative projection',
  tilesets: const [],
  maps: const [
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
);
