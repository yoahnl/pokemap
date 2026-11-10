import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_preview_panel.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_structure_projection.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui09_dialogue_harness.dart';
import 'support/ui09_runtime_fixture.dart';

Future<Ui09DialogueHarness> setup(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = (await tester.runAsync(() => Ui09DialogueHarness.create(tester)))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(h.dispose);
  });
  await tester.pumpWidget(h.app());
  await h.open(tester);
  return h;
}

Future<void> selectDialogue(
  WidgetTester tester,
  Ui09DialogueHarness harness, {
  String? step,
  String? branch,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  FocusManager.instance.applyFocusChangesIfNeeded();
  final node = harness.dialogues.active!.document.nodes.first;
  harness.views
      .forDialogue(ui09DialogueId)
      .select(node.id, step: step, branch: branch);
  harness.notify();
  await pumpIo(tester, frames: 4);
}

Finder field(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is StudioCommitField && w.label == label),
  matching: find.byType(TextField),
);

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await pumpIo(tester, frames: 12);
}

void main() {
  testWidgets(
    'EV04 guided value picker distinguishes player identity from a Fact of the same name',
    (tester) async {
      final h = await setup(tester);
      h.maps.project = h.maps.project!.copyWith(
        facts: [
          ...h.maps.project!.facts,
          NarrativeFactDefinition(
            id: 'player_name',
            label: 'Nom de la gare',
            initialValue: const NarrativeValue.string('Selbrume'),
          ),
        ],
      );
      final line = h.dialogues.active!.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first;
      await selectDialogue(tester, h, step: line.id);
      final picker = find.byKey(ValueKey('dialogue-text-value-${line.id}'));
      final select = tester.widget<StudioSelect>(picker);
      expect(select.options['player_name'], 'Nom du joueur');
      expect(select.options['fact:player_name'], contains('Nom de la gare'));
      select.onChanged!('fact:player_name');
      await pumpIo(tester, frames: 4);
      expect(h.dialogues.active!.source, contains('{{ fact.player_name }}'));
      tester.widget<StudioSelect>(picker).onChanged!('player_name');
      await pumpIo(tester, frames: 4);
      expect(h.dialogues.active!.source, contains('{{ player_name }}'));
    },
  );

  testWidgets('switching inspector tab commits focused text before disposal', (
    tester,
  ) async {
    final h = await setup(tester);
    final line = h.dialogues.active!.document.nodes.first.steps
        .whereType<DeLineStep>()
        .first;
    await selectDialogue(tester, h, step: line.id);
    await tester.enterText(
      field('Texte'),
      'Réplique conservée pendant le changement d’onglet.',
    );
    await tap(tester, find.text('Yarn'));
    expect(
      h.dialogues.active!.source,
      contains('Réplique conservée pendant le changement d’onglet.'),
    );
    expect(h.dialogues.dirty, isTrue);
  });
  testWidgets('focused text saves exact source and history remains usable', (
    tester,
  ) async {
    final h = await setup(tester);
    final node = h.dialogues.active!.document.nodes.first;
    final line = node.steps.whereType<DeLineStep>().first;
    await selectDialogue(tester, h, step: line.id);
    await tester.enterText(field('Texte'), 'Le prochain train vous attend.');
    expect(h.dialogues.active!.source, isNot(contains('Le prochain train')));
    await tap(tester, find.text('Enregistrer'));
    expect(h.port.writes, 1);
    expect(h.dialogues.busy, isFalse);
    expect(h.dialogues.dirty, isFalse);
    expect(
      (await tester.runAsync(() => h.fixture.port.load(ui09DialogueId)))!
          .source,
      contains('Le prochain train vous attend.'),
    );
    await tap(tester, find.byTooltip('Annuler le dialogue'));
    expect(h.dialogues.active!.source, contains('Souhaitez-vous préparer'));
    expect(h.dialogues.dirty, isTrue);
    await tap(tester, find.byTooltip('Rétablir le dialogue'));
    expect(h.dialogues.dirty, isFalse);
    await tap(tester, find.text('Retour à la scène'));
    expect(h.backCount, 1);
  });

  testWidgets('preview plays both explicit branches without publication', (
    tester,
  ) async {
    final h = await setup(tester);
    Finder inside(String text) => find.descendant(
      of: find.byType(DialoguePreviewPanel),
      matching: find.text(text),
    );
    for (final choice in [0, 1]) {
      await tap(tester, find.text('Tester'));
      await tap(tester, inside('Continuer'));
      await tap(
        tester,
        inside(choice == 0 ? 'Je pars maintenant' : 'Je préfère attendre'),
      );
      expect(
        h.dialogues.preview!.line!.text,
        contains(choice == 0 ? 'train vous attend' : 'Prenez votre temps'),
      );
      await h.capture(
        tester,
        '04-apercu-${choice == 0 ? 'depart' : 'attente'}',
      );
      await tap(tester, inside('Continuer'));
      expect(h.dialogues.preview!.outcomes, [
        choice == 0 ? 'depart' : 'attente',
      ]);
      expect(h.dialogues.preview!.ended, isTrue);
      await h.capture(
        tester,
        'ui09-preview-${choice == 0 ? 'depart' : 'attente'}',
      );
    }
    expect(h.port.writes, 0);
    expect(h.dialogues.dirty, isFalse);
  });

  testWidgets(
    'projected response reconnection preserves history without publishing',
    (tester) async {
      final h = await setup(tester);
      final node = h.dialogues.active!.document.nodes.first;
      final branch = node.steps.whereType<DeChoiceStep>().first.branches.first;
      final destination = h.dialogues.active!.document.nodes[1];
      expect(h.dialogues.disconnect(branch.id), isTrue);
      final before = h.dialogues.active!.source;
      final projection = DialogueStructureProjection(
        h.dialogues.active!.document,
      );
      final row = projection.rows[node.id]!.indexWhere(
        (row) => row.id == branch.id,
      );
      final port = projection.portIdAt(node.id, row)!;
      expect(
        await h.dialogues.connectSelection(
          port,
          destination.id,
          confirmReplacement: () async => throw StateError('No replacement'),
        ),
        isTrue,
      );
      expect(h.dialogues.active!.source, contains('<<jump Depart>>'));
      await tap(tester, find.byTooltip('Annuler le dialogue'));
      expect(h.dialogues.active!.source, before);
      await tap(tester, find.byTooltip('Rétablir le dialogue'));
      expect(h.dialogues.active!.source, contains('<<jump Depart>>'));
      expect(h.port.writes, 0);
    },
  );
}
