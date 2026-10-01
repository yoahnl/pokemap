import 'package:map_core/map_core.dart';

final class BattleCombatantBallResolver {
  BattleCombatantBallResolver({
    Map<int, String> playerLineupBallItemIdsByIndex = const {},
    Map<int, String> enemyLineupBallItemIdsByIndex = const {},
  })  : _playerLineupBallItemIdsByIndex =
            Map.unmodifiable(playerLineupBallItemIdsByIndex),
        _enemyLineupBallItemIdsByIndex =
            Map.unmodifiable(enemyLineupBallItemIdsByIndex);

  factory BattleCombatantBallResolver.fromParty({
    required GameState gameState,
    required List<int> lineupPartyIndices,
    Map<int, String> enemyLineupBallItemIdsByIndex = const {},
  }) {
    final playerItems = <int, String>{};
    final party = gameState.party.members;
    for (var lineupIndex = 0;
        lineupIndex < lineupPartyIndices.length;
        lineupIndex++) {
      final partyIndex = lineupPartyIndices[lineupIndex];
      if (partyIndex < 0 || partyIndex >= party.length) continue;
      final itemId = party[partyIndex].provenance?.ballItemId.trim();
      if (itemId != null && itemId.isNotEmpty) {
        playerItems[lineupIndex] = itemId;
      }
    }
    return BattleCombatantBallResolver(
      playerLineupBallItemIdsByIndex: playerItems,
      enemyLineupBallItemIdsByIndex: enemyLineupBallItemIdsByIndex,
    );
  }

  final Map<int, String> _playerLineupBallItemIdsByIndex;
  final Map<int, String> _enemyLineupBallItemIdsByIndex;

  String? resolve({required bool isPlayerSide, required int lineupIndex}) {
    if (lineupIndex < 0) return null;
    final itemId = (isPlayerSide
            ? _playerLineupBallItemIdsByIndex
            : _enemyLineupBallItemIdsByIndex)[lineupIndex]
        ?.trim();
    return itemId == null || itemId.isEmpty ? null : itemId;
  }
}
