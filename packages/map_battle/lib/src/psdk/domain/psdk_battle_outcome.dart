enum PsdkBattleOutcomeKind {
  victory,
  defeat,
  fled,
}

class PsdkBattleOutcome {
  const PsdkBattleOutcome({
    required this.kind,
  });

  final PsdkBattleOutcomeKind kind;
}
