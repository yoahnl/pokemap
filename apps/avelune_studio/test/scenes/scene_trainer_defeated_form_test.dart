import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  const trainer = ProjectTrainerEntry(
    id: 'clair',
    name: 'Sandra',
    trainerClass: 'Championne',
  );
  Future<void> pump(
    WidgetTester tester,
    ProjectManifest project,
    ValueChanged<SceneConditionSource> onApply,
  ) => tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: SceneConditionForm(
              project: project,
              current: SceneConditionPayload(
                conditionSource: SceneConditionSource.trainerDefeated(
                  trainerId: 'clair',
                ),
              ),
              onApply: onApply,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'trainer picker authors the raw trainer ID and inverse condition only on apply',
    (tester) async {
      final changes = <SceneConditionSource>[];
      await pump(
        tester,
        ProjectManifest(
          name: 'Johto',
          maps: [],
          tilesets: [],
          trainers: [
            trainer,
            trainer.copyWith(
              id: 'lugia',
              name: 'Lugia',
              tags: ['static-encounter'],
            ),
          ],
        ),
        changes.add,
      );
      expect(find.text('Dresseur déjà vaincu'), findsOneWidget);
      var selectors = tester
          .widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .toList();
      expect(selectors, hasLength(3));
      expect(
        tester
            .widgetList<StudioSelect>(find.byType(StudioSelect))
            .toList()[1]
            .options
            .keys,
        ['clair'],
      );
      expect(find.textContaining('trainer_defeated:'), findsNothing);
      selectors[2].onChanged!('false');
      await tester.pump();
      expect(changes, isEmpty);
      await tester.tap(find.text('Appliquer la condition'));
      expect(
        changes.single.sourceKind,
        SceneConditionSourceKind.trainerDefeated,
      );
      expect(changes.single.sourceId, 'clair');
      expect(changes.single.trainerDefeatedExpected, isFalse);
      expect(changes.single.factOperator, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removed or ambiguous trainer leaves apply disabled without choosing another ID',
    (tester) async {
      for (final trainers in <List<ProjectTrainerEntry>>[
        [],
        [trainer, trainer],
      ]) {
        final changes = <SceneConditionSource>[];
        await pump(
          tester,
          ProjectManifest(
            name: 'Johto',
            maps: [],
            tilesets: [],
            trainers: trainers,
          ),
          changes.add,
        );
        expect(
          tester.widget<StudioButton>(find.byType(StudioButton)).onPressed,
          isNull,
        );
        expect(changes, isEmpty);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
