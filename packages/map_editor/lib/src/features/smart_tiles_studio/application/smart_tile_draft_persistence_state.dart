enum SmartTileDraftPersistencePhase {
  localOnly,
  dirty,
  saving,
  saved,
  failed,
  conflict,
}

/// Observable state of the canonical Smart Tile draft autosave pipeline.
final class SmartTileDraftPersistenceState {
  const SmartTileDraftPersistenceState({
    required this.phase,
    required this.generation,
    required this.persistedGeneration,
    required this.snapshotRevision,
    this.fingerprint,
    this.errorCode,
    this.errorMessage,
  });

  const SmartTileDraftPersistenceState.localOnly({
    required String snapshotRevision,
  }) : this(
          phase: SmartTileDraftPersistencePhase.localOnly,
          generation: 0,
          persistedGeneration: 0,
          snapshotRevision: snapshotRevision,
        );

  final SmartTileDraftPersistencePhase phase;
  final int generation;
  final int persistedGeneration;
  final String snapshotRevision;
  final String? fingerprint;
  final String? errorCode;
  final String? errorMessage;

  bool get isSettled =>
      phase == SmartTileDraftPersistencePhase.localOnly ||
      phase == SmartTileDraftPersistencePhase.saved;

  bool get canRetry =>
      phase == SmartTileDraftPersistencePhase.failed ||
      phase == SmartTileDraftPersistencePhase.conflict;

  SmartTileDraftPersistenceState copyWith({
    SmartTileDraftPersistencePhase? phase,
    int? generation,
    int? persistedGeneration,
    String? snapshotRevision,
    String? fingerprint,
    String? errorCode,
    String? errorMessage,
    bool clearFingerprint = false,
    bool clearError = false,
  }) {
    return SmartTileDraftPersistenceState(
      phase: phase ?? this.phase,
      generation: generation ?? this.generation,
      persistedGeneration: persistedGeneration ?? this.persistedGeneration,
      snapshotRevision: snapshotRevision ?? this.snapshotRevision,
      fingerprint: clearFingerprint ? null : fingerprint ?? this.fingerprint,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SmartTileDraftPersistenceState &&
      other.phase == phase &&
      other.generation == generation &&
      other.persistedGeneration == persistedGeneration &&
      other.snapshotRevision == snapshotRevision &&
      other.fingerprint == fingerprint &&
      other.errorCode == errorCode &&
      other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
        phase,
        generation,
        persistedGeneration,
        snapshotRevision,
        fingerprint,
        errorCode,
        errorMessage,
      );
}
