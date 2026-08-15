import 'package:map_core/map_core.dart';

import 'game_package_compatibility.dart';
import 'game_package_manifest.dart';
import 'game_package_security_policy.dart';

final class GamePackageInspectionReceipt {
  const GamePackageInspectionReceipt({
    required this.receiptVersion,
    required this.securityPolicyVersion,
    required this.gameId,
    required this.gameVersion,
    required this.treeSha256,
    required this.manifestSha256,
    required this.packageSha256,
    required this.archiveBytes,
    required this.payloadBytes,
    required this.fileCount,
    required this.signatureStatus,
    required this.pokemonRuleset,
  });

  final int receiptVersion;
  final int securityPolicyVersion;
  final String gameId;
  final String gameVersion;
  final String treeSha256;
  final String manifestSha256;
  final String packageSha256;
  final int archiveBytes;
  final int payloadBytes;
  final int fileCount;
  final PackageSignatureStatus signatureStatus;
  final PokemonRulesetReference pokemonRuleset;

  Map<String, Object?> toJson() => <String, Object?>{
        'receiptVersion': receiptVersion,
        'securityPolicyVersion': securityPolicyVersion,
        'gameId': gameId,
        'gameVersion': gameVersion,
        'treeSha256': treeSha256,
        'manifestSha256': manifestSha256,
        'packageSha256': packageSha256,
        'archiveBytes': archiveBytes,
        'payloadBytes': payloadBytes,
        'fileCount': fileCount,
        'signatureStatus': signatureStatus.name,
        'pokemonRuleset': pokemonRuleset.toJson(),
      };
}

final class GamePackageInspectionResult {
  GamePackageInspectionResult({
    required this.manifest,
    required List<String> payloadPaths,
    required this.signatureStatus,
    required this.compatibility,
    required this.receipt,
  }) : payloadPaths = List.unmodifiable(payloadPaths);

  final GamePackageManifest manifest;
  final List<String> payloadPaths;
  final PackageSignatureStatus signatureStatus;
  final GamePackageCompatibilityResult? compatibility;
  final GamePackageInspectionReceipt receipt;
}
