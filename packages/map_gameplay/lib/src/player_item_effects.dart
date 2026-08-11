import 'package:map_core/map_core.dart';

import 'items/mvp_item_catalog.dart';

enum PlayerItemEffectKind {
  healHp,
  cureStatus,
  revive,
  restorePp,
  keyItem,
  ballMetadata,
}

final class PlayerItemEffectDefinition {
  const PlayerItemEffectDefinition({
    required this.kind,
    this.amount = 0,
    this.statusIds = const <String>{},
    this.curesAnyStatus = false,
    this.revivePercent = 0,
    this.ballMultiplier = 0,
  });

  final PlayerItemEffectKind kind;
  final int amount;
  final Set<String> statusIds;
  final bool curesAnyStatus;
  final int revivePercent;
  final double ballMultiplier;
}

final Map<String, PlayerItemEffectDefinition> _mvpPlayerItemEffectProjection =
    Map.unmodifiable({
  for (final item in mvpItemCatalog.entries)
    if (_projectPlayerItemEffect(item) case final effect?) item.id: effect,
});

final class PlayerItemEffectRegistry {
  const PlayerItemEffectRegistry({
    Map<String, PlayerItemEffectDefinition> effects =
        const <String, PlayerItemEffectDefinition>{},
  })  : _effects = effects,
        _usesMvpCatalog = false;

  const PlayerItemEffectRegistry.mvp()
      : _effects = const <String, PlayerItemEffectDefinition>{},
        _usesMvpCatalog = true;

  final Map<String, PlayerItemEffectDefinition> _effects;
  final bool _usesMvpCatalog;

  Map<String, PlayerItemEffectDefinition> get effects =>
      _usesMvpCatalog ? _mvpPlayerItemEffectProjection : _effects;

  PlayerItemEffectDefinition? effectFor(String itemId) =>
      effects[itemId.trim()];
}

PlayerItemEffectDefinition? _projectPlayerItemEffect(
  ProjectItemDefinition item,
) {
  if (item.capture case final capture?) {
    return PlayerItemEffectDefinition(
      kind: PlayerItemEffectKind.ballMetadata,
      ballMultiplier: capture.rateNumerator / capture.rateDenominator,
    );
  }
  if (item.tags.contains('key-item')) {
    return const PlayerItemEffectDefinition(
      kind: PlayerItemEffectKind.keyItem,
    );
  }
  if (item.uses.isEmpty) {
    return null;
  }
  return switch (item.uses.first.effect) {
    ProjectItemHealHpEffectDefinition(:final mode, :final amount) =>
      PlayerItemEffectDefinition(
        kind: PlayerItemEffectKind.healHp,
        amount: mode == ProjectItemAmountMode.full ? 0x7fffffff : amount!,
      ),
    ProjectItemCureStatusEffectDefinition(:final mode, :final statusIds) =>
      PlayerItemEffectDefinition(
        kind: PlayerItemEffectKind.cureStatus,
        statusIds: statusIds,
        curesAnyStatus: mode == ProjectItemStatusCureMode.all,
      ),
    ProjectItemReviveEffectDefinition(
      :final rateNumerator,
      :final rateDenominator,
    ) =>
      PlayerItemEffectDefinition(
        kind: PlayerItemEffectKind.revive,
        revivePercent:
            (rateNumerator * 100 + rateDenominator - 1) ~/ rateDenominator,
      ),
    ProjectItemRestorePpEffectDefinition(:final mode, :final amount) =>
      PlayerItemEffectDefinition(
        kind: PlayerItemEffectKind.restorePp,
        amount: mode == ProjectItemAmountMode.full ? 0x7fffffff : amount!,
      ),
    ProjectItemRepelEffectDefinition() ||
    ProjectItemSemanticActionEffectDefinition() =>
      null,
    _ => null,
  };
}

enum PlayerItemUseFailure {
  invalidRequest,
  unknownItem,
  invalidTarget,
  insufficientQuantity,
  wrongTarget,
  noEffect,
}

final class PlayerItemUseResult {
  const PlayerItemUseResult._({
    required this.state,
    this.failure,
  });

  const PlayerItemUseResult.success(GameState state) : this._(state: state);

  const PlayerItemUseResult.failed(
    GameState state,
    PlayerItemUseFailure failure,
  ) : this._(state: state, failure: failure);

  final GameState state;
  final PlayerItemUseFailure? failure;

  bool get isSuccess => failure == null;
}

final class PlayerItemOperations {
  const PlayerItemOperations({
    this.registry = const PlayerItemEffectRegistry.mvp(),
  });

  final PlayerItemEffectRegistry registry;

  PlayerItemUseResult useOnPartyMember(
    GameState state, {
    required String itemId,
    required int partyIndex,
    required int maxHp,
    String? moveId,
    Map<String, int> maxPpByMoveId = const {},
  }) {
    final normalizedItemId = itemId.trim();
    if (normalizedItemId.isEmpty || maxHp <= 0) {
      return PlayerItemUseResult.failed(
        state,
        PlayerItemUseFailure.invalidRequest,
      );
    }
    final effect = registry.effectFor(normalizedItemId);
    if (effect == null) {
      return PlayerItemUseResult.failed(
        state,
        PlayerItemUseFailure.unknownItem,
      );
    }
    if (partyIndex < 0 || partyIndex >= state.party.members.length) {
      return PlayerItemUseResult.failed(
        state,
        PlayerItemUseFailure.invalidTarget,
      );
    }
    final hasItem = state.bag.normalized().entries.any(
          (entry) => entry.itemId == normalizedItemId && entry.quantity > 0,
        );
    if (!hasItem) {
      return PlayerItemUseResult.failed(
        state,
        PlayerItemUseFailure.insufficientQuantity,
      );
    }

    final target = state.party.members[partyIndex];
    final resolution = _applyEffect(
      target,
      effect: effect,
      maxHp: maxHp,
      moveId: moveId?.trim(),
      maxPpByMoveId: maxPpByMoveId,
    );
    if (resolution.failure != null) {
      return PlayerItemUseResult.failed(state, resolution.failure!);
    }

    final nextBag = _consumeOne(state.bag, normalizedItemId);
    if (nextBag == null) {
      return PlayerItemUseResult.failed(
        state,
        PlayerItemUseFailure.insufficientQuantity,
      );
    }
    final nextMembers = [...state.party.members];
    nextMembers[partyIndex] = resolution.pokemon!;
    return PlayerItemUseResult.success(
      state.copyWith(
        party: PlayerParty(members: nextMembers).normalized(),
        bag: nextBag,
      ),
    );
  }
}

final class _PlayerItemEffectResolution {
  const _PlayerItemEffectResolution.success(this.pokemon) : failure = null;

  const _PlayerItemEffectResolution.failed(this.failure) : pokemon = null;

  final PlayerPokemon? pokemon;
  final PlayerItemUseFailure? failure;
}

_PlayerItemEffectResolution _applyEffect(
  PlayerPokemon target, {
  required PlayerItemEffectDefinition effect,
  required int maxHp,
  required String? moveId,
  required Map<String, int> maxPpByMoveId,
}) {
  switch (effect.kind) {
    case PlayerItemEffectKind.healHp:
      if (target.isFainted) {
        return const _PlayerItemEffectResolution.failed(
          PlayerItemUseFailure.wrongTarget,
        );
      }
      if (target.currentHp >= maxHp) {
        return const _PlayerItemEffectResolution.failed(
          PlayerItemUseFailure.noEffect,
        );
      }
      final healedHp = target.currentHp + effect.amount;
      return _PlayerItemEffectResolution.success(
        target.copyWith(currentHp: healedHp > maxHp ? maxHp : healedHp),
      );
    case PlayerItemEffectKind.cureStatus:
      final statusId = target.statusId.trim();
      if (statusId.isEmpty) {
        return const _PlayerItemEffectResolution.failed(
          PlayerItemUseFailure.noEffect,
        );
      }
      if (!effect.curesAnyStatus && !effect.statusIds.contains(statusId)) {
        return const _PlayerItemEffectResolution.failed(
          PlayerItemUseFailure.wrongTarget,
        );
      }
      return _PlayerItemEffectResolution.success(
        target.copyWith(statusId: ''),
      );
    case PlayerItemEffectKind.revive:
      if (!target.isFainted) {
        return const _PlayerItemEffectResolution.failed(
          PlayerItemUseFailure.wrongTarget,
        );
      }
      final revivedHp = (maxHp * effect.revivePercent + 99) ~/ 100;
      return _PlayerItemEffectResolution.success(
        target.copyWith(currentHp: revivedHp < 1 ? 1 : revivedHp),
      );
    case PlayerItemEffectKind.restorePp:
      final normalizedMoveId = moveId ?? '';
      final currentPpByMoveId = target.currentPpByMoveId;
      final maxPp = maxPpByMoveId[normalizedMoveId];
      if (normalizedMoveId.isEmpty ||
          currentPpByMoveId == null ||
          !target.knownMoveIds.contains(normalizedMoveId) ||
          !currentPpByMoveId.containsKey(normalizedMoveId) ||
          maxPp == null ||
          maxPp <= 0) {
        return const _PlayerItemEffectResolution.failed(
          PlayerItemUseFailure.wrongTarget,
        );
      }
      final currentPp = currentPpByMoveId[normalizedMoveId]!;
      if (currentPp >= maxPp) {
        return const _PlayerItemEffectResolution.failed(
          PlayerItemUseFailure.noEffect,
        );
      }
      final restored = currentPp + effect.amount;
      return _PlayerItemEffectResolution.success(
        target.copyWith(
          currentPpByMoveId: <String, int>{
            ...currentPpByMoveId,
            normalizedMoveId: restored > maxPp ? maxPp : restored,
          },
        ),
      );
    case PlayerItemEffectKind.keyItem:
    case PlayerItemEffectKind.ballMetadata:
      return const _PlayerItemEffectResolution.failed(
        PlayerItemUseFailure.wrongTarget,
      );
  }
}

Bag? _consumeOne(Bag bag, String itemId) {
  final nextEntries = <BagEntry>[];
  var consumed = false;
  for (final entry in bag.normalized().entries) {
    if (!consumed && entry.itemId == itemId) {
      consumed = true;
      if (entry.quantity > 1) {
        nextEntries.add(entry.copyWith(quantity: entry.quantity - 1));
      }
    } else {
      nextEntries.add(entry);
    }
  }
  return consumed ? Bag(entries: nextEntries).normalized() : null;
}
