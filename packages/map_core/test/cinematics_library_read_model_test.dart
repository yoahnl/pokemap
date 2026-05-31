import 'dart:io';

import 'package:test/test.dart';
import 'package:map_core/map_core.dart';

void main() {
  group('buildCinematicsLibraryReadModel', () {
    test('lists canonical CinematicAsset and scenario bridges separately', () {
      final project = _projectWithCinematics();

      final readModel = buildCinematicsLibraryReadModel(project);

      expect(readModel.canonicalEntries, hasLength(1));
      expect(readModel.bridgeEntries, hasLength(1));
      expect(readModel.metrics.canonicalCount, 1);
      expect(readModel.metrics.bridgeCount, 1);

      final canonical = readModel.canonicalEntries.single;
      expect(canonical.id, 'cinematic_intro');
      expect(canonical.title, 'Intro cinematic');
      expect(canonical.kind, CinematicsLibraryEntryKind.canonical);
      expect(canonical.statusLabel, 'CinematicAsset canonique');
      expect(canonical.mapId, 'map_lab');
      expect(canonical.requiredActors.map((actor) => actor.actorId),
          contains('actor_professor'));
      expect(canonical.timeline.stepCount, 2);
      expect(canonical.timeline.estimatedDurationMs, 750);
      expect(canonical.timeline.stepKindLabels, contains('camera'));
      expect(canonical.timeline.actorIds, contains('actor_professor'));
      expect(canonical.isEditable, isTrue);

      final bridge = readModel.bridgeEntries.single;
      expect(bridge.id, 'scenario_cutscene');
      expect(bridge.kind, CinematicsLibraryEntryKind.scenarioBridge);
      expect(bridge.statusLabel, 'Bridge legacy Scenario/Cutscene');
      expect(bridge.isEditable, isFalse);
      expect(bridge.isRemovable, isFalse);
      expect(
        bridge.diagnostics.map((diagnostic) => diagnostic.code),
        contains('legacyBridge'),
      );
    });

    test('attaches diagnostics and reports empty timeline metrics', () {
      final project = ProjectManifest(
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        name: 'cinematic_project',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_empty',
            title: 'Empty cinematic',
            timeline: CinematicTimeline(),
          ),
        ],
      );

      final readModel = buildCinematicsLibraryReadModel(project);

      expect(readModel.metrics.emptyTimelineCount, 1);
      expect(readModel.metrics.diagnosticCount, 1);
      expect(readModel.canonicalEntries.single.timeline.isEmpty, isTrue);
      expect(
        readModel.canonicalEntries.single.diagnostics
            .map((diagnostic) => diagnostic.code),
        contains('cinematicEmptyTimeline'),
      );
    });

    test('reports canonical, bridge, and unknown Scene references', () {
      final project = _projectWithCinematics(
        scenes: [
          _sceneReferencing(
            id: 'scene_canonical',
            name: 'Canonical scene',
            nodeId: 'node_cinematic',
            nodeTitle: 'Play intro',
            cinematicId: 'cinematic_intro',
          ),
          _sceneReferencing(
            id: 'scene_bridge',
            name: 'Bridge scene',
            nodeId: 'node_bridge',
            nodeTitle: 'Play bridge',
            cinematicId: 'scenario_cutscene',
          ),
          _sceneReferencing(
            id: 'scene_unknown',
            name: 'Unknown scene',
            nodeId: 'node_missing',
            nodeTitle: 'Play missing',
            cinematicId: 'cinematic_missing',
          ),
        ],
      );

      final readModel = buildCinematicsLibraryReadModel(project);

      expect(readModel.metrics.referencedCount, 2);
      expect(readModel.unknownUsages, hasLength(1));
      expect(
        readModel.unknownUsages.single.referenceStatus,
        CinematicsLibraryReferenceStatus.unknown,
      );

      final canonicalUsage = readModel.canonicalEntries.single.usages.single;
      expect(canonicalUsage.sceneId, 'scene_canonical');
      expect(canonicalUsage.sceneTitle, 'Canonical scene');
      expect(canonicalUsage.nodeId, 'node_cinematic');
      expect(canonicalUsage.nodeTitle, 'Play intro');
      expect(
        canonicalUsage.referenceStatus,
        CinematicsLibraryReferenceStatus.canonical,
      );

      final bridgeUsage = readModel.bridgeEntries.single.usages.single;
      expect(bridgeUsage.sceneId, 'scene_bridge');
      expect(
        bridgeUsage.referenceStatus,
        CinematicsLibraryReferenceStatus.bridgeLegacy,
      );
    });

    test('does not mutate ProjectManifest or import Flutter/runtime packages',
        () {
      final project = _projectWithCinematics();
      final beforeJson = project.toJson();

      buildCinematicsLibraryReadModel(project);

      expect(project.toJson(), beforeJson);
      expect(
        _readModelSource(),
        allOf(
          isNot(contains('package:flutter')),
          isNot(contains('package:flame')),
          isNot(contains('map_runtime')),
          isNot(contains('PlayableMapGame')),
        ),
      );
    });
  });
}

ProjectManifest _projectWithCinematics({
  List<SceneAsset> scenes = const <SceneAsset>[],
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'cinematic_project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(id: 'map_lab', name: 'Lab map', relativePath: 'lab.json'),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: scenes,
    scenarios: const <ScenarioAsset>[
      ScenarioAsset(
        id: 'scenario_cutscene',
        name: 'Legacy cutscene',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        metadata: <String, String>{
          'authoring.cutsceneSchema': 'cutscene-studio-v0',
        },
      ),
    ],
    cinematics: [
      CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinematic',
        description: 'Camera reveal.',
        mapId: 'map_lab',
        requiredActors: [
          CinematicActorRef(
            actorId: 'actor_professor',
            label: 'Professor',
          ),
        ],
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'step_camera',
              kind: CinematicTimelineStepKind.camera,
              label: 'Camera reveal',
              durationMs: 500,
            ),
            CinematicTimelineStep(
              id: 'step_emote',
              kind: CinematicTimelineStepKind.actorEmote,
              label: 'Professor reacts',
              durationMs: 250,
              actorId: 'actor_professor',
            ),
          ],
        ),
      ),
    ],
  );
}

SceneAsset _sceneReferencing({
  required String id,
  required String name,
  required String nodeId,
  required String nodeTitle,
  required String cinematicId,
}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: nodeId,
          kind: SceneNodeKind.cinematic,
          title: nodeTitle,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
    ),
  );
}

String _readModelSource() {
  return File('lib/src/read_models/cinematics_library_read_model.dart')
      .readAsStringSync();
}
