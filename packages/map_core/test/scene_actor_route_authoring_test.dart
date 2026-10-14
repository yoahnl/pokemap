import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _target({String mapId = 'map', String? entityId}) => {
  'kind': entityId == null ? 'player' : 'entity',
  'mapId': mapId,
  'entityId': ?entityId,
};

Map<String, dynamic> _route({
  Map<String, dynamic>? target,
  List<Map<String, dynamic>>? steps,
}) => {
  'kind': 'actorRoute',
  'target': target ?? _target(entityId: 'door'),
  'steps':
      steps ??
      [
        {'kind': 'face', 'direction': 'south'},
        {'kind': 'move', 'direction': 'south', 'durationMs': 200},
        {'kind': 'wait', 'durationMs': 0},
        {'kind': 'through', 'enabled': true},
        {'kind': 'sound', 'mediaAssetId': 'door-sound', 'gain': 0.8},
      ],
  'skippable': false,
};

Map<String, dynamic> _visibility({Map<String, dynamic>? target}) => {
  'kind': 'actorVisibility',
  'target': target ?? _target(entityId: 'door'),
  'visible': false,
};

SceneAsset _scene(Map<String, dynamic> wire) => SceneAsset(
  id: 'scene',
  name: 'Scene',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'actor',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.fromJson(wire),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'actor',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'blocked'])
        SceneEdge(
          id: port,
          fromNodeId: 'actor',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
    ],
  ),
);

CinematicMediaAsset _media({
  CinematicMediaAssetKind kind = CinematicMediaAssetKind.sound,
  bool loop = false,
}) => CinematicMediaAsset(
  id: 'door-sound',
  label: 'Door',
  kind: kind,
  relativePath: 'audio/door.wav',
  loopByDefault: loop,
);

MapData _map({
  String id = 'map',
  List<MapEntity>? entities,
  MapSpatialScene? spatialScene,
}) => MapData(
  version: spatialScene == null ? ProjectVersion.v8 : ProjectVersion.v9,
  id: id,
  name: id,
  size: const GridSize(width: 2, height: 2),
  spatialScene: spatialScene,
  entities:
      entities ??
      const [
        MapEntity(
          id: 'door',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 0, y: 0),
          npc: MapEntityNpcData(characterId: 'actor-character'),
        ),
      ],
);

ProjectManifest _project(
  SceneAsset scene, {
  List<CinematicMediaAsset>? media,
  List<ProjectMapEntry>? maps,
  List<ProjectCharacterEntry>? characters,
  List<ProjectTrainerEntry> trainers = const [],
  ProjectDimension dimension = ProjectDimension.twoD,
}) => ProjectManifest(
  version: dimension == ProjectDimension.threeD
      ? ProjectVersion.v9
      : ProjectVersion.v8,
  settings: ProjectSettings(dimension: dimension),
  name: 'QA',
  tilesets: const [
    ProjectTilesetEntry(
      id: 'actor-sheet',
      name: 'Original QA sheet',
      relativePath: 'assets/actor.png',
    ),
  ],
  characters:
      characters ??
      const [
        ProjectCharacterEntry(
          id: 'actor-character',
          name: 'Original QA actor',
          tilesetId: 'actor-sheet',
          frameHeight: 1,
        ),
      ],
  trainers: trainers,
  scenes: [scene],
  maps:
      maps ??
      const [
        ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
      ],
  cinematicMediaAssets: media ?? [_media()],
);

void main() {
  test(
    'actor commands expose a 2D runtime while the editor remains unsupported',
    () {
      final catalog = NarrativeCommandCatalog.canonical();
      for (final id in ['actorRoute', 'actorVisibility']) {
        final descriptor = catalog.byId(id);
        expect(descriptor, isNotNull, reason: id);
        expect(descriptor!.wireId, 'SceneInteractiveCommand.$id');
        expect(descriptor.fgLotId, 'FG-092');
        expect(
          descriptor.backend,
          NarrativeCommandBackend.interactiveRuntimeCommand,
        );
        expect(descriptor.isPersistent, isFalse);
        expect(descriptor.isAwaitable, isTrue);
        expect(descriptor.isPublishable, isFalse);
        expect(
          descriptor.capabilities.model,
          NarrativeCommandCapabilityStatus.supported,
        );
        expect(
          descriptor.capabilities.editor,
          NarrativeCommandCapabilityStatus.unsupported,
        );
        expect(
          descriptor.capabilities.runtime,
          NarrativeCommandCapabilityStatus.supported,
        );
        expect(descriptor.capabilities.reason, isNotEmpty);
        expect(descriptor.capabilities.reason, contains('Player 2D'));
        expect(
          descriptor.capabilities.reason,
          contains('formulaire guidé non qualifié'),
        );
        expect(descriptor.capabilities.reason, contains('aucun support 3D'));
      }
      expect(catalog.byId('actorRoute')!.parameters.map((p) => p.id), [
        'target',
        'steps',
        'skippable',
      ]);
      expect(catalog.byId('actorVisibility')!.parameters.map((p) => p.id), [
        'mapId',
        'targetKind',
        'entityId',
        'visible',
      ]);
    },
  );

  test('visibility payload builder preserves a strict guided target', () {
    for (final entityId in <String?>[null, 'door']) {
      final parameters = {
        'mapId': 'map',
        'targetKind': entityId == null ? 'player' : 'entity',
        'entityId': ?entityId,
        'visible': 'false',
      };
      expect(
        () => buildScenePayloadForNarrativeCommand(
          commandId: 'actorVisibility',
          parameters: parameters,
        ),
        returnsNormally,
      );
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: 'actorVisibility',
                parameters: parameters,
              )
              as SceneActionPayload;
      expect(
        payload.interactiveCommand!.toJson(),
        _visibility(target: _target(entityId: entityId)),
      );
    }
    for (final parameters in [
      {'mapId': 'map', 'targetKind': 'player', 'visible': 'anything'},
      {
        'mapId': 'map',
        'targetKind': 'player',
        'entityId': 'door',
        'visible': 'true',
      },
      {'mapId': 'map', 'targetKind': 'entity', 'visible': 'true'},
      {
        'mapId': 'map',
        'targetKind': 'player',
        'visible': 'true',
        'persist': 'true',
      },
    ]) {
      expect(
        () => buildScenePayloadForNarrativeCommand(
          commandId: 'actorVisibility',
          parameters: parameters,
        ),
        throwsA(anyOf(isA<ArgumentError>(), isA<FormatException>())),
      );
    }
  });

  for (final wire in [_route(), _visibility(), _route(target: _target())]) {
    test(
      '${wire['kind']} resolves a map-bound target and remains diagnostic safe',
      () {
        final scene = _scene(wire);
        expect(
          diagnoseSceneAgainstProject(
            scene,
            _project(scene),
            mapsById: {'map': _map()},
          ).hasErrors,
          isFalse,
        );
        final index = buildNarrativeDependencyIndex(
          project: _project(scene),
          maps: [_map()],
        );
        final usages = index.usages
            .where(
              (usage) =>
                  usage.owner == const NarrativeDependencyKey.scene('scene'),
            )
            .toList();
        final targetUsages = usages
            .where((usage) => usage.path.contains('.target.'))
            .toList();
        expect(
          targetUsages,
          hasLength((wire['target'] as Map)['kind'] == 'entity' ? 2 : 1),
        );
        expect(
          targetUsages.every(
            (usage) =>
                usage.resolution == NarrativeDependencyResolution.resolved,
          ),
          isTrue,
        );
        expect(
          targetUsages.every(
            (usage) =>
                usage.criticality ==
                NarrativeDependencyCriticality.runtimeBlocking,
          ),
          isTrue,
        );
        expect(
          targetUsages.map((usage) => usage.path),
          contains(
            'scenes[scene].graph.nodes[1].payload.interactiveCommand.target.mapId',
          ),
        );
      },
    );
  }

  test('actor target requires the exact declared loaded map', () {
    for (final fixture in [
      (_target(mapId: 'missing'), <String, MapData>{'map': _map()}, null),
      (_target(), <String, MapData>{}, null),
      (_target(), <String, MapData>{'map': _map(id: 'other')}, null),
      (
        _target(),
        <String, MapData>{'map': _map()},
        <ProjectMapEntry>[
          const ProjectMapEntry(
            id: 'map',
            name: 'First',
            relativePath: 'maps/a.json',
          ),
          const ProjectMapEntry(
            id: 'map',
            name: 'Second',
            relativePath: 'maps/b.json',
          ),
        ],
      ),
    ]) {
      final scene = _scene(_visibility(target: fixture.$1));
      final result = diagnoseSceneAgainstProject(
        scene,
        _project(scene, maps: fixture.$3),
        mapsById: fixture.$2,
      );
      expect(result.hasErrors, isTrue, reason: fixture.toString());
      expect(
        result.diagnostics.any(
          (d) => d.code.name == 'commandInvalidActorTarget',
        ),
        isTrue,
      );
    }
  });

  test('entity target cannot borrow an ID from another map or a duplicate', () {
    for (final entities in [
      const <MapEntity>[],
      <MapEntity>[..._map().entities, ..._map().entities],
    ]) {
      final scene = _scene(_route());
      final result = diagnoseSceneAgainstProject(
        scene,
        _project(scene),
        mapsById: {
          'map': _map(entities: entities),
          'other': _map(id: 'other'),
        },
      );
      expect(result.hasErrors, isTrue);
      expect(
        result.diagnostics.any(
          (d) => d.code.name == 'commandInvalidActorTarget',
        ),
        isTrue,
      );
    }
  });

  for (final kind in [MapEntityKind.sign, MapEntityKind.custom]) {
    test('actor commands refuse a unique ${kind.name} target', () {
      final map = _map(
        entities: [
          MapEntity(id: 'door', kind: kind, pos: const GridPos(x: 0, y: 0)),
        ],
      );
      for (final wire in [_route(), _visibility()]) {
        final scene = _scene(wire);
        final project = _project(scene);
        final result = diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'map': map},
        );
        expect(
          result.hasErrors,
          isTrue,
          reason: '${wire['kind']} ${kind.name}',
        );
        expect(
          result.diagnostics.map((d) => d.code.name),
          contains('commandInvalidActorTarget'),
        );
        final index = buildNarrativeDependencyIndex(
          project: project,
          maps: [map],
        );
        final usage = index.usages.singleWhere(
          (usage) => usage.path.endsWith('target.entityId'),
        );
        expect(usage.resolution, NarrativeDependencyResolution.unavailable);
        expect(
          index.issues.singleWhere((issue) => issue.path == usage.path).message,
          contains('native 2D actor'),
        );
      }
    });
  }

  test('actor commands refuse a spatial map for player and entity targets', () {
    final map = _map(spatialScene: MapSpatialScene(width: 2, depth: 2));
    for (final target in [_target(), _target(entityId: 'door')]) {
      for (final wire in [
        _route(target: target),
        _visibility(target: target),
      ]) {
        final scene = _scene(wire);
        final project = _project(scene, dimension: ProjectDimension.threeD);
        final result = diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'map': map},
        );
        expect(
          result.hasErrors,
          isTrue,
          reason: '${wire['kind']} ${target['kind']}',
        );
        expect(
          result.diagnostics.map((d) => d.code.name),
          contains('commandInvalidActorTarget'),
        );
        final index = buildNarrativeDependencyIndex(
          project: project,
          maps: [map],
        );
        final usages = index.usages.where(
          (usage) => usage.path.contains('interactiveCommand.target.'),
        );
        expect(
          usages.every(
            (usage) =>
                usage.resolution == NarrativeDependencyResolution.unavailable,
          ),
          isTrue,
        );
      }
    }
  });

  test('actor unavailability keeps duplicate target definitions ambiguous', () {
    final scene = _scene(_route());
    final map = _map(
      spatialScene: MapSpatialScene(width: 2, depth: 2),
      entities: [..._map().entities, ..._map().entities],
    );
    final project = _project(
      scene,
      dimension: ProjectDimension.threeD,
      maps: const [
        ProjectMapEntry(
          id: 'map',
          name: 'First',
          relativePath: 'maps/map.json',
        ),
        ProjectMapEntry(
          id: 'map',
          name: 'Second',
          relativePath: 'maps/duplicate.json',
        ),
      ],
    );
    final index = buildNarrativeDependencyIndex(project: project, maps: [map]);
    final usages = index.usages.where(
      (u) => u.path.contains('interactiveCommand.target.'),
    );
    expect(
      usages.every(
        (u) => u.resolution == NarrativeDependencyResolution.ambiguous,
      ),
      isTrue,
    );
  });

  final trainer = const ProjectTrainerEntry(
    id: 'actor-trainer',
    name: 'Original QA trainer',
    trainerClass: 'QA',
    characterId: 'actor-character',
  );
  final character = const ProjectCharacterEntry(
    id: 'actor-character',
    name: 'Original QA actor',
    tilesetId: 'actor-sheet',
    frameHeight: 1,
  );
  for (final fixture
      in <
        (
          String,
          MapEntityNpcData?,
          List<ProjectCharacterEntry>,
          List<ProjectTrainerEntry>,
        )
      >[
        ('missing payload', null, [character], []),
        ('empty payload', const MapEntityNpcData(), [character], []),
        (
          'unknown character',
          const MapEntityNpcData(characterId: 'missing'),
          [character],
          [],
        ),
        (
          'absent character registry',
          const MapEntityNpcData(characterId: 'actor-character'),
          [],
          [],
        ),
        (
          'ambiguous character',
          const MapEntityNpcData(characterId: 'actor-character'),
          [character, character],
          [],
        ),
        (
          'unknown trainer',
          const MapEntityNpcData(trainerId: 'missing'),
          [character],
          [trainer],
        ),
        (
          'ambiguous trainer',
          const MapEntityNpcData(trainerId: 'actor-trainer'),
          [character],
          [trainer, trainer],
        ),
        (
          'trainer character absent',
          const MapEntityNpcData(trainerId: 'actor-trainer'),
          [],
          [trainer],
        ),
        (
          'trainer character ambiguous',
          const MapEntityNpcData(trainerId: 'actor-trainer'),
          [character, character],
          [trainer],
        ),
        (
          'invalid direct character keeps priority',
          const MapEntityNpcData(
            characterId: 'missing',
            trainerId: 'actor-trainer',
          ),
          [character],
          [trainer],
        ),
      ]) {
    test('actor reference refuses ${fixture.$1}', () {
      final map = _map(
        entities: [
          MapEntity(
            id: 'door',
            kind: MapEntityKind.npc,
            pos: const GridPos(x: 0, y: 0),
            npc: fixture.$2,
          ),
        ],
      );
      for (final wire in [_route(), _visibility()]) {
        final scene = _scene(wire);
        final project = _project(
          scene,
          characters: fixture.$3,
          trainers: fixture.$4,
        );
        final result = diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'map': map},
        );
        expect(
          result.diagnostics.map((d) => d.code.name),
          contains('commandInvalidActorTarget'),
        );
        final index = buildNarrativeDependencyIndex(
          project: project,
          maps: [map],
        );
        expect(
          index.usages
              .singleWhere((u) => u.path.endsWith('target.entityId'))
              .resolution,
          NarrativeDependencyResolution.unavailable,
        );
      }
    });
  }

  test(
    'actor reference resolves the unique trainer character without a direct reference',
    () {
      final map = _map(
        entities: const [
          MapEntity(
            id: 'door',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 0, y: 0),
            npc: MapEntityNpcData(trainerId: ' actor-trainer '),
          ),
        ],
      );
      for (final wire in [_route(), _visibility()]) {
        final scene = _scene(wire);
        final project = _project(scene, trainers: [trainer]);
        expect(
          diagnoseSceneAgainstProject(
            scene,
            project,
            mapsById: {'map': map},
          ).hasErrors,
          isFalse,
        );
        final index = buildNarrativeDependencyIndex(
          project: project,
          maps: [map],
        );
        expect(
          index.usages
              .singleWhere((u) => u.path.endsWith('target.entityId'))
              .resolution,
          NarrativeDependencyResolution.resolved,
        );
      }
    },
  );

  for (final assets in [
    <CinematicMediaAsset>[],
    [_media(kind: CinematicMediaAssetKind.music)],
    [_media(kind: CinematicMediaAssetKind.cinematicFx)],
    [_media(loop: true)],
    [_media(), _media(kind: CinematicMediaAssetKind.music)],
    [_media(), _media()],
  ]) {
    test(
      'actor route sound refuses unavailable incompatible or ambiguous media ${assets.map((a) => '${a.kind.name}:${a.loopByDefault}').join(',')}',
      () {
        final scene = _scene(_route());
        final project = _project(scene, media: assets);
        final diagnostics = diagnoseSceneAgainstProject(
          scene,
          project,
          mapsById: {'map': _map()},
        );
        expect(diagnostics.hasErrors, isTrue);
        expect(
          diagnostics.diagnostics.any(
            (d) => [
              'commandUnknownSoundMedia',
              'commandInvalidSoundMedia',
            ].contains(d.code.name),
          ),
          isTrue,
        );
        final usage = buildNarrativeDependencyIndex(
          project: project,
          maps: [_map()],
        ).usages.singleWhere((u) => u.path.endsWith('.steps[4].mediaAssetId'));
        expect(
          usage.resolution,
          assets.isEmpty
              ? NarrativeDependencyResolution.missing
              : assets.length > 1
              ? NarrativeDependencyResolution.ambiguous
              : NarrativeDependencyResolution.unavailable,
        );
      },
    );
  }

  test('each route sound retains its precise nested dependency path', () {
    final scene = _scene(
      _route(
        steps: [
          {'kind': 'sound', 'mediaAssetId': 'door-sound', 'gain': 0.8},
          {'kind': 'wait', 'durationMs': 50},
          {'kind': 'sound', 'mediaAssetId': 'door-sound', 'gain': 0.5},
        ],
      ),
    );
    final index = buildNarrativeDependencyIndex(
      project: _project(scene),
      maps: [_map()],
    );
    final uses = index.usagesFor(
      const NarrativeDependencyKey(
        NarrativeDependencyTargetKind.media,
        'door-sound',
      ),
    );
    expect(uses.map((u) => u.path), [
      'scenes[scene].graph.nodes[1].payload.interactiveCommand.steps[0].mediaAssetId',
      'scenes[scene].graph.nodes[1].payload.interactiveCommand.steps[2].mediaAssetId',
    ]);
    expect(
      uses.every((u) => u.resolution == NarrativeDependencyResolution.resolved),
      isTrue,
    );
  });

  test('route authoring leaves movement bounds to the dynamic runtime', () {
    final scene = _scene(
      _route(
        steps: [
          for (var i = 0; i < 10; i++)
            {'kind': 'move', 'direction': 'east', 'durationMs': 200},
        ],
      ),
    );
    expect(
      diagnoseSceneAgainstProject(
        scene,
        _project(scene),
        mapsById: {'map': _map()},
      ).hasErrors,
      isFalse,
    );
  });

  test(
    'actor world actions compile while the no-code publication gate is closed',
    () {
      for (final wire in [_route(), _visibility()]) {
        final scene = _scene(wire);
        final node = scene.graph.nodes[1];
        expect(
          sceneExecutionCapabilityForNode(SceneExecutionProfile.world, node),
          SceneExecutionCapabilityIds.worldAction,
        );
        final plan = buildSceneRuntimePlan(scene);
        expect(plan.canBuild, isTrue);
        expect(
          plan.plan!.nodes[1].intent.kind,
          SceneRuntimePlanIntentKind.executeInteractiveCommand,
        );
        expect(
          NarrativeCommandCatalog.canonical()
              .byId(wire['kind'] as String)!
              .isPublishable,
          isFalse,
        );
      }
    },
  );

  test('actor commands remain forbidden in pre-session scenes', () {
    for (final wire in [_route(), _visibility()]) {
      final scene = SceneAsset.fromJson({
        ..._scene(wire).toJson(),
        'executionProfile': 'preSession',
      });
      expect(
        diagnoseScene(scene).diagnostics.any(
          (d) => d.code == SceneDiagnosticCode.capabilityForbiddenForProfile,
        ),
        isTrue,
      );
      expect(buildSceneRuntimePlan(scene).canBuild, isFalse);
    }
  });
}
