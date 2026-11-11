import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction_edits.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  const dialogue = DialogueDraft(
    entry: ProjectDialogueEntry(
      id: 'station',
      name: 'Gare',
      relativePath: 'dialogues/station.yarn',
    ),
    branches: [
      DialogueBranchDraft(
        id: 'Start',
        name: 'Début',
        choices: [
          DialogueChoiceDraft(text: 'Oui', targetId: 'Start', outcomeId: 'yes'),
          DialogueChoiceDraft(text: 'Silence', targetId: 'Start'),
        ],
      ),
      DialogueBranchDraft(
        id: 'Other',
        name: 'Suite',
        choices: [
          DialogueChoiceDraft(text: 'Non', targetId: 'Start', outcomeId: 'no'),
          DialogueChoiceDraft(text: 'Peut-être', targetId: 'Start', outcomeId: 'yes'),
        ],
      ),
    ],
  );
  final interaction = NarrativeInteractionDraft(
    id: 'evt_00000000-0000-7000-8000-000000000001',
    name: 'Chef',
    mapId: 'a',
    source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
    dialogueId: 'station',
    branches: {
      'yes': [
        const NarrativeSequenceStep(
          kind: NarrativeSequenceKind.completeStep,
          targetId: 'arrival',
        ),
      ],
    },
  );

  test('one consequence section exists per outcome and the last choice text names it', () {
    final sections = narrativeOutcomeSections(dialogue);
    expect(sections.keys, ['yes', 'no']);
    expect(sections['yes'], 'Peut-être');
    expect(sections['no'], 'Non');
    expect(narrativeOutcomeSectionTitle('Non'), 'Après le choix « Non »');
  });

  test('a choice without outcome opens no section', () {
    expect(narrativeOutcomeSections(dialogue).values, isNot(contains('Silence')));
  });

  test('outcome steps default to empty and replacing one leaves the others', () {
    expect(narrativeOutcomeSteps(interaction, 'yes'), hasLength(1));
    expect(narrativeOutcomeSteps(interaction, 'no'), isEmpty);
    final next = withNarrativeOutcomeSteps(interaction, 'no', const [
      NarrativeSequenceStep(kind: NarrativeSequenceKind.wait),
    ]);
    expect(next.branches.keys, ['yes', 'no']);
    expect(next.branches['yes'], hasLength(1));
    expect(next.branches['no']!.single.kind, NarrativeSequenceKind.wait);
    expect(interaction.branches.keys, ['yes']);
    expect(withNarrativeOutcomeSteps(interaction, 'yes', const []).branches['yes'], isEmpty);
  });

  test('priority only accepts an integer', () {
    expect(narrativePriorityFromInput('12'), 12);
    expect(narrativePriorityFromInput('-3'), -3);
    expect(narrativePriorityFromInput('douze'), isNull);
    expect(narrativePriorityFromInput(''), isNull);
    expect(narrativePriorityFromInput('1.5'), isNull);
  });

  test('the map name falls back to the current map and the origin tells entity from zone', () {
    const project = ProjectManifest(
      name: 'P',
      maps: [ProjectMapEntry(id: 'a', name: 'Gare', relativePath: 'a.json')],
      tilesets: [],
    );
    expect(narrativeInteractionMapName(project, 'a'), 'Gare');
    expect(narrativeInteractionMapName(project, 'gone'), 'Carte courante');
    expect(
      narrativeInteractionOriginLabel(interaction),
      'Interaction avec un personnage',
    );
    final zone = NarrativeInteractionDraft(
      id: 'evt_00000000-0000-7000-8000-000000000002',
      name: 'Zone',
      mapId: 'a',
      source: NarrativeEventSourceRef.triggerEnter('a', 'platform'),
      dialogueId: 'station',
    );
    expect(narrativeInteractionOriginLabel(zone), 'Entrée dans une zone');
  });
}
