import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StorylineAsset JSON roundtrip', () {
    test('round-trips minimal main draft', () {
      final storyline = StorylineAsset(
        id: 'main_story',
        type: StorylineType.main,
        title: 'Main Story',
      );

      final json = storyline.toJson();
      final decoded = StorylineAsset.fromJson(json);

      expect(decoded, equals(storyline));
      expect(json['type'], 'main');
      expect(json['status'], 'draft');
      expect(json['chapters'], isA<List<dynamic>>());
      expect(json['sceneLinks'], isA<List<dynamic>>());
      expect(json['relationships'], isA<List<dynamic>>());
      expect(json['metadata'], isA<Map<String, String>>());
    });

    test('round-trips minimal side quest draft', () {
      final storyline = StorylineAsset(
        id: 'side_story',
        type: StorylineType.sideQuest,
        title: 'Side Story',
      );

      expect(StorylineAsset.fromJson(storyline.toJson()), equals(storyline));
    });

    test('round-trips complete authoring shape', () {
      final storyline = _completeStoryline();

      final json = storyline.toJson();
      final decoded = StorylineAsset.fromJson(json);

      expect(decoded, equals(storyline));
      expect(
        decoded.chapters.single.steps.single.entryCondition?.type,
        ScriptConditionType.flagIsSet,
      );
      expect(
        decoded.relationships.single.availability?.availabilityCondition?.type,
        ScriptConditionType.flagIsSet,
      );
    });
  });

  group('StorylineAsset JSON enum strings', () {
    test('uses stable lowerCamel strings and never enum indexes', () {
      final json = _completeStoryline().toJson();
      final sceneLinks = json['sceneLinks'] as List<dynamic>;
      final linkedScene = sceneLinks[1] as Map<String, dynamic>;
      final sceneRef = linkedScene['sceneRef'] as Map<String, dynamic>;
      final outcomeLinks = linkedScene['outcomeLinks'] as List<dynamic>;
      final outcomeLink = outcomeLinks.single as Map<String, dynamic>;
      final effects = outcomeLink['effects'] as List<dynamic>;
      final effect = effects.first as Map<String, dynamic>;
      final relationships = json['relationships'] as List<dynamic>;
      final relationship = relationships.single as Map<String, dynamic>;
      final availability = relationship['availability'] as Map<String, dynamic>;
      final endAnchor = availability['endAnchor'] as Map<String, dynamic>;

      expect(json['type'], 'sideQuest');
      expect(json['status'], 'active');
      expect(linkedScene['state'], 'linkedScenario');
      expect(linkedScene['role'], 'branch');
      expect(sceneRef['kind'], 'scenario');
      expect(effect['type'], 'activateStep');
      expect(relationship['kind'], 'sideQuestAvailableDuring');
      expect(endAnchor['kind'], 'sceneOutcome');
      expect(json['type'], isNot(isA<int>()));
      expect(linkedScene['state'], isNot(isA<int>()));
      expect(effect['type'], isNot(isA<int>()));
    });
  });

  group('StorylineAsset JSON defaults', () {
    test('decodes defaults from minimal JSON', () {
      final decoded = StorylineAsset.fromJson({
        'id': 'story',
        'type': 'main',
        'title': 'Story',
      });

      expect(decoded.schemaVersion, 1);
      expect(decoded.status, StorylineStatus.draft);
      expect(decoded.chapters, isEmpty);
      expect(decoded.sceneLinks, isEmpty);
      expect(decoded.relationships, isEmpty);
      expect(decoded.metadata, isEmpty);
    });
  });

  group('StorylineAsset invalid JSON', () {
    test('rejects unknown or mistyped top-level fields', () {
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'unknown',
          'title': 'Story',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'main',
          'status': 'unknown',
          'title': 'Story',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({'type': 'main', 'title': 'Story'}),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({'id': 'story', 'title': 'Story'}),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({'id': 'story', 'type': 'main'}),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'schemaVersion': '1',
          'type': 'main',
          'title': 'Story',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'main',
          'title': 'Story',
          'chapters': 'not-list',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'main',
          'title': 'Story',
          'metadata': 'not-map',
        }),
        _throwsFormat,
      );
      expect(
        () => StorylineAsset.fromJson({
          'id': 'story',
          'type': 'main',
          'title': 'Story',
          'metadata': {'ok': 1},
        }),
        _throwsFormat,
      );
    });

    test('rejects unknown nested enum values', () {
      final invalidSceneRef = _completeStoryline().toJson();
      final sceneLinks = invalidSceneRef['sceneLinks'] as List<dynamic>;
      final linkedScene = sceneLinks[1] as Map<String, dynamic>;
      final sceneRef = linkedScene['sceneRef'] as Map<String, dynamic>;
      sceneRef['kind'] = 'dialogue';

      expect(() => StorylineAsset.fromJson(invalidSceneRef), _throwsFormat);

      final invalidEffect = _completeStoryline().toJson();
      final invalidEffectSceneLinks = invalidEffect['sceneLinks'] as List;
      final invalidEffectScene =
          invalidEffectSceneLinks[1] as Map<String, dynamic>;
      final outcomeLinks = invalidEffectScene['outcomeLinks'] as List;
      final outcomeLink = outcomeLinks.single as Map<String, dynamic>;
      final effects = outcomeLink['effects'] as List;
      final effect = effects.first as Map<String, dynamic>;
      effect['type'] = 'unknownEffect';

      expect(() => StorylineAsset.fromJson(invalidEffect), _throwsFormat);
    });
  });

  group('StorylineAsset JSON constructor validation', () {
    test('rejects duplicate chapter ids during decode', () {
      final json = _completeStoryline().toJson();
      json['chapters'] = [
        (json['chapters'] as List).single,
        (json['chapters'] as List).single,
      ];

      expect(() => StorylineAsset.fromJson(json), _throwsDecode);
    });

    test('rejects scene link references to missing chapter or step', () {
      final missingChapter = _completeStoryline().toJson();
      final missingChapterSceneLinks = missingChapter['sceneLinks'] as List;
      final sceneLink = missingChapterSceneLinks.first as Map<String, dynamic>;
      sceneLink['chapterId'] = 'missing';

      expect(() => StorylineAsset.fromJson(missingChapter), _throwsDecode);

      final missingStep = _completeStoryline().toJson();
      final missingStepSceneLinks = missingStep['sceneLinks'] as List;
      final missingStepLink =
          missingStepSceneLinks.first as Map<String, dynamic>;
      missingStepLink['stepId'] = 'missing';

      expect(() => StorylineAsset.fromJson(missingStep), _throwsDecode);
    });

    test('rejects invalid scene link state combinations', () {
      final placeholderWithRef = _completeStoryline().toJson();
      final placeholderSceneLinks = placeholderWithRef['sceneLinks'] as List;
      final placeholder = placeholderSceneLinks.first as Map<String, dynamic>;
      placeholder['sceneRef'] = {
        'kind': 'scenario',
        'targetId': 'scenario',
      };

      expect(() => StorylineAsset.fromJson(placeholderWithRef), _throwsDecode);

      final linkedWithoutRef = _completeStoryline().toJson();
      final linkedSceneLinks = linkedWithoutRef['sceneLinks'] as List;
      final linked = linkedSceneLinks[1] as Map<String, dynamic>;
      linked.remove('sceneRef');

      expect(() => StorylineAsset.fromJson(linkedWithoutRef), _throwsDecode);
    });

    test('rejects inline relationship source mismatch', () {
      final json = _completeStoryline().toJson();
      final relationships = json['relationships'] as List;
      final relationship = relationships.single as Map<String, dynamic>;
      relationship['sourceStorylineId'] = 'other_story';

      expect(() => StorylineAsset.fromJson(json), _throwsDecode);
    });
  });
}

final Matcher _throwsFormat = throwsA(isA<FormatException>());
final Matcher _throwsDecode = throwsA(
  anyOf(isA<FormatException>(), isA<ValidationException>()),
);

StorylineAsset _completeStoryline() {
  return StorylineAsset(
    id: 'side_story',
    schemaVersion: 1,
    type: StorylineType.sideQuest,
    status: StorylineStatus.active,
    title: 'Side Story',
    description: 'Optional branch.',
    sortOrder: 2,
    locale: 'fr',
    chapters: [
      StorylineChapter(
        id: 'chapter_1',
        title: 'Chapter One',
        description: 'Chapter description.',
        order: 0,
        directSceneLinkIds: const ['scene_placeholder'],
        status: StorylineStatus.active,
        authorNotes: 'Chapter notes.',
        metadata: const {'chapterKey': 'chapterValue'},
        steps: [
          StorylineStep(
            id: 'step_1',
            title: 'Find the clue',
            description: 'Step description.',
            order: 0,
            entryCondition: ScriptConditionFactory.flagIsSet('side.started'),
            completionCondition:
                ScriptConditionFactory.eventIsConsumed('event_clue'),
            sceneLinkIds: const ['scene_placeholder', 'scene_linked'],
            expectedOutcomeIds: const ['outcome_a'],
            status: StorylineStatus.active,
            authorNotes: 'Step notes.',
            metadata: const {'stepKey': 'stepValue'},
          ),
        ],
      ),
    ],
    sceneLinks: [
      StorylineSceneLink(
        id: 'scene_placeholder',
        chapterId: 'chapter_1',
        stepId: 'step_1',
        label: 'Placeholder Scene',
        state: StorylineSceneLinkState.placeholder,
        role: StorylineSceneLinkRole.setup,
        order: 0,
        expectedOutcomeIds: const ['outcome_planned'],
        authorNotes: 'Placeholder notes.',
        metadata: const {'placeholderKey': 'placeholderValue'},
      ),
      StorylineSceneLink(
        id: 'scene_linked',
        chapterId: 'chapter_1',
        stepId: 'step_1',
        label: 'Linked Scene',
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.branch,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'scenario_intro',
        ),
        order: 1,
        expectedOutcomeIds: const ['outcome_a'],
        outcomeLinks: [
          StorylineSceneOutcomeLink(
            id: 'outcome_link',
            outcomeId: 'outcome_a',
            label: 'Success',
            effects: [
              StorylineEffect(
                type: StorylineEffectType.activateStep,
                targetId: 'step_2',
              ),
              StorylineEffect(
                type: StorylineEffectType.completeStep,
                targetId: 'step_1',
              ),
              StorylineEffect(
                type: StorylineEffectType.unlockStoryline,
                targetId: 'main_story',
              ),
            ],
            notes: 'Outcome notes.',
            metadata: const {'outcomeKey': 'outcomeValue'},
          ),
        ],
        authorNotes: 'Linked notes.',
        metadata: const {'sceneKey': 'sceneValue'},
      ),
    ],
    relationships: [
      StorylineRelationship(
        id: 'rel_1',
        kind: StorylineRelationshipKind.sideQuestAvailableDuring,
        sourceStorylineId: 'side_story',
        targetStorylineId: 'main_story',
        anchor: StorylineAnchor(
          kind: StorylineAnchorKind.step,
          targetId: 'step_1',
        ),
        availability: SideQuestAvailability(
          startAnchor: StorylineAnchor(
            kind: StorylineAnchorKind.chapter,
            targetId: 'chapter_1',
          ),
          endAnchor: StorylineAnchor(
            kind: StorylineAnchorKind.sceneOutcome,
            targetId: 'outcome_a',
          ),
          availabilityCondition:
              ScriptConditionFactory.flagIsSet('main.chapter_1'),
          expiresCondition: ScriptConditionFactory.flagIsUnset('main.ended'),
          requiredOutcomeIds: const ['outcome_a'],
        ),
        condition: ScriptConditionFactory.playerOnMap('harbor'),
        notes: 'Relationship notes.',
        metadata: const {'relationshipKey': 'relationshipValue'},
      ),
    ],
    legacySource: StorylineLegacySource(
      kind: 'scenario.globalStory',
      sourceId: 'legacy_global',
      metadata: const {'legacyKey': 'legacyValue'},
    ),
    authorNotes: 'Story notes.',
    metadata: const {'storyKey': 'storyValue'},
  );
}
