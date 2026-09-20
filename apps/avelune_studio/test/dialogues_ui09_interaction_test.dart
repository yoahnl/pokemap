import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_preview_panel.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_graph_node.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_graph_painter.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
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
  testWidgets('switching inspector tab commits focused text before disposal', (
    tester,
  ) async {
    final h = await setup(tester);
    final line = h.dialogues.active!.document.nodes.first.steps
        .whereType<DeLineStep>()
        .first;
    await tap(tester, find.byKey(ValueKey('dialogue-row-${line.id}')));
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
    await tap(tester, find.byKey(ValueKey('dialogue-row-${line.id}')));
    await tester.enterText(field('Texte'), 'Le prochain train vous attend.');
    expect(h.dialogues.active!.source, isNot(contains('Le prochain train')));
    await tap(tester, find.text('Enregistrer'));
    expect(h.port.writes, 1);
    expect(h.dialogues.busy, isFalse);
    expect(h.dialogues.dirty, isFalse);
    expect(
      (await tester.runAsync(
        () => h.fixture.port.load(ui09DialogueId),
      ))!.source,
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

  for (final zoom in [.55, .9]) {
    testWidgets(
      'wire drag cancellation and real reconnection preserve history at $zoom',
      (tester) async {
        final h = await setup(tester);
        final node = h.dialogues.active!.document.nodes.first;
        final branch = node.steps
            .whereType<DeChoiceStep>()
            .first
            .branches
            .first;
        final destination = h.dialogues.active!.document.nodes[1];
        h.dialogues.disconnect(branch.id);
        final viewport = h.views.forDialogue(ui09DialogueId).viewport;
        viewport.zoomAt(zoom, viewport.size.center(Offset.zero));
        await pumpIo(tester);
        final before = h.dialogues.active!.source;
        final port = find.byKey(ValueKey('dialogue-port-${branch.id}'));
        final start = tester.getCenter(port);
        final gesture = await tester.startGesture(start);
        await gesture.moveBy(const Offset(40, -25));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(h.dialogues.active!.source, before);
        final end =
            tester.getTopLeft(
              find.byKey(ValueKey('dialogue-node-${destination.id}')),
            ) +
            const Offset(1, 19);
        final reconnect = await tester.startGesture(tester.getCenter(port));
        await reconnect.moveBy(const Offset(20, 0));
        await tester.pump();
        await reconnect.moveTo(end);
        await tester.pump();
        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<DialogueGraphPainter>()
            .single;
        expect(painter.pendingStart, isNotNull);
        expect(
          painter.pendingEnd,
          painter.geometry.view.viewport.worldToLocal(
            painter.geometry.input(destination.id),
          ),
          reason:
              'input=$end start=$start zoom=${painter.geometry.view.viewport.zoom}',
        );
        expect(
          tester
              .widgetList<DialogueGraphNode>(find.byType(DialogueGraphNode))
              .where((w) => w.target)
              .map((w) => w.node.id),
          contains(destination.id),
        );
        await h.capture(tester, '02-connexion-en-cours');
        await reconnect.up();
        await pumpIo(tester);
        expect(h.dialogues.active!.source, contains('<<jump Depart>>'));
        await tap(tester, find.byTooltip('Annuler le dialogue'));
        expect(h.dialogues.active!.source, before);
        await tap(tester, find.byTooltip('Rétablir le dialogue'));
        expect(h.dialogues.active!.source, contains('<<jump Depart>>'));
      },
    );
  }
}
