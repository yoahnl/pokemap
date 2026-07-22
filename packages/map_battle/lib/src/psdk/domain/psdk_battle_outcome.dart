enum PsdkBattleOutcomeKind {
  victory,
  defeat,
  fled,
}

class PsdkBattleOutcome {
  factory PsdkBattleOutcome({
    required PsdkBattleOutcomeKind kind,
    Set<int> playerParticipantPartyIndexes = const <int>{},
  }) {
    for (final partyIndex in playerParticipantPartyIndexes) {
      RangeError.checkNotNegative(
        partyIndex,
        'playerParticipantPartyIndexes',
      );
    }
    return PsdkBattleOutcome._(
      kind: kind,
      playerParticipantPartyIndexes: Set<int>.unmodifiable(
        playerParticipantPartyIndexes,
      ),
    );
  }

  const PsdkBattleOutcome._({
    required this.kind,
    required Set<int> playerParticipantPartyIndexes,
  }) : _playerParticipantPartyIndexes = playerParticipantPartyIndexes;

  final PsdkBattleOutcomeKind kind;
  final Set<int> _playerParticipantPartyIndexes;

  Set<int> get playerParticipantPartyIndexes =>
      Set<int>.unmodifiable(_playerParticipantPartyIndexes);

  PsdkBattleOutcome withPlayerParticipantPartyIndexes(
    Iterable<int> partyIndexes,
  ) {
    return PsdkBattleOutcome(
      kind: kind,
      playerParticipantPartyIndexes: Set<int>.unmodifiable(partyIndexes),
    );
  }

  // Participant indexes are post-battle metadata. Outcome value equality
  // deliberately remains based on the terminal kind for backwards
  // compatibility with existing engine decisions and switch effects.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PsdkBattleOutcome && kind == other.kind;

  @override
  int get hashCode => kind.hashCode;
}
