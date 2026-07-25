import 'package:pub_semver/pub_semver.dart';

import 'game_package_manifest.dart';
import 'semver_precedence.dart';

enum GamePackageCompatibilityDecision { accept, migrate, reject }

final class GamePackageHostCompatibility {
  GamePackageHostCompatibility({
    required this.hubVersion,
    required this.runtimeApiVersion,
    required Set<String> capabilities,
    required Set<String> supportedProjectFormats,
    required this.currentProjectFormat,
    required Set<int> supportedSaveFormats,
  })  : capabilities = Set.unmodifiable(capabilities),
        supportedProjectFormats = Set.unmodifiable(supportedProjectFormats),
        supportedSaveFormats = Set.unmodifiable(supportedSaveFormats);

  final Version hubVersion;
  final Version runtimeApiVersion;
  final Set<String> capabilities;
  final Set<String> supportedProjectFormats;
  final String currentProjectFormat;
  final Set<int> supportedSaveFormats;
}

final class GamePackageCompatibilityResult {
  const GamePackageCompatibilityResult.accept()
      : decision = GamePackageCompatibilityDecision.accept,
        code = null,
        blockingCodes = const <String>[],
        missingCapabilities = const <String>[];

  const GamePackageCompatibilityResult.migrate({required this.code})
      : decision = GamePackageCompatibilityDecision.migrate,
        blockingCodes = const <String>[],
        missingCapabilities = const <String>[];

  const GamePackageCompatibilityResult.reject({
    required this.code,
    this.blockingCodes = const <String>[],
    this.missingCapabilities = const <String>[],
  }) : decision = GamePackageCompatibilityDecision.reject;

  final GamePackageCompatibilityDecision decision;
  final String? code;
  final List<String> blockingCodes;
  final List<String> missingCapabilities;

  @override
  bool operator ==(Object other) =>
      other is GamePackageCompatibilityResult &&
      decision == other.decision &&
      code == other.code &&
      _listEquals(blockingCodes, other.blockingCodes) &&
      _listEquals(missingCapabilities, other.missingCapabilities);

  @override
  int get hashCode => Object.hash(
        decision,
        code,
        Object.hashAll(blockingCodes),
        Object.hashAll(missingCapabilities),
      );

  static bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

/// Applies the precedence documented by the Phase 0 compatibility contract.
final class GamePackageCompatibilityEvaluator {
  const GamePackageCompatibilityEvaluator();

  GamePackageCompatibilityResult evaluate(
    GamePackageManifest manifest,
    GamePackageHostCompatibility host,
  ) {
    final compatibility = manifest.compatibility;
    final blockers = <String>[];
    if (manifest.packageFormat != 1) {
      blockers.add('packageFormatUnsupported');
    }
    if (compareSemverPrecedence(
          host.hubVersion,
          compatibility.minHubVersion,
        ) <
        0) {
      blockers.add('hubTooOld');
    }
    if (!semverConstraintAllows(
      compatibility.runtimeApi,
      host.runtimeApiVersion,
    )) {
      blockers.add('runtimeApiUnsupported');
    }
    final missing = compatibility.requiredCapabilities
        .where((capability) => !host.capabilities.contains(capability))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      blockers.add('capabilityUnsupported');
    }
    if (!host.supportedProjectFormats.contains(
      compatibility.projectFormat,
    )) {
      blockers.add('projectFormatUnsupported');
    }
    if (!host.supportedSaveFormats.contains(compatibility.saveFormat)) {
      blockers.add('saveFormatUnsupported');
    }
    if (blockers.isNotEmpty) {
      return GamePackageCompatibilityResult.reject(
        code: blockers.first,
        blockingCodes: List.unmodifiable(blockers),
        missingCapabilities: missing,
      );
    }
    if (compatibility.projectFormat != host.currentProjectFormat) {
      return const GamePackageCompatibilityResult.migrate(
        code: 'projectMigrationRequired',
      );
    }
    return const GamePackageCompatibilityResult.accept();
  }
}
