import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui12_world_harness.dart';

void main() {
  test(
    'a state and the rule that hides an entity survive a reopening',
    () async {
      final h = await Ui12WorldHarness.create();
      var disposed = false;
      addTearDown(() async {
        if (!disposed) await h.dispose();
      });

      final factId = h.world.createFact();
      h.world.editFact(
        NarrativeFactDefinition(
          id: factId,
          label: 'Train parti',
          initialValue: const NarrativeValue.boolean(false),
        ),
      );
      expect(h.world.isFactDirty(factId), isTrue);
      expect(await h.world.saveFact(factId), isTrue, reason: h.world.error);
      // The canonical creation names the state after its label.
      final savedFactId = h.world.selectedFactId!;
      expect(savedFactId, isNot(factId));
      expect(h.world.isFactDirty(savedFactId), isFalse);

      final map = h.world.maps.firstWhere((map) => map.entities.isNotEmpty);
      final entity = map.entities.first;
      final ruleId = h.world.createRule(factId: savedFactId);
      h.world.editRule(ruleId, (draft) {
        draft.label = 'Masquer le conducteur';
        draft.source = WorldRuleSource.factValue(
          factId: savedFactId,
          operator: NarrativeFactOperator.equals,
          expectedValue: const NarrativeValue.boolean(true),
        );
        draft.target = WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: map.id,
          entityId: entity.id,
        );
        draft.effect = const WorldRuleEffect(
          kind: WorldRuleEffectKind.entityHidden,
        );
      });
      expect(h.world.ruleDraft(ruleId)!.missing, isEmpty);
      expect(await h.world.saveRule(ruleId), isTrue, reason: h.world.error);
      final savedRuleId = h.world.selectedRuleId!;

      bool visible(Ui12WorldHarness harness) => harness
          .world
          .report!
          .entityStates
          .firstWhere(
            (state) => state.mapId == map.id && state.entityId == entity.id,
          )
          .visible;

      h.world.simulate();
      expect(visible(h), isTrue, reason: 'The initial value is false');

      h.world.setSimulationValue(
        savedFactId,
        const NarrativeValue.boolean(true),
      );
      h.world.simulate();
      expect(visible(h), isFalse, reason: 'The condition now holds');
      expect(
        h.world.traceFor(savedRuleId)!.winner,
        isTrue,
        reason: 'The projection must retain the only rule on this target',
      );
      expect(
        h.world.fact(savedFactId)!.initialValue,
        const NarrativeValue.boolean(false),
        reason: 'A test value never rewrites the value of the project',
      );

      await h.dispose(deleteDirectory: false);
      disposed = true;
      final reopened = await Ui12WorldHarness.open(h.directory);
      addTearDown(reopened.dispose);
      expect(reopened.world.fact(savedFactId)!.label, 'Train parti');
      expect(
        reopened.world.fact(savedFactId)!.initialValue,
        const NarrativeValue.boolean(false),
      );
      final saved = reopened.world.rule(savedRuleId)!;
      expect(saved.target.entityId, entity.id);
      expect(saved.effect.kind, WorldRuleEffectKind.entityHidden);

      reopened.world.simulate();
      expect(visible(reopened), isTrue);
      reopened.world.setSimulationValue(
        savedFactId,
        const NarrativeValue.boolean(true),
      );
      reopened.world.simulate();
      expect(visible(reopened), isFalse);
    },
  );
}
