import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildLegacyGlobalStoryImportPreview', () {
    test('reports no legacy globalStory when manifest has none', () {
      final preview = buildLegacyGlobalStoryImportPreview(_manifest());

      expect(preview.candidates, isEmpty);
      expect(preview.hasCandidates, isFalse);
      expect(preview.issues, _containsRule('noLegacyGlobalStoryFound'));
    });

    test('builds a minimal main draft candidate from globalStory', () {
      final scenario = _globalStory(
        id: 'global_story',
        name: 'Audit Global Story',
        description: 'Legacy description',
      );
      final manifest = _manifest(scenarios: [scenario]);
      final before = jsonEncode(manifest.toJson());

      final preview = buildLegacyGlobalStoryImportPreview(manifest);
      final after = jsonEncode(manifest.toJson());

      expect(preview.candidates, hasLength(1));
      final candidate = preview.candidates.single;
      expect(candidate.sourceScenarioId, 'global_story');
      expect(candidate.sourceScenarioName, 'Audit Global Story');
      expect(candidate.draftStoryline.id, 'legacy_global_story');
      expect(candidate.draftStoryline.type, StorylineType.main);
      expect(candidate.draftStoryline.status, StorylineStatus.draft);
      expect(candidate.draftStoryline.title, 'Audit Global Story');
      expect(candidate.draftStoryline.description, 'Legacy description');
      expect(candidate.draftStoryline.chapters, isEmpty);
      expect(candidate.draftStoryline.legacySource, isNotNull);
      expect(
          candidate.draftStoryline.legacySource!.kind, 'scenario.globalStory');
      expect(candidate.draftStoryline.legacySource!.sourceId, 'global_story');
      expect(candidate.issues, _containsRule('missingGlobalStoryMetadata'));
      expect(candidate.issues, _containsRule('missingStepStudioMetadata'));
      expect(after, before);
    });

    test('ignores localEventFlow and never creates a side quest', () {
      final manifest = _manifest(
        scenarios: [
          _localEventFlow(id: 'local_story_like_flow', name: 'Looks Narrative'),
        ],
      );

      final preview = buildLegacyGlobalStoryImportPreview(manifest);

      expect(preview.candidates, isEmpty);
      expect(preview.issues, _containsRule('localEventFlowIgnored'));
      expect(
        preview.candidates.where(
          (candidate) =>
              candidate.draftStoryline.type == StorylineType.sideQuest,
        ),
        isEmpty,
      );
    });

    test('imports only globalStory when localEventFlow also exists', () {
      final manifest = _manifest(
        scenarios: [
          _globalStory(id: 'main_global', name: 'Main Global'),
          _localEventFlow(id: 'local_flow', name: 'Local Flow'),
        ],
      );

      final preview = buildLegacyGlobalStoryImportPreview(manifest);

      expect(preview.candidates, hasLength(1));
      expect(preview.candidates.single.sourceScenarioId, 'main_global');
      expect(preview.issues, _containsRule('localEventFlowIgnored'));
      expect(preview.candidates.single.draftStoryline.type, StorylineType.main);
    });

    test('builds one candidate per globalStory and reports multiples', () {
      final preview = buildLegacyGlobalStoryImportPreview(
        _manifest(
          scenarios: [
            _globalStory(id: 'global_one', name: 'Global One'),
            _globalStory(id: 'global_two', name: 'Global Two'),
          ],
        ),
      );

      expect(preview.candidates, hasLength(2));
      expect(preview.issues, _containsRule('multipleLegacyGlobalStoriesFound'));
      expect(
        preview.candidates.map((candidate) => candidate.draftStoryline.id),
        containsAll(['legacy_global_one', 'legacy_global_two']),
      );
    });

    test('previews with existing storylines without mutating them', () {
      final existing = StorylineAsset(
        id: 'existing_story',
        type: StorylineType.main,
        title: 'Existing',
      );
      final manifest = _manifest(
        scenarios: [_globalStory(id: 'global_story', name: 'Global')],
        storylines: [existing],
      );
      final before = jsonEncode(manifest.toJson());

      final preview = buildLegacyGlobalStoryImportPreview(manifest);
      final after = jsonEncode(manifest.toJson());

      expect(preview.candidates, hasLength(1));
      expect(preview.issues, _containsRule('existingStorylinesPresent'));
      expect(manifest.storylines.single, same(existing));
      expect(after, before);
    });

    test('reports candidate id collision without silently changing id', () {
      final existing = StorylineAsset(
        id: 'legacy_global_story',
        type: StorylineType.main,
        title: 'Existing',
      );

      final preview = buildLegacyGlobalStoryImportPreview(
        _manifest(
          scenarios: [_globalStory(id: 'global_story', name: 'Global')],
          storylines: [existing],
        ),
      );

      expect(preview.candidates, hasLength(1));
      expect(
          preview.candidates.single.draftStoryline.id, 'legacy_global_story');
      expect(
        preview.candidates.single.issues,
        _containsRule('candidateIdAlreadyExists'),
      );
      expect(preview.hasBlockingIssues, isTrue);
    });

    test('imports legacy chapters and attached steps when metadata is valid',
        () {
      final manifest = _manifest(
        scenarios: [
          _globalStory(
            id: 'global_story',
            name: 'Global',
            metadata: {
              'authoring.globalStoryStudioDocument': _globalStoryDocumentJson(
                chapters: [
                  {
                    'id': 'chapter_intro',
                    'name': 'Intro chapter',
                    'description': 'Chapter description',
                    'order': 2,
                    'stepIds': ['step_intro', 'missing_step'],
                  },
                ],
              ),
              'authoring.stepStudioDocument': _stepStudioDocumentJson(
                steps: [
                  {
                    'id': 'step_intro',
                    'name': 'Intro step',
                    'description': 'Step description',
                    'order': 3,
                  },
                  {
                    'id': 'step_unassigned',
                    'name': 'Unassigned step',
                    'description': '',
                    'order': 4,
                  },
                ],
              ),
            },
            declaredOutcomes: ['legacy.outcome'],
          ),
        ],
      );
      final before = jsonEncode(manifest.toJson());

      final preview = buildLegacyGlobalStoryImportPreview(manifest);
      final after = jsonEncode(manifest.toJson());

      final storyline = preview.candidates.single.draftStoryline;
      expect(storyline.chapters, hasLength(1));
      final chapter = storyline.chapters.single;
      expect(chapter.id, 'chapter_intro');
      expect(chapter.title, 'Intro chapter');
      expect(chapter.description, 'Chapter description');
      expect(chapter.order, 2);
      expect(chapter.steps, hasLength(1));
      expect(chapter.steps.single.id, 'step_intro');
      expect(chapter.steps.single.title, 'Intro step');
      expect(chapter.steps.single.description, 'Step description');
      expect(chapter.steps.single.order, 3);
      expect(preview.candidates.single.issues,
          _containsRule('missingReferencedStep'));
      expect(preview.candidates.single.issues,
          _containsRule('unassignedLegacyStep'));
      expect(preview.candidates.single.issues,
          _containsRule('declaredOutcomesNotMapped'));
      expect(after, before);
    });

    test('reports invalid legacy metadata without throwing', () {
      final preview = buildLegacyGlobalStoryImportPreview(
        _manifest(
          scenarios: [
            _globalStory(
              id: 'global_story',
              name: 'Global',
              metadata: const {
                'authoring.globalStoryStudioDocument': '[',
                'authoring.stepStudioDocument': '[',
              },
            ),
          ],
        ),
      );

      expect(preview.candidates, hasLength(1));
      expect(preview.candidates.single.draftStoryline.chapters, isEmpty);
      expect(preview.candidates.single.issues,
          _containsRule('invalidGlobalStoryMetadata'));
      expect(preview.candidates.single.issues,
          _containsRule('invalidStepStudioMetadata'));
    });
  });
}

Matcher _containsRule(String ruleId) {
  return contains(
    isA<StorylineValidationIssue>().having(
      (issue) => issue.ruleId,
      'ruleId',
      ruleId,
    ),
  );
}

ProjectManifest _manifest({
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<StorylineAsset> storylines = const <StorylineAsset>[],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    scenarios: scenarios,
    storylines: storylines,
  );
}

ScenarioAsset _globalStory({
  required String id,
  required String name,
  String description = '',
  Map<String, String> metadata = const <String, String>{},
  List<String> declaredOutcomes = const <String>[],
}) {
  return ScenarioAsset(
    id: id,
    name: name,
    description: description,
    scope: ScenarioScope.globalStory,
    entryNodeId: 'start',
    declaredOutcomes: declaredOutcomes,
    nodes: const [ScenarioNode(id: 'start', type: ScenarioNodeType.start)],
    metadata: metadata,
  );
}

ScenarioAsset _localEventFlow({
  required String id,
  required String name,
}) {
  return ScenarioAsset(
    id: id,
    name: name,
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'start',
    nodes: const [ScenarioNode(id: 'start', type: ScenarioNodeType.start)],
  );
}

String _globalStoryDocumentJson(
    {required List<Map<String, Object?>> chapters}) {
  return jsonEncode({
    'schemaVersion': 'global_story_studio_v1.1',
    'globalStoryScenarioId': 'global_story',
    'entryStepId': '',
    'nodes': <Object?>[],
    'chapters': chapters,
  });
}

String _stepStudioDocumentJson({required List<Map<String, Object?>> steps}) {
  return jsonEncode({
    'schemaVersion': 'step_studio_v1',
    'globalStoryScenarioId': 'global_story',
    'steps': steps,
  });
}
