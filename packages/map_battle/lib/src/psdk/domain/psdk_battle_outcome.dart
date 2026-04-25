enum PsdkBattleOutcomeKind {
  victory,
  defeat,
}

class PsdkBattleOutcome {
  const PsdkBattleOutcome({
    required this.kind,
  });

  final PsdkBattleOutcomeKind kind;
}
