import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft_fact_identity.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'story_draft_fixtures.dart';

const _old = 'fact_nouveau_jalon';

StorylineAsset _story(String factId) => StorylineAsset(
  id: 'main',
  type: StorylineType.main,
  title: 'Trame',
  chapters: [
    StorylineChapter(
      id: 'chapter',
      title: 'Chapitre',
      order: 0,
      steps: [
        StorylineStep(
          id: 'milestone',
          title: 'Jalon',
          order: 0,
          completionCondition: ScriptConditionFactory.factEquals(
            factId,
            const NarrativeValue.boolean(true),
          ),
        ),
      ],
    ),
  ],
);

NarrativeEventRecord _event(String factId) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: eventId(1),
        name: 'Parler',
        source: NarrativeEventSourceRef.mapEnter('map'),
        conditions: [NarrativeEventCondition.fact(factId, true)],
        sceneId: 'scene',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 1,
      ),
      enabled: false,
    );

SceneAsset _scene(String factId) => SceneAsset(
  id: 'scene',
  name: 'Scène',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'set',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: factId, value: true),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    edges: [
      SceneEdge(
        id: 'start-set',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'set',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'set-end',
        fromNodeId: 'set',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);

WorldRuleDefinition _rule(String factId) => WorldRuleDefinition(
  id: 'gate',
  label: 'Porte',
  source: WorldRuleSource(
    kind: WorldRuleSourceKind.fact,
    sourceId: factId,
    predicate: WorldRuleSourcePredicate.isTrue,
  ),
  target: const WorldRuleTarget(
    kind: WorldRuleTargetKind.narrativeEvent,
    mapId: 'map',
    eventId: 'event',
  ),
  effect: const WorldRuleEffect(kind: WorldRuleEffectKind.eventEnabled),
);

StoryDialogueSource _line(String factId) => dialogue(
  'talk',
  'Tu as {{ fact.$factId }} pièces, pas {{ fact.${factId}_2 }}.',
);

StoryDraft _draftCiting(String label) {
  final draft = StoryDraft();
  for (final kind in StoryDraftKind.values) {
    draft.load(kind, switch (kind) {
      StoryDraftKind.event => eventId(1),
      StoryDraftKind.scene => 'scene',
      StoryDraftKind.dialogue => 'talk',
      StoryDraftKind.fact => _old,
      StoryDraftKind.story => 'main',
      StoryDraftKind.worldRule => 'gate',
    }, null);
  }
  draft
    ..put(StoryDraftKind.fact, fact(_old, label))
    ..put(StoryDraftKind.story, _story(_old))
    ..put(StoryDraftKind.event, _event(_old))
    ..put(StoryDraftKind.scene, _scene(_old))
    ..put(StoryDraftKind.dialogue, _line(_old))
    ..put(StoryDraftKind.worldRule, _rule(_old));
  return draft;
}

void main() {
  test('a renamed unsaved fact takes the id of its name everywhere', () {
    final draft = _draftCiting('Jalon A');
    final recorded = draft.recorded;

    expect(followDraftFactName(draft, _old, taken: const []), 'fact_jalon_a');

    expect(draft.recorded, recorded + 1);
    expect(draft.isTouched(StoryDraftKind.fact, _old), isFalse);
    expect(
      draft.currentOf(StoryDraftKind.fact, 'fact_jalon_a'),
      fact('fact_jalon_a', 'Jalon A'),
    );
    expect(
      draft.entryOf(StoryDraftKind.fact, 'fact_jalon_a')!.creation,
      isTrue,
    );
    expect(
      draft.currentOf(StoryDraftKind.story, 'main'),
      _story('fact_jalon_a'),
    );
    expect(
      draft.currentOf(StoryDraftKind.event, eventId(1))!.toJson(),
      _event('fact_jalon_a').toJson(),
    );
    expect(
      draft.currentOf(StoryDraftKind.scene, 'scene'),
      _scene('fact_jalon_a'),
    );
    expect(
      draft.currentOf(StoryDraftKind.worldRule, 'gate'),
      _rule('fact_jalon_a'),
    );
    expect(
      draft.currentOf(StoryDraftKind.dialogue, 'talk')!.source,
      'Tu as {{ fact.fact_jalon_a }} pièces, pas {{ fact.${_old}_2 }}.',
    );

    draft.undo();
    expect(draft.currentOf(StoryDraftKind.fact, _old), fact(_old, 'Jalon A'));
    expect(draft.isTouched(StoryDraftKind.fact, 'fact_jalon_a'), isFalse);
    expect(draft.currentOf(StoryDraftKind.story, 'main'), _story(_old));
    expect(draft.currentOf(StoryDraftKind.dialogue, 'talk'), _line(_old));
  });

  test('the generator keeps accents out and suffixes a taken id', () {
    final accent = _draftCiting('Départ');
    expect(followDraftFactName(accent, _old, taken: const []), 'fact_d_part');

    final saved = _draftCiting('Jalon A');
    expect(
      followDraftFactName(saved, _old, taken: const ['fact_jalon_a']),
      'fact_jalon_a_2',
    );

    final drafted = _draftCiting('Jalon A')
      ..load(StoryDraftKind.fact, 'fact_jalon_a', null)
      ..put(StoryDraftKind.fact, fact('fact_jalon_a', 'Autre'));
    expect(
      followDraftFactName(drafted, _old, taken: const []),
      'fact_jalon_a_2',
    );
    expect(
      drafted.currentOf(StoryDraftKind.story, 'main'),
      _story('fact_jalon_a_2'),
    );
  });

  test('a saved fact or a name that still fits keeps its id', () {
    final saved = StoryDraft()
      ..load(StoryDraftKind.fact, _old, fact(_old, 'Nouveau jalon'))
      ..load(StoryDraftKind.story, 'main', null);
    saved
      ..put(StoryDraftKind.fact, fact(_old, 'Jalon A'))
      ..put(StoryDraftKind.story, _story(_old));
    final recorded = saved.recorded;
    expect(followDraftFactName(saved, _old, taken: const [_old]), isNull);
    expect(saved.recorded, recorded);
    expect(saved.currentOf(StoryDraftKind.story, 'main'), _story(_old));

    final fitting = _draftCiting('Nouveau jalon');
    expect(followDraftFactName(fitting, _old, taken: const []), isNull);
    expect(fitting.currentOf(StoryDraftKind.story, 'main'), _story(_old));
  });
}
