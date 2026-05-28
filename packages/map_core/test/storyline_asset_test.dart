import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StorylineAsset construction', () {
    test('accepts minimal main draft with default schema and empty structure',
        () {
      final storyline = StorylineAsset(
        id: 'main_story',
        type: StorylineType.main,
        title: 'Main Story',
      );

      expect(storyline.schemaVersion, 1);
      expect(storyline.status, StorylineStatus.draft);
      expect(storyline.chapters, isEmpty);
      expect(storyline.sceneLinks, isEmpty);
      expect(storyline.relationships, isEmpty);
    });

    test('accepts minimal side quest draft', () {
      final storyline = StorylineAsset(
        id: 'side_quest',
        type: StorylineType.sideQuest,
        title: 'Side Quest',
      );

      expect(storyline.type, StorylineType.sideQuest);
      expect(storyline.status, StorylineStatus.draft);
    });

    test('exposes V1 initial and future enum values', () {
      expect(StorylineType.main, isA<StorylineType>());
      expect(StorylineType.sideQuest, isA<StorylineType>());
      expect(StorylineStatus.draft, isA<StorylineStatus>());
      expect(
        StorylineSceneLinkState.placeholder,
        isA<StorylineSceneLinkState>(),
      );
      expect(
        StorylineSceneLinkState.linkedScenario,
        isA<StorylineSceneLinkState>(),
      );
      expect(StorylineEffectType.activateStep, isA<StorylineEffectType>());
      expect(StorylineEffectType.completeStep, isA<StorylineEffectType>());
      expect(StorylineEffectType.unlockStoryline, isA<StorylineEffectType>());
      expect(StorylineType.hiddenEvent, isA<StorylineType>());
      expect(StorylineEffectType.setWorldRule, isA<StorylineEffectType>());
    });
  });

  group('StorylineAsset field validation', () {
    test('rejects blank StorylineAsset id and title', () {
      expect(
        () => StorylineAsset(id: ' ', type: StorylineType.main, title: 'A'),
        _throwsValidation,
      );
      expect(
        () => StorylineAsset(id: 'a', type: StorylineType.main, title: ' '),
        _throwsValidation,
      );
      expect(
        () => StorylineAsset(
          id: 'a',
          schemaVersion: 0,
          type: StorylineType.main,
          title: 'A',
        ),
        _throwsValidation,
      );
    });

    test('rejects blank StorylineChapter id and title', () {
      expect(
        () => StorylineChapter(id: '', title: 'Chapter', order: 0),
        _throwsValidation,
      );
      expect(
        () => StorylineChapter(id: 'chapter', title: ' ', order: 0),
        _throwsValidation,
      );
      expect(
        () => StorylineChapter(id: 'chapter', title: 'Chapter', order: -1),
        _throwsValidation,
      );
    });

    test('rejects blank StorylineStep id and title', () {
      expect(
        () => StorylineStep(id: '', title: 'Step', order: 0),
        _throwsValidation,
      );
      expect(
        () => StorylineStep(id: 'step', title: ' ', order: 0),
        _throwsValidation,
      );
      expect(
        () => StorylineStep(id: 'step', title: 'Step', order: -1),
        _throwsValidation,
      );
    });

    test('rejects blank scene link fields', () {
      expect(
        () => StorylineSceneLink(
          id: '',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: '',
          label: 'Scene',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: '',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
        ),
        _throwsValidation,
      );
    });

    test('rejects blank leaf object fields', () {
      expect(
        () => StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: ' ',
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneOutcomeLink(
          id: '',
          outcomeId: 'outcome',
          effects: [_activateStep()],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneOutcomeLink(
          id: 'outcome-link',
          outcomeId: '',
          effects: [_activateStep()],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineSceneOutcomeLink(
          id: 'outcome-link',
          outcomeId: 'outcome',
          effects: const [],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineEffect(
          type: StorylineEffectType.activateStep,
          targetId: '',
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineAnchor(kind: StorylineAnchorKind.step, targetId: ' '),
        _throwsValidation,
      );
      expect(
        () => StorylineValidationIssue(
          targetRef: '',
          ruleId: 'rule',
          message: 'message',
          severity: StorylineValidationSeverity.error,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineValidationIssue(
          targetRef: 'target',
          ruleId: '',
          message: 'message',
          severity: StorylineValidationSeverity.error,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineValidationIssue(
          targetRef: 'target',
          ruleId: 'rule',
          message: '',
          severity: StorylineValidationSeverity.error,
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineLegacySource(kind: '', sourceId: 'global_story'),
        _throwsValidation,
      );
      expect(
        () => StorylineLegacySource(kind: 'scenario.globalStory', sourceId: ''),
        _throwsValidation,
      );
      expect(
        () => StorylineRelationship(
          id: '',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'source',
          targetStorylineId: 'target',
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineRelationship(
          id: 'rel',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: '',
          targetStorylineId: 'target',
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineRelationship(
          id: 'rel',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'source',
          targetStorylineId: '',
        ),
        _throwsValidation,
      );
    });
  });

  group('StorylineAsset local uniqueness', () {
    test('rejects duplicate chapter ids', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [
            StorylineChapter(id: 'chapter', title: 'One', order: 0),
            StorylineChapter(id: 'chapter', title: 'Two', order: 1),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate step ids across the storyline', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [
            StorylineChapter(
              id: 'chapter-a',
              title: 'A',
              order: 0,
              steps: [StorylineStep(id: 'step', title: 'Step A', order: 0)],
            ),
            StorylineChapter(
              id: 'chapter-b',
              title: 'B',
              order: 1,
              steps: [StorylineStep(id: 'step', title: 'Step B', order: 0)],
            ),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate scene link ids', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [_chapter()],
          sceneLinks: [
            _placeholderSceneLink(id: 'scene'),
            _placeholderSceneLink(id: 'scene'),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate outcome link ids inside scene link', () {
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          order: 0,
          outcomeLinks: [
            StorylineSceneOutcomeLink(
              id: 'outcome-link',
              outcomeId: 'a',
              effects: [_activateStep()],
            ),
            StorylineSceneOutcomeLink(
              id: 'outcome-link',
              outcomeId: 'b',
              effects: [_activateStep()],
            ),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate ids in string lists', () {
      expect(
        () => StorylineStep(
          id: 'step',
          title: 'Step',
          order: 0,
          sceneLinkIds: const ['scene', 'scene'],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineStep(
          id: 'step',
          title: 'Step',
          order: 0,
          expectedOutcomeIds: const ['outcome', 'outcome'],
        ),
        _throwsValidation,
      );
      expect(
        () => StorylineChapter(
          id: 'chapter',
          title: 'Chapter',
          order: 0,
          directSceneLinkIds: const ['scene', 'scene'],
        ),
        _throwsValidation,
      );
      expect(
        () => SideQuestAvailability(
          startAnchor: StorylineAnchor(
            kind: StorylineAnchorKind.step,
            targetId: 'step',
          ),
          requiredOutcomeIds: const ['outcome', 'outcome'],
        ),
        _throwsValidation,
      );
    });

    test('rejects duplicate relationship ids', () {
      expect(
        () => StorylineAsset(
          id: 'side',
          type: StorylineType.sideQuest,
          title: 'Side',
          relationships: [
            _relationship(id: 'rel'),
            _relationship(id: 'rel'),
          ],
        ),
        _throwsValidation,
      );
    });
  });

  group('StorylineAsset internal references', () {
    test('requires scene link chapterId to reference an existing chapter', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          sceneLinks: [_placeholderSceneLink()],
        ),
        _throwsValidation,
      );
    });

    test('requires scene link stepId to reference an existing step', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [_chapter()],
          sceneLinks: [_placeholderSceneLink(stepId: 'missing_step')],
        ),
        _throwsValidation,
      );
    });

    test('requires scene link stepId to belong to the referenced chapter', () {
      expect(
        () => StorylineAsset(
          id: 'story',
          type: StorylineType.main,
          title: 'Story',
          chapters: [
            StorylineChapter(id: 'chapter', title: 'Chapter', order: 0),
            StorylineChapter(
              id: 'other',
              title: 'Other',
              order: 1,
              steps: [StorylineStep(id: 'step', title: 'Step', order: 0)],
            ),
          ],
          sceneLinks: [_placeholderSceneLink(stepId: 'step')],
        ),
        _throwsValidation,
      );
    });

    test('requires inline relationship source to match storyline id', () {
      expect(
        () => StorylineAsset(
          id: 'side',
          type: StorylineType.sideQuest,
          title: 'Side',
          relationships: [
            StorylineRelationship(
              id: 'rel',
              kind: StorylineRelationshipKind.sideQuestUnlockedBy,
              sourceStorylineId: 'other',
              targetStorylineId: 'main',
            ),
          ],
        ),
        _throwsValidation,
      );
    });

    test('rejects relationship with identical source and target', () {
      expect(
        () => StorylineRelationship(
          id: 'rel',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'story',
          targetStorylineId: 'story',
        ),
        _throwsValidation,
      );
    });
  });

  group('StorylineSceneLink state rules', () {
    test('placeholder rejects sceneRef', () {
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.placeholder,
          role: StorylineSceneLinkRole.primary,
          sceneRef: StorylineSceneRef(
            kind: StorylineSceneRefKind.scenario,
            targetId: 'scenario',
          ),
          order: 0,
        ),
        _throwsValidation,
      );
    });

    test('linkedScenario requires scenario sceneRef', () {
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.linkedScenario,
          role: StorylineSceneLinkRole.primary,
          order: 0,
        ),
        _throwsValidation,
      );

      final link = StorylineSceneLink(
        id: 'scene',
        chapterId: 'chapter',
        label: 'Scene',
        state: StorylineSceneLinkState.linkedScenario,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'scenario',
        ),
        order: 0,
      );

      expect(link.sceneRef?.targetId, 'scenario');
    });

    test('needsImplementation rejects sceneRef', () {
      expect(
        () => StorylineSceneLink(
          id: 'scene',
          chapterId: 'chapter',
          label: 'Scene',
          state: StorylineSceneLinkState.needsImplementation,
          role: StorylineSceneLinkRole.primary,
          sceneRef: StorylineSceneRef(
            kind: StorylineSceneRefKind.scenario,
            targetId: 'scenario',
          ),
          order: 0,
        ),
        _throwsValidation,
      );
    });

    test('brokenLink accepts null or stale sceneRef for diagnostics', () {
      final withoutRef = StorylineSceneLink(
        id: 'broken-a',
        chapterId: 'chapter',
        label: 'Broken A',
        state: StorylineSceneLinkState.brokenLink,
        role: StorylineSceneLinkRole.primary,
        order: 0,
      );
      final withRef = StorylineSceneLink(
        id: 'broken-b',
        chapterId: 'chapter',
        label: 'Broken B',
        state: StorylineSceneLinkState.brokenLink,
        role: StorylineSceneLinkRole.primary,
        sceneRef: StorylineSceneRef(
          kind: StorylineSceneRefKind.scenario,
          targetId: 'missing_scenario',
        ),
        order: 1,
      );

      expect(withoutRef.sceneRef, isNull);
      expect(withRef.sceneRef?.targetId, 'missing_scenario');
    });
  });

  group('StorylineAsset immutability', () {
    test('defensively copies constructor lists and maps', () {
      final chapters = [_chapter()];
      final sceneLinks = [_placeholderSceneLink()];
      final metadata = {'key': 'value'};

      final storyline = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        chapters: chapters,
        sceneLinks: sceneLinks,
        metadata: metadata,
      );

      chapters.clear();
      sceneLinks.clear();
      metadata['key'] = 'changed';

      expect(storyline.chapters, hasLength(1));
      expect(storyline.sceneLinks, hasLength(1));
      expect(storyline.metadata['key'], 'value');
    });

    test('exposes unmodifiable collections', () {
      final storyline = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        chapters: [_chapter()],
        sceneLinks: [_placeholderSceneLink()],
        metadata: const {'key': 'value'},
      );

      expect(
        () => storyline.chapters.add(
          StorylineChapter(id: 'other', title: 'Other', order: 1),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => storyline.sceneLinks.add(_placeholderSceneLink(id: 'other')),
        throwsUnsupportedError,
      );
      expect(
        () => storyline.metadata['other'] = 'value',
        throwsUnsupportedError,
      );
    });

    test('supports value equality for equivalent models', () {
      final first = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        chapters: [_chapter()],
        sceneLinks: [_placeholderSceneLink()],
      );
      final second = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        chapters: [_chapter()],
        sceneLinks: [_placeholderSceneLink()],
      );
      final withMetadataA = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        metadata: const {'a': '1', 'b': '2'},
      );
      final withMetadataB = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
        metadata: const {'b': '2', 'a': '1'},
      );

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(withMetadataA, equals(withMetadataB));
      expect(withMetadataA.hashCode, equals(withMetadataB.hashCode));
      expect(first.toString(), contains('story'));
    });
  });

  group('StorylineAsset V1-03 scope guards', () {
    test('does not expose JSON codecs in pure model lot', () {
      final dynamic storyline = StorylineAsset(
        id: 'story',
        type: StorylineType.main,
        title: 'Story',
      );

      expect(() => storyline.toJson(), throwsA(isA<NoSuchMethodError>()));
    });
  });
}

final Matcher _throwsValidation = throwsA(isA<ValidationException>());

StorylineChapter _chapter() {
  return StorylineChapter(
    id: 'chapter',
    title: 'Chapter',
    order: 0,
    steps: [StorylineStep(id: 'step', title: 'Step', order: 0)],
  );
}

StorylineSceneLink _placeholderSceneLink({
  String id = 'scene',
  String? stepId = 'step',
}) {
  return StorylineSceneLink(
    id: id,
    chapterId: 'chapter',
    stepId: stepId,
    label: 'Scene',
    state: StorylineSceneLinkState.placeholder,
    role: StorylineSceneLinkRole.primary,
    order: 0,
  );
}

StorylineEffect _activateStep() {
  return StorylineEffect(
    type: StorylineEffectType.activateStep,
    targetId: 'step',
  );
}

StorylineRelationship _relationship({required String id}) {
  return StorylineRelationship(
    id: id,
    kind: StorylineRelationshipKind.sideQuestUnlockedBy,
    sourceStorylineId: 'side',
    targetStorylineId: 'main',
  );
}
