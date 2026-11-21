import 'package:map_authoring/map_authoring.dart';
import 'package:map_distribution/map_distribution.dart';

final class EvaluationDistributionPackageInput {
  EvaluationDistributionPackageInput({
    required this.manifest,
    required Map<String, List<int>> payloadFiles,
  }) : payloadFiles = Map.unmodifiable({
          for (final entry in payloadFiles.entries)
            entry.key: List<int>.unmodifiable(entry.value),
        });

  final GamePackageManifest manifest;
  final Map<String, List<int>> payloadFiles;
}

final class EvaluationInstalledPackageEvidence {
  EvaluationInstalledPackageEvidence({
    required String packageSha256,
    required this.passed,
    required String evidenceRef,
  })  : packageSha256 = _sha256(packageSha256, 'packageSha256'),
        evidenceRef = _evidenceRef(evidenceRef);

  final String packageSha256;
  final bool passed;
  final String evidenceRef;
}

typedef EvaluationDistributionInputLoader
    = Future<EvaluationDistributionPackageInput> Function(
  PackageBuildRequest request,
);

typedef EvaluationPackageInstaller = Future<EvaluationInstalledPackageEvidence>
    Function({
  required AuthoringArtifactRef artifact,
  required List<int> packageBytes,
  required GamePackageInspectionResult inspection,
});

/// Production-byte adapter for the protocol-neutral Authoring package port.
///
/// The caller owns project I/O and platform installation. This service owns
/// deterministic package construction, in-memory artifact identity and strict
/// inspection through `map_distribution`.
final class EvaluationDistributionPackageService
    implements AuthoringPackagePort {
  EvaluationDistributionPackageService({
    required EvaluationDistributionInputLoader inputLoader,
    required EvaluationPackageInstaller installer,
    GamePackageBuilder builder = const GamePackageBuilder(),
    GamePackageInspector inspector = const GamePackageInspector(),
  })  : _inputLoader = inputLoader,
        _installer = installer,
        _builder = builder,
        _inspector = inspector;

  final EvaluationDistributionInputLoader _inputLoader;
  final EvaluationPackageInstaller _installer;
  final GamePackageBuilder _builder;
  final GamePackageInspector _inspector;
  final Map<String, List<int>> _bytesByDigest = <String, List<int>>{};
  final Map<String, GamePackageInspectionResult> _inspectionsByDigest =
      <String, GamePackageInspectionResult>{};

  @override
  Future<PackageBuildEvidence> build(PackageBuildRequest request) async {
    final input = await _inputLoader(request);
    final built = _builder.build(
      manifest: input.manifest,
      payloadFiles: input.payloadFiles,
    );
    final digest = built.packageSha256;
    _bytesByDigest[digest] = List<int>.unmodifiable(built.packageBytes);
    final artifact = AuthoringArtifactRef(
      id: 'package-${request.packageId}-${request.requestId}',
      mediaType: 'application/vnd.pokemap.game+zip',
      uri: 'artifact://sha256/$digest',
      byteLength: built.archiveBytes,
      sha256: digest,
    );
    return PackageBuildEvidence(
      request: request,
      artifact: artifact,
      treeDigest: 'sha256:${built.manifest.content.treeSha256}',
      evidenceRef: 'package-build://${request.packageId}/$digest',
    );
  }

  @override
  Future<PackageInspectionEvidence> inspect(
    AuthoringArtifactRef package,
  ) async {
    final bytes = _resolve(package);
    final inspection = _inspector.inspect(bytes);
    final digest = package.sha256!;
    final passed = inspection.receipt.packageSha256 == digest;
    if (passed) _inspectionsByDigest[digest] = inspection;
    return PackageInspectionEvidence(
      artifact: package,
      treeDigest: 'sha256:${inspection.receipt.treeSha256}',
      passed: passed,
      evidenceRef: 'package-inspection://${inspection.manifest.gameId}/$digest',
    );
  }

  @override
  Future<PackageInstallEvidence> install(
    AuthoringArtifactRef package,
  ) async {
    final bytes = _resolve(package);
    final digest = package.sha256!;
    final inspection =
        _inspectionsByDigest[digest] ?? _inspector.inspect(bytes);
    final installed = await _installer(
      artifact: package,
      packageBytes: List<int>.unmodifiable(bytes),
      inspection: inspection,
    );
    return PackageInstallEvidence(
      exportedDigest: 'sha256:$digest',
      installedDigest: 'sha256:${installed.packageSha256}',
      passed: installed.passed,
      evidenceRef: installed.evidenceRef,
    );
  }

  List<int> _resolve(AuthoringArtifactRef artifact) {
    final digest = artifact.sha256;
    if (digest == null || artifact.uri != 'artifact://sha256/$digest') {
      throw StateError('Package artifact identity is incomplete.');
    }
    final bytes = _bytesByDigest[digest];
    if (bytes == null || artifact.byteLength != bytes.length) {
      throw StateError('Package artifact is unknown or stale.');
    }
    return bytes;
  }
}

String _sha256(String value, String field) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a SHA-256 hex digest');
  }
  return value;
}

String _evidenceRef(String value) {
  final normalized = value.trim();
  final uri = Uri.tryParse(normalized);
  if (normalized.isEmpty ||
      uri == null ||
      !uri.hasScheme ||
      uri.scheme == 'file') {
    throw ArgumentError.value(
      value,
      'evidenceRef',
      'must be a stable non-file URI',
    );
  }
  return normalized;
}
