import '../../contracts/authoring_receipt.dart';

final class PackageBuildRequest {
  PackageBuildRequest({
    required String requestId,
    required String packageId,
    required String projectId,
    required String sourceRevision,
    required String releaseVersion,
  })  : requestId = _safeId(requestId, 'requestId'),
        packageId = _safeId(packageId, 'packageId'),
        projectId = _safeId(projectId, 'projectId'),
        sourceRevision = _digest(sourceRevision, 'sourceRevision'),
        releaseVersion = _nonBlank(releaseVersion, 'releaseVersion');

  final String requestId;
  final String packageId;
  final String projectId;
  final String sourceRevision;
  final String releaseVersion;

  Map<String, Object?> toJson() => <String, Object?>{
        'requestId': requestId,
        'packageId': packageId,
        'projectId': projectId,
        'sourceRevision': sourceRevision,
        'releaseVersion': releaseVersion,
      };
}

final class PackageBuildEvidence {
  PackageBuildEvidence({
    required this.request,
    required this.artifact,
    required String treeDigest,
    required String evidenceRef,
  })  : treeDigest = _digest(treeDigest, 'treeDigest'),
        evidenceRef = _evidenceRef(evidenceRef) {
    _artifactDigest(artifact, 'artifact');
  }

  final PackageBuildRequest request;
  final AuthoringArtifactRef artifact;
  final String treeDigest;
  final String evidenceRef;

  String get packageDigest => _artifactDigest(artifact, 'artifact');
}

final class PackageInspectionEvidence {
  PackageInspectionEvidence({
    required this.artifact,
    required String treeDigest,
    required this.passed,
    required String evidenceRef,
  })  : treeDigest = _digest(treeDigest, 'treeDigest'),
        evidenceRef = _evidenceRef(evidenceRef) {
    _artifactDigest(artifact, 'artifact');
  }

  final AuthoringArtifactRef artifact;
  final String treeDigest;
  final bool passed;
  final String evidenceRef;

  String get packageDigest => _artifactDigest(artifact, 'artifact');
}

final class PackageInstallEvidence {
  PackageInstallEvidence({
    required String exportedDigest,
    required String installedDigest,
    required this.passed,
    required String evidenceRef,
  })  : exportedDigest = _digest(exportedDigest, 'exportedDigest'),
        installedDigest = _digest(installedDigest, 'installedDigest'),
        evidenceRef = _evidenceRef(evidenceRef);

  final String exportedDigest;
  final String installedDigest;
  final bool passed;
  final String evidenceRef;
}

abstract interface class AuthoringPackagePort {
  Future<PackageBuildEvidence> build(PackageBuildRequest request);

  Future<PackageInspectionEvidence> inspect(
    AuthoringArtifactRef package,
  );

  Future<PackageInstallEvidence> install(
    AuthoringArtifactRef package,
  );
}

final class PackageReleaseGateEvidence {
  PackageReleaseGateEvidence({
    required String id,
    required this.passed,
    required String summary,
    required String evidenceRef,
  })  : id = _safeId(id, 'id'),
        summary = _nonBlank(summary, 'summary'),
        evidenceRef = _evidenceRef(evidenceRef);

  final String id;
  final bool passed;
  final String summary;
  final String evidenceRef;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'passed': passed,
        'summary': summary,
        'evidenceRef': evidenceRef,
      };
}

final class GameplayLotReleaseMapping {
  GameplayLotReleaseMapping({
    required String lotId,
    required String status,
  })  : lotId = _lotId(lotId),
        status = _lotStatus(status);

  final String lotId;
  final String status;

  /// Roadmap writes are intentionally outside this release action.
  bool get updateApplied => false;

  Map<String, Object?> toJson() => <String, Object?>{
        'lotId': lotId,
        'status': status,
        'updateApplied': false,
      };
}

final class AuthoringPackageReleaseReceipt {
  AuthoringPackageReleaseReceipt({
    required String requestId,
    required String projectId,
    required String sourceRevision,
    required String packageDigest,
    required String installedDigest,
    required Iterable<PackageReleaseGateEvidence> gates,
    required Iterable<GameplayLotReleaseMapping> gameplayLots,
  })  : requestId = _safeId(requestId, 'requestId'),
        projectId = _safeId(projectId, 'projectId'),
        sourceRevision = _digest(sourceRevision, 'sourceRevision'),
        packageDigest = _digest(packageDigest, 'packageDigest'),
        installedDigest = _digest(installedDigest, 'installedDigest'),
        gates = _sortedGates(gates),
        gameplayLots = _sortedLots(gameplayLots);

  final String requestId;
  final String projectId;
  final String sourceRevision;
  final String packageDigest;
  final String installedDigest;
  final List<PackageReleaseGateEvidence> gates;
  final List<GameplayLotReleaseMapping> gameplayLots;

  bool get isReady =>
      packageDigest == installedDigest && gates.every((gate) => gate.passed);

  Map<String, Object?> toJson() => <String, Object?>{
        'requestId': requestId,
        'projectId': projectId,
        'sourceRevision': sourceRevision,
        'packageDigest': packageDigest,
        'installedDigest': installedDigest,
        'ready': isReady,
        'gates': gates.map((gate) => gate.toJson()).toList(),
        'gameplayLots': gameplayLots.map((lot) => lot.toJson()).toList(),
      };
}

/// Orchestrates the public build/inspect/install sequence and fails closed in
/// its release receipt. The concrete adapter remains the byte authority.
final class DistributionPackageActions {
  const DistributionPackageActions({required AuthoringPackagePort port})
      : _port = port;

  final AuthoringPackagePort _port;

  Future<PackageBuildEvidence> build(PackageBuildRequest request) =>
      _port.build(request);

  Future<PackageInspectionEvidence> inspect(
    AuthoringArtifactRef package,
  ) =>
      _port.inspect(package);

  Future<PackageInstallEvidence> verify(
    AuthoringArtifactRef package,
  ) =>
      _port.install(package);

  Future<AuthoringPackageReleaseReceipt> release({
    required PackageBuildRequest request,
    required Iterable<PackageReleaseGateEvidence> regressionGates,
    required Iterable<GameplayLotReleaseMapping> gameplayLots,
  }) async {
    final built = await build(request);
    final inspection = await inspect(built.artifact);
    final sameTree = built.treeDigest == inspection.treeDigest;
    final installation = inspection.passed && sameTree
        ? await verify(built.artifact)
        : PackageInstallEvidence(
            exportedDigest: built.packageDigest,
            installedDigest: 'sha256:${'0' * 64}',
            passed: false,
            evidenceRef: inspection.evidenceRef,
          );
    final sameBytes = built.packageDigest == inspection.packageDigest &&
        built.packageDigest == installation.exportedDigest &&
        built.packageDigest == installation.installedDigest;
    return AuthoringPackageReleaseReceipt(
      requestId: request.requestId,
      projectId: request.projectId,
      sourceRevision: request.sourceRevision,
      packageDigest: built.packageDigest,
      installedDigest: installation.installedDigest,
      gates: <PackageReleaseGateEvidence>[
        PackageReleaseGateEvidence(
          id: 'package.build',
          passed: true,
          summary: 'Deterministic package bytes were built.',
          evidenceRef: built.evidenceRef,
        ),
        PackageReleaseGateEvidence(
          id: 'package.inspect',
          passed: inspection.passed && sameTree,
          summary: sameTree
              ? 'Package inspection preserved the content-tree identity.'
              : 'Package inspection reported a different content tree.',
          evidenceRef: inspection.evidenceRef,
        ),
        PackageReleaseGateEvidence(
          id: 'package.byte-identity',
          passed: installation.passed && sameBytes,
          summary: sameBytes
              ? 'Exported and installed package bytes are identical.'
              : 'Exported and installed package bytes differ.',
          evidenceRef: installation.evidenceRef,
        ),
        ...regressionGates,
      ],
      gameplayLots: gameplayLots,
    );
  }
}

List<PackageReleaseGateEvidence> _sortedGates(
  Iterable<PackageReleaseGateEvidence> gates,
) {
  final result = gates.toList()..sort((a, b) => a.id.compareTo(b.id));
  if (result.isEmpty) {
    throw ArgumentError.value(gates, 'gates', 'must not be empty');
  }
  for (var index = 1; index < result.length; index += 1) {
    if (result[index - 1].id == result[index].id) {
      throw ArgumentError.value(result[index].id, 'gates', 'duplicate gate');
    }
  }
  return List.unmodifiable(result);
}

List<GameplayLotReleaseMapping> _sortedLots(
  Iterable<GameplayLotReleaseMapping> mappings,
) {
  final result = mappings.toList()..sort((a, b) => a.lotId.compareTo(b.lotId));
  for (var index = 1; index < result.length; index += 1) {
    if (result[index - 1].lotId == result[index].lotId) {
      throw ArgumentError.value(
        result[index].lotId,
        'gameplayLots',
        'duplicate lot',
      );
    }
  }
  return List.unmodifiable(result);
}

String _lotId(String value) {
  final normalized = _nonBlank(value, 'lotId');
  if (!RegExp(r'^FG-[0-9]{3}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, 'lotId', 'must match FG-NNN');
  }
  return normalized;
}

String _lotStatus(String value) {
  final normalized = _nonBlank(value, 'status');
  if (!const <String>{'TODO', 'PARTIAL', 'BLOCKED', 'DONE'}
      .contains(normalized)) {
    throw ArgumentError.value(value, 'status', 'unknown roadmap status');
  }
  return normalized;
}

String _digest(String value, String field) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 digest');
  }
  return value;
}

String _artifactDigest(AuthoringArtifactRef artifact, String field) {
  final sha256 = artifact.sha256;
  if (sha256 == null) {
    throw ArgumentError.value(artifact, field, 'must contain a SHA-256');
  }
  final digest = 'sha256:$sha256';
  _digest(digest, field);
  if (artifact.uri != 'artifact://sha256/$sha256') {
    throw ArgumentError.value(
      artifact.uri,
      field,
      'artifact URI must match its SHA-256',
    );
  }
  return digest;
}

String _safeId(String value, String field) {
  final normalized = _nonBlank(value, field);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{2,127}$').hasMatch(normalized)) {
    throw ArgumentError.value(value, field, 'must be a stable identifier');
  }
  return normalized;
}

String _evidenceRef(String value) {
  final normalized = _nonBlank(value, 'evidenceRef');
  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasScheme || uri.scheme == 'file') {
    throw ArgumentError.value(
      value,
      'evidenceRef',
      'must be a stable non-file URI',
    );
  }
  return normalized;
}

String _nonBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return value.trim();
}
