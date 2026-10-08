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
    expect(inspected.manifest.compatibility.requiredCapabilities,
        ['map3d@1', 'map3d.gameplay@1', 'map3d.story@1', 'map3d.animation@1']);
    final decoded = _project(files);
    expect(buildSceneRuntimePlan(decoded.scenes.single).canBuild, isTrue);
    expect(decoded.cinematics.single.timeline.steps.map((s) => s.kind),
        SpatialGameplayCapabilities.cinematicStepKinds);
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
