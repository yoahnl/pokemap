import 'package:map_core/map_core.dart';

import 'game_state_mutations.dart';

const playerRecoveryMapIdMetadataKey = 'player.recovery.map_id';
const playerRecoveryPositionXMetadataKey = 'player.recovery.position_x';
const playerRecoveryPositionYMetadataKey = 'player.recovery.position_y';
const playerRecoveryFacingMetadataKey = 'player.recovery.facing';
const playerDefeatCountMetadataKey = 'player.defeat.count';
const playerLastDefeatMoneyLossMetadataKey = 'player.defeat.last_money_loss';

final class PlayerRecoveryPoint {
  const PlayerRecoveryPoint({
    required this.mapId,
    required this.position,
    required this.facing,
  });

  final String mapId;
  final GridPos position;
  final EntityFacing facing;

  static PlayerRecoveryPoint? tryRead(GameState state) {
    final mapId = state.metadata[playerRecoveryMapIdMetadataKey]?.trim();
    final x =
        int.tryParse(state.metadata[playerRecoveryPositionXMetadataKey] ?? '');
    final y =
        int.tryParse(state.metadata[playerRecoveryPositionYMetadataKey] ?? '');
    final facingName = state.metadata[playerRecoveryFacingMetadataKey]?.trim();
    final facing = EntityFacing.values
        .where((entry) => entry.name == facingName)
        .firstOrNull;
    if (mapId == null ||
        mapId.isEmpty ||
        x == null ||
        y == null ||
        x < 0 ||
        y < 0 ||
        facing == null) {
      return null;
    }
    return PlayerRecoveryPoint(
      mapId: mapId,
      position: GridPos(x: x, y: y),
      facing: facing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerRecoveryPoint &&
          other.mapId == mapId &&
          other.position == position &&
          other.facing == facing;

  @override
  int get hashCode => Object.hash(mapId, position, facing);
}

final class PlayerDefeatRecoveryPolicy {
  const PlayerDefeatRecoveryPolicy({
    this.moneyPenaltyBasisPoints = 1000,
  }) : assert(
          moneyPenaltyBasisPoints >= 0 && moneyPenaltyBasisPoints <= 10000,
        );

  /// Percentage in hundredths of a percent. `1000` is a 10% penalty.
  final int moneyPenaltyBasisPoints;
}

final class PlayerDefeatRecoveryResult {
  const PlayerDefeatRecoveryResult({
    required this.state,
    required this.recoveryPoint,
    required this.moneyLost,
  });

  final GameState state;
  final PlayerRecoveryPoint recoveryPoint;
  final int moneyLost;
}

GameState recordPlayerRecoveryPoint(GameState state) {
  final mapId = state.currentMapId.trim();
  if (mapId.isEmpty) {
    throw StateError('A recovery point requires a current map id.');
  }
  return state.copyWith(
    metadata: <String, String>{
      ...state.metadata,
      playerRecoveryMapIdMetadataKey: mapId,
      playerRecoveryPositionXMetadataKey: state.playerPosition.x.toString(),
      playerRecoveryPositionYMetadataKey: state.playerPosition.y.toString(),
      playerRecoveryFacingMetadataKey: state.playerFacing.name,
    },
  );
}

PlayerDefeatRecoveryResult applyPlayerDefeatRecovery({
  required GameState state,
  required PlayerRecoveryPoint fallbackPoint,
  required Map<int, int> maxHpByPartyIndex,
  Map<int, Map<String, int>> maxPpByPartyIndex =
      const <int, Map<String, int>>{},
  PlayerDefeatRecoveryPolicy policy = const PlayerDefeatRecoveryPolicy(),
}) {
  for (var index = 0; index < state.party.members.length; index++) {
    if ((maxHpByPartyIndex[index] ?? 0) <= 0) {
      throw StateError(
        'Defeat recovery requires a positive max HP for party slot $index.',
      );
    }
  }
  final recoveryPoint = PlayerRecoveryPoint.tryRead(state) ?? fallbackPoint;
  final healed = const GameStateMutations().recoverParty(
    state,
    maxHpByPartyIndex: maxHpByPartyIndex,
    maxPpByPartyIndex: maxPpByPartyIndex,
  );
  final money = state.trainerProfile.money;
  final rawLoss = (money * policy.moneyPenaltyBasisPoints) ~/ 10000;
  final moneyLost =
      money > 0 && policy.moneyPenaltyBasisPoints > 0 && rawLoss == 0
          ? 1
          : rawLoss;
  final previousDefeatCount =
      int.tryParse(state.metadata[playerDefeatCountMetadataKey] ?? '') ?? 0;
  final nextState = healed.copyWith(
    currentMapId: recoveryPoint.mapId,
    playerPosition: recoveryPoint.position,
    playerFacing: recoveryPoint.facing,
    playerMovementMode: MovementMode.walk,
    trainerProfile: healed.trainerProfile.copyWith(
      money: money - moneyLost,
    ),
    metadata: <String, String>{
      ...healed.metadata,
      playerDefeatCountMetadataKey: (previousDefeatCount + 1).toString(),
      playerLastDefeatMoneyLossMetadataKey: moneyLost.toString(),
    },
  );
  return PlayerDefeatRecoveryResult(
    state: nextState,
    recoveryPoint: recoveryPoint,
    moneyLost: moneyLost,
  );
}
