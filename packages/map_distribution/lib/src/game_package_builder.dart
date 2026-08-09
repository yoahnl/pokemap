import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'canonical_json.dart';
import 'deterministic_zip_encoder.dart';
import 'game_package_format_exception.dart';
import 'game_package_content_validator.dart';
import 'game_package_inventory_builder.dart';
import 'game_package_manifest.dart';
import 'game_package_manifest_codec.dart';
import 'game_package_project_validator.dart';
import 'game_package_security_policy.dart';
import 'package_path_policy.dart';

final class GamePackageBuildResult {
  GamePackageBuildResult({
    required this.manifest,
    required List<int> packageBytes,
  }) : packageBytes = List.unmodifiable(packageBytes),
       packageSha256 = sha256.convert(packageBytes).toString(),
       archiveBytes = packageBytes.length;

  final GamePackageManifest manifest;
  final List<int> packageBytes;
  final String packageSha256;
  final int archiveBytes;
}

/// Builds the deterministic ZIP representation of a `.avelunegame` archive.
final class GamePackageBuilder {
  const GamePackageBuilder({
    this.inventoryBuilder = const GamePackageInventoryBuilder(),
    this.manifestCodec = const GamePackageManifestCodec(),
    this.securityPolicy = const GamePackageSecurityPolicy(),
  });

  final GamePackageInventoryBuilder inventoryBuilder;
  final GamePackageManifestCodec manifestCodec;
  final GamePackageSecurityPolicy securityPolicy;

  GamePackageBuildResult build({
    required GamePackageManifest manifest,
    required Map<String, List<int>> payloadFiles,
    PackageMediaTypeResolver? mediaTypeForPath,
  }) {
    final inventory = inventoryBuilder.buildWithSnapshot(
      payloadFiles,
      mediaTypeForPath: mediaTypeForPath,
    );
    final content = inventory.content;
    final payloadSnapshot = inventory.payloadSnapshot;
    if (content.fileCount > securityPolicy.maxPayloadEntries) {
      throw GamePackageFormatException(
        code: 'entryCountExceeded',
        path: r'$.content.files',
        message: 'Payload entry count exceeds builder policy.',
      );
    }
    if (content.totalBytes > securityPolicy.maxTotalPayloadBytes) {
      throw GamePackageFormatException(
        code: 'archiveTooLarge',
        path: r'$.content.totalBytes',
        message: 'Payload total exceeds builder policy.',
      );
    }
    for (final entry in content.files) {
      if (entry.size > securityPolicy.maxFileBytes) {
        throw GamePackageFormatException(
          code: 'entryTooLarge',
          path: entry.path,
          message: 'Payload entry exceeds builder policy.',
        );
      }
    }
    if (manifest.signature != null &&
        CanonicalJson.encode(manifest.content.toJson()) !=
            CanonicalJson.encode(content.toJson())) {
      throw GamePackageFormatException(
        code: 'staleSignature',
        path: r'$.signature',
        message: 'Signed manifest content differs from the payload inventory.',
      );
    }
    final packagedManifest = manifest.copyWith(content: content);
    final manifestBytes = manifestCodec.encodeCanonicalUtf8(packagedManifest);
    if (manifestBytes.length > securityPolicy.maxManifestBytes) {
      throw GamePackageFormatException(
        code: 'manifestTooLarge',
        path: 'game-manifest.json',
        message: 'Manifest exceeds builder policy.',
      );
    }
    final contentValidator = GamePackageContentValidator(securityPolicy);
    GamePackageBinarySecretScanner('game-manifest.json').add(manifestBytes);
    for (final entry in content.files) {
      contentValidator.validate(
        entry,
        Uint8List.fromList(payloadSnapshot[entry.path]!),
      );
    }
    GamePackageProjectValidator(securityPolicy).validate(
      packagedManifest,
      Uint8List.fromList(payloadSnapshot['project/project.json']!),
      payloadPaths: payloadSnapshot.keys.toSet(),
    );
    final entries =
        <MapEntry<String, List<int>>>[
          MapEntry<String, List<int>>('game-manifest.json', manifestBytes),
          ...payloadSnapshot.entries,
        ]..sort(
          (left, right) => PackagePathPolicy.compareUtf8(left.key, right.key),
        );

    final bytes = DeterministicZipEncoder.encode(entries);
    if (bytes.length > securityPolicy.maxArchiveBytes) {
      throw GamePackageFormatException(
        code: 'archiveTooLarge',
        path: r'$',
        message: 'Built package exceeds archive policy.',
      );
    }
    return GamePackageBuildResult(
      manifest: manifestCodec.decodeUtf8(manifestBytes),
      packageBytes: bytes,
    );
  }
}
