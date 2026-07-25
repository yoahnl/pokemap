import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('world service requests are typed and own their access policy', () {
    final shop = OpenShopService(
      interactionId: 'npc.mart',
      shopId: 'shop.port',
      requiredCapabilities: <String>{'service.shop.v1'},
      availabilityCondition: ScriptConditionFactory.flagIsSet('mart_open'),
    );
    const heal = OpenHealService(
      interactionId: 'npc.nurse',
      requiresConfirmation: false,
    );
    const pc = OpenPcService(
      interactionId: 'object.pc',
      storageId: 'regional',
    );

    expect(shop.kind, RuntimeWorldServiceKind.shop);
    expect(shop.interactionId, 'npc.mart');
    expect(shop.shopId, 'shop.port');
    expect(shop.requiredCapabilities, <String>{'service.shop.v1'});
    expect(shop.availabilityCondition, isNotNull);
    expect(heal.kind, RuntimeWorldServiceKind.heal);
    expect(heal.requiresConfirmation, isFalse);
    expect(pc.kind, RuntimeWorldServiceKind.pc);
    expect(pc.storageId, 'regional');
    expect(
        () => shop.requiredCapabilities.add('other'), throwsUnsupportedError);
  });

  test(
      'modal snapshot is immutable, revisioned and explains unavailable actions',
      () {
    final actions = <RuntimeWorldServiceActionAvailability>[
      const RuntimeWorldServiceActionAvailability.enabled(
        RuntimeWorldServiceAction.confirm,
      ),
      RuntimeWorldServiceActionAvailability.disabled(
        RuntimeWorldServiceAction.withdraw,
        reason: 'Aucune boîte n’est disponible.',
      ),
    ];
    final snapshot = RuntimeWorldServiceSnapshot(
      revision: 4,
      request: const OpenPcService(interactionId: 'object.pc'),
      stage: RuntimeWorldServiceStage.active,
      actions: actions,
      logicalSelectionId: 'box.local',
    );

    actions.clear();

    expect(snapshot.actions, hasLength(2));
    expect(snapshot.isActionEnabled(RuntimeWorldServiceAction.confirm), isTrue);
    expect(
        snapshot.isActionEnabled(RuntimeWorldServiceAction.withdraw), isFalse);
    expect(
      snapshot.unavailableReasonFor(RuntimeWorldServiceAction.withdraw),
      'Aucune boîte n’est disponible.',
    );
    expect(
      snapshot.next(
        stage: RuntimeWorldServiceStage.applying,
        logicalSelectionId: 'box.remote',
      ),
      isA<RuntimeWorldServiceSnapshot>()
          .having((value) => value.revision, 'revision', 5)
          .having(
            (value) => value.logicalSelectionId,
            'logicalSelectionId',
            'box.remote',
          ),
    );
  });

  test('service commands retain the exact source revision', () {
    const command = RuntimeWorldServiceCommand(
      action: RuntimeWorldServiceAction.confirm,
      snapshotRevision: 9,
      targetId: 'potion',
      quantity: 3,
    );

    expect(command.snapshotRevision, 9);
    expect(command.targetId, 'potion');
    expect(command.quantity, 3);
  });

  test('invalid identities, revisions and duplicate actions are rejected', () {
    expect(
      () => OpenShopService(interactionId: '', shopId: 'mart'),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => RuntimeWorldServiceSnapshot(
        revision: -1,
        request: const OpenPcService(interactionId: 'pc'),
        stage: RuntimeWorldServiceStage.active,
      ),
      throwsArgumentError,
    );
    expect(
      () => RuntimeWorldServiceSnapshot(
        revision: 0,
        request: const OpenPcService(interactionId: 'pc'),
        stage: RuntimeWorldServiceStage.active,
        actions: const <RuntimeWorldServiceActionAvailability>[
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.close,
          ),
          RuntimeWorldServiceActionAvailability.enabled(
            RuntimeWorldServiceAction.close,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
