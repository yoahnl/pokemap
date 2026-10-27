import 'dart:collection';

import 'package:map_core/map_core.dart';

import 'runtime_pokemon_summary.dart';
import 'runtime_player_pause_data.dart';

enum RuntimeWorldServiceKind { shop, heal, pc, textInput, regionalMap,
  partyTrade, pokemonGift,
}

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
    this.displayEntityId,
    super.requiredCapabilities,
    super.availabilityCondition,
  });

  final bool requiresConfirmation;
  final String? displayEntityId;

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

final class OpenRegionalMapService extends RuntimeWorldServiceRequest {
  const OpenRegionalMapService({
    required super.interactionId,
    super.requiredCapabilities,
    super.availabilityCondition,
  });

  @override
  RuntimeWorldServiceKind get kind => RuntimeWorldServiceKind.regionalMap;
}

final class RuntimeRegionalMapServiceContent {
  const RuntimeRegionalMapServiceContent({required this.detail, this.selectedPointId, this.message, this.applying = false});

  final RuntimePlayerPauseDetailSnapshot detail;
  final String? selectedPointId;
  final String? message;
  final bool applying;
}

final class OpenPartyTradeService extends RuntimeWorldServiceRequest {
  const OpenPartyTradeService({
    required super.interactionId,
    this.npcOffer,
    super.requiredCapabilities,
    super.availabilityCondition,
  });

  final NpcPokemonTradeOffer? npcOffer;

  @override
  RuntimeWorldServiceKind get kind => RuntimeWorldServiceKind.partyTrade;
}

enum RuntimePartyTradePhase {
  selectFirst,
  choosePartner,
  selectPartner,
  review,
  completed,
}

final class RuntimePartyTradePokemonSnapshot {
  const RuntimePartyTradePokemonSnapshot({
    required this.individualId,
    required this.speciesId,
    required this.label,
    required this.level,
  });
  final String individualId, speciesId, label;
  final int level;
}

final class RuntimePartyTradeServiceContent {
  RuntimePartyTradeServiceContent({
    required this.phase,
    required Iterable<RuntimePartyTradePokemonSnapshot> members,
    this.firstIndividualId,
    this.partnerIndividualId,
    this.completionMessage,
  }) : members = List.unmodifiable(members);
  static const samePartnerTarget = 'trade:partner:self';
  static const otherPartnerTarget = 'trade:partner:choose';
  final RuntimePartyTradePhase phase;
  final List<RuntimePartyTradePokemonSnapshot> members;
  final String? firstIndividualId, partnerIndividualId, completionMessage;
}

final class OpenTextInputService extends RuntimeWorldServiceRequest {
  OpenTextInputService({
    required super.interactionId,
    required String variableId,
    required this.interaction,
    super.requiredCapabilities,
    super.availabilityCondition,
  }) : variableId = variableId.trim() {
    if (this.variableId.isEmpty) {
      throw ArgumentError.value(variableId, 'variableId');
    }
  }

  final String variableId;
  final SceneTextInteractionRequest interaction;

  @override
  RuntimeWorldServiceKind get kind => RuntimeWorldServiceKind.textInput;
}

final class OpenSceneTextInteractionService extends RuntimeWorldServiceRequest {
  OpenSceneTextInteractionService({
    required super.interactionId,
    required this.interaction,
  }) {
    if (interaction is! SceneIntegerInteractionRequest &&
        interaction is! SceneTextInteractionRequest &&
        interaction is! SceneConfirmationInteractionRequest &&
        interaction is! SceneChoiceInteractionRequest &&
        interaction is! SceneMessageInteractionRequest) {
      throw ArgumentError(
        'Scene text input requires a text, choice, confirmation or message request.',
      );
    }
  }

  final SceneInteractionRequest interaction;

  @override
  RuntimeWorldServiceKind get kind => RuntimeWorldServiceKind.textInput;
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
  showPurchases,
  showSales,
  decreaseQuantity,
  increaseQuantity,
  confirm,
  cancel,
  close,
  deposit,
  withdraw,
  swap,

  /// BETA-PTY-003 : déplacer un Pokémon de la box affichée vers une autre box
  /// (`targetId` = le Pokémon, `secondaryTargetId` = la box de destination).
  move,
}

enum RuntimeShopMode {
  buy,
  sell,
}

final class RuntimeShopEntrySnapshot {
  const RuntimeShopEntrySnapshot({
    required this.itemId,
    required this.label,
    required this.unitPrice,
    this.remainingStock,
    this.ownedQuantity = 0,
    this.canTransact = true,
    this.unavailableReason,
  })  : assert(itemId != ''),
        assert(label != ''),
        assert(unitPrice >= 0),
        assert(remainingStock == null || remainingStock >= 0),
        assert(ownedQuantity >= 0);

  final String itemId;
  final String label;
  final int unitPrice;
  final int? remainingStock;
  final int ownedQuantity;
  final bool canTransact;
  final String? unavailableReason;
}

/// Runtime-owned Shop projection. Prices and availability are already resolved.
final class RuntimeShopServiceContent {
  RuntimeShopServiceContent({
    required this.title,
    required this.message,
    required this.money,
    List<RuntimeShopEntrySnapshot> entries = const <RuntimeShopEntrySnapshot>[],
    this.mode = RuntimeShopMode.buy,
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
  final RuntimeShopMode mode;
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
    this.display,
  })  : assert(title != ''),
        members = List<RuntimeHealPartyMemberSnapshot>.unmodifiable(members);

  final String title;
  final String message;
  final List<RuntimeHealPartyMemberSnapshot> members;
  final bool wasHealed;
  final RuntimeHealingDisplaySnapshot? display;
}

final class RuntimeHealingDisplaySnapshot {
  RuntimeHealingDisplaySnapshot({required this.mapId, required this.entityId, required this.memberCount}) {
    if (mapId.isEmpty || mapId.trim() != mapId || entityId.isEmpty || entityId.trim() != entityId ||
        memberCount < 1 || memberCount > 6) {
      throw const FormatException('Unsupported healing display state.');
    }
  }

  final String mapId;
  final String entityId;
  final int memberCount;
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
  RuntimePcPokemonSnapshot({
    required this.targetId,
    required this.label,
    required this.speciesId,
    this.formId = '',
    required this.level,
    required this.natureId,
    required this.abilityId,
    required this.currentHp,
    this.gender,
    this.statusId = '',
    this.isShiny = false,
    this.heldItemId = '',
    this.nickname = '',
    this.friendship = 0,
    this.originKind = 'unknown',
    this.metMapId = '',
    this.metSourceId = '',
    this.ballItemId = '',
    this.metLevel,
    List<String> knownMoveIds = const <String>[],
    required this.canTransfer,
    this.unavailableReason,
    this.summary,
  })  : assert(targetId != ''),
        assert(label != ''),
        assert(speciesId != ''),
        assert(level > 0),
        assert(natureId != ''),
        assert(abilityId != ''),
        assert(currentHp >= 0),
        assert(friendship >= 0 && friendship <= 255),
        assert(metLevel == null || (metLevel >= 1 && metLevel <= 100)),
        assert(
          canTransfer || (unavailableReason != null && unavailableReason != ''),
        ),
        knownMoveIds = List<String>.unmodifiable(knownMoveIds);

  /// Fiche canonique identique à celle de l'équipe.
  ///
  /// Absente quand le catalogue d'espèces n'a pas pu être résolu : la surface
  /// retombe alors sur les champs bruts ci-dessous plutôt que de ne rien
  /// afficher.
  final RuntimePokemonSummarySnapshot? summary;

  /// Opaque target echoed by the player UI. Only the runtime interprets it.
  final String targetId;
  final String label;
  final String speciesId;
  final String formId;
  final int level;
  final String natureId;
  final String abilityId;
  final int currentHp;
  final String? gender;
  final String statusId;
  final bool isShiny;
  final String heldItemId;
  final String nickname;
  final int friendship;
  final String originKind;
  final String metMapId;
  final String metSourceId;
  final String ballItemId;
  final int? metLevel;
  final List<String> knownMoveIds;
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
    this.secondaryTargetId,
    this.quantity,
    this.interactionResult,
  })  : assert(snapshotRevision >= 0),
        assert(quantity == null || quantity > 0);

  final RuntimeWorldServiceAction action;
  final int snapshotRevision;
  final String? targetId;
  final String? secondaryTargetId;
  final int? quantity;
  final SceneInteractionResult? interactionResult;
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


enum RuntimeRegionalMapClosing { closed, cancelled, travelled, failed }

final class RuntimeRegionalMapOpening {
  const RuntimeRegionalMapOpening(this.completed);
  final Future<RuntimeRegionalMapClosing> completed;
}

abstract interface class RuntimeRegionalMapPort {
  Future<RuntimeRegionalMapOpening?> openPlayerRegionalMap();
}

enum PokemonGiftInteractionStage {
  received,
  pokedex,
  nicknameConfirmation,
  nickname,
  destination,
}

final class OpenPokemonGiftInteractionService
    extends RuntimeWorldServiceRequest {
  const OpenPokemonGiftInteractionService({
    required super.interactionId,
    required this.interaction,
    required this.stage,
    required this.pokemon,
    required this.projectedState,
    this.pokedexDetail,
    this.speciesName,
    this.isNewPokedexEntry = false,
  });
  final SceneInteractionRequest interaction;
  final PokemonGiftInteractionStage stage;
  final PlayerPokemon pokemon;
  final GameState projectedState;
  final RuntimePlayerPauseDetailSnapshot? pokedexDetail;
  final String? speciesName;
  final bool isNewPokedexEntry;
  @override
  RuntimeWorldServiceKind get kind => RuntimeWorldServiceKind.pokemonGift;
}
