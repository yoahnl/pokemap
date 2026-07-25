import 'package:map_distribution/map_distribution.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('GamePackageReleasePolicy', () {
    const policy = GamePackageReleasePolicy();
    final installed = GamePackageReleaseIdentity(
      gameId: 'games.example.release',
      gameVersion: Version.parse('1.2.0'),
      treeSha256: 'a' * 64,
    );

    test('HP-023 rejects a republished identity with different content', () {
      final candidate = GamePackageReleaseIdentity(
        gameId: installed.gameId,
        gameVersion: installed.gameVersion,
        treeSha256: 'b' * 64,
      );

      expect(
        policy
            .evaluate(
              installed: installed,
              candidate: candidate,
              mode: GamePackageActivationMode.update,
            )
            .code,
        'releaseConflict',
      );
    });

    test('distinguishes update and rollback activation', () {
      final older = GamePackageReleaseIdentity(
        gameId: installed.gameId,
        gameVersion: Version.parse('1.1.0'),
        treeSha256: 'b' * 64,
      );
      expect(
        policy
            .evaluate(
              installed: installed,
              candidate: older,
              mode: GamePackageActivationMode.update,
            )
            .code,
        'notAnUpdate',
      );
      expect(
        policy.evaluate(
          installed: installed,
          candidate: older,
          mode: GamePackageActivationMode.rollback,
          compatibleSaveSnapshotAvailable: true,
        ),
        const GamePackageReleaseResult.acceptWithWarning(
          code: 'rollbackConfirmationRequired',
        ),
      );
    });

    test('ignores build metadata for SemVer precedence', () {
      final withBuild = GamePackageReleaseIdentity(
        gameId: installed.gameId,
        gameVersion: Version.parse('1.2.0+build.2'),
        treeSha256: installed.treeSha256,
      );
      expect(
        policy
            .evaluate(
              installed: installed,
              candidate: withBuild,
              mode: GamePackageActivationMode.update,
            )
            .code,
        'notAnUpdate',
      );

      final conflictingBuild = GamePackageReleaseIdentity(
        gameId: installed.gameId,
        gameVersion: Version.parse('1.2.0+repacked'),
        treeSha256: 'b' * 64,
      );
      expect(
        policy
            .evaluate(
              installed: installed,
              candidate: conflictingBuild,
              mode: GamePackageActivationMode.update,
            )
            .code,
        'releaseConflict',
      );
    });
  });
}
