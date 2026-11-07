import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/events/event_conditions.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_trigger_inspector.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  final facts = [
    NarrativeFactDefinition(id: 'ticket', label: 'Billet'),
    NarrativeFactDefinition(id: 'ready', label: 'Prêt'),
  ];
  final notTicket = NarrativeEventConditionExpression.not(
    NarrativeEventConditionExpression.leaf(
      NarrativeEventCondition.fact('ticket', true),
    ),
  );
  final ready = NarrativeEventConditionExpression.leaf(
    NarrativeEventCondition.fact('ready', true),
  );

  Future<List<NarrativeEventConditionExpression>> pump(
    WidgetTester tester,
    NarrativeEventConditionExpression expression,
  ) async {
    final changes = <NarrativeEventConditionExpression>[];
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: EventConditions(
            expression: expression,
            facts: facts,
            records: const [],
            onChanged: changes.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return changes;
  }

  String text(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(ValueKey(key))).data!;

  testWidgets('the result sentence states the group logic and the inversion', (
    tester,
  ) async {
    await pump(
      tester,
      NarrativeEventConditionExpression.any([notTicket, ready]),
    );
    final result = text(tester, 'event-conditions-result');
    expect(result, contains('au moins une'));
    expect(result, contains('il n’est pas vrai que'));
    expect(result, contains('Billet'));
    expect(result, contains(' ou '));
    expect(result, contains('Prêt'));
    expect(find.text('Au moins une condition'), findsOneWidget);
    expect(find.text('Inverser cette condition'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a group logic is chosen explicitly and keeps its children', (
    tester,
  ) async {
    final changes = await pump(
      tester,
      NarrativeEventConditionExpression.any([notTicket, ready]),
    );
    final all = find.byKey(const ValueKey('event-group-all-root'));
    final any = find.byKey(const ValueKey('event-group-any-root'));
    expect(all, findsOneWidget);
    expect(any, findsOneWidget);
    expect(tester.widget<StudioChoice>(any).selected, isTrue);
    expect(tester.widget<StudioChoice>(all).selected, isFalse);
    await tester.tap(all);
    await tester.pump();
    expect(
      changes.single,
      NarrativeEventConditionExpression.all([notTicket, ready]),
    );
    expect(find.byTooltip('Au moins une'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inverting announces its effect before it is applied', (
    tester,
  ) async {
    final changes = await pump(
      tester,
      NarrativeEventConditionExpression.all([ready]),
    );
    expect(
      find.byTooltip(
        'Inverser : se déclencher quand « Prêt est égal à Oui » est faux',
      ),
      findsWidgets,
    );
    expect(changes, isEmpty);
    expect(
      text(tester, 'event-conditions-result'),
      'L’événement se déclenche quand Prêt est égal à Oui.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty condition list reads as no condition', (tester) async {
    await pump(tester, NarrativeEventConditionExpression.all(const []));
    expect(
      text(tester, 'event-conditions-result'),
      'L’événement se déclenche sans condition.',
    );
  });

  testWidgets('a story zone names the events it triggers', (tester) async {
    final document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a').copyWith(
          triggers: const [
            MapTrigger(
              id: 'quai',
              name: 'Quai',
              type: TriggerType.event,
              area: MapRect(
                pos: GridPos(x: 2, y: 3),
                size: GridSize(width: 2, height: 1),
              ),
            ),
          ],
        ),
        revision: 'r0',
        mapId: 'a',
      ),
    );
    final project = workspaceProject.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: 'evt_00000000-0000-7000-8000-000000000011',
              name: 'Annonce du train',
              source: NarrativeEventSourceRef.triggerEnter('a', 'quai'),
              conditions: const [],
              priority: 0,
              order: 0,
            ),
          ),
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: 'evt_00000000-0000-7000-8000-000000000012',
              name: 'Autre zone',
              source: NarrativeEventSourceRef.triggerEnter('a', 'ailleurs'),
              conditions: const [],
              priority: 0,
              order: 0,
            ),
          ),
        ],
        legacyClaims: const [],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: MapTriggerInspector(
            document: document,
            project: project,
            trigger: document.current.triggers.single,
            onChanged: () {},
            onDeleted: () {},
          ),
        ),
      ),
    );
    final events = find.byKey(const ValueKey('trigger-events'));
    expect(
      find.descendant(
        of: events,
        matching: find.textContaining('Annonce du train'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: events, matching: find.textContaining('en entrant')),
      findsOneWidget,
    );
    expect(find.textContaining('Autre zone'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
