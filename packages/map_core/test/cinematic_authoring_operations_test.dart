import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Cinematic authoring operations', () {
    test('addCinematicAsset adds an asset without mutating project', () {
      final project = _project();
      final cinematic = _cinematic(id: 'cinematic_intro');

      final result = addCinematicAsset(project, cinematic);

      expect(project.cinematics, isEmpty);
      expect(result.updatedProject.cinematics, [cinematic]);
      expect(result.cinematic, cinematic);
      expect(result.updatedProject.scenarios, project.scenarios);
      expect(result.updatedProject.scenes, project.scenes);
    });

    test('addCinematicAsset refuses duplicate ids', () {
      final project = _project(cinematics: [_cinematic(id: 'cinematic_intro')]);

      expect(
        () => addCinematicAsset(project, _cinematic(id: 'cinematic_intro')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateCinematicAsset replaces an existing asset only', () {
      final existing = _cinematic(id: 'cinematic_intro');
      final other = _cinematic(id: 'cinematic_other', title: 'Other');
      final project = _project(cinematics: [existing, other]);
      final updated = _cinematic(
        id: 'cinematic_intro',
        title: 'Updated intro',
        description: 'Updated description',
      );

      final result = updateCinematicAsset(project, updated);

      expect(result.updatedProject.cinematics, [updated, other]);
      expect(result.cinematic, updated);
      expect(project.cinematics, [existing, other]);
    });

    test('removeCinematicAsset removes unused asset', () {
      final cinematic = _cinematic(id: 'cinematic_intro');
      final project = _project(cinematics: [cinematic]);

      final result = removeCinematicAsset(project, 'cinematic_intro');

      expect(result.removedCinematic, cinematic);
      expect(result.updatedProject.cinematics, isEmpty);
      expect(project.cinematics, [cinematic]);
    });

    test('removeCinematicAsset refuses a cinematic referenced by a Scene', () {
      final project = _project(
        cinematics: [_cinematic(id: 'cinematic_intro')],
        scenes: [_sceneReferencingCinematic('cinematic_intro')],
      );

      expect(
        () => removeCinematicAsset(project, 'cinematic_intro'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('replaceCinematics validates duplicate ids and preserves other data',
        () {
      final scenario = const ScenarioAsset(
        id: 'scenario_legacy',
        name: 'Legacy',
        entryNodeId: 'start',
      );
      final scene = _sceneReferencingCinematic('cinematic_intro');
      final project = _project(scenarios: [scenario], scenes: [scene]);
      final cinematic = _cinematic(id: 'cinematic_intro');

      final updated = replaceCinematics(project, [cinematic]);

      expect(updated.cinematics, [cinematic]);
      expect(updated.scenarios, [scenario]);
      expect(updated.scenes, [scene]);
      expect(
        () => replaceCinematics(project, [cinematic, cinematic]),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('findCinematicById returns matching asset or null', () {
      final cinematic = _cinematic(id: 'cinematic_intro');
      final project = _project(cinematics: [cinematic]);

      expect(findCinematicById(project, 'cinematic_intro'), cinematic);
      expect(findCinematicById(project, 'missing'), isNull);
    });
  });
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const [],
  List<ScenarioAsset> scenarios = const [],
  List<SceneAsset> scenes = const [],
}) {
  return ProjectManifest(
    name: 'Cinematic authoring test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
    scenarios: scenarios,
    scenes: scenes,
  );
}

CinematicAsset _cinematic({
  required String id,
  String title = 'Intro cinematic',
  String? description,
}) {
  return CinematicAsset(
    id: id,
    title: title,
    description: description,
    timeline: CinematicTimeline(
      steps: [
        CinematicTimelineStep(
          id: 'step_wait',
          kind: CinematicTimelineStepKind.wait,
          durationMs: 100,
        ),
      ],
    ),
  );
}

SceneAsset _sceneReferencingCinematic(String cinematicId) {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_cinematic',
          kind: SceneNodeKind.cinematic,
          payload: SceneCinematicPayload(cinematicId: cinematicId),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_cinematic',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_cinematic',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_cinematic_end',
          fromNodeId: 'node_cinematic',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.cinematicCompleted,
        ),
      ],
    ),
  );
}
