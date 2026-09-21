import 'package:map_core/map_core_domain.dart';

/// How a runtime smoke receipt relates to the version being verified.
enum VerificationRuntimeState {
  freshPass,
  freshFail,
  absent,
  stale,
  profileMismatch,
  incompleteSuites,
  invalid,
  unreadable,
}

class VerificationRuntimeEvidence {
  const VerificationRuntimeEvidence({
    required this.state,
    required this.reason,
    this.receipt,
  });

  final VerificationRuntimeState state;
  final String reason;
  final NarrativeRuntimeSmokeReceipt? receipt;

  NarrativeValidationStatus get status => switch (state) {
    VerificationRuntimeState.freshPass => NarrativeValidationStatus.pass,
    VerificationRuntimeState.freshFail => NarrativeValidationStatus.fail,
    _ => NarrativeValidationStatus.notRun,
  };
}

/// Reads what a narrative verification consumes. It never writes.
abstract interface class VerificationPort {
  /// The maps the validator, the dependency index and the graph read.
  Future<List<MapData>> loadMaps();

  /// Revision of the saved project, used to notice that the disk moved.
  Future<String> projectRevision();

  /// The runtime proof on disk, classified against [profile] and the
  /// canonical project fingerprint rather than assumed fresh.
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile profile,
  );

  /// Runs the canonical physical reachability solver and answers in canonical
  /// terms. The solver itself lives in a package the application layer may not
  /// reach, so infrastructure runs it and the verdict crosses the port.
  Future<NarrativeValidationDimensionResult> physicalReachability({
    required ProjectManifest project,
    required List<MapData> maps,
    required NarrativeSymbolicReachabilityReport? symbolic,
  });
}

class VerificationFailure implements Exception {
  const VerificationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
