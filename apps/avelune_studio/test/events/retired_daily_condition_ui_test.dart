import 'package:avelune_studio/features/events/application/event_condition_labels.dart';
import 'package:avelune_studio/presentation/features/events/event_condition_dialog.dart';
import 'package:avelune_studio/presentation/features/events/event_conditions.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  for (final expected in [false, true]) {
    testWidgets(
      'unavailable daily condition intent preserves exact reference predicate and groups expected=$expected',
      (tester) async {
        tester.view.physicalSize = const Size(1536, 1024);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final reference = PeriodicRewardReference(
          sceneId: 'published-scene',
          nodeId: 'claim',
          rewardId: 'daily-fruit',
        );
        final condition = NarrativeEventCondition.periodicRewardAvailable(
          reference: reference,
          expectedValue: expected,
        );
        final expression = NarrativeEventConditionExpression.any([
          NarrativeEventConditionExpression.not(
            NarrativeEventConditionExpression.leaf(condition),
          ),
          NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.fact('ready', true),
          ),
        ]);
        final before = expression.toJson();
        var changes = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: EventConditions(
                expression: expression,
                facts: [NarrativeFactDefinition(id: 'ready', label: 'Prêt')],
                records: const [],
                onChanged: (_) => changes++,
              ),
            ),
          ),
        );
        final panel = find.byWidgetPredicate(
          (widget) =>
              widget is StudioPanel &&
              widget.title ==
                  eventConditionLabel(condition, const [], const []),
        );
        expect(panel, findsOneWidget);
        final edit = find.descendant(
          of: panel,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is StudioTool && widget.label == 'Modifier la condition',
          ),
        );
        expect(edit, findsOneWidget);
        expect(tester.widget<StudioTool>(edit).onPressed, isNull);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        final context = tester.element(find.byType(EventConditions));
        final result = await chooseEventCondition(
          context,
          facts: const [],
          records: const [],
          initial: condition,
        );
        expect(result, isNull);
        expect(find.byType(AlertDialog), findsNothing);
        expect(changes, 0);
        expect(expression.toJson(), before);
        expect(condition.rewardReference, same(reference));
        expect(condition.expectedValue, expected);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets(
    'remaining fact condition edits stay available and daily creation is absent',
    (tester) async {
      final initial = NarrativeEventCondition.fact('ready', false);
      final expression = NarrativeEventConditionExpression.leaf(initial);
      NarrativeEventConditionExpression? changed;
      final facts = [NarrativeFactDefinition(id: 'ready', label: 'Prêt')];
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: EventConditions(
              expression: expression,
              facts: facts,
              records: const [],
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Modifier la condition'));
      await tester.pumpAndSettle();
      final kind = tester.widget<StudioSelect>(
        find.byWidgetPredicate(
          (widget) => widget is StudioSelect && widget.label == 'Condition sur',
        ),
      );
      expect(kind.options, isNot(contains('periodicReward')));
      final expected = tester.widget<StudioSelect>(
        find.byWidgetPredicate(
          (widget) =>
              widget is StudioSelect && widget.label == 'Valeur attendue',
        ),
      );
      expected.onChanged!('true');
      await tester.pump();
      await tester.tap(
        find.widgetWithText(StudioButton, 'Appliquer la condition'),
      );
      await tester.pumpAndSettle();
      expect(
        changed,
        NarrativeEventConditionExpression.leaf(
          NarrativeEventCondition.fact('ready', true),
        ),
      );
      expect(expression, NarrativeEventConditionExpression.leaf(initial));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
