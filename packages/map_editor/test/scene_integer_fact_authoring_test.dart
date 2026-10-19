import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_node_read_only_inspector.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

ProjectManifest _project({bool integer = true}) => ProjectManifest(
  name: 'Integer authoring',
  maps: const [],
  tilesets: const [],
  facts: [
    if (integer)
      NarrativeFactDefinition(
        id: 'counter',
        label: 'Avancement',
        initialValue: NarrativeValue.integer(0),
      ),
    NarrativeFactDefinition(id: 'flag', label: 'Drapeau'),
    NarrativeFactDefinition(
      id: 'text',
      label: 'Texte',
      initialValue: const NarrativeValue.string('Original'),
    ),
    NarrativeFactDefinition(
      id: 'duplicate',
      label: 'Doublon A',
      initialValue: NarrativeValue.integer(0),
    ),
    NarrativeFactDefinition(
      id: 'duplicate',
      label: 'Doublon B',
      initialValue: NarrativeValue.integer(0),
    ),
  ],
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SingleChildScrollView(child: SizedBox(width: 440, child: child)),
      ),
    ),
  );
  await tester.pump();
}

PokeMapButton _submit(WidgetTester tester) => tester.widget<PokeMapButton>(
  find.byKey(const ValueKey('scene-action-submit')),
);

void main() {
  testWidgets(
    'adjustment selects only unique integer facts and accepts signed bounds',
    (tester) async {
      SceneNodePayload? submitted;
      await _pump(
        tester,
        SceneActionBuilder(
          project: _project(),
          initialCommandId: 'adjustIntegerFact',
          initialParameters: const {
            'delta': '-2',
            'minimum': '-5',
            'maximum': '0',
          },
          onSubmit: (payload) => submitted = payload,
        ),
      );
      final picker = tester.widget<PokeMapDropdownField<String>>(
        find.byWidgetPredicate(
          (widget) =>
              widget is PokeMapDropdownField<String> &&
              widget.label == 'Compteur',
        ),
      );
      expect(picker.items.map((item) => item.value), ['counter']);
      expect(_submit(tester).onPressed, isNotNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-action-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      expect(
        (submitted as SceneActionPayload).consequence,
        SceneConsequence.adjustIntegerFact(
          factId: 'counter',
          delta: -2,
          minimum: -5,
          maximum: 0,
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('scene-action-parameter-maximum')),
        '-6',
      );
      await tester.pump();
      expect(_submit(tester).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('scene-action-parameter-maximum')),
        '0',
      );
      await tester.enterText(
        find.byKey(const ValueKey('scene-action-parameter-delta')),
        '9007199254740992',
      );
      await tester.pump();
      expect(_submit(tester).onPressed, isNull);
    },
  );

  testWidgets('editing an adjustment retains its signed initial parameters', (
    tester,
  ) async {
    final original = SceneConsequence.adjustIntegerFact(
      factId: 'counter',
      delta: -3,
      minimum: -12,
      maximum: 0,
    );
    await _pump(
      tester,
      SceneActionBuilder(
        project: _project(),
        initialPayload: SceneActionPayload.consequence(original),
        allowCommandSelection: false,
        onSubmit: (_) {},
      ),
    );
    for (final field in {
      'delta': '-3',
      'minimum': '-12',
      'maximum': '0',
    }.entries) {
      final widget = tester.widget<TextField>(
        find.byKey(ValueKey('scene-action-parameter-${field.key}')),
      );
      expect(widget.controller!.text, field.value);
    }
    expect(_submit(tester).onPressed, isNotNull);
  });

  testWidgets(
    'an adjustment without an unambiguous integer fact cannot publish',
    (tester) async {
      await _pump(
        tester,
        SceneActionBuilder(
          project: _project(integer: false),
          initialCommandId: 'adjustIntegerFact',
          onSubmit: (_) {},
        ),
      );
      expect(_submit(tester).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final invalidTarget in ['missing', 'flag', 'duplicate']) {
    testWidgets('an adjustment can replace invalid target $invalidTarget', (
      tester,
    ) async {
      SceneNodePayload? submitted;
      await _pump(
        tester,
        SceneActionBuilder(
          project: _project(),
          initialPayload: SceneActionPayload.consequence(
            SceneConsequence.adjustIntegerFact(
              factId: invalidTarget,
              delta: -2,
              minimum: -5,
              maximum: 8,
            ),
          ),
          allowCommandSelection: false,
          onSubmit: (value) => submitted = value,
        ),
      );
      expect(_submit(tester).onPressed, isNull);
      final picker = find.byWidgetPredicate(
        (widget) =>
            widget is PokeMapDropdownField<String> &&
            widget.label == 'Compteur',
      );
      expect(picker, findsOneWidget);
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Avancement').last);
      await tester.pumpAndSettle();
      expect(_submit(tester).onPressed, isNotNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-action-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      expect(
        (submitted as SceneActionPayload).consequence,
        SceneConsequence.adjustIntegerFact(
          factId: 'counter',
          delta: -2,
          minimum: -5,
          maximum: 8,
        ),
      );
    });
  }

  for (final value in [
    NarrativeValue.integer(-4),
    const NarrativeValue.boolean(true),
  ]) {
    testWidgets(
      'SET ${value.kind.name} target replacement preserves metadata',
      (tester) async {
        SceneConsequence? updated;
        await _pump(
          tester,
          _inspector(
            SceneConsequence.setFactValue(
              factId: 'missing',
              value: value,
              label: 'Original label',
              notes: 'Original notes',
            ),
            (result) => updated = result,
          ),
        );
        final change = find.byKey(
          const ValueKey('scene-consequence-edit-fact-action'),
        );
        await tester.ensureVisible(change);
        await tester.tap(change);
        await tester.pumpAndSettle();
        final target = value.kind == NarrativeValueKind.integer
            ? 'counter'
            : 'flag';
        await tester.tap(
          find.byKey(ValueKey('scene-consequence-fact-edit-option-$target')),
        );
        await tester.pumpAndSettle();
        final actual = updated! as SceneSetFactConsequence;
        expect(actual.factId, target);
        expect(actual.narrativeValue, value);
        expect(actual.label, 'Original label');
        expect(actual.notes, 'Original notes');
      },
    );
  }

  testWidgets(
    'imported integer SET edits its typed value without boolean coercion',
    (tester) async {
      final original = SceneConsequence.setFactValue(
        factId: 'counter',
        value: NarrativeValue.integer(-4),
        label: 'Original label',
        notes: 'Original notes',
      );
      SceneConsequence? updated;
      await _pump(tester, _inspector(original, (value) => updated = value));
      expect(tester.takeException(), isNull);
      final field = find.byKey(
        const ValueKey('scene-consequence-integer-value'),
      );
      expect(tester.widget<PokeMapTextField>(field).controller!.text, '-4');
      await tester.ensureVisible(field);
      await tester.enterText(field, '-7');
      await tester.pump();
      final apply = find.byKey(
        const ValueKey('scene-consequence-integer-apply'),
      );
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pump();
      final actual = updated! as SceneSetFactConsequence;
      expect(actual.narrativeValue, NarrativeValue.integer(-7));
      expect(actual.factId, 'counter');
      expect(actual.label, 'Original label');
      expect(actual.notes, 'Original notes');
    },
  );

  testWidgets(
    'adjustment inspector uses the guided editor and preserves metadata',
    (tester) async {
      final original = SceneConsequence.adjustIntegerFact(
        factId: 'counter',
        delta: -2,
        minimum: -5,
        maximum: 3,
        label: 'Counter label',
        notes: 'Counter notes',
      );
      SceneConsequence? updated;
      await _pump(tester, _inspector(original, (value) => updated = value));
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-action-parameter-delta')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('scene-action-parameter-delta')),
        '-3',
      );
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('scene-action-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('scene-action-submit')));
      await tester.pump();
      final actual = updated! as SceneAdjustIntegerFactConsequence;
      expect(actual.delta, -3);
      expect(actual.minimum, -5);
      expect(actual.maximum, 3);
      expect(actual.label, 'Counter label');
      expect(actual.notes, 'Counter notes');
    },
  );
}

Widget _inspector(
  SceneConsequence consequence,
  ValueChanged<SceneConsequence> changed,
) {
  final graph = SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'action',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(consequence),
      ),
    ],
  );
  final scene = SceneAsset(id: 'scene', name: 'Progression', graph: graph);
  return SceneNodeReadOnlyInspector(
    project: _project(),
    scene: NarrativeSceneSummary(
      id: scene.id,
      name: scene.name,
      nodeCount: 2,
      edgeCount: 0,
      declaredOutcomeCount: 0,
      declaredOutcomes: const [],
      tags: const [],
      graph: graph,
      layout: scene.layout,
      diagnostics: diagnoseScene(scene),
      outcomeDefinitions: const [],
    ),
    selectedNodeId: 'action',
    consequenceFactOptions: [
      SceneConsequenceFactPickerOption(
        factId: 'counter',
        label: 'Avancement',
        valueKind: NarrativeValueKind.integer,
        initialValue: NarrativeValue.integer(0),
      ),
      const SceneConsequenceFactPickerOption(factId: 'flag', label: 'Drapeau'),
    ],
    onUpdateActionConsequence: ({required nodeId, required consequence}) async {
      changed(consequence);
      return true;
    },
  );
}
