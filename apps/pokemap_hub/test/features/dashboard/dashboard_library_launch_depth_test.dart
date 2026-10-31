import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/app/di/dashboard_dependencies_provider.dart';
import 'package:pokemap_hub/app/di/providers.dart';
import 'package:pokemap_hub/features/installation/data/repositories/installed_game_verifier.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/session/data/repositories/installed_game_launch_resolver.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';
import 'package:pub_semver/pub_semver.dart';

final class _CountingLaunchRepository
    implements SessionLaunchRepositoryInterface {
  int resolved = 0;

  @override
  Future<InstalledGameLaunchContext> resolve(InstalledGame game) async {
    resolved++;
    throw const InstalledGameLaunchException(
      InstalledGameLaunchErrorCode.installationUnhealthy,
      'counted',
    );
  }
}

InstalledGame _game() {
  final installed = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: 'a' * 64,
    installedAt: DateTime.utc(2026, 10, 31),
    receiptFileName: '1.0.0-${'a' * 64}.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return InstalledGame(
    gameId: 'games.example.depth',
    title: 'Depth',
    authorName: 'Example',
    defaultLocale: 'fr',
    supportedLocales: const <String>['fr'],
    current: InstalledGamePointer(
      gameVersion: installed.gameVersion,
      treeSha256: 'a' * 64,
    ),
    versions: <InstalledGameVersion>[installed],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('dashboard_launch_depth_');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('the library launch resolver stops at structure depth', () async {
    final container = ProviderContainer(
      overrides: [supportRootProvider.overrideWith((ref) async => root)],
    );
    addTearDown(container.dispose);

    final resolver =
        await container.read(libraryLaunchRepositoryProvider.future)
            as InstalledGameLaunchResolver;

    expect(
      resolver.verificationDepth,
      InstalledGameVerificationDepth.structure,
    );
    expect(resolver.supportRoot.path, root.path);
  });

  test('the dashboard activity reader goes through the library provider',
      () async {
    final counting = _CountingLaunchRepository();
    final container = ProviderContainer(
      overrides: [
        supportRootProvider.overrideWith(
          (ref) async => Directory(p.join(root.path, 'support'))..createSync(),
        ),
        libraryLaunchRepositoryProvider.overrideWith((ref) async => counting),
      ],
    );
    addTearDown(container.dispose);

    final dependencies = await container.read(
      hubDashboardDependenciesProvider.future,
    );
    final activity = await dependencies.activityReader(_game());

    expect(counting.resolved, 1);
    expect(activity.installationHealthy, isFalse);
  });
}
