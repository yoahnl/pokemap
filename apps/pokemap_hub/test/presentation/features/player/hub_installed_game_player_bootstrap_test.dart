import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';
import 'package:pokemap_hub/presentation/features/player/pages/hub_installed_game_player.dart';

void main() {
  testWidgets('mounts the runtime splash on the first frame', (tester) async {
    final launch = Completer<InstalledGameLaunchContext>();

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.light(),
        home: HubInstalledGamePlayer(
          supportRoot: Directory.systemTemp,
          saveRepositoryFactory: (_, __) => throw UnimplementedError(),
          preferencesRepository: _UnusedPreferencesRepository(),
          controlProfileRepository: _UnusedControlProfileRepository(),
          launchResolver: _PendingLaunchResolver(launch.future),
          game: _game(),
          onHubRequested: () async {},
          diagnosticLogFile: File('/dev/null'),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('pokemap-runtime-startup-shell')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('startup-splash-timeline')),
      findsOneWidget,
    );
    expect(find.byType(PlayerLoadingSurface), findsNothing);
    final splash = find.byKey(
      const ValueKey<String>('startup-splash-timeline'),
    );
    final background =
        tester
            .widgetList<DecoratedBox>(
              find.descendant(of: splash, matching: find.byType(DecoratedBox)),
            )
            .first;
    final gradient = (background.decoration as BoxDecoration).gradient;
    expect((gradient as RadialGradient).colors.last, const Color(0xFF02040A));

    launch.completeError(StateError('bootstrap test completed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
  });
}

final class _PendingLaunchResolver implements SessionLaunchRepositoryInterface {
  const _PendingLaunchResolver(this.pending);

  final Future<InstalledGameLaunchContext> pending;

  @override
  Future<InstalledGameLaunchContext> resolve(InstalledGame game) => pending;
}

final class _UnusedPreferencesRepository
    implements PlayerPreferencesRepositoryInterface {
  @override
  Future<HubPreferencesRead> load() => throw UnimplementedError();

  @override
  Future<void> save(PlayerPreferences preferences) =>
      throw UnimplementedError();
}

final class _UnusedControlProfileRepository
    implements ControlProfileRepositoryInterface {
  @override
  Future<PlayerControlProfile> load() => throw UnimplementedError();

  @override
  Future<void> save(PlayerControlProfile profile) => throw UnimplementedError();
}

InstalledGame _game() {
  final version = Version(0, 1, 1);
  const tree =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  final installedVersion = InstalledGameVersion(
    gameVersion: version,
    treeSha256: tree,
    installedAt: DateTime.utc(2026, 8, 9),
    receiptFileName: 'receipt.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return InstalledGame(
    gameId: 'games.example.train',
    title: 'Le Train de 17h42',
    authorName: 'PokeMap',
    defaultLocale: 'fr',
    supportedLocales: const <String>['fr'],
    current: installedVersion.pointer,
    versions: <InstalledGameVersion>[installedVersion],
  );
}
