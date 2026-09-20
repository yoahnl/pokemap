import 'package:avelune_studio/presentation/features/events/event_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui08_journey_driver.dart';
import '../support/ui08_workspace_harness.dart';

void main() {
  testWidgets(
    'UI08 focused name commits original owner on selection save and undo',
    (tester) async {
      tester.view.physicalSize = const Size(1584, 994);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = (await tester.runAsync(
        () => Ui08WorkspaceHarness.create(tester),
      ))!;
      addTearDown(f.dispose);
      await tester.pumpWidget(f.app());
      await pumpIo(tester);
      await ui08Open(tester);
      await ui08Tap(tester, 'PNJ Chef de gare');
      final controller = ui08Page(tester).controller;
      final first = controller.active!;
      final other = controller.records.firstWhere(
        (r) => eventName(r) == 'Voyageuse',
      );
      Finder name(String id) => find.descendant(
        of: find.byKey(ValueKey('event-name:$id')),
        matching: find.byType(TextField),
      );
      await tester.enterText(name(first.id), 'Chef renommé avant sélection');
      await tester.tap(find.byKey(ValueKey('event-library:${other.id}')));
      await pumpIo(tester);
      expect(controller.activeId, other.id);
      expect(
        eventName(controller.record(first.id)!),
        'Chef renommé avant sélection',
      );
      expect(eventName(controller.record(other.id)!), 'Voyageuse');
      await tester.tap(
        find.byKey(const ValueKey('event-library:${Ui06SceneFixture.eventId}')),
      );
      await pumpIo(tester);
      await tester.enterText(
        name(first.id),
        'Chef encore focalisé au moment de sauver',
      );
      await ui08Tap(tester, 'Enregistrer');
      expect(controller.error, isNull);
      expect(controller.dirty, false);
      final saved = (await tester.runAsync(f.source.readFresh))!;
      expect(
        eventName(
          saved.eventRegistry!.records.singleWhere((r) => r.id == first.id),
        ),
        'Chef encore focalisé au moment de sauver',
      );
      await tester.enterText(name(first.id), 'Changement à annuler');
      await tester.tap(find.byTooltip('Annuler la modification'));
      await pumpIo(tester);
      expect(
        eventName(controller.record(first.id)!),
        'Chef encore focalisé au moment de sauver',
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await pumpIo(tester);
      expect(eventName(controller.record(first.id)!), 'Changement à annuler');
      await ui08Tap(tester, 'Options');
      final priority = find.descendant(
        of: find.byKey(ValueKey('priority:${first.id}')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(priority);
      await tester.enterText(priority, 'pas un nombre');
      await ui08Tap(tester, 'Enregistrer');
      expect(f.events.writes, 1);
      expect(controller.dirty, true);
      expect(controller.error, isNotEmpty);
      expect(find.text(controller.error!), findsWidgets);
      await tester.enterText(priority, '0');
      await ui08Tap(tester, 'Enregistrer');
      expect(f.events.writes, 2);
      expect(controller.dirty, false);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
