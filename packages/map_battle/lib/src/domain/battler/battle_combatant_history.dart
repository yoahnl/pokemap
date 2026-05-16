import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_move.dart';

/// Damage history carried by the PSDK lane.
///
/// Pokemon SDK stores battle histories on the battler and many move families
/// read them later. This object is intentionally passive in FIGHT-02: it
/// records facts, while handlers introduced in later lots will decide how those
/// facts influence damage, effects, switches, or faint processing.
final class PsdkBattleDamageHistoryEntry {
  const PsdkBattleDamageHistoryEntry({
    required this.turn,
    required this.source,
    required this.moveId,
    required this.damage,
    required this.remainingHp,
    this.moveCategory,
  });

  final int turn;
  final PsdkBattleSlotRef source;
  final String moveId;
  final int damage;
  final int remainingHp;
  final PsdkBattleMoveCategory? moveCategory;
}

final class PsdkBattleDamageHistory {
  PsdkBattleDamageHistory({
    List<PsdkBattleDamageHistoryEntry> entries =
        const <PsdkBattleDamageHistoryEntry>[],
  }) : _entries = List<PsdkBattleDamageHistoryEntry>.unmodifiable(entries);

  const PsdkBattleDamageHistory.empty() : _entries = const [];

  final List<PsdkBattleDamageHistoryEntry> _entries;

  List<PsdkBattleDamageHistoryEntry> get entries =>
      List<PsdkBattleDamageHistoryEntry>.unmodifiable(_entries);

  PsdkBattleDamageHistory record(PsdkBattleDamageHistoryEntry entry) {
    return PsdkBattleDamageHistory(
      entries: <PsdkBattleDamageHistoryEntry>[..._entries, entry],
    );
  }
}

/// Stat-change history carried by the PSDK lane.
///
/// This mirrors PSDK's "remember what changed this battle" contract without
/// applying any prevention or ability logic yet. FIGHT-04 handlers will become
/// the only writers for real stat changes.
final class PsdkBattleStatHistoryEntry {
  const PsdkBattleStatHistoryEntry({
    required this.turn,
    required this.stat,
    required this.delta,
    required this.currentStage,
  });

  final int turn;
  final String stat;
  final int delta;
  final int currentStage;
}

final class PsdkBattleStatHistory {
  PsdkBattleStatHistory({
    List<PsdkBattleStatHistoryEntry> entries =
        const <PsdkBattleStatHistoryEntry>[],
  }) : _entries = List<PsdkBattleStatHistoryEntry>.unmodifiable(entries);

  const PsdkBattleStatHistory.empty() : _entries = const [];

  final List<PsdkBattleStatHistoryEntry> _entries;

  List<PsdkBattleStatHistoryEntry> get entries =>
      List<PsdkBattleStatHistoryEntry>.unmodifiable(_entries);

  PsdkBattleStatHistory record(PsdkBattleStatHistoryEntry entry) {
    return PsdkBattleStatHistory(
      entries: <PsdkBattleStatHistoryEntry>[..._entries, entry],
    );
  }
}
