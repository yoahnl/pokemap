enum PsdkBattleOutcomeKind {
  victory,
  defeat,
  fled,
  captured,
}

class PsdkBattleOutcome {
  factory PsdkBattleOutcome({
    required PsdkBattleOutcomeKind kind,
    String? captureAttemptId,
    Set<int> playerParticipantPartyIndexes = const <int>{},
  }) {
    final normalizedCaptureAttemptId = captureAttemptId?.trim();
    if (kind == PsdkBattleOutcomeKind.captured &&
        (normalizedCaptureAttemptId == null ||
            normalizedCaptureAttemptId.isEmpty)) {
      throw ArgumentError.value(
        captureAttemptId,
        'captureAttemptId',
        'A captured outcome requires its exact capture attempt id.',
      );
    }
    if (kind != PsdkBattleOutcomeKind.captured && captureAttemptId != null) {
      throw ArgumentError.value(
        captureAttemptId,
        'captureAttemptId',
        'Only captured outcomes can carry a capture attempt id.',
      );
    }
    for (final partyIndex in playerParticipantPartyIndexes) {
      RangeError.checkNotNegative(
        partyIndex,
        'playerParticipantPartyIndexes',
      );
    }
    return PsdkBattleOutcome._(
      kind: kind,
      captureAttemptId: normalizedCaptureAttemptId,
      playerParticipantPartyIndexes: Set<int>.unmodifiable(
        playerParticipantPartyIndexes,
      ),
    );
  }

  const PsdkBattleOutcome._({
    required this.kind,
    required this.captureAttemptId,
    required Set<int> playerParticipantPartyIndexes,
  }) : _playerParticipantPartyIndexes = playerParticipantPartyIndexes;

  final PsdkBattleOutcomeKind kind;
  final String? captureAttemptId;
  final Set<int> _playerParticipantPartyIndexes;

  Set<int> get playerParticipantPartyIndexes =>
      Set<int>.unmodifiable(_playerParticipantPartyIndexes);

  PsdkBattleOutcome withPlayerParticipantPartyIndexes(
    Iterable<int> partyIndexes,
  ) {
    return PsdkBattleOutcome(
      kind: kind,
      captureAttemptId: captureAttemptId,
      playerParticipantPartyIndexes: Set<int>.unmodifiable(partyIndexes),
    );
  }

  // Participant indexes are post-battle metadata. Capture identity is terminal
  // gameplay truth and therefore participates in value equality.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PsdkBattleOutcome &&
          kind == other.kind &&
          captureAttemptId == other.captureAttemptId;

  @override
  int get hashCode => Object.hash(kind, captureAttemptId);
}
