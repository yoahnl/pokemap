import 'package:pub_semver/pub_semver.dart';

import 'game_package_security_policy.dart';

enum GamePackageInstallSource { localExport, localFile, publicCatalog }

enum GamePackageInstallCompatibility { accept, migrate }

final class GamePackageInstallValidation {
  const GamePackageInstallValidation({
    required this.compatibility,
  });

  final GamePackageInstallCompatibility compatibility;

  Map<String, Object?> toJson() => <String, Object?>{
        'packageInspection': 'passed',
        'projectValidation': 'passed',
        'loadSmoke': 'passed',
        'compatibility': compatibility.name,
      };
}

final class GamePackageInstallReceipt {
  const GamePackageInstallReceipt({
    required this.receiptFormat,
    required this.securityPolicyVersion,
    required this.gameId,
    required this.gameVersion,
    required this.treeSha256,
    required this.manifestSha256,
    required this.packageSha256,
    required this.validatedAt,
    required this.installedAt,
    required this.source,
    required this.signatureStatus,
    required this.validation,
  });

  final int receiptFormat;
  final int securityPolicyVersion;
  final String gameId;
  final Version gameVersion;
  final String treeSha256;
  final String manifestSha256;
  final String packageSha256;
  final DateTime validatedAt;
  final DateTime installedAt;
  final GamePackageInstallSource source;
  final PackageSignatureStatus signatureStatus;
  final GamePackageInstallValidation validation;

  Map<String, Object?> toJson() => <String, Object?>{
        'receiptFormat': receiptFormat,
        'securityPolicyVersion': securityPolicyVersion,
        'gameId': gameId,
        'gameVersion': gameVersion.toString(),
        'treeSha256': treeSha256,
        'manifestSha256': manifestSha256,
        'packageSha256': packageSha256,
        'validatedAt': validatedAt.toUtc().toIso8601String(),
        'installedAt': installedAt.toUtc().toIso8601String(),
        'source': source.name,
        'signatureStatus': signatureStatus.name,
        'validation': validation.toJson(),
      };
}
