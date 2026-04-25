/// Stable slot coordinate for the first PSDK singles slice.
///
/// Pokemon SDK names sides as banks and active positions. This first lot only
/// supports bank 0 position 0 versus bank 1 position 0, but keeping the shape
/// now prevents the timeline from lying about the future topology model.
class PsdkBattleSlotRef {
  const PsdkBattleSlotRef({
    required this.bank,
    required this.position,
  });

  final int bank;
  final int position;

  Map<String, Object?> toJson() => <String, Object?>{
        'bank': bank,
        'position': position,
      };

  @override
  bool operator ==(Object other) {
    return other is PsdkBattleSlotRef &&
        other.bank == bank &&
        other.position == position;
  }

  @override
  int get hashCode => Object.hash(bank, position);
}

/// Internal singles slot for the player bank.
///
/// It is public to sibling PSDK files, but callers should build decisions
/// through the engine instead of hardcoding this constant in product code.
const psdkPlayerSlot = PsdkBattleSlotRef(bank: 0, position: 0);

/// Internal singles slot for the opponent bank.
const psdkOpponentSlot = PsdkBattleSlotRef(bank: 1, position: 0);

/// Resolve the opposing singles slot for the currently supported topology.
PsdkBattleSlotRef psdkSinglesFoeOf(PsdkBattleSlotRef user) {
  return user.bank == psdkPlayerSlot.bank ? psdkOpponentSlot : psdkPlayerSlot;
}
