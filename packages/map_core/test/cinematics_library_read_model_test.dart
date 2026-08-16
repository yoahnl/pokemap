import 'dart:io';

import 'package:test/test.dart';
import 'package:map_core/map_core.dart';

void main() {
  group('buildCinematicsLibraryReadModel', () {
    test('lists only canonical CinematicAsset entries', () {
      final project = _projectWithCinematics();

      final readModel = buildCinematicsLibraryReadModel(project);

      expect(readModel.canonicalEntries, hasLength(1));
      expect(readModel.metrics.canonicalCount, 1);

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

      expect(readModel.entryById('scenario_cutscene'), isNull);
    });

    test('attaches diagnostics and reports empty timeline metrics', () {
      final project = ProjectManifest(
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

    test('reports non-canonical Scene references as unknown', () {
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

      expect(readModel.metrics.referencedCount, 1);
      expect(readModel.unknownUsages, hasLength(2));
      expect(
        readModel.unknownUsages.map((usage) => usage.sceneId),
        containsAll(['scene_bridge', 'scene_unknown']),
      );
      expect(
        readModel.unknownUsages.map((usage) => usage.referenceStatus),
        everyElement(
        CinematicsLibraryReferenceStatus.unknown,
        ),
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

    test('searches sorts and groups canonical assets with human labels', () {
      final project = _projectWithCinematics(
        extraCinematics: [
          CinematicAsset(
            id: 'cinematic_archive',
            title: 'Retour du rival',
            storylineId: 'story_main',
            chapterId: 'chapter_port',
            mapId: 'map_lab',
            tags: const ['rival', 'port'],
            metadata: const {cinematicLibraryArchivedMetadataKey: 'true'},
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'wait_archive',
                  kind: CinematicTimelineStepKind.wait,
                  durationMs: 1200,
                ),
              ],
            ),
          ),
        ],
        storylines: [
          StorylineAsset(
            id: 'story_main',
            type: StorylineType.main,
            title: 'Brume principale',
            chapters: [
              StorylineChapter(
                id: 'chapter_port',
                title: 'Le port',
                order: 0,
              ),
            ],
          ),
        ],
      );

      final readModel = buildCinematicsLibraryReadModel(project);
      final archived = readModel.queryEntries(
        const CinematicsLibraryQuery(
          searchText: 'rival port',
          visibility: CinematicsLibraryVisibility.archived,
          sort: CinematicsLibrarySort.durationDescending,
        ),
      );

      expect(archived, hasLength(1));
      expect(archived.single.mapLabel, 'Lab map');
      expect(archived.single.storylineTitle, 'Brume principale');
      expect(archived.single.chapterTitle, 'Le port');
      expect(archived.single.isArchived, isTrue);

      final groups = readModel.groupEntries(
        const CinematicsLibraryQuery(
          visibility: CinematicsLibraryVisibility.archived,
        ),
      );
      expect(groups, hasLength(1));
      expect(groups.single.storylineLabel, 'Brume principale');
      expect(groups.single.chapterLabel, 'Le port');
      expect(groups.single.locationLabel, 'Lab map');
      expect(groups.single.entries.single.id, 'cinematic_archive');
    });

    test('exposes parent Scene outcomes for navigable usages', () {
      final project = _projectWithCinematics(
        scenes: [
          _sceneReferencing(
            id: 'scene_canonical',
            name: 'Canonical scene',
            nodeId: 'node_cinematic',
            nodeTitle: 'Play intro',
            cinematicId: 'cinematic_intro',
            outcomeLabels: const ['Victoire', 'Échec'],
          ),
        ],
      );

      final usage = buildCinematicsLibraryReadModel(project)
          .canonicalEntries
          .single
          .usages
          .single;

      expect(usage.outcomeLabels, ['Victoire', 'Échec']);
    });
  });
}

ProjectManifest _projectWithCinematics({
  List<SceneAsset> scenes = const <SceneAsset>[],
  List<CinematicAsset> extraCinematics = const <CinematicAsset>[],
  List<StorylineAsset> storylines = const <StorylineAsset>[],
}) {
  return ProjectManifest(
    name: 'cinematic_project',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(id: 'map_lab', name: 'Lab map', relativePath: 'lab.json'),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    storylines: storylines,
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
      ...extraCinematics,
    ],
  );
}

SceneAsset _sceneReferencing({
  required String id,
  required String name,
  required String nodeId,
  required String nodeTitle,
  required String cinematicId,
  List<String> outcomeLabels = const <String>[],
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
      edges: [
        for (var index = 0; index < outcomeLabels.length; index++)
          SceneEdge(
            id: 'edge_outcome_$index',
            fromNodeId: nodeId,
            fromPortId: 'outcome_$index',
            toNodeId: 'node_end',
            kind: SceneEdgeKind.cinematicCompleted,
            label: outcomeLabels[index],
          ),
      ],
    ),
  );
}

String _readModelSource() {
  return File('lib/src/read_models/cinematics_library_read_model.dart')
      .readAsStringSync();
}
