import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_detail_lines.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final lab = StorylineAsset(
    id: 'main',
    type: StorylineType.main,
    title: 'Aventure',
    chapters: [
      StorylineChapter(
        id: 'c',
        title: 'C',
        order: 0,
        steps: [
          StorylineStep(id: 'one', title: 'Un', order: 0, sceneLinkIds: const ['byId']),
          StorylineStep(id: 'two', title: 'Deux', order: 1),
        ],
      ),
    ],
    sceneLinks: [
      _link('byStep', stepId: 'one', role: StorylineSceneLinkRole.primary),
      _link('byId', stepId: 'two', role: StorylineSceneLinkRole.payoff, withScene: true),
      _link('other', stepId: 'two', role: StorylineSceneLinkRole.setup),
    ],
    relationships: [
      StorylineRelationship(
        id: 'r1',
        sourceStorylineId: 'main',
        kind: StorylineRelationshipKind.requires,
        targetStorylineId: 'side',
      ),
      StorylineRelationship(
        id: 'r2',
        sourceStorylineId: 'main',
        kind: StorylineRelationshipKind.blocks,
        targetStorylineId: 'gone',
      ),
    ],
  );
  final side = StorylineAsset(id: 'side', type: StorylineType.sideQuest, title: 'Annexe');

  test('a step shows the links that name it or that it lists', () {
    final one = lab.chapters.single.steps.first;
    final two = lab.chapters.single.steps.last;
    expect(narrativeStepSceneLinks(lab, one).map((l) => l.id), ['byStep', 'byId']);
    expect(narrativeStepSceneLinks(lab, two).map((l) => l.id), ['byId', 'other']);
  });

  test('a scene link states its role and flags a missing scene', () {
    expect(narrativeSceneLinkLines(lab.sceneLinks[0]), [
      'Lien byStep',
      'Rôle : Principal',
      'Scène non renseignée',
    ]);
    expect(narrativeSceneLinkLines(lab.sceneLinks[1]), [
      'Lien byId',
      'Rôle : Résolution',
    ]);
  });

  test('every role and relationship has a sentence', () {
    expect(
      StorylineSceneLinkRole.values.map(narrativeSceneLinkRoleLabel).toSet(),
      hasLength(StorylineSceneLinkRole.values.length),
    );
    expect(
      StorylineRelationshipKind.values.map(narrativeRelationshipLabel).toSet(),
      hasLength(StorylineRelationshipKind.values.length),
    );
  });

  test('story organisation counts chapters, steps and scene links', () {
    expect(narrativeStoryOrganizationLines(lab), [
      '1 chapitre(s)',
      '2 étape(s)',
      '3 lien(s) de scène',
    ]);
  });

  test('a relation names its target or says that it is missing', () {
    expect(narrativeStoryRelationLines(lab, [lab, side]), [
      'Nécessite → Annexe',
      'Bloque → gone (introuvable)',
    ]);
  });

  test('a fact states its type and its initial value', () {
    final flag = NarrativeFactDefinition(id: 'flag', label: 'Drapeau');
    expect(narrativeFactDefinitionLines(flag), [
      'Type : Oui / non',
      'Valeur initiale : Non',
    ]);
  });

  test('an interaction without condition says whether analysis is unavailable', () {
    expect(narrativeInteractionConditionLines(_interaction()), [
      'Aucune condition déclarée',
    ]);
    expect(narrativeInteractionConditionLines(_interaction(advanced: true)), [
      'Analyse détaillée indisponible',
    ]);
    expect(
      narrativeInteractionConditionLines(_interaction(conditions: ['Si A'])),
      ['Si A'],
    );
  });

  test('the scene of an interaction comes from its record', () {
    expect(narrativeInteractionSceneId(_interaction()), isNull);
    expect(
      narrativeInteractionSceneId(
        _interaction(
          record: NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: 'evt_00000000-0000-7000-8000-000000000001',
              name: 'Arrivée',
              source: NarrativeEventSourceRef.mapEnter('a'),
              conditions: const [],
              priority: 0,
              order: 0,
              sceneId: 'lab',
            ),
          ),
        ),
      ),
      'lab',
    );
  });
}

StorylineSceneLink _link(
  String id, {
  required String stepId,
  required StorylineSceneLinkRole role,
  bool withScene = false,
}) => StorylineSceneLink(
  id: id,
  chapterId: 'c',
  stepId: stepId,
  label: 'Lien $id',
  state: withScene
      ? StorylineSceneLinkState.linkedScenario
      : StorylineSceneLinkState.placeholder,
  role: role,
  sceneRef: withScene
      ? StorylineSceneRef(kind: StorylineSceneRefKind.scenario, targetId: 'legacy')
      : null,
  order: 0,
);

NarrativeOverviewInteraction _interaction({
  bool advanced = false,
  List<String> conditions = const [],
  NarrativeEventRecord? record,
}) => NarrativeOverviewInteraction(
  id: 'i',
  name: 'Interaction',
  mapId: 'a',
  mapLabel: 'Gare',
  sourceLabel: 'Chef',
  whenText: 'Quand',
  dirty: false,
  advanced: advanced,
  conditions: conditions,
  consequences: const [],
  references: const [],
  missingReferences: const [],
  record: record,
);
