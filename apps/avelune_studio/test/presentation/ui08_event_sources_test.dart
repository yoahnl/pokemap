import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/events/event_context_map.dart';
import 'package:avelune_studio/presentation/features/events/event_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui08_journey_driver.dart';
import '../support/ui08_workspace_harness.dart';

void main() {
  testWidgets(
    'UI08 four real sources preserve exact targets and Escape cancels without writes',
    (tester) async {
      tester.view.physicalSize = const Size(1584, 994);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = (await tester.runAsync(
        () => Ui08WorkspaceHarness.create(tester),
      ))!;
      addTearDown(f.dispose);
      final mapBytes = await tester.runAsync(f.mapBytes);
      await tester.pumpWidget(f.app());
      await pumpIo(tester);
      await ui08Open(tester);
      await ui08Tap(tester, 'PNJ Chef de gare');
      final controller = ui08Page(tester).controller;
      final original = controller.active!;
      final source = eventSource(original)!;
      await ui08Tap(tester, 'Entrée de zone');
      expect(find.byKey(const ValueKey('event-target:chief')), findsNothing);
      expect(
        find.byKey(const ValueKey('event-target:platform')),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await pumpIo(tester);
      expect(eventSource(controller.active!), source);
      expect(controller.dirty, false);
      await ui08Tap(tester, 'Entrée de zone');
      await tester.tap(find.byKey(const ValueKey('event-target:platform')));
      await pumpIo(tester);
      expect(
        eventSource(controller.active!)!.kind,
        NarrativeEventSourceKind.triggerEnter,
      );
      await ui08Tap(tester, 'Interaction du joueur');
      expect(find.byKey(const ValueKey('event-target:platform')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('event-target:traveller')));
      await pumpIo(tester);
      expect(eventTargetId(eventSource(controller.active!)), 'traveller');
      await ui08Tap(tester, 'Entrée sur la carte');
      expect(
        find.byKey(const ValueKey('event-target:traveller')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('event-context-viewport')));
      await pumpIo(tester);
      expect(
        eventSource(controller.active!)!.kind,
        NarrativeEventSourceKind.mapEnter,
      );
      await ui08Tap(tester, 'Réception d’un résultat');
      final result = controller.catalog.outcomeSources.options.firstWhere(
        (o) => o.selectable,
      );
      await tester.tap(
        find.byKey(ValueKey('outcome:${result.debugTechnicalLabel}')),
      );
      await pumpIo(tester);
      expect(
        eventSource(controller.active!),
        NarrativeEventSourceRef.outcomeReceived(result.outcome!),
      );
      expect(find.byType(EventContextMap), findsNothing);
      expect(find.text('Global / Résultats'), findsWidgets);
      expect(controller.records.length, 4);
      expect(f.events.writes, 0);
      expect(await tester.runAsync(f.mapBytes), mapBytes);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
