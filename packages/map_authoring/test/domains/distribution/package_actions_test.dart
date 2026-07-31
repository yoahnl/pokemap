import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('release runs build inspect install and binds identical digests',
      () async {
    final port = _FakePackagePort(installedDigest: _digest('a'));
    final actions = DistributionPackageActions(port: port);

    final receipt = await actions.release(
      request: PackageBuildRequest(
        requestId: 'request-072',
        packageId: 'golden-slice',
        projectId: 'golden-project',
        sourceRevision: _digest('b'),
        releaseVersion: '1.0.0',
      ),
      regressionGates: <PackageReleaseGateEvidence>[
        PackageReleaseGateEvidence(
          id: 'runtime.golden-slice',
          passed: true,
          summary: 'Production runtime reached the expected map.',
          evidenceRef: 'test://runtime/golden-slice',
        ),
        PackageReleaseGateEvidence(
          id: 'regression.matrix',
          passed: true,
          summary: 'The scoped matrix passed.',
          evidenceRef: 'test://release/regression-matrix',
        ),
      ],
      gameplayLots: <GameplayLotReleaseMapping>[
        GameplayLotReleaseMapping(lotId: 'FG-180', status: 'DONE'),
        GameplayLotReleaseMapping(lotId: 'FG-185', status: 'PARTIAL'),
      ],
    );

    expect(port.calls, <String>['build', 'inspect', 'install']);
    expect(receipt.isReady, isTrue);
    expect(receipt.sourceRevision, _digest('b'));
    expect(receipt.packageDigest, _digest('a'));
    expect(receipt.installedDigest, receipt.packageDigest);
    expect(receipt.gates, everyElement(hasEvidence));
    expect(
      receipt.gameplayLots.map((item) => item.updateApplied),
      everyElement(isFalse),
    );
  });

  test('release fails closed when installed bytes differ', () async {
    final port = _FakePackagePort(installedDigest: _digest('c'));

    final receipt = await DistributionPackageActions(port: port).release(
      request: PackageBuildRequest(
        requestId: 'request-mismatch',
        packageId: 'golden-slice',
        projectId: 'golden-project',
        sourceRevision: _digest('b'),
        releaseVersion: '1.0.0',
      ),
      regressionGates: <PackageReleaseGateEvidence>[],
      gameplayLots: <GameplayLotReleaseMapping>[],
    );

    expect(receipt.isReady, isFalse);
    expect(
      receipt.gates.singleWhere((gate) => gate.id == 'package.byte-identity'),
      isA<PackageReleaseGateEvidence>()
          .having((gate) => gate.passed, 'passed', isFalse)
          .having((gate) => gate.evidenceRef, 'evidenceRef', isNotEmpty),
    );
  });

  test('release never installs a package rejected by inspection', () async {
    final port = _FakePackagePort(
      installedDigest: _digest('a'),
      inspectionPassed: false,
    );

    final receipt = await DistributionPackageActions(port: port).release(
      request: PackageBuildRequest(
        requestId: 'request-rejected',
        packageId: 'golden-slice',
        projectId: 'golden-project',
        sourceRevision: _digest('b'),
        releaseVersion: '1.0.0',
      ),
      regressionGates: <PackageReleaseGateEvidence>[],
      gameplayLots: <GameplayLotReleaseMapping>[],
    );

    expect(port.calls, <String>['build', 'inspect']);
    expect(receipt.isReady, isFalse);
    expect(
      receipt.gates.singleWhere((gate) => gate.id == 'package.inspect').passed,
      isFalse,
    );
  });
}

Matcher get hasEvidence => isA<PackageReleaseGateEvidence>()
    .having((gate) => gate.evidenceRef, 'evidenceRef', isNotEmpty);

String _digest(String character) => 'sha256:${character * 64}';

final class _FakePackagePort implements AuthoringPackagePort {
  _FakePackagePort({
    required this.installedDigest,
    this.inspectionPassed = true,
  });

  final String installedDigest;
  final bool inspectionPassed;
  final List<String> calls = <String>[];

  AuthoringArtifactRef get artifact => AuthoringArtifactRef(
        id: 'package-golden',
        mediaType: 'application/vnd.pokemap.game+zip',
        uri: 'artifact://sha256/${'a' * 64}',
        byteLength: 128,
        sha256: 'a' * 64,
      );

  @override
  Future<PackageBuildEvidence> build(PackageBuildRequest request) async {
    calls.add('build');
    return PackageBuildEvidence(
      request: request,
      artifact: artifact,
      treeDigest: _digest('d'),
      evidenceRef: 'build://golden/${artifact.sha256}',
    );
  }

  @override
  Future<PackageInspectionEvidence> inspect(
    AuthoringArtifactRef package,
  ) async {
    calls.add('inspect');
    return PackageInspectionEvidence(
      artifact: package,
      treeDigest: _digest('d'),
      passed: inspectionPassed,
      evidenceRef: 'inspection://golden/${package.sha256}',
    );
  }

  @override
  Future<PackageInstallEvidence> install(
    AuthoringArtifactRef package,
  ) async {
    calls.add('install');
    return PackageInstallEvidence(
      exportedDigest: 'sha256:${package.sha256}',
      installedDigest: installedDigest,
      passed: true,
      evidenceRef: 'install://golden/${package.sha256}',
    );
  }
}
