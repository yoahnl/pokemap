import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_portrait_image.dart';
import 'support/ui09_dialogue_harness.dart';
import 'support/ui09_runtime_fixture.dart';
import 'support/m2_ui_fixture.dart';

void main() {
  testWidgets('UI09 early real widget capture and compact layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = (await tester.runAsync(
      () => Ui09DialogueHarness.create(tester),
    ))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.dispose);
    });
    await tester.pumpWidget(h.app());
    await h.open(tester);
    final document = h.dialogues.active!.document;
    final view = h.views.forDialogue(ui09DialogueId);
    view.select(
      document.nodes.first.id,
      step: document.nodes.first.steps.whereType<DeLineStep>().first.id,
    );
    h.dialogues.startPreview();
    await pumpIo(tester);
    final portraits = find.byType(DialoguePortraitImage);
    expect(portraits, findsWidgets);
    expect(
      find
          .descendant(of: portraits, matching: find.byType(Image))
          .evaluate()
          .length,
      portraits.evaluate().length,
    );
    await h.capture(tester, 'ui09-dialogue-early-1536');
    await h.capture(tester, '01-composition-complete');
    await h.capture(tester, '03-inspecteur-portrait');
    await h.dialogues.open(ui09DialogueId, startNode: 'DepartAbsent');
    h.dialogues.startPreview();
    await pumpIo(tester);
    expect(h.dialogues.preview!.error, isNotNull);
    await h.capture(tester, '06-depart-absent-diagnostic');
    await h.dialogues.open(ui09DialogueId, startNode: 'Accueil');
    h.dialogues.startPreview();
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(1024, 640);
    await tester.pumpWidget(h.app(textScale: 1.5));
    await pumpIo(tester);
    await tester.tap(find.byTooltip('Cadrer le dialogue'));
    await pumpIo(tester);
    await h.capture(tester, 'ui09-dialogue-compact-150');
    await h.capture(tester, '07-compact-150');
    expect(tester.takeException(), isNull);
  });
}
