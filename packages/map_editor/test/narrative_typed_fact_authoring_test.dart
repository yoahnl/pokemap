import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_authoring_sheets.dart';
import 'package:map_editor/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart';

const _eventId = 'evt_019abcde-5100-7000-8000-000000000001';

void main() {
  testWidgets('Facts manager authors an integer without raw JSON',
      (tester) async {
    NarrativeValue? savedValue;
    final project = ProjectManifest(
      name: 'Typed Facts UI',
      maps: const [],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
          id: 'fact_reputation',
          label: 'Réputation',
          initialValue: NarrativeValue.integer(3),
        ),
      ],
    );
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: FactsWorldRulesWorkspace(
            project: project,
            activeMap: null,
            initialMode: FactsWorldRulesWorkspaceMode.facts,
            onCreateFact: ({required label}) async => null,
            onDuplicateFact: ({required factId}) async => null,
            onUpdateFact: ({
              required factId,
              required label,
              required description,
              required category,
              required initialValue,
            }) async {
              savedValue = initialValue;
              return true;
            },
            onRemoveFact: ({required factId}) async => false,
            onCreateWorldRule: ({
              required label,
              required description,
              required enabled,
              required source,
              required target,
              required effect,
              required priority,
            }) async =>
                null,
            onUpdateWorldRule: ({
              required ruleId,
              required label,
              required description,
              required enabled,
              required source,
              required target,
              required effect,
              required priority,
            }) async =>
                false,
            onRemoveWorldRule: ({required ruleId}) async => false,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('fact-list-fact_reputation')));
    await tester.pump();
    expect(
        find.byKey(const ValueKey('fact-editor-type-picker')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('fact-editor-value-field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('fact-editor-value-field')),
      '8',
    );
    await tester.tap(find.byKey(const ValueKey('fact-editor-save')));
    await tester.pump();

    expect(savedValue, NarrativeValue.integer(8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Event sheet authors a typed comparison without manual IDs',
      (tester) async {
    NarrativeEventConditionExpression? saved;
    await tester.binding.setSurfaceSize(const Size(540, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: EventBuilderV2ConditionsSheet(
            snapshot: _snapshot(),
            onSubmit: (expression) async {
              saved = expression;
              return 'keep-open';
            },
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('event-builder-v2-fact-operator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('event-builder-v2-fact-value')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-fact-operator')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('est supérieur ou égal à').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('event-builder-v2-fact-value')),
      '5',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-v2-add-condition')).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-add-condition')).first,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('event-builder-v2-save-conditions')).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('event-builder-v2-save-conditions')).first,
    );
    await tester.pump();

    final condition = saved!.leaves.single;
    expect(
        condition.comparisonOperator, NarrativeFactOperator.greaterThanOrEqual);
    expect(condition.expectedNarrativeValue, NarrativeValue.integer(5));
    expect(tester.takeException(), isNull);
  });
}

NarrativeEventBuilderV2EditorSnapshot _snapshot() {
  final record = NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Typed Event',
      source: NarrativeEventSourceRef.mapEnter('map_port'),
      conditions: const [],
      sceneId: 'scene_port',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: false,
  );
  return NarrativeEventBuilderV2EditorSnapshot(
    projectRevision: 'typed-revision',
    record: record,
    spatialSources: const [],
    outcomeSources: const [],
    scenes: const [],
    facts: [
      NarrativeEventProjectFactEntry(
        NarrativeFactDefinition(
          id: 'fact_reputation',
          label: 'Réputation',
          initialValue: NarrativeValue.integer(0),
        ),
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
