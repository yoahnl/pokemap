import 'dart:collection';

import 'package:map_core/map_core.dart';

enum RuntimeWorldServiceKind { shop, heal, pc }

/// Typed request emitted by an interaction in the running world.
///
/// Access metadata is evaluated by the runtime before it acquires the modal
/// input lock. Presentation code never decides whether a service may open.
sealed class RuntimeWorldServiceRequest {
  const RuntimeWorldServiceRequest({
    required this.interactionId,
    Set<String> requiredCapabilities = const <String>{},
    this.availabilityCondition,
  })  : assert(interactionId != ''),
        _requiredCapabilities = requiredCapabilities;

  final String interactionId;
  final Set<String> _requiredCapabilities;
  final ScriptCondition? availabilityCondition;

  RuntimeWorldServiceKind get kind;

  Set<String> get requiredCapabilities =>
      UnmodifiableSetView<String>(_requiredCapabilities);
}

final class OpenShopService extends RuntimeWorldServiceRequest {
  const OpenShopService({
    required super.interactionId,
    required this.shopId,
    super.requiredCapabilities,
    super.availabilityCondition,
  }) : assert(shopId != '');

  final String shopId;

  @override
  RuntimeWorldServiceKind get kind => RuntimeWorldServiceKind.shop;
}

final class OpenHealService extends RuntimeWorldServiceRequest {
  const OpenHealService({
    required super.interactionId,
    this.requiresConfirmation = true,
    super.requiredCapabilities,
    super.availabilityCondition,
  });

  final bool requiresConfirmation;

  @override
  RuntimeWorldServiceKind get kind => RuntimeWorldServiceKind.heal;
}

final class OpenPcService extends RuntimeWorldServiceRequest {
  const OpenPcService({
    required super.interactionId,
    this.storageId,
    super.requiredCapabilities,
    super.availabilityCondition,
  }) : assert(storageId == null || storageId != '');

  final String? storageId;

  @override
  RuntimeWorldServiceKind get kind => RuntimeWorldServiceKind.pc;
}

enum RuntimeWorldServiceStage {
  opening,
  active,
  applying,
  completed,
  failed,
}

enum RuntimeWorldServiceAction {
  select,
  decreaseQuantity,
  increaseQuantity,
  confirm,
  cancel,
  close,
  deposit,
  withdraw,
}

final class RuntimeShopEntrySnapshot {
  const RuntimeShopEntrySnapshot({
    required this.itemId,
    required this.label,
    required this.unitPrice,
    this.remainingStock,
  })  : assert(itemId != ''),
        assert(label != ''),
        assert(unitPrice >= 0),
        assert(remainingStock == null || remainingStock >= 0);

  final String itemId;
  final String label;
  final int unitPrice;
  final int? remainingStock;
}

/// Runtime-owned Shop projection. Prices and availability are already resolved.
final class RuntimeShopServiceContent {
  RuntimeShopServiceContent({
    required this.title,
    required this.message,
    required this.money,
    List<RuntimeShopEntrySnapshot> entries = const <RuntimeShopEntrySnapshot>[],
    this.selectedItemId,
    this.quantity = 1,
    this.totalPrice = 0,
  })  : assert(title != ''),
        assert(money >= 0),
        assert(quantity > 0),
        assert(totalPrice >= 0),
        entries = List<RuntimeShopEntrySnapshot>.unmodifiable(entries);

  final String title;
  final String message;
  final int money;
  final List<RuntimeShopEntrySnapshot> entries;
  final String? selectedItemId;
  final int quantity;
  final int totalPrice;
}

final class RuntimeHealPartyMemberSnapshot {
  const RuntimeHealPartyMemberSnapshot({
    required this.partyIndex,
    required this.label,
    required this.currentHp,
    required this.maxHp,
    required this.hasStatus,
    required this.depletedMoveCount,
  })  : assert(partyIndex >= 0),
        assert(label != ''),
        assert(currentHp >= 0),
        assert(maxHp > 0),
        assert(depletedMoveCount >= 0);

  final int partyIndex;
  final String label;
  final int currentHp;
  final int maxHp;
  final bool hasStatus;
  final int depletedMoveCount;
}

/// Runtime-owned healing projection. Recovery caps are already resolved.
final class RuntimeHealServiceContent {
  RuntimeHealServiceContent({
    required this.title,
    required this.message,
    List<RuntimeHealPartyMemberSnapshot> members =
        const <RuntimeHealPartyMemberSnapshot>[],
    this.wasHealed = false,
  })  : assert(title != ''),
        members = List<RuntimeHealPartyMemberSnapshot>.unmodifiable(members);

  final String title;
  final String message;
  final List<RuntimeHealPartyMemberSnapshot> members;
  final bool wasHealed;
}

final class RuntimePcBoxSnapshot {
  const RuntimePcBoxSnapshot({
    required this.boxId,
    required this.label,
    required this.count,
    required this.capacity,
  })  : assert(boxId != ''),
        assert(label != ''),
        assert(count >= 0),
        assert(capacity > 0),
        assert(count <= capacity);

  final String boxId;
  final String label;
  final int count;
  final int capacity;
}

final class RuntimePcPokemonSnapshot {
  const RuntimePcPokemonSnapshot({
    required this.targetId,
    required this.label,
    required this.level,
    required this.canTransfer,
    this.unavailableReason,
  })  : assert(targetId != ''),
        assert(label != ''),
        assert(level > 0),
        assert(
          canTransfer || (unavailableReason != null && unavailableReason != ''),
        );

  /// Opaque target echoed by the player UI. Only the runtime interprets it.
  final String targetId;
  final String label;
  final int level;
  final bool canTransfer;
  final String? unavailableReason;
}

/// Runtime-owned PC projection for one selected box.
final class RuntimePcServiceContent {
  RuntimePcServiceContent({
    required this.title,
    required this.message,
    required this.selectedBoxId,
    List<RuntimePcBoxSnapshot> boxes = const <RuntimePcBoxSnapshot>[],
    List<RuntimePcPokemonSnapshot> party = const <RuntimePcPokemonSnapshot>[],
    List<RuntimePcPokemonSnapshot> stored = const <RuntimePcPokemonSnapshot>[],
  })  : assert(title != ''),
        assert(selectedBoxId != ''),
        boxes = List<RuntimePcBoxSnapshot>.unmodifiable(boxes),
        party = List<RuntimePcPokemonSnapshot>.unmodifiable(party),
        stored = List<RuntimePcPokemonSnapshot>.unmodifiable(stored);

  final String title;
  final String message;
  final String selectedBoxId;
  final List<RuntimePcBoxSnapshot> boxes;
  final List<RuntimePcPokemonSnapshot> party;
  final List<RuntimePcPokemonSnapshot> stored;
}

final class RuntimeWorldServiceActionAvailability {
  const RuntimeWorldServiceActionAvailability.enabled(this.action)
      : isEnabled = true,
        unavailableReason = null;

  RuntimeWorldServiceActionAvailability.disabled(
    this.action, {
    required String reason,
  })  : isEnabled = false,
        unavailableReason = reason {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(
        reason,
        'reason',
        'must contain a player-safe explanation',
      );
    }
  }

  final RuntimeWorldServiceAction action;
  final bool isEnabled;
  final String? unavailableReason;
}

/// Data-only modal state rendered by `map_player_ui`.
///
/// [content] is always a runtime-owned immutable projection. Concrete content
/// models are introduced with each service lot.
final class RuntimeWorldServiceSnapshot {
  RuntimeWorldServiceSnapshot({
    required this.revision,
    required this.request,
    required this.stage,
    List<RuntimeWorldServiceActionAvailability> actions =
        const <RuntimeWorldServiceActionAvailability>[],
    this.content,
    this.safeMessage,
    this.logicalSelectionId,
  }) : actions =
            List<RuntimeWorldServiceActionAvailability>.unmodifiable(actions) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must be non-negative');
    }
    final actionStates =
        <RuntimeWorldServiceAction, RuntimeWorldServiceActionAvailability>{};
    for (final availability in this.actions) {
      if (actionStates.containsKey(availability.action)) {
        throw ArgumentError.value(
          availability.action,
          'actions',
          'contains duplicate action declarations',
        );
      }
      actionStates[availability.action] = availability;
    }
    _actionStates = UnmodifiableMapView<RuntimeWorldServiceAction,
        RuntimeWorldServiceActionAvailability>(actionStates);
  }

  final int revision;
  final RuntimeWorldServiceRequest request;
  final RuntimeWorldServiceStage stage;
  final List<RuntimeWorldServiceActionAvailability> actions;
  final Object? content;
  final String? safeMessage;
  final String? logicalSelectionId;

  late final Map<RuntimeWorldServiceAction,
      RuntimeWorldServiceActionAvailability> _actionStates;

  bool isActionEnabled(RuntimeWorldServiceAction action) =>
      _actionStates[action]?.isEnabled ?? false;

  String? unavailableReasonFor(RuntimeWorldServiceAction action) =>
      _actionStates[action]?.unavailableReason;

  RuntimeWorldServiceSnapshot next({
    RuntimeWorldServiceStage? stage,
    List<RuntimeWorldServiceActionAvailability>? actions,
    Object? content,
    bool clearContent = false,
    String? safeMessage,
    bool clearSafeMessage = false,
    String? logicalSelectionId,
    bool clearLogicalSelection = false,
  }) {
    return RuntimeWorldServiceSnapshot(
      revision: revision + 1,
      request: request,
      stage: stage ?? this.stage,
      actions: actions ?? this.actions,
      content: clearContent ? null : content ?? this.content,
      safeMessage: clearSafeMessage ? null : safeMessage ?? this.safeMessage,
      logicalSelectionId: clearLogicalSelection
          ? null
          : logicalSelectionId ?? this.logicalSelectionId,
    );
  }
}

final class RuntimeWorldServiceCommand {
  const RuntimeWorldServiceCommand({
    required this.action,
    required this.snapshotRevision,
    this.targetId,
    this.quantity,
  })  : assert(snapshotRevision >= 0),
        assert(quantity == null || quantity > 0);

  final RuntimeWorldServiceAction action;
  final int snapshotRevision;
  final String? targetId;
  final int? quantity;
}

enum RuntimeWorldServiceCommandStatus {
  accepted,
  stale,
  unavailable,
  cancelled,
  failed,
}

final class RuntimeWorldServiceCommandResult {
  const RuntimeWorldServiceCommandResult({
    required this.status,
    this.safeMessage,
  });

  final RuntimeWorldServiceCommandStatus status;
  final String? safeMessage;
}

/// Optional session capability implemented by runtimes that expose contextual
/// world services. Child-process adapters can mirror this contract later.
abstract interface class RuntimeWorldServicePort {
  RuntimeWorldServiceSnapshot? get worldServiceSnapshot;

  Stream<RuntimeWorldServiceSnapshot?> get worldServiceSnapshots;

  Future<RuntimeWorldServiceCommandResult> dispatchWorldService(
    RuntimeWorldServiceCommand command,
  );
}
