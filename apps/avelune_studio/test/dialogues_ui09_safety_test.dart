import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';

import 'dialogues_ui09_interaction_test.dart'
    show setup, tap, field, selectDialogue;
import 'support/m2_ui_fixture.dart';
import 'support/ui09_runtime_fixture.dart';

void main() {
  testWidgets(
    'CmdS and CtrlS publish text while inspector keeps keyboard focus',
    (tester) async {
      final h = await setup(tester);
      final line = h.dialogues.active!.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first;
      await selectDialogue(tester, h, step: line.id);
      for (final modifier in [
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.controlLeft,
      ]) {
        final text = 'Enregistrement au clavier ${modifier.keyLabel}.';
        await tester.enterText(field('Texte'), text);
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.sendKeyUpEvent(modifier);
        await pumpIo(tester);
        expect(h.dialogues.dirty, isFalse);
        expect(
          (await tester.runAsync(() => h.fixture.port.load(ui09DialogueId)))!
              .source,
          contains(text),
        );
      }
      expect(h.port.writes, 2);
    },
  );
  testWidgets('invalid suite name on save stays visible without publishing', (
    tester,
  ) async {
    final h = await setup(tester);
    await tester.enterText(field('Nom de la suite'), 'Depart');
    await tap(tester, find.text('Enregistrer'));
    expect(h.port.writes, 0);
    expect(h.dialogues.error, isNotNull);
    expect(find.text(h.dialogues.error!), findsWidgets);
    expect(h.dialogues.active!.document.nodes.first.title, 'Accueil');
    expect(h.dialogues.dirty, isFalse);
  });

  testWidgets('undo commits pending focused edit then restores exactly once', (
    tester,
  ) async {
    final h = await setup(tester);
    final line = h.dialogues.active!.document.nodes.first.steps
        .whereType<DeLineStep>()
        .first;
    await selectDialogue(tester, h, step: line.id);
    final source = h.dialogues.active!.source;
    await tester.enterText(field('Texte'), 'Une édition encore au clavier.');
    await tap(tester, find.byTooltip('Annuler le dialogue'));
    expect(h.dialogues.active!.source, source);
    expect(h.dialogues.canRedo, isTrue);
    await tap(tester, find.byTooltip('Rétablir le dialogue'));
    expect(
      h.dialogues.active!.source,
      contains('Une édition encore au clavier.'),
    );
    expect(h.port.writes, 0);
  });

  testWidgets(
    'inspector replacement confirms and a newer semantic edit invalidates pending consent',
    (tester) async {
      final h = await setup(tester);
      final document = h.dialogues.active!.document;
      final node = document.nodes.first;
      final choice = node.steps.whereType<DeChoiceStep>().first;
      final branch = choice.branches.first;
      await selectDialogue(tester, h, step: choice.id, branch: branch.id);
      final selector = find.byWidgetPredicate(
        (widget) => widget is StudioSelect && widget.label == 'Continuer vers',
      );
      await tap(tester, selector);
      await tap(tester, find.text('Attente').last);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(h.dialogues.active!.source, contains('<<jump Depart>>'));
      await tap(tester, find.text('Confirmer'));
      DeChoiceBranch current() => h.dialogues.active!.document.nodes.first.steps
          .whereType<DeChoiceStep>()
          .first
          .branches
          .first;
      expect(
        current().steps.whereType<DeJumpStep>().single.targetTitle,
        'Attente',
      );
      expect(current().label, branch.label);
      expect(current().outcomeId, branch.outcomeId);
      await tap(tester, selector);
      await tap(tester, find.text('Depart').last);
      expect(find.byType(AlertDialog), findsOneWidget);
      final line = h.dialogues.active!.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first;
      h.dialogues.updateLine(line.id, text: 'Édition pendant la confirmation.');
      await pumpIo(tester);
      final before = h.dialogues.active!.source;
      await tap(tester, find.text('Confirmer'));
      expect(h.dialogues.active!.source, before);
      expect(
        current().steps.whereType<DeJumpStep>().single.targetTitle,
        'Attente',
      );
      expect(h.port.writes, 0);
    },
  );
}
