import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_graph_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'dialogues_ui09_interaction_test.dart' show setup, tap, field;
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
      await tap(tester, find.byKey(ValueKey('dialogue-row-${line.id}')));
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
          (await tester.runAsync(
            () => h.fixture.port.load(ui09DialogueId),
          ))!.source,
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
    await tap(tester, find.byKey(ValueKey('dialogue-row-${line.id}')));
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
    'wire replacement confirms and semantic edit cancels pending wire',
    (tester) async {
      final h = await setup(tester);
      final document = h.dialogues.active!.document;
      final source = document.nodes.first;
      final branch = source.steps
          .whereType<DeChoiceStep>()
          .first
          .branches
          .first;
      final target = document.nodes.last;
      final view = h.views.forDialogue(ui09DialogueId).viewport;
      view.zoomAt(.6, view.size.center(Offset.zero));
      await pumpIo(tester);
      final port = find.byKey(ValueKey('dialogue-port-${branch.id}'));
      final targetHeader = find.byKey(ValueKey('dialogue-node-${target.id}'));
      final drag = await tester.startGesture(tester.getCenter(port));
      await drag.moveBy(const Offset(25, 0));
      await tester.pump();
      await drag.moveTo(tester.getTopLeft(targetHeader) + const Offset(1, 15));
      await tester.pump();
      await drag.up();
      await pumpIo(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(h.dialogues.active!.source, contains('<<jump Depart>>'));
      await tap(tester, find.text('Confirmer'));
      final updated = h.dialogues.active!.document.nodes.first.steps
          .whereType<DeChoiceStep>()
          .first
          .branches
          .first;
      expect(
        updated.steps.whereType<DeJumpStep>().single.targetTitle,
        'Attente',
      );
      expect(updated.label, branch.label);
      expect(updated.outcomeId, branch.outcomeId);
      final pending = await tester.startGesture(tester.getCenter(port));
      await pending.moveBy(const Offset(25, 0));
      await tester.pump();
      final line = h.dialogues.active!.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first;
      h.dialogues.updateLine(line.id, text: 'Édition pendant la connexion.');
      await tester.pump();
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<DialogueGraphPainter>()
          .single;
      expect(painter.pendingStart, isNull);
      await pending.up();
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(h.port.writes, 0);
    },
  );
}
