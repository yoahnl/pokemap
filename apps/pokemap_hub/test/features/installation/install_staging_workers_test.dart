import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/features/installation/data/repositories/install_staging.dart';
import 'package:pokemap_hub/features/installation/domain/entities/game_installation_diagnostic.dart';
import 'package:test/test.dart';

import '../../support/game_package_fixture.dart';

void main() {
  late Directory root;
  late File package;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('install-inspection-workers-');
    package = await writeTestPackage(Directory('${root.path}/selected'));
  });

  tearDown(() async => root.delete(recursive: true));

  InstallStaging staging(GamePackageInspector inspector) => InstallStaging(
    supportRoot: Directory('${root.path}/support'),
    inspector: inspector,
  );

  test('inspects signed packages away from the calling isolate', () async {
    await _sign(package);
    final messages = ReceivePort();
    addTearDown(messages.close);
    final inspection = await staging(
      GamePackageInspector(
        trustRequirement: PackageTrustRequirement.signatureRequired,
        signatureVerifier: _ReportingVerifier(messages.sendPort),
        hostCompatibility: testHostCompatibility(),
      ),
    ).inspect(package);

    expect(await messages.first, isNot(Isolate.current.debugName));
    expect(inspection.signatureStatus, PackageSignatureStatus.verified);
    expect(
      inspection.compatibility!.decision,
      GamePackageCompatibilityDecision.accept,
    );
  });

  test('preserves rejection of invalid signatures', () async {
    await _sign(package);
    await expectLater(
      staging(
        GamePackageInspector(
          trustRequirement: PackageTrustRequirement.signatureRequired,
          signatureVerifier: const _RejectingVerifier(),
        ),
      ).inspect(package),
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'signatureInvalid',
        ),
      ),
    );
  });

  test('preserves required signatures for unsigned packages', () async {
    await expectLater(
      staging(
        const GamePackageInspector(
          trustRequirement: PackageTrustRequirement.signatureRequired,
        ),
      ).inspect(package),
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'signatureRequired',
        ),
      ),
    );
  });

  test('preserves lowered package quotas', () async {
    await expectLater(
      staging(
        const GamePackageInspector(
          policy: GamePackageSecurityPolicy(maxArchiveBytes: 1),
        ),
      ).inspect(package),
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'archiveTooLarge',
        ),
      ),
    );
  });

  test('preserves custom host capability rejection', () async {
    final host = testHostCompatibility();
    await expectLater(
      staging(
        GamePackageInspector(
          hostCompatibility: GamePackageHostCompatibility(
            hubVersion: host.hubVersion,
            runtimeApiVersion: host.runtimeApiVersion,
            capabilities: const {},
            supportedProjectFormats: host.supportedProjectFormats,
            currentProjectFormat: host.currentProjectFormat,
            supportedSaveFormats: host.supportedSaveFormats,
          ),
        ),
      ).inspect(package),
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'capabilityUnsupported',
        ),
      ),
    );
  });

  Future<(InstallStaging, Directory, GamePackageManifest)>
  stagedProject() async {
    final service = staging(
      GamePackageInspector(hostCompatibility: testHostCompatibility()),
    );
    final inspection = await service.inspect(package);
    final target = Directory('${root.path}/staged');
    await service.extractSnapshot(
      package,
      target,
      inspection,
      cancellationToken: GameInstallCancellationToken(),
      onProgress: null,
    );
    return (service, target, inspection.manifest);
  }

  test('rejects same-size staged tampering in project validation', () async {
    final (service, target, manifest) = await stagedProject();
    final project = File('${target.path}/project/project.json');
    final bytes = await project.readAsBytes();
    bytes[bytes.length - 1] ^= 1;
    await project.writeAsBytes(bytes, flush: true);

    await expectLater(
      service.validateProject(target, manifest),
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'hashMismatch',
        ),
      ),
    );
  });

  test('rejects a staged project replaced by a symlink', () async {
    final (service, target, manifest) = await stagedProject();
    final project = File('${target.path}/project/project.json');
    final outside = await project.copy('${root.path}/outside.json');
    await project.delete();
    await Link(project.path).create(outside.path);

    await expectLater(
      service.validateProject(target, manifest),
      throwsA(
        isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'unsafeEntry',
        ),
      ),
    );
  }, skip: Platform.isWindows);
}

Future<void> _sign(File file) async {
  final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
  try {
    final manifest = const GamePackageManifestCodec().decodeUtf8(
      archive.findFile('game-manifest.json')!.content,
    );
    final built = const GamePackageBuilder().build(
      manifest: manifest.copyWith(
        signature: GamePackageSignature(
          algorithm: 'ed25519',
          keyId: 'test.publisher',
          value: base64Encode(List<int>.filled(64, 7)),
        ),
      ),
      payloadFiles: {
        for (final entry in archive.files)
          if (entry.name != 'game-manifest.json') entry.name: entry.content,
      },
    );
    await file.writeAsBytes(built.packageBytes, flush: true);
  } finally {
    await archive.clear();
  }
}

final class _ReportingVerifier implements GamePackageSignatureVerifier {
  const _ReportingVerifier(this.messages);
  final SendPort messages;

  @override
  bool verify({
    required String keyId,
    required List<int> preimage,
    required List<int> signature,
  }) {
    messages.send(Isolate.current.debugName);
    return true;
  }
}

final class _RejectingVerifier implements GamePackageSignatureVerifier {
  const _RejectingVerifier();

  @override
  bool verify({
    required String keyId,
    required List<int> preimage,
    required List<int> signature,
  }) => false;
}
