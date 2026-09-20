import 'dart:convert';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/events/event_conditions.dart';
import 'package:avelune_studio/presentation/features/events/event_simulation_dialog.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/event_backend_fixture.dart';
import 'support/ui06_scene_fixture.dart';

void main() {
  testWidgets(
    'simulation reruns against a removed source without stale success',
    (tester) async {
      final fixture = (await tester.runAsync(EventBackendFixture.create))!;
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      expect(await tester.runAsync(controller.prepare), isTrue);
      await _openSimulation(tester, controller);
      await tester.tap(find.text('Simuler'));
      await tester.pumpAndSettle();
      expect(find.text('Cet événement est sélectionné'), findsOneWidget);
      expect(controller.setSource(Ui06SceneFixture.eventId, null), isTrue);
      await tester.tap(find.text('Simuler'));
      await tester.pumpAndSettle();
      expect(find.text('Cet événement est sélectionné'), findsNothing);
      expect(find.text('Aucun événement sélectionné'), findsOneWidget);
      expect(find.textContaining('Source absente'), findsWidgets);
    },
  );

  testWidgets(
    'simulation names the competing event instead of selecting target',
    (tester) async {
      final fixture = (await tester.runAsync(EventBackendFixture.create))!;
      addTearDown(fixture.dispose);
      final controller = fixture.attach();
      expect(await tester.runAsync(controller.prepare), isTrue);
      final source = controller.record(Ui06SceneFixture.eventId)!.source;
      expect(
        await tester.runAsync(
          () => controller.changeMode(EventSystemMode.dualRead),
        ),
        isTrue,
        reason: controller.error,
      );
      expect(await tester.runAsync(controller.prepare), isTrue);
      final rival = controller.create('Annonce prioritaire', source: source)!;
      expect(controller.setScene(rival.id, Ui06SceneFixture.sceneId), isTrue);
      expect(
        controller.setReuse(rival.id, NarrativeEventReusePolicy.reusable),
        isTrue,
      );
      expect(controller.setPriority(rival.id, 100), isTrue);
      expect(controller.configure(rival.id), isTrue, reason: controller.error);
      expect(
        controller.setEnabled(rival.id, true),
        isTrue,
        reason: controller.error,
      );
      final bytes = jsonEncode(controller.project.toJson());
      await _openSimulation(tester, controller);
      await tester.tap(find.text('Simuler'));
      await tester.pumpAndSettle();
      expect(find.text('Un autre événement est prioritaire'), findsOneWidget);
      expect(find.text('Cet événement est sélectionné'), findsNothing);
      expect(find.text('Annonce prioritaire'), findsWidgets);
      expect(jsonEncode(controller.project.toJson()), bytes);
    },
  );

  testWidgets('grouped conditions remain ANY and NOT when removing a sibling', (
    tester,
  ) async {
    final left = NarrativeEventConditionExpression.not(
      NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.fact('ticket', false),
      ),
    );
    final right = NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('ready', true),
    );
    NarrativeEventConditionExpression? changed;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: EventConditions(
            expression: NarrativeEventConditionExpression.any([left, right]),
            facts: [
              NarrativeFactDefinition(id: 'ticket', label: 'Billet'),
              NarrativeFactDefinition(id: 'ready', label: 'Prêt'),
            ],
            records: [],
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );
    expect(find.text('Au moins une condition'), findsOneWidget);
    expect(find.text('Inverser cette condition'), findsOneWidget);
    await tester.tap(find.byTooltip('Retirer la condition').last);
    await tester.pump();
    expect(changed, NarrativeEventConditionExpression.any([left]));
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid numeric simulation never reports a stale success', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(EventBackendFixture.create))!;
    addTearDown(() => fixture.dispose());
    fixture.narrative.pendingFacts['ui08.count'] = NarrativeFactDefinition(
      id: 'ui08.count',
      label: 'Nombre de billets',
      initialValue: NarrativeValue.integer(2),
    );
    final controller = fixture.attach();
    expect(await tester.runAsync(controller.prepare), isTrue);
    final bytes = jsonEncode(controller.project.toJson());
    await _openSimulation(tester, controller);
    await tester.tap(find.text('Simuler'));
    await tester.pumpAndSettle();
    expect(find.text('Cet événement est sélectionné'), findsOneWidget);
    final field = find.descendant(
      of: find.byKey(const ValueKey('simulation:ui08.count')),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'pas un entier');
    await tester.tap(find.text('Simuler'));
    await tester.pumpAndSettle();
    expect(find.text('Cet événement est sélectionné'), findsNothing);
    expect(find.textContaining('avant de simuler'), findsOneWidget);
    await tester.enterText(field, '2');
    await tester.tap(find.text('Simuler'));
    await tester.pumpAndSettle();
    expect(find.text('Cet événement est sélectionné'), findsOneWidget);
    expect(jsonEncode(controller.project.toJson()), bytes);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consumed simulation input is isolated and withdraws selection', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(EventBackendFixture.create))!;
    addTearDown(() => fixture.dispose());
    final controller = fixture.attach();
    expect(await tester.runAsync(controller.prepare), isTrue);
    controller.setReuse(
      Ui06SceneFixture.eventId,
      NarrativeEventReusePolicy.oneShot,
    );
    controller.setEnabled(Ui06SceneFixture.eventId, true);
    final bytes = jsonEncode(controller.project.toJson());
    await _openSimulation(tester, controller);
    await tester.tap(find.text('Simuler'));
    await tester.pumpAndSettle();
    expect(find.text('Cet événement est sélectionné'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Cet événement est sélectionné'), findsNothing);
    await tester.tap(find.text('Simuler'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun événement sélectionné'), findsOneWidget);
    expect(find.textContaining('Déjà joué'), findsWidgets);
    expect(jsonEncode(controller.project.toJson()), bytes);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openSimulation(
  WidgetTester tester,
  EventWorkspaceController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showEventSimulation(
              context,
              controller,
              Ui06SceneFixture.eventId,
            ),
            child: const Text('Ouvrir la simulation'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir la simulation'));
  await tester.pumpAndSettle();
}
