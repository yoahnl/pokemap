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

/// The canonical result of one analysis, produced away from the interface.
class VerificationAnalysis {
  const VerificationAnalysis({
    required this.validation,
    required this.dependencies,
    required this.physical,
    required this.isolateName,
  });

  final NarrativeProjectValidationReport validation;
  final NarrativeDependencyIndex dependencies;
  final NarrativeValidationDimensionResult physical;

  /// Where the computation actually ran, so a test can prove it left the
  /// interface isolate instead of trusting an await.
  final String isolateName;
}

/// One analysis in flight, owned by the request that started it.
class VerificationJob {
  const VerificationJob({required this.result, required this.cancel});
  final Future<VerificationAnalysis> result;
  final void Function() cancel;
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

  /// Runs the canonical validators away from the interface isolate. Cancelling
  /// the returned job stops that work and frees it, without touching another
  /// session.
  VerificationJob analyse({
    required ProjectManifest project,
    required List<MapData> maps,
  });
}

class VerificationFailure implements Exception {
  const VerificationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
