import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  testWidgets('caught species editing follows the current project dimension', (
    tester,
  ) async {
    final source = SceneConditionSource.pokedexCaughtAtLeast(
      range: PokedexSpeciesRange(firstNationalDex: 1, lastNationalDex: 151),
      minimum: 20,
    );
    final changes = <SceneConditionSource>[];
    Future<void> show(ProjectDimension dimension) => tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SceneConditionForm(
              key: const ValueKey('condition-form'),
              project: ProjectManifest(
                name: 'Kanto',
                maps: [],
                tilesets: [],
                settings: ProjectSettings(dimension: dimension),
              ),
              current: SceneConditionPayload(conditionSource: source),
              onApply: changes.add,
            ),
          ),
        ),
      ),
    );
    await show(ProjectDimension.twoD);
    expect(find.byType(TextField), findsNWidgets(3));
    await show(ProjectDimension.threeD);
    final picker = tester
        .widgetList<StudioSelect>(find.byType(StudioSelect))
        .singleWhere((value) => value.label == 'Source de la condition');
    expect(picker.options, isNot(contains('pokedexCaughtCount')));
    expect(find.textContaining('Condition avancée conservée'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNull,
    );
    expect(changes, isEmpty);
    await show(ProjectDimension.twoD);
    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.textContaining('Condition avancée conservée'), findsNothing);
    expect(
      tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
      isNotNull,
    );
    expect(changes, isEmpty);
  });

  testWidgets(
    'caught Pokédex threshold is editable without technical ids and applies explicitly',
    (tester) async {
      final changes = <SceneConditionSource>[];
      final source = SceneConditionSource.pokedexCaughtAtLeast(
        range: PokedexSpeciesRange(firstNationalDex: 1, lastNationalDex: 151),
        minimum: 20,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 400,
                child: SceneConditionForm(
                  project: ProjectManifest(
                    name: 'Kanto',
                    maps: [],
                    tilesets: [],
                  ),
                  current: SceneConditionPayload(conditionSource: source),
                  onApply: changes.add,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('Condition avancée conservée'), findsNothing);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(changes, isEmpty);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('pokedex-minimum-count')),
          matching: find.byType(TextField),
        ),
        '25',
      );
      await tester.tap(find.text('Appliquer la condition'));
      expect(changes.single.pokedexMinimumCaughtCount, 25);
      expect(changes.single.pokedexSpeciesRange, source.pokedexSpeciesRange);
      expect(changes.single.operator, SceneConditionOperator.isTrue);
      for (final invalid in ['0', '5.2', '65536', 'bad']) {
        await tester.enterText(
          find.descendant(
            of: find.byKey(const ValueKey('pokedex-minimum-count')),
            matching: find.byType(TextField),
          ),
          invalid,
        );
        await tester.pump();
        expect(
          tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
          isNull,
        );
      }
      expect(changes, hasLength(1));
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('pokedex-minimum-count')),
          matching: find.byType(TextField),
        ),
        '20',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('pokedex-first-national')),
          matching: find.byType(TextField),
        ),
        '200',
      );
      await tester.pump();
      expect(
        tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
        isNull,
      );
      expect(changes, hasLength(1));
    },
  );
}
