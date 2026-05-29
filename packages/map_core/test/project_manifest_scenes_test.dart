import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest scenes integration', () {
    test('decodes old project JSON without scenes as empty list', () {
      final manifest = ProjectManifest.fromJson(_minimalProjectJson());

      expect(manifest.scenes, isEmpty);
      expect(manifest.scenarios, isEmpty);
      expect(manifest.storylines, isEmpty);
    });

    test('decodes scenes null and empty scenes as empty list', () {
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': null,
        }).scenes,
        isEmpty,
      );
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': <Object?>[],
        }).scenes,
        isEmpty,
      );
    });

    test('decodes project JSON with a SceneAsset', () {
      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenes': [_scene().toJson()],
      });

      expect(manifest.scenes, hasLength(1));
      expect(manifest.scenes.single.id, 'scene_intro');
      expect(manifest.scenes.single.graph.nodes, hasLength(2));
    });

    test('round-trips manifest with scenes through JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        scenes: [_scene()],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(decoded.scenes, equals(manifest.scenes));
      expect(decoded.toJson()['scenes'], isA<List<dynamic>>());
    });

    test('keeps scenarios and storylines independent from scenes', () {
      final scenario = const ScenarioAsset(
        id: 'legacy_scenario',
        name: 'Legacy Scenario',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      final storyline = StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Main Story',
      );

      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenarios': [scenario.toJson()],
        'storylines': [storyline.toJson()],
        'scenes': [_scene().toJson()],
      });

      expect(manifest.scenes, hasLength(1));
      expect(manifest.scenarios, hasLength(1));
      expect(manifest.scenarios.single.id, 'legacy_scenario');
      expect(manifest.storylines, hasLength(1));
      expect(manifest.storylines.single.id, 'story_main');
    });

    test('rejects invalid scenes JSON shape', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': 'not-a-list',
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': ['not-an-object'],
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'scenes': [
            {
              'id': '',
              'name': 'Broken',
              'graph': _graphJson(),
            },
          ],
        }),
        _throwsDecode,
      );
    });
  });
}

final Matcher _throwsDecode = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

Map<String, dynamic> _minimalProjectJson() {
  return {
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
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

Map<String, dynamic> _graphJson() {
  return {
    'startNodeId': 'node_start',
    'nodes': [
      {'id': 'node_start', 'kind': 'start'},
      {'id': 'node_end', 'kind': 'end'},
    ],
    'edges': [
      {
        'id': 'edge_start_end',
        'fromNodeId': 'node_start',
        'fromPortId': 'completed',
        'toNodeId': 'node_end',
        'kind': 'default',
      },
    ],
  };
}
