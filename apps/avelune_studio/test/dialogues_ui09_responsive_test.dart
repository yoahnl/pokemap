import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'dialogues_ui09_interaction_test.dart' show setup, tap, field;
import 'support/m2_ui_fixture.dart';
import 'support/ui09_runtime_fixture.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets(
      'responsive ${size.width.toInt()}x${size.height.toInt()} edits text and response then saves',
      (tester) async {
        final h = await setup(tester);
        final node = h.dialogues.active!.document.nodes.first;
        final line = node.steps.whereType<DeLineStep>().first;
        final branch = node.steps
            .whereType<DeChoiceStep>()
            .first
            .branches
            .first;
        await tap(tester, find.byKey(ValueKey('dialogue-row-${line.id}')));
        tester.view.physicalSize = size;
        final compact = size.width == 1024;
        await tester.pumpWidget(h.app(textScale: compact ? 1.5 : 1));
        await pumpIo(tester);
        if (compact) {
          await tap(tester, find.byTooltip('Inspecteur du dialogue'));
        }
        await tester.ensureVisible(field('Texte'));
        final text = 'Lecture et sauvegarde à ${size.width.toInt()} pixels.';
        await tester.enterText(field('Texte'), text);
        await tap(tester, find.text('Enregistrer'));
        expect(h.port.writes, 1);
        expect(h.dialogues.dirty, isFalse);
        expect(
          (await tester.runAsync(
            () => h.fixture.port.load(ui09DialogueId),
          ))!.source,
          contains(text),
        );
        if (compact) {
          await tap(tester, find.byTooltip('Inspecteur du dialogue'));
        }
        await tap(tester, find.byTooltip('Cadrer le dialogue'));
        await tap(tester, find.byKey(ValueKey('dialogue-row-${branch.id}')));
        if (compact) {
          await tap(tester, find.byTooltip('Inspecteur du dialogue'));
        }
        await tester.ensureVisible(field('Réponse du joueur'));
        final answer = 'Partir à ${size.width.toInt()} pixels';
        await tester.enterText(field('Réponse du joueur'), answer);
        await tap(tester, find.text('Enregistrer'));
        expect(h.port.writes, 2);
        expect(h.dialogues.dirty, isFalse);
        final saved = (await tester.runAsync(
          () => h.fixture.port.load(ui09DialogueId),
        ))!.source;
        expect(saved, contains(text));
        expect(saved, contains(answer));
        expect(saved, contains('<<jump Depart>>'));
        expect(saved, contains('<<outcome depart>>'));
        expect(tester.takeException(), isNull);
        await h.capture(
          tester,
          'responsive-${size.width.toInt()}x${size.height.toInt()}-${compact ? '150' : '100'}',
        );
      },
    );
  }
}
