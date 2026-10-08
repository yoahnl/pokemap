import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'qualified model commands and world cinematics select spatial gameplay',
    () {
      final scene = _scene();
      expect(
        SpatialGameplayCapabilities.supportsSceneNode(
          SceneExecutionProfile.world,
          scene.graph.nodes[1],
        ),
        isTrue,
      );
      expect(
        SpatialGameplayCapabilities.supportsSceneNode(
          SceneExecutionProfile.world,
          SceneNode(
            id: 'cinematic',
            kind: SceneNodeKind.cinematic,
            payload: SceneCinematicPayload(cinematicId: 'intro'),
          ),
        ),
        isTrue,
      );
      expect(
        SpatialGameplayCapabilities.supportsSceneNode(
          SceneExecutionProfile.preSession,
          SceneNode(
            id: 'cinematic',
            kind: SceneNodeKind.cinematic,
            payload: SceneCinematicPayload(cinematicId: 'intro'),
          ),
        ),
        isFalse,
      );
      expect(
        SpatialGameplayCapabilities.requiresGameplay(
          _project().copyWith(
            cinematics: [
              CinematicAsset(
                id: 'intro',
                title: 'Intro',
                timeline: CinematicTimeline(),
              ),
            ],
          ),
        ),
        isTrue,
      );
      expect(SpatialGameplayCapabilities.productionExportEnabled, isFalse);
    },
  );

  test(
    'new story semantics require a distinct capability without changing exploration',
    () {
      final project = _project();
      expect(SpatialGameplayCapabilities.storyCapabilityId, 'map3d.story@1');
      expect(SpatialGameplayCapabilities.requiresStory(project), isFalse);
      expect(
        SpatialGameplayCapabilities.requiresStory(
          project.copyWith(scenes: [_scene()]),
        ),
        isTrue,
      );
      expect(
        SpatialGameplayCapabilities.requiresModelAnimation(project),
        isFalse,
      );
      expect(
        SpatialGameplayCapabilities.requiresModelAnimation(
          project.copyWith(scenes: [_scene()]),
        ),
        isTrue,
      );
      final cinematic = SceneAsset(
        id: 'intro',
        name: 'Intro',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'movie',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: 'movie'),
            ),
          ],
          edges: [],
        ),
      );
      expect(
        SpatialGameplayCapabilities.requiresStory(
          project.copyWith(scenes: [cinematic]),
        ),
        isTrue,
      );
      final event = NarrativeEventDefinition(
        id: 'evt_019a6190-0000-7000-8000-000000000001',
        name: 'Open',
        source: NarrativeEventSourceRef.modelInteract('map', 'door'),
        conditions: [],
        sceneId: 'open',
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: 0,
      );
      expect(
        SpatialGameplayCapabilities.requiresStory(
          project.copyWith(
            eventRegistry: NarrativeEventRegistry(
              schemaVersion: 1,
              mode: EventSystemMode.v2Only,
              records: [
                NarrativeEventRecord.configuredStructurallyUnchecked(
                  event,
                  enabled: true,
                ),
              ],
              legacyClaims: [],
            ),
          ),
        ),
        isTrue,
      );
    },
  );

  test(
    'model animation diagnostics resolve the map instance model and clip',
    () {
      final project = _project().copyWith(scenes: [_scene()]);
      final valid = diagnoseSceneAgainstProject(
        project.scenes.single,
        project,
        mapsById: {'map': _map()},
      );
      expect(
        valid.hasErrors,
        isFalse,
        reason: valid.diagnostics.map((d) => d.message).join('\n'),
      );
      expect(
        valid.diagnostics.where(
          (d) => d.code.name.startsWith('commandUnknownModel'),
        ),
        isEmpty,
      );
      for (final entry in [
        (
          scene: _scene(mapId: 'missing'),
          map: _map(),
          project: project,
          code: 'commandUnknownMap',
        ),
        (
          scene: _scene(instanceId: 'missing'),
          map: _map(),
          project: project,
          code: 'commandUnknownModelInstance',
        ),
        (
          scene: _scene(),
          map: _map(),
          project: project.copyWith(models3d: []),
          code: 'commandUnknownModel',
        ),
        (
          scene: _scene(animationIndex: 1),
          map: _map(),
          project: project,
          code: 'commandUnknownModelAnimation',
        ),
      ]) {
        final report = diagnoseSceneAgainstProject(
          entry.scene,
          entry.project,
          mapsById: {'map': entry.map},
        );
        expect(
          report.diagnostics.where((d) => d.code.name == entry.code),
          hasLength(1),
          reason: entry.code,
        );
      }
    },
  );

  test(
    'dependency identity connects scene commands to instances and clips',
    () {
      final project = _project().copyWith(scenes: [_scene()]);
      final index = buildNarrativeDependencyIndex(
        project: project,
        maps: [_map()],
      );
      final usages = index.usagesOwnedBy(
        const NarrativeDependencyKey.scene('open'),
      );
      expect(
        usages.where((u) => u.target.sourceKind == 'modelInstance'),
        hasLength(1),
      );
      expect(
        usages.where((u) => u.target.sourceKind == 'modelAnimation'),
        hasLength(1),
      );
      expect(
        usages.every(
          (u) => u.resolution == NarrativeDependencyResolution.resolved,
        ),
        isTrue,
      );
      final absent = buildNarrativeDependencyIndex(
        project: project,
        maps: [
          _map().copyWith(spatialScene: MapSpatialScene(width: 8, depth: 8)),
        ],
      );
      expect(
        absent
            .usagesOwnedBy(const NarrativeDependencyKey.scene('open'))
            .where((u) => u.target.sourceKind == 'modelInstance')
            .single
            .resolution,
        NarrativeDependencyResolution.missing,
      );
    },
  );
}

SceneAsset _scene({
  String mapId = 'map',
  String instanceId = 'door',
  int animationIndex = 0,
}) => SceneAsset(
  id: 'open',
  name: 'Open door',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'play',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.playModelAnimation(
            mapId: mapId,
            instanceId: instanceId,
            animationIndex: animationIndex,
            blocksMovementAfter: false,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'play',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final port in ['completed', 'blocked', 'cancelled'])
        SceneEdge(
          id: port,
          fromNodeId: 'play',
          fromPortId: port,
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
    ],
  ),
);

ProjectManifest _project() => ProjectManifest(
  name: 'Spatial',
  version: ProjectVersion.v9,
  settings: ProjectSettings(dimension: ProjectDimension.threeD),
  pokemon: const ProjectPokemonConfig(
    enabled: false,
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
  ),
  maps: [
    const ProjectMapEntry(
      id: 'map',
      name: 'Map',
      relativePath: 'maps/map.json',
    ),
  ],
  tilesets: [],
  models3d: [
    ProjectModel3dEntry(
      id: 'door-model',
      name: 'Door',
      sourceAssetId: 'door-source',
      relativePath: 'assets/models3d/door-model.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 1, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
        animations: [
          Model3dAnimation(index: 0, name: 'Open', durationSeconds: 1),
        ],
      ),
    ),
  ],
);

MapData _map() => MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v9,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    instances: [
      SpatialModelInstance(
        id: 'door',
        modelId: 'door-model',
        position: Model3dVector3.zero,
      ),
    ],
  ),
);
