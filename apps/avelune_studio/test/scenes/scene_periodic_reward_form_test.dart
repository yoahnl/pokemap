import 'package:avelune_studio/presentation/features/scenes/scene_action_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  for (final existing in [false, true]) {
    testWidgets(
      'periodic picker applies label item quantity and keeps identity existing=$existing',
      (tester) async {
        final results = <SceneNodePayload>[];
        var loads = 0;
        final current = SceneActionPayload.interactive(
          SceneInteractiveCommand.claimPeriodicReward(
            definition: PeriodicItemRewardDefinition(
              rewardId: 'saved-reward',
              label: 'Fruit',
              itemId: 'fruit',
              quantity: 2,
            ),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SceneActionForm(
                  project: const ProjectManifest(
                    name: 'Reward',
                    maps: [],
                    tilesets: [],
                  ),
                  current: existing ? current : null,
                  loadItems: () async {
                    loads++;
                    return {'fruit': 'Noigrume rouge', 'ball': 'Poké Ball'};
                  },
                  onApply: results.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        StudioSelect select(String label) => tester.widget<StudioSelect>(
          find.byWidgetPredicate(
            (widget) => widget is StudioSelect && widget.label == label,
          ),
        );
        if (!existing) {
          select('Commande').onChanged!('claimPeriodicReward');
          await tester.pumpAndSettle();
        }
        expect(select('Objet').options, {
          'fruit': 'Noigrume rouge',
          'ball': 'Poké Ball',
        });
        Future<void> field(String label, String value) async {
          final finder = find.descendant(
            of: find.byWidgetPredicate(
              (widget) => widget is StudioDraftField && widget.label == label,
            ),
            matching: find.byType(TextField),
          );
          await tester.ensureVisible(finder);
          await tester.enterText(finder, value);
          await tester.pump();
        }

        await field('Nom de la récompense', 'Récolte du jardin');
        select('Objet').onChanged!('ball');
        await tester.pump();
        await field('Quantité', '3');
        Future<void> apply() async {
          final finder = find.widgetWithText(
            StudioButton,
            existing ? 'Appliquer l’action' : 'Ajouter l’action',
          );
          expect(tester.widget<StudioButton>(finder).onPressed, isNotNull);
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pump();
        }

        await apply();
        final first =
            ((results.last as SceneActionPayload).interactiveCommand
                    as SceneClaimPeriodicRewardInteractiveCommand)
                .definition;
        expect(
          first.rewardId,
          existing ? 'saved-reward' : startsWith('reward-'),
        );
        expect(first.label, 'Récolte du jardin');
        expect(first.itemId, 'ball');
        expect(first.quantity, 3);
        await field('Quantité', '0');
        expect(
          tester
              .widget<StudioButton>(
                find.widgetWithText(
                  StudioButton,
                  existing ? 'Appliquer l’action' : 'Ajouter l’action',
                ),
              )
              .onPressed,
          isNull,
        );
        await field('Quantité', '4');
        await apply();
        final second =
            ((results.last as SceneActionPayload).interactiveCommand
                    as SceneClaimPeriodicRewardInteractiveCommand)
                .definition;
        expect(second.rewardId, first.rewardId);
        expect(second.quantity, 4);
        expect(loads, 1);
      },
    );
  }
  testWidgets('missing item keeps reward intact and disables apply', (
    tester,
  ) async {
    var applies = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SceneActionForm(
              project: const ProjectManifest(
                name: 'Reward',
                maps: [],
                tilesets: [],
              ),
              current: SceneActionPayload.interactive(
                SceneInteractiveCommand.claimPeriodicReward(
                  definition: PeriodicItemRewardDefinition(
                    rewardId: 'saved-reward',
                    label: 'Fruit',
                    itemId: 'removed',
                    quantity: 1,
                  ),
                ),
              ),
              loadItems: () async => {'fruit': 'Fruit'},
              onApply: (_) => applies++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<StudioButton>(
            find.widgetWithText(StudioButton, 'Appliquer l’action'),
          )
          .onPressed,
      isNull,
    );
    expect(applies, 0);
  });

  testWidgets(
    'periodic reward reopens a stable identity in the guided item form',
    (tester) async {
      final definition = PeriodicItemRewardDefinition(
        rewardId: 'tree-fruit',
        label: 'Fruit quotidien',
        itemId: 'fruit',
        quantity: 2,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SceneActionForm(
                project: const ProjectManifest(
                  name: 'Reward',
                  maps: [],
                  tilesets: [],
                ),
                current: SceneActionPayload.interactive(
                  SceneInteractiveCommand.claimPeriodicReward(
                    definition: definition,
                  ),
                ),
                onApply: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<StudioSelect>(find.byType(StudioSelect).first).value,
        'claimPeriodicReward',
      );
      expect(find.text('Identité stable de la récompense'), findsNothing);
      expect(find.text('Nom de la récompense'), findsOneWidget);
      expect(
        find.widgetWithText(StudioButton, 'Appliquer l’action'),
        findsOneWidget,
      );
    },
  );
}
