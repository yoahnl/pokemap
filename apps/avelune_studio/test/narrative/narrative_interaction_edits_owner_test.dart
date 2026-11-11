import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_editing_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction_edits.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m3_story_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('real conditions and ordered sequence stay editable through the interaction draft', () async {
    final fixture = await M3StoryFixture.create();
    final workspace = MapWorkspaceController(fixture.session, fixture.maps);
    await workspace.initialize();
    var changes = 0;
    final narrative = NarrativeWorkspaceController(
      workspace,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () => changes++,
      (_, _) async {},
    );
    addTearDown(() async {
      workspace.dispose();
      await fixture.directory.delete(recursive: true);
    });
    final record = workspace.project!.eventRegistry!.records.firstWhere(
      (r) => r.definitionOrNull?.name == 'Autoriser le départ',
    );
    await narrative.openRecord(record);
    final edit = narrative.active!;
    NarrativeInteractionDraft interaction() => edit.current.interaction;

    expect(
      narrativeConditionFacts(narrative.facts).map((fact) => fact.id),
      contains('visited'),
    );
    final before = interaction().conditions.first.expectedNarrativeValue;
    final toggled = toggledNarrativeCondition(interaction().conditions, 0)!;
    edit.change(interaction: interaction().revise(conditions: toggled));
    expect(
      interaction().conditions.first.expectedNarrativeValue,
      isNot(before),
    );
    edit.restore(redo: false);
    expect(interaction().conditions.first.expectedNarrativeValue, before);

    expect(interaction().steps.first.kind, NarrativeSequenceKind.facing);
    final secondKind = interaction().steps[1].kind;
    expect(movedNarrativeStep(interaction().steps, 0, -1), isNull);
    final moved = movedNarrativeStep(interaction().steps, 0, 1)!;
    edit.change(interaction: interaction().revise(steps: moved));
    expect(interaction().steps.first.kind, secondKind);
    expect(interaction().steps.first.kind, NarrativeSequenceKind.wait);
    expect(interaction().steps[1].kind, NarrativeSequenceKind.facing);
    edit.restore(redo: false);
    expect(interaction().steps.first.kind, NarrativeSequenceKind.facing);

    final editor = DialogueEditingController(edit, narrative.changed);
    editor.addChoice();
    final outcome = editor.branch.choices.last.outcomeId!;
    expect(interaction().branches[outcome], isEmpty);
    expect(
      interaction().project().scene.graph.nodes
          .where((node) => node.payload is SceneYarnDialoguePayload)
          .first
          .payload,
      isA<SceneYarnDialoguePayload>().having(
        (payload) => payload.expectedOutcomes,
        'outcomes',
        contains(outcome),
      ),
    );

    final source = interaction().source;
    final greatest = narrative.project.eventRegistry!.records
        .where((record) => record.definitionOrNull?.source == source)
        .map((record) => record.definitionOrNull!.order)
        .reduce((a, b) => a > b ? a : b);
    await narrative.openSource(workspace.active!, source, 'Variante');
    expect(narrative.active!.current.interaction.order, greatest + 1);
  }, timeout: _slow);

  test('condition list edits keep only boolean facts and preserve other conditions', () {
    final facts = [
      NarrativeFactDefinition(id: 'ready', label: 'Prêt'),
      NarrativeFactDefinition(
        id: 'score',
        label: 'Score',
        initialValue: NarrativeValue.integer(0),
      ),
      NarrativeFactDefinition(id: 'gone', label: 'Parti'),
    ];
    final conditions = [
      NarrativeEventCondition.fact('ready', true),
      NarrativeEventCondition.fact('gone', false),
    ];

    expect(narrativeConditionFacts(facts).map((fact) => fact.id), [
      'ready',
      'gone',
    ]);
    expect(toggledNarrativeCondition(conditions, 1), [
      NarrativeEventCondition.fact('ready', true),
      NarrativeEventCondition.fact('gone', true),
    ]);
    expect(withNarrativeCondition(conditions, 0, 'gone', false), [
      NarrativeEventCondition.fact('gone', false),
      NarrativeEventCondition.fact('gone', false),
    ]);
    expect(addedNarrativeCondition(conditions, facts)!.last,
        NarrativeEventCondition.fact('ready', true));
    expect(addedNarrativeCondition(conditions, [facts[1]]), isNull);
    expect(withoutNarrativeItem(conditions, 0), [
      NarrativeEventCondition.fact('gone', false),
    ]);
    expect(conditions, hasLength(2));
  });

  test('sequence list edits swap, remove, add with first target and validate waits', () {
    const steps = [
      NarrativeSequenceStep(kind: NarrativeSequenceKind.facing, targetId: 'a'),
      NarrativeSequenceStep(kind: NarrativeSequenceKind.wait),
      NarrativeSequenceStep(kind: NarrativeSequenceKind.setFact, targetId: 'f'),
    ];

    expect(
      movedNarrativeStep(steps, 2, -1)!.map((step) => step.kind),
      [
        NarrativeSequenceKind.facing,
        NarrativeSequenceKind.setFact,
        NarrativeSequenceKind.wait,
      ],
    );
    expect(movedNarrativeStep(steps, 2, 1), isNull);
    expect(withoutNarrativeItem(steps, 1).map((step) => step.kind), [
      NarrativeSequenceKind.facing,
      NarrativeSequenceKind.setFact,
    ]);
    final added = addedNarrativeStep(steps, NarrativeSequenceKind.setFact, {
      'first': 'Premier',
      'second': 'Second',
    });
    expect(added.last.kind, NarrativeSequenceKind.setFact);
    expect(added.last.targetId, 'first');
    expect(
      addedNarrativeStep(steps, NarrativeSequenceKind.wait, const {}).last.targetId,
      '',
    );
    expect(narrativeWaitMilliseconds('0'), 0);
    expect(narrativeWaitMilliseconds('450'), 450);
    expect(narrativeWaitMilliseconds('-1'), isNull);
    expect(narrativeWaitMilliseconds('abc'), isNull);
    expect(steps, hasLength(3));
  });
}

const _slow = Timeout(Duration(minutes: 3));
