import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest cinematics integration', () {
    test('decodes old project JSON without cinematics as empty list', () {
      final manifest = ProjectManifest.fromJson(_minimalProjectJson());

      expect(manifest.cinematics, isEmpty);
      expect(manifest.scenarios, isEmpty);
      expect(manifest.scenes, isEmpty);
    });

    test('decodes cinematics null and empty cinematics as empty list', () {
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'cinematics': null,
        }).cinematics,
        isEmpty,
      );
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'cinematics': <Object?>[],
        }).cinematics,
        isEmpty,
      );
    });

    test('round-trips manifest with cinematics through JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        cinematics: [_cinematic()],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(decoded.cinematics, equals(manifest.cinematics));
      expect(decoded.toJson()['cinematics'], isA<List<dynamic>>());
    });

    test('round-trips cinematic stage context through manifest JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [
          ProjectMapEntry(
            id: 'map_lab',
            name: 'Lab',
            relativePath: 'maps/lab.json',
          ),
        ],
        tilesets: const [],
        cinematics: [
          CinematicAsset(
            id: 'cinematic_intro',
            title: 'Intro cinematic',
            mapId: 'map_lab',
            requiredActors: [
              CinematicActorRef(actorId: 'actor_player', label: 'Joueur'),
            ],
            stageContext: CinematicStageContext(
              backdropMode: CinematicStageBackdropMode.projectMap,
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'actor_player',
                  kind: CinematicActorBindingKind.player,
                ),
              ],
              initialPlacements: [
                CinematicActorInitialPlacement(
                  actorId: 'actor_player',
                  kind: CinematicActorInitialPlacementKind.unset,
                ),
              ],
            ),
            timeline: CinematicTimeline(
              steps: [
                CinematicTimelineStep(
                  id: 'step_wait',
                  kind: CinematicTimelineStepKind.wait,
                  durationMs: 100,
                ),
              ],
            ),
          ),
        ],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);
      final cinematicJson =
          (json['cinematics'] as List<dynamic>).single as Map<String, dynamic>;

      expect(decoded.cinematics, manifest.cinematics);
      expect(cinematicJson, contains('stageContext'));
      expect(cinematicJson['stageContext'], isNot(contains('mapId')));
    });

    test('keeps scenarios and scenes independent from cinematics', () {
      final scenario = const ScenarioAsset(
        id: 'legacy_scenario',
        name: 'Legacy Scenario',
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      final scene = _scene();

      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenarios': [scenario.toJson()],
        'scenes': [scene.toJson()],
        'cinematics': [_cinematic().toJson()],
      });

      expect(manifest.cinematics.single.id, 'cinematic_intro');
      expect(manifest.scenarios.single.id, 'legacy_scenario');
      expect(manifest.scenes.single.id, 'scene_intro');
    });

    test('rejects invalid cinematics JSON shape', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'cinematics': 'not-a-list',
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'cinematics': ['not-an-object'],
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'cinematics': [
            {
              'id': '',
              'title': 'Broken',
              'timeline': {'steps': <Object?>[]},
            },
          ],
        }),
        _throwsDecode,
      );
    });
  });
}

final Matcher _throwsDecode = throwsA(
  anyOf(
      isA<FormatException>(), isA<ArgumentError>(), isA<ValidationException>()),
);

Map<String, dynamic> _minimalProjectJson() {
  return {
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_intro',
    title: 'Intro cinematic',
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

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_intro',
    name: 'Intro scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}
