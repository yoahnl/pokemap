import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  final facts = [
    NarrativeFactDefinition(
      id: 'count',
      label: 'Nombre de billets',
      initialValue: NarrativeValue.integer(0),
    ),
    NarrativeFactDefinition(
      id: 'name',
      label: 'Nom du quai',
      initialValue: const NarrativeValue.string(''),
    ),
    NarrativeFactDefinition(id: 'pass', label: 'Laissez-passer'),
  ];
  final project = ProjectManifest(
    name: 'Test',
    maps: [],
    tilesets: [],
    facts: facts,
  );
  final changes = <SceneConditionSource>[];
  setUp(changes.clear);
  Future<void> pump(
    WidgetTester tester,
    SceneConditionSource? source, {
    ProjectManifest? catalog,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: SceneConditionForm(
              project: catalog ?? project,
              current: SceneConditionPayload(conditionSource: source),
              onApply: changes.add,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'integer comparison only applies explicitly and refuses invalid integer',
    (tester) async {
      await pump(
        tester,
        SceneConditionSource.factValue(
          factId: 'count',
          operator: NarrativeFactOperator.greaterThanOrEqual,
          expectedValue: NarrativeValue.integer(3),
        ),
      );
      expect(changes, isEmpty);
      await tester.enterText(find.byType(TextField), '5');
      expect(changes, isEmpty);
      await tester.tap(find.text('Appliquer la condition'));
      expect(changes.single.expectedFactValue, NarrativeValue.integer(5));
      expect(
        changes.single.factOperator,
        NarrativeFactOperator.greaterThanOrEqual,
      );
      await tester.enterText(find.byType(TextField), '5.2');
      await tester.pump();
      final button = tester.widget<StudioButton>(find.byType(StudioButton));
      expect(button.onPressed, isNull);
      expect(changes, hasLength(1));
    },
  );

  testWidgets('string value keeps spaces and exposes equality operators only', (
    tester,
  ) async {
    await pump(
      tester,
      SceneConditionSource.factValue(
        factId: 'name',
        operator: NarrativeFactOperator.notEquals,
        expectedValue: const NarrativeValue.string('Quai'),
      ),
    );
    await tester.enterText(find.byType(TextField), '  Quai nord  ');
    await tester.tap(find.text('Appliquer la condition'));
    expect(
      changes.single.expectedFactValue,
      const NarrativeValue.string('  Quai nord  '),
    );
    expect(changes.single.factOperator, NarrativeFactOperator.notEquals);
    final selectors = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(selectors, hasLength(3));
    expect(find.text('Est supérieur à'), findsNothing);
  });

  testWidgets(
    'advanced source remains intact without selecting a replacement',
    (tester) async {
      final advanced = SceneConditionSource(
        sourceKind: SceneConditionSourceKind.worldState,
        sourceId: 'weather',
        operator: SceneConditionOperator.equals,
        value: 'rain',
        label: 'Météo',
      );
      await pump(tester, advanced);
      expect(changes, isEmpty);
      expect(
        find.textContaining('Condition avancée conservée'),
        findsOneWidget,
      );
      expect(
        tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty catalogue does not choose a fictitious source', (
    tester,
  ) async {
    await pump(
      tester,
      null,
      catalog: const ProjectManifest(name: 'Vide', maps: [], tilesets: []),
    );
    expect(changes, isEmpty);
    expect(find.textContaining('Aucune référence disponible'), findsOneWidget);
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
