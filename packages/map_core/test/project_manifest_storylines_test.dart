import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest storylines integration', () {
    test('decodes old project JSON without storylines as empty list', () {
      final manifest = ProjectManifest.fromJson(_minimalProjectJson());

      expect(manifest.storylines, isEmpty);
      expect(manifest.scenarios, isEmpty);
    });

    test('decodes project JSON with main and side quest storylines', () {
      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'storylines': [
          _mainStoryline().toJson(),
          _sideQuestStoryline().toJson(),
        ],
      });

      expect(manifest.storylines, hasLength(2));
      expect(manifest.storylines[0].type, StorylineType.main);
      expect(manifest.storylines[0].title, 'Main Story');
      expect(manifest.storylines[1].type, StorylineType.sideQuest);
      expect(manifest.storylines[1].title, 'Side Quest');
    });

    test('round-trips manifest with storylines through JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        storylines: [_mainStoryline(), _sideQuestStoryline()],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(decoded.storylines, equals(manifest.storylines));
      expect(decoded.toJson()['storylines'], isA<List<dynamic>>());
    });

    test('does not import legacy globalStory scenarios automatically', () {
      final scenario = const ScenarioAsset(
        id: 'legacy_global_story',
        name: 'Legacy Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenarios': [scenario.toJson()],
      });

      expect(manifest.storylines, isEmpty);
      expect(manifest.scenarios, hasLength(1));
      expect(manifest.scenarios.single.scope, ScenarioScope.globalStory);
      expect(manifest.scenarios.single.id, 'legacy_global_story');
    });

    test('does not promote localEventFlow scenario to side quest', () {
      final scenario = const ScenarioAsset(
        id: 'local_event_flow',
        name: 'Local Event Flow',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        nodes: [
          ScenarioNode(id: 'start', type: ScenarioNodeType.start),
        ],
      );
      final manifest = ProjectManifest.fromJson({
        ..._minimalProjectJson(),
        'scenarios': [scenario.toJson()],
      });

      expect(manifest.storylines, isEmpty);
      expect(manifest.scenarios.single.scope, ScenarioScope.localEventFlow);
    });

    test('rejects invalid storylines JSON shape', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'storylines': 'not-a-list',
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'storylines': ['not-an-object'],
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'storylines': [
            {
              'id': 'broken',
              'type': 'unknown',
              'title': 'Broken',
            },
          ],
        }),
        _throwsDecode,
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'storylines': [
            {
              'id': '',
              'type': 'main',
              'title': 'Broken',
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

StorylineAsset _mainStoryline() {
  return StorylineAsset(
    id: 'main_story',
    type: StorylineType.main,
    title: 'Main Story',
  );
}

StorylineAsset _sideQuestStoryline() {
  return StorylineAsset(
    id: 'side_quest',
    type: StorylineType.sideQuest,
    title: 'Side Quest',
  );
}
