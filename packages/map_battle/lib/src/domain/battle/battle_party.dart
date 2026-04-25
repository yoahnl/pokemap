import 'battle_battler.dart';

/// Ordered party owned by one PSDK bank.
final class BattleParty {
  BattleParty({
    required this.id,
    required List<BattleBattler> battlers,
  }) : _battlers = List<BattleBattler>.unmodifiable(battlers) {
    final partyIndexes = <int>{};
    final instanceIds = <String>{};
    for (final battler in _battlers) {
      if (battler.partyId != id) {
        throw ArgumentError(
          'Battler ${battler.instanceId} belongs to party '
          '${battler.partyId}, not party $id.',
        );
      }
      if (!partyIndexes.add(battler.partyIndex)) {
        throw ArgumentError(
          'Duplicate partyIndex ${battler.partyIndex} in party $id.',
        );
      }
      if (!instanceIds.add(battler.instanceId)) {
        throw ArgumentError(
          'Duplicate battler instanceId ${battler.instanceId} in party $id.',
        );
      }
    }
  }

  final int id;
  final List<BattleBattler> _battlers;

  List<BattleBattler> get battlers =>
      List<BattleBattler>.unmodifiable(_battlers);

  Iterable<BattleBattler> get aliveBattlers =>
      _battlers.where((battler) => battler.isAlive);

  BattleBattler? battlerByPartyIndex(int partyIndex) {
    for (final battler in _battlers) {
      if (battler.partyIndex == partyIndex) {
        return battler;
      }
    }
    return null;
  }
}
