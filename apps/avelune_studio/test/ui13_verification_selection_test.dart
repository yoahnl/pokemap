import 'package:avelune_studio/features/verification/application/verification_workspace_controller.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/ui13_verification_harness.dart';

void main() {
  test('a new control keeps a selection whose key survives', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final chosen = h.verification.report!.diagnostics.first;
    h.verification.select(chosen.stableKey);

    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    expect(
      h.verification.selectedKey,
      chosen.stableKey,
      reason: 'the same problem stays chosen across two controls',
    );
    expect(h.verification.selectionNotice, isNull);
  });

  test('a selection that vanished is explained, not called solved', () async {
    final h = await Ui13VerificationHarness.create();
    addTearDown(h.dispose);
    await h.world.initialize();
    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    final orphan = h.verification.report!.diagnostics.firstWhere(
      (item) =>
          item.code == 'worldRuleSourceUnknown' &&
          item.worldRuleId == Ui13VerificationHarness.orphanRuleId,
    );
    h.verification.select(orphan.stableKey);

    final map = h.world.maps.firstWhere((item) => item.entities.isNotEmpty);
    final entity = map.entities.first;
    h.world.editRule(Ui13VerificationHarness.orphanRuleId, (draft) {
      draft.source = WorldRuleSource.factValue(
        factId: Ui13VerificationHarness.knownFactId,
        operator: NarrativeFactOperator.equals,
        expectedValue: const NarrativeValue.boolean(true),
      );
      draft.target = WorldRuleTarget(
        kind: WorldRuleTargetKind.mapEntity,
        mapId: map.id,
        entityId: entity.id,
        label: entity.id,
      );
    });
    expect(
      await h.world.saveRule(Ui13VerificationHarness.orphanRuleId),
      isTrue,
      reason: h.world.error ?? '',
    );

    expect(await h.verification.run(), isTrue, reason: h.verification.error);
    expect(h.verification.selectedKey, isNull);
    expect(
      h.verification.selectionNotice,
      contains('ne prouve pas qu’il est résolu'),
      reason: 'a vanished key is not a proof of resolution',
    );
  });
}
