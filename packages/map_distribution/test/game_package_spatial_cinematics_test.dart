import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'package:pub_semver/pub_semver.dart';

import 'support/glb_fixture.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test('exports qualified 3D cinematic and model clip commands unchanged', () {
    final files = _payload();
    final built = const GamePackageBuilder().build(
        manifest: spatialManifest(capabilities: [
          'map3d@1',
          'map3d.gameplay@1',
          'map3d.story@1',
          'map3d.animation@1'
        ]),
        payloadFiles: files);
    final inspected = const GamePackageInspector().inspect(built.packageBytes);
    expect(inspected.manifest.compatibility.requiredCapabilities, [
      'catalog.partitioned@2',
      'map3d.animation@1',
      'map3d.gameplay@1',
      'map3d.story@1',
      'map3d@1'
    ]);
    final decoded = _project(files);
    expect(buildSceneRuntimePlan(decoded.scenes.single).canBuild, isTrue);
    expect(decoded.cinematics.single.timeline.steps.map((s) => s.kind), [
      CinematicTimelineStepKind.wait,
      CinematicTimelineStepKind.camera,
      CinematicTimelineStepKind.actorMove,
      CinematicTimelineStepKind.actorFace,
      CinematicTimelineStepKind.marker,
    ]);
    final command =
        (decoded.scenes.single.graph.nodes[2].payload as SceneActionPayload)
            .interactiveCommand as ScenePlayModelAnimationInteractiveCommand;
    expect(command.animationIndex, 0);
    expect(command.speed, 2);
    expect(command.blocksMovementAfter, false);
  });

  test('rejects omitted story and dynamic animation capabilities', () {
    for (final omitted in ['map3d.story@1', 'map3d.animation@1']) {
      final capabilities = [
        'map3d@1',
        'map3d.gameplay@1',
        'map3d.story@1',
        'map3d.animation@1'
      ].where((value) => value != omitted).toList();
      expect(
          () => const GamePackageBuilder().build(
              manifest: spatialManifest(capabilities: capabilities),
              payloadFiles: _payload()),
          throwsA(isA<GamePackageFormatException>()
              .having((e) => e.message, 'message', contains(omitted))));
    }
  });

  test('a previous gameplay host rejects the new story profile', () {
    final host = GamePackageHostCompatibility(
        hubVersion: Version.parse('1.0.0'),
        runtimeApiVersion: Version.parse('1.0.0'),
        capabilities: {'map3d@1', 'map3d.gameplay@1', 'map3d.animation@1'},
        supportedProjectFormats: {'v9'},
        currentProjectFormat: 'v9',
        supportedSaveFormats: {1});
    final compatibility = const GamePackageCompatibilityEvaluator().evaluate(
        spatialManifest(capabilities: [
          'map3d@1',
          'map3d.gameplay@1',
          'map3d.story@1',
          'map3d.animation@1'
        ]),
        host);
    expect(compatibility.decision, GamePackageCompatibilityDecision.reject);
    expect(compatibility.missingCapabilities, ['map3d.story@1']);
  });

  test('exploration alone cannot export cinematic gameplay', () {
    final files = _payload();
    expect(
        () => const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: files),
        throwsA(isA<GamePackageFormatException>()));
  });

  for (final kind in CinematicTimelineStepKind.values.where((kind) =>
      !SpatialGameplayCapabilities.cinematicStepKinds.contains(kind))) {
    test('rejects active unsupported ${kind.name} beat at its step path', () {
      final files = _payload();
      final project = _project(files);
      final asset = project.cinematics.single.copyWith(
          timeline: CinematicTimeline(
              steps: [CinematicTimelineStep(id: 'unsupported', kind: kind)]));
      _write(files, project.copyWith(cinematics: [asset]));
      expect(
          () => _validate(files),
          throwsA(isA<GamePackageFormatException>()
              .having((e) => e.code, 'code', 'runtime3d.cinematic_unsupported')
              .having((e) => e.path, 'path', contains('unsupported'))));
    });
  }

  final invalid = <String, void Function(Map<String, dynamic>)>{
    'foreign map': (j) => j['mapId'] = 'missing',
    'point outside cell bounds': (j) =>
        j['stageContext']['stagePoints'][0]['x'] = 8.0,
    'missing actor entity': (j) =>
        j['stageContext']['actorBindings'][0]['mapEntityId'] = 'missing',
    'missing target entity': (j) => j['stageContext']['movementTargetBindings']
            [0]
        .addAll({'kind': 'mapEntity', 'sourceId': 'missing'}),
    'missing manual path': (j) => j['timeline']['steps'][2]['metadata']
        [cinematicTimelineActorPathModeMetadataKey] = 'manual',
    'missing movement duration': (j) =>
        j['timeline']['steps'][2].remove('durationMs'),
    'missing facing': (j) =>
        j['timeline']['steps'][3]['metadata'] = <String, String>{},
    'missing camera actor': (j) => j['timeline']['steps'][1]['metadata']
        [cinematicTimelineCameraTargetActorIdMetadataKey] = 'missing',
    'unknown movement waypoint': (j) {
      j['timeline']['steps'][2]['metadata']
          [cinematicTimelineActorPathModeMetadataKey] = 'manual';
      j['stageContext']['manualPaths'] = [
        {
          'id': 'route',
          'label': 'Route',
          'ownerActorMoveStepId': 'move',
          'waypointStagePointIds': ['missing']
        }
      ];
    },
  };
  for (final entry in invalid.entries) {
    test('rejects ${entry.key} before runtime playback', () {
      final files = _payload();
      final project = _project(files);
      final json = jsonDecode(jsonEncode(project.cinematics.single.toJson()))
          as Map<String, dynamic>;
      entry.value(json);
      _write(
          files, project.copyWith(cinematics: [CinematicAsset.fromJson(json)]));
      expect(
          () => _validate(files),
          throwsA(isA<GamePackageFormatException>()
              .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
    });
  }

  test('rejects a missing scene cinematic reference precisely', () {
    final files = _payload();
    _write(files, _project(files).copyWith(cinematics: []));
    expect(
        () => _validate(files),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'runtime3d.cinematic_missing')));
  });

  for (final direction in MapConnectionDirection.values) {
    for (final inverse in [false, true]) {
      for (final offset in [-2, 2]) {
        test(
            'exports ${inverse ? 'inverse' : 'direct'} ${direction.name} cinematic neighbor offset $offset',
            () {
          final files = _connectedPayload(direction, offset, inverse: inverse);
          final point = switch (direction) {
            MapConnectionDirection.east => (x: 8.5, y: offset + 2.5),
            MapConnectionDirection.west => (x: -7.5, y: offset + 2.5),
            MapConnectionDirection.north => (x: offset + 2.5, y: -7.5),
            MapConnectionDirection.south => (x: offset + 2.5, y: 8.5),
          };
          _editCinematic(files, (json) {
            json['stageContext']['stagePoints'][0]
                .addAll({'x': point.x, 'y': point.y});
            json['stageContext']['initialPlacements'][0] = {
              'actorId': 'guide',
              'kind': 'stagePoint',
              'stagePointId': 'point',
            };
          });
          final built = const GamePackageBuilder()
              .build(manifest: _storyManifest(connected: true), payloadFiles: files);
          expect(
              const GamePackageInspector()
                  .inspect(built.packageBytes)
                  .payloadPaths,
              contains('project/maps/neighbor.json'));
          expect(
              _project(files)
                  .cinematics
                  .single
                  .stageContext!
                  .stagePoints
                  .single
                  .x,
              point.x);
        });
      }
    }
  }

  for (final point in [(x: 16.0, y: 2.5), (x: 8.5, y: -0.5)]) {
    test('rejects cinematic outside directly connected cells $point', () {
      final files = _connectedPayload(MapConnectionDirection.east, 0);
      _editCinematic(
          files,
          (json) => json['stageContext']['stagePoints'][0]
              .addAll({'x': point.x, 'y': point.y}));
      expect(
          () => _validate(files),
          throwsA(isA<GamePackageFormatException>()
              .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
    });
  }

  test('unconnected map does not extend the cinematic coordinate domain', () {
    final files = _connectedPayload(MapConnectionDirection.east, 0);
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!)));
    files['project/maps/map.json'] =
        utf8.encode(jsonEncode(map.copyWith(connections: []).toJson()));
    _editCinematic(
        files, (json) => json['stageContext']['stagePoints'][0]['x'] = 8.5);
    expect(
        () => _validate(files),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
  });

  test('player cannot finish in a connected neighbor', () {
    final files = _connectedPayload(MapConnectionDirection.east, 0);
    _editCinematic(files, (json) {
      json['stageContext']['actorBindings'][0] = {'actorId': 'guide', 'kind': 'player'};
      json['stageContext']['stagePoints'][0]['x'] = 8.5;
    });
    expect(() => _validate(files), throwsA(isA<GamePackageFormatException>()
        .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
  });

  test('player can cross a direct neighbor before returning to its active map', () {
    final files = _connectedPayload(MapConnectionDirection.east, 0);
    _editCinematic(files, (json) {
      json['stageContext']['actorBindings'][0] = {'actorId': 'guide', 'kind': 'player'};
      json['stageContext']['stagePoints'].add(
          {'id': 'outside', 'label': 'Outside', 'x': 8.5, 'y': 4.5});
      json['stageContext']['manualPaths'] = [{
        'id': 'route', 'label': 'Route', 'ownerActorMoveStepId': 'move',
        'waypointStagePointIds': ['outside'],
      }];
      json['timeline']['steps'][2]['metadata']
          [cinematicTimelineActorPathModeMetadataKey] = 'manual';
    });
    final built = const GamePackageBuilder().build(
        manifest: _storyManifest(connected: true), payloadFiles: files);
    expect(() => const GamePackageInspector().inspect(built.packageBytes), returnsNormally);
  });

  test('duplicate stage point identities remain invalid', () {
    final files = _payload();
    _editCinematic(files, (json) {
      json['stageContext']['stagePoints'].add(
          Map<String, dynamic>.from(json['stageContext']['stagePoints'][0]));
    });
    expect(
        () => _validate(files),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
  });

  test('rejects ambiguous neighbors introduced by an inverse connection', () {
    final files = _connectedPayload(MapConnectionDirection.east, 0);
    final neighbor = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/neighbor.json']!)));
    files['project/maps/other.json'] = utf8.encode(jsonEncode(neighbor.copyWith(
      id: 'other', connections: [
        const MapConnection(direction: MapConnectionDirection.west, targetMapId: 'map'),
      ],
    ).toJson()));
    final project = _project(files);
    _write(files, project.copyWith(maps: [...project.maps,
      const ProjectMapEntry(id: 'other', name: 'Other', relativePath: 'maps/other.json'),
    ]));
    _editCinematic(files, (json) => json['stageContext']['stagePoints'][0]['x'] = 8.5);
    expect(() => _validate(files), throwsA(isA<GamePackageFormatException>()
        .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
  });

  test('exports finite negative actor-relative offsets unchanged', () {
    final files = _payload();
    _editCinematic(
        files,
        (json) => json['stageContext']['stagePoints'][0]
            .addAll({'x': -1.0, 'y': -0.5, 'relativeToActorId': 'guide'}));
    final built = const GamePackageBuilder()
        .build(manifest: _storyManifest(), payloadFiles: files);
    expect(
        const GamePackageInspector()
            .inspect(built.packageBytes)
            .manifest
            .compatibility
            .requiredCapabilities,
        contains('map3d.story@1'));
    final point =
        _project(files).cinematics.single.stageContext!.stagePoints.single;
    expect((point.x, point.y, point.relativeToActorId), (-1.0, -0.5, 'guide'));
  });

  test('rejects actor-relative point without a bound origin', () {
    final files = _payload();
    _editCinematic(
        files,
        (json) => json['stageContext']['stagePoints'][0]
            .addAll({'x': -1.0, 'relativeToActorId': 'missing'}));
    expect(
        () => _validate(files),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
  });

  for (final relative in [false, true]) {
    test('rejects nonfinite ${relative ? 'relative' : 'absolute'} point', () {
      final files = _payload();
      if (relative) {
        _editCinematic(
            files,
            (json) => json['stageContext']['stagePoints'][0]
                ['relativeToActorId'] = 'guide');
      }
      files['project/project.json'] = utf8.encode(utf8
          .decode(files['project/project.json']!)
          .replaceFirst('"x":4.5', '"x":1e999'));
      expect(
          () => _validate(files),
          throwsA(isA<GamePackageFormatException>()
              .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
    });
  }

  for (final offset in [-1.2, -1.1875]) {
    test('relative player terminal offset $offset retains movement precision',
        () {
      final files = _payload();
      _editCinematic(files, (json) {
        json['stageContext']['actorBindings']
            [0] = {'actorId': 'guide', 'kind': 'player'};
        json['stageContext']['stagePoints'][0]
            .addAll({'x': offset, 'y': -0.5, 'relativeToActorId': 'guide'});
      });
      if (offset == -1.2) {
        expect(
            () => _validate(files),
            throwsA(isA<GamePackageFormatException>()
                .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
      } else {
        final built = const GamePackageBuilder()
            .build(manifest: _storyManifest(), payloadFiles: files);
        expect(() => const GamePackageInspector().inspect(built.packageBytes),
            returnsNormally);
      }
    });
  }

  for (final endpoint in [3.2, 3.1875]) {
    test('player terminal $endpoint preserves the movement lattice contract',
        () {
      final files = _payload();
      final project = _project(files);
      final json = jsonDecode(jsonEncode(project.cinematics.single.toJson()))
          as Map<String, dynamic>;
      json['stageContext']['actorBindings']
          [0] = {'actorId': 'guide', 'kind': 'player'};
      json['stageContext']['stagePoints'][0]['x'] = endpoint;
      _write(
          files, project.copyWith(cinematics: [CinematicAsset.fromJson(json)]));
      if (endpoint == 3.2) {
        expect(
            () => _validate(files),
            throwsA(isA<GamePackageFormatException>()
                .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
      } else {
        expect(() => _validate(files), returnsNormally);
        expect(
            _project(files)
                .cinematics
                .single
                .stageContext!
                .stagePoints
                .single
                .x,
            endpoint);
      }
    });
  }

  test('a placement-only player endpoint must align without asset snapping',
      () {
    final files = _payload();
    final project = _project(files);
    final json = jsonDecode(jsonEncode(project.cinematics.single.toJson()))
        as Map<String, dynamic>;
    json['stageContext']['actorBindings']
        [0] = {'actorId': 'guide', 'kind': 'player'};
    json['stageContext']['initialPlacements'][0] = {
      'actorId': 'guide',
      'kind': 'stagePoint',
      'stagePointId': 'point'
    };
    json['stageContext']['stagePoints'][0]['x'] = 3.2;
    json['timeline']['steps'] =
        (json['timeline']['steps'] as List).take(2).toList();
    _write(
        files, project.copyWith(cinematics: [CinematicAsset.fromJson(json)]));
    expect(
        () => _validate(files),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
    expect(_project(files).cinematics.single.stageContext!.stagePoints.single.x,
        3.2);
  });

  test(
      'intermediate player points and NPC endpoints keep continuous coordinates',
      () {
    for (final player in [true, false]) {
      final files = _payload();
      final project = _project(files);
      final json = jsonDecode(jsonEncode(project.cinematics.single.toJson()))
          as Map<String, dynamic>;
      if (player) {
        json['stageContext']['actorBindings']
            [0] = {'actorId': 'guide', 'kind': 'player'};
        json['stageContext']['stagePoints']
            .add({'id': 'waypoint', 'label': 'Waypoint', 'x': 3.2, 'y': 3.2});
        json['stageContext']['manualPaths'] = [
          {
            'id': 'route',
            'label': 'Route',
            'ownerActorMoveStepId': 'move',
            'waypointStagePointIds': ['waypoint']
          }
        ];
        json['timeline']['steps'][2]['metadata']
            [cinematicTimelineActorPathModeMetadataKey] = 'manual';
      } else {
        json['stageContext']['stagePoints'][0]['x'] = 3.2;
      }
      _write(
          files, project.copyWith(cinematics: [CinematicAsset.fromJson(json)]));
      expect(() => _validate(files), returnsNormally);
    }
  });

  test('an active manual route cannot silently become a direct movement', () {
    final files = _payload();
    final project = _project(files);
    final json = jsonDecode(jsonEncode(project.cinematics.single.toJson()))
        as Map<String, dynamic>;
    json['stageContext']['manualPaths'] = [
      {
        'id': 'route',
        'label': 'Route',
        'ownerActorMoveStepId': 'move',
        'waypointStagePointIds': <String>[]
      }
    ];
    json['timeline']['steps'][2]['metadata']
        [cinematicTimelineActorPathModeMetadataKey] = 'manual';
    _write(
        files, project.copyWith(cinematics: [CinematicAsset.fromJson(json)]));
    expect(
        () => _validate(files),
        throwsA(isA<GamePackageFormatException>()
            .having((e) => e.code, 'code', 'runtime3d.cinematic_invalid')));
  });

  test('rejects model commands with missing instance or uninspected clip', () {
    for (final command in [
      SceneInteractiveCommand.playModelAnimation(
          mapId: 'map', instanceId: 'missing', animationIndex: 0),
      SceneInteractiveCommand.playModelAnimation(
          mapId: 'map', instanceId: 'placement', animationIndex: 2),
    ]) {
      final files = _payload();
      final project = _project(files);
      _write(files, project.copyWith(scenes: [_scene(command)]));
      expect(
          () => _validate(files),
          throwsA(isA<GamePackageFormatException>().having(
              (e) => e.code, 'code', 'runtime3d.model_animation_invalid')));
    }
  });
}

GamePackageManifest _storyManifest({bool connected = false}) => spatialManifest(capabilities: [
      if (connected) 'map3d.cinematic-connected@1',
      'map3d@1',
      'map3d.gameplay@1',
      'map3d.story@1',
      'map3d.animation@1',
    ]);

void _editCinematic(
    Map<String, List<int>> files, void Function(Map<String, dynamic>) edit) {
  final project = _project(files);
  final json = jsonDecode(jsonEncode(project.cinematics.single.toJson()))
      as Map<String, dynamic>;
  edit(json);
  _write(files, project.copyWith(cinematics: [CinematicAsset.fromJson(json)]));
}

Map<String, List<int>> _connectedPayload(
    MapConnectionDirection direction, int offset,
    {bool inverse = false}) {
  final files = _payload();
  final map = MapData.fromJson(
      jsonDecode(utf8.decode(files['project/maps/map.json']!)));
  final connection = MapConnection(
      direction: direction, targetMapId: 'neighbor', offset: offset);
  files['project/maps/map.json'] = utf8.encode(jsonEncode(
      map.copyWith(connections: inverse ? [] : [connection]).toJson()));
  files['project/maps/neighbor.json'] = utf8.encode(jsonEncode(map
      .copyWith(
          id: 'neighbor',
          name: 'Neighbor',
          entities: [],
          connections: inverse
              ? [
                  MapConnection(
                      direction: direction.opposite,
                      targetMapId: 'map',
                      offset: -offset)
                ]
              : [],
          spatialScene: map.spatialScene!.copyWith(instances: []))
      .toJson()));
  final project = _project(files);
  _write(
      files,
      project.copyWith(maps: [
        ...project.maps,
        const ProjectMapEntry(
            id: 'neighbor',
            name: 'Neighbor',
            relativePath: 'maps/neighbor.json'),
      ]));
  return files;
}

void _validate(Map<String, List<int>> files) =>
    const GamePackageSpatialProjectValidator(gameplay: true)
        .validate(_project(files), (path) => files[path]);

ProjectManifest _project(Map<String, List<int>> files) =>
    ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!))
            as Map<String, dynamic>);

void _write(Map<String, List<int>> files, ProjectManifest project) =>
    files['project/project.json'] = utf8.encode(jsonEncode(project.toJson()));

Map<String, List<int>> _payload() {
  final files = spatialPayload(modelBytes: animatedGlb(edit: (json) {
    json['nodes'][0].remove('translation');
    json['nodes'][0].remove('scale');
  }));
  final project = _project(files);
  final map = MapData.fromJson(
      jsonDecode(utf8.decode(files['project/maps/map.json']!)));
  files['project/maps/map.json'] =
      utf8.encode(jsonEncode(map.copyWith(entities: [
    MapEntity(
        id: 'guide',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 2),
        blocksMovement: true,
        npc: MapEntityNpcData(characterId: 'hero')),
  ]).toJson()));
  _write(
      files,
      project.copyWith(
          settings: project.settings.copyWith(tileWidth: 32, tileHeight: 24),
          scenes: [
            _scene(SceneInteractiveCommand.playModelAnimation(
                mapId: 'map',
                instanceId: 'placement',
                animationIndex: 0,
                speed: 2,
                blocksMovementAfter: false))
          ],
          cinematics: [
            _cinematic()
          ]));
  return files;
}

SceneAsset _scene(SceneInteractiveCommand command) => SceneAsset(
    id: 'intro',
    name: 'Intro',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'movie',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: 'movie')),
      SceneNode(
          id: 'open',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.interactive(command)),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start-movie',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'movie',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'movie-open',
          fromNodeId: 'movie',
          fromPortId: 'completed',
          toNodeId: 'open',
          kind: SceneEdgeKind.cinematicCompleted),
      for (final port in ['completed', 'blocked', 'cancelled'])
        SceneEdge(
            id: port,
            fromNodeId: 'open',
            fromPortId: port,
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow),
    ]));

CinematicAsset _cinematic() => CinematicAsset(
    id: 'movie',
    title: 'Movie',
    mapId: 'map',
    requiredActors: [CinematicActorRef(actorId: 'guide')],
    movementTargets: [
      CinematicMovementTargetRef(targetId: 'target', label: 'Target')
    ],
    stageContext: CinematicStageContext(
      backdropMode: CinematicStageBackdropMode.projectMap,
      actorBindings: [
        CinematicActorBinding(
            actorId: 'guide',
            kind: CinematicActorBindingKind.mapEntity,
            mapEntityId: 'guide')
      ],
      initialPlacements: [
        CinematicActorInitialPlacement(
            actorId: 'guide',
            kind: CinematicActorInitialPlacementKind.fromMapEntity)
      ],
      movementTargetBindings: [
        CinematicMovementTargetBinding(
            targetId: 'target',
            kind: CinematicMovementTargetBindingKind.stagePoint,
            sourceId: 'point')
      ],
      stagePoints: [
        CinematicStagePoint(id: 'point', label: 'Point', x: 4.5, y: 4.5)
      ],
    ),
    timeline: CinematicTimeline(steps: [
      CinematicTimelineStep(
          id: 'wait', kind: CinematicTimelineStepKind.wait, durationMs: 20),
      CinematicTimelineStep(
          id: 'camera',
          kind: CinematicTimelineStepKind.camera,
          durationMs: 100,
          metadata: const {
            cinematicTimelineCameraModeMetadataKey: 'focus',
            cinematicTimelineCameraTargetKindMetadataKey: 'actor',
            cinematicTimelineCameraTargetActorIdMetadataKey: 'guide',
            cinematicTimelineCameraZoomPresetMetadataKey: 'medium',
          }),
      CinematicTimelineStep(
          id: 'move',
          kind: CinematicTimelineStepKind.actorMove,
          actorId: 'guide',
          targetId: 'target',
          durationMs: 100,
          metadata: const {
            cinematicTimelineActorMovementModeMetadataKey: 'walk',
            cinematicTimelineActorPathModeMetadataKey: 'direct',
          }),
      CinematicTimelineStep(
          id: 'face',
          kind: CinematicTimelineStepKind.actorFace,
          actorId: 'guide',
          metadata: const {cinematicTimelineActorDirectionMetadataKey: 'left'}),
      CinematicTimelineStep(
          id: 'marker', kind: CinematicTimelineStepKind.marker),
    ]));
