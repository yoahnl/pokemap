import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';

void main() {
  testWidgets('authors ANY and NOT as one bounded expression', (tester) async {
    final condition = NarrativeEventCondition.fact('fact_open', true);
    final expression = NarrativeEventConditionExpression.any([
      NarrativeEventConditionExpression.leaf(condition),
    ]);
    NarrativeEventConditionExpression? saved;
    await tester.binding.setSurfaceSize(const Size(520, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: EventBuilderV2ConditionsSheet(
            snapshot: _snapshot(expression),
            onSubmit: (value) async {
              saved = value;
              return 'keep-open';
            },
          ),
        ),
      ),
    );

    expect(find.text('Au moins une doit être remplie'), findsOneWidget);
    expect(find.text('Port ouvert est égal à Vrai'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-negate-condition-0')),
    );
    await tester.scrollUntilVisible(
      find.text('Enregistrer les conditions'),
      240,
    );
    await tester.tap(find.text('Enregistrer les conditions'));
    await tester.pump();

    expect(saved, isA<NarrativeEventConditionAny>());
    final any = saved! as NarrativeEventConditionAny;
    expect(any.children.single, isA<NarrativeEventConditionNot>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers deterministic reset policies only for one-shot Events',
      (tester) async {
    final outcome = NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene_signal',
      outcomeId: 'completed',
    );
    await tester.binding.setSurfaceSize(const Size(520, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: EventBuilderV2BehaviorSheet(
            record: _snapshot(
              NarrativeEventConditionExpression.all(const []),
            ).record!,
            outcomeSources: [
              NarrativeOutcomeEventSourceOption(
                outcome: outcome,
                producerLabel: 'Signal de Scene',
                outcomeLabel: 'Terminé',
                humanSourceSentence: 'Quand la Scene est terminée.',
                status: NarrativeOutcomeReachabilityStatus.reachable,
                selectable: true,
                origin: NarrativeOutcomeSourceOrigin.scene,
                debugTechnicalLabel: 'scene_signal#completed',
              ),
            ],
            onSave: (_) async => 'keep-open',
            onPublish: () async => 'keep-open',
            onSetEnabled: (_) async => 'keep-open',
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('event-builder-v2-reset-policy')),
      findsOneWidget,
    );
    expect(find.text('Jamais'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

NarrativeEventBuilderV2EditorSnapshot _snapshot(
  NarrativeEventConditionExpression expression,
) {
  final conditions = expression.leaves;
  final record = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Rencontre au port',
      source: NarrativeEventSourceRef.mapEnter('map_port'),
      conditions: conditions,
      conditionExpression: expression,
      sceneId: 'scene_port',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: false,
  );
  return NarrativeEventBuilderV2EditorSnapshot(
    projectRevision: 'revision',
    record: record,
    spatialSources: const [],
    outcomeSources: const [],
    scenes: const [],
    facts: [
      NarrativeEventProjectFactEntry(
        NarrativeFactDefinition(id: 'fact_open', label: 'Port ouvert'),
      ),
    ],
    events: [
      NarrativeEventProjectEventEntry(
        record: record,
        proposed: false,
        inDependencyCycle: false,
        contextuallyValid: true,
      ),
    ],
  );
}
