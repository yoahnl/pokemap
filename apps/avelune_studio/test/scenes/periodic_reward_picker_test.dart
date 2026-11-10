import 'package:avelune_studio/features/world/application/world_editor_workflow.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/world_authoring_workflow_fixture.dart';

PeriodicRewardReference reference(String scene) => PeriodicRewardReference(
  sceneId: scene,
  nodeId: 'claim',
  rewardId: 'daily-$scene',
);

void main() {
  test(
    'World Rule coordinator preserves an existing negative daily predicate',
    () async {
      final h = await WorldAuthoringWorkflowFixture.create();
      addTearDown(h.dispose);
      final world = h.world;
      final id = world.createRule();
      world.editRule(
        id,
        (draft) => draft.source = WorldRuleSource.periodicRewardAvailable(
          reference: reference('A'),
          expectedValue: false,
        ),
      );
      final initial = worldPeriodicRewardSelection(world.ruleDraft(id)!.source);
      expect(initial.reference, reference('A'));
      expect(initial.expectedValue, isFalse);
      h.editor.applyPeriodicRewardCondition(
        id,
        initial.reference!,
        initial.expectedValue,
      );
      expect(
        world.ruleDraft(id)!.source!.predicate,
        WorldRuleSourcePredicate.isFalse,
      );
      expect(world.ruleDraft(id)!.source!.rewardReference, reference('A'));
    },
  );
}
