import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_action_builder.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  for (final existing in [false, true]) {
    testWidgets(
      'periodic builder keeps stable identity and guided item existing=$existing',
      (tester) async {
        final results = <SceneNodePayload>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: PokeMapTheme.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SceneActionBuilder(
                  project: const ProjectManifest(
                    name: 'Reward',
                    maps: [],
                    tilesets: [],
                  ),
                  initialCommandId: 'claimPeriodicReward',
                  initialPayload: existing
                      ? SceneActionPayload.interactive(
                          SceneInteractiveCommand.claimPeriodicReward(
                            definition: PeriodicItemRewardDefinition(
                              rewardId: 'saved-reward',
                              label: 'Fruit',
                              itemId: 'fruit',
                              quantity: 2,
                            ),
                          ),
                        )
                      : null,
                  pickerOptions: const {
                    NarrativeCommandParameterKind.item: [
                      SceneActionPickerOption(
                        id: 'fruit',
                        label: 'Noigrume rouge',
                      ),
                    ],
                  },
                  onSubmit: results.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('scene-action-parameter-rewardId')),
          findsNothing,
        );
        expect(find.text('Noigrume rouge'), findsWidgets);
        Future<void> field(String id, String value) async {
          final finder = find.byKey(ValueKey('scene-action-parameter-$id'));
          await tester.ensureVisible(finder);
          await tester.enterText(finder, value);
          await tester.pump();
        }

        await field('label', 'Récolte du jardin');
        await field('quantity', '3');
        final submit = find.byKey(const ValueKey('scene-action-submit'));
        expect(tester.widget<PokeMapButton>(submit).onPressed, isNotNull);
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pump();
        final first =
            ((results.last as SceneActionPayload).interactiveCommand
                    as SceneClaimPeriodicRewardInteractiveCommand)
                .definition;
        expect(
          first.rewardId,
          existing ? 'saved-reward' : startsWith('reward-'),
        );
        expect(first.quantity, 3);
        expect(first.itemId, 'fruit');
        await field('quantity', '0');
        expect(tester.widget<PokeMapButton>(submit).onPressed, isNull);
        await field('quantity', '4');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pump();
        final second =
            ((results.last as SceneActionPayload).interactiveCommand
                    as SceneClaimPeriodicRewardInteractiveCommand)
                .definition;
        expect(second.rewardId, first.rewardId);
        expect(second.quantity, 4);
      },
    );
  }
}
