import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pokemap_hub/features/library/domain/entities/game_library.dart';
import 'package:pokemap_hub/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:pokemap_hub/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_bootstrap.dart';
import 'package:pokemap_hub/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:pokemap_hub/features/session/domain/repositories/control_profile_repository_interface.dart';
import 'package:pokemap_hub/features/session/domain/repositories/session_launch_repository_interface.dart';
import 'package:pokemap_hub/presentation/features/player/pages/hub_installed_game_player.dart';

import '../../../support/runtime_player_hub_fixture.dart';

void main() {
  test(
    'closing cancels the splash frame gate before resolving a game',
    () async {
      final lifetime = HubRuntimeStartupLifetime();
      final frame = Completer<void>();
      final resolver = _PendingLaunchResolver(
        Completer<InstalledGameLaunchContext>().future,
      );
      final bootstrap = HubRuntimeStartupBootstrap(
        lifetime: lifetime,
        startupWorkGate: frame.future,
        supportRoot: Directory.systemTemp,
        saveRepositoryFactory: (_, _) => throw UnimplementedError(),
        preferencesRepository: _UnusedPreferencesRepository(),
        controlProfileRepository: _UnusedControlProfileRepository(),
        launchResolver: resolver,
        game: _game(),
        onHubRequested: () async {},
        mountGame: (_) async {},
        unmountGame: (_) async {},
        stopIntroPlayback: () async {},
        defaultProfileDisplayNameForLocale: (_) => 'Joueur',
        diagnosticLogFile: File('/dev/null'),
      );
      final preparation = bootstrap.prepare(onStageCompleted: (_) {});
      final cancelled = expectLater(preparation, throwsA(isA<Exception>()));
      await lifetime.close().timeout(const Duration(seconds: 1));
      await cancelled;
      expect(frame.isCompleted, isFalse);
      expect(resolver.resolveCalls, 0);
    },
  );

  test(
    'closed preparation waits for late resolution and cannot touch saves',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'avelune-stop-bootstrap-',
      );
      addTearDown(() => root.delete(recursive: true));
      final context = await createRuntimePlayerLaunchContext(root);
      final launch = Completer<InstalledGameLaunchContext>();
      final lifetime = HubRuntimeStartupLifetime();
      var saveCalls = 0;
      final bootstrap = HubRuntimeStartupBootstrap(
        lifetime: lifetime,
        supportRoot: root,
        saveRepositoryFactory: (_, _) {
          saveCalls++;
          throw StateError('a cancelled preparation must not open saves');
        },
        preferencesRepository: _UnusedPreferencesRepository(),
        controlProfileRepository: _UnusedControlProfileRepository(),
        launchResolver: _PendingLaunchResolver(launch.future),
        game: context.game,
        onHubRequested: () async {},
        mountGame: (_) async {},
        unmountGame: (_) async {},
        stopIntroPlayback: () async {},
        defaultProfileDisplayNameForLocale: (_) => 'Joueur',
        diagnosticLogFile: File('/dev/null'),
      );
      final preparation = bootstrap.prepare(onStageCompleted: (_) {});
      final cancelled = expectLater(preparation, throwsA(isA<Exception>()));
      var closed = false;
      final closing = lifetime.close().then((_) => closed = true);
      await Future<void>.delayed(Duration.zero);
      expect(closed, isFalse);
      launch.complete(context);
      await cancelled;
      await closing;
      expect(closed, isTrue);
      expect(saveCalls, 0);
      expect(await Directory(root.path).list().map((e) => e.path).toList(), [
        Directory('${root.path}/version').path,
      ]);
    },
  );

  test(
    'waits until the splash reveal finishes before preparing the game',
    () async {
      final reveal = Completer<void>();
      final launch = Completer<InstalledGameLaunchContext>();
      final resolver = _PendingLaunchResolver(launch.future);
      final bootstrap = HubRuntimeStartupBootstrap(
        supportRoot: Directory.systemTemp,
        saveRepositoryFactory: (_, _) => throw UnimplementedError(),
        preferencesRepository: _UnusedPreferencesRepository(),
        controlProfileRepository: _UnusedControlProfileRepository(),
        launchResolver: resolver,
        game: _game(),
        onHubRequested: () async {},
        mountGame: (_) async {},
        unmountGame: (_) async {},
        stopIntroPlayback: () async {},
        defaultProfileDisplayNameForLocale: (_) => 'Joueur',
        diagnosticLogFile: File('/dev/null'),
        startupWorkGate: reveal.future,
      );

      final preparation = bootstrap.prepare(onStageCompleted: (_) {});
      await Future<void>.delayed(Duration.zero);
      expect(resolver.resolveCalls, 0);

      reveal.complete();
      await Future<void>.delayed(Duration.zero);
      expect(resolver.resolveCalls, 1);
      launch.completeError(StateError('bootstrap test completed'));
      await expectLater(
        preparation,
        throwsA(isA<RuntimeStartupBootstrapException>()),
      );
    },
  );

  testWidgets('loads the game while motion waits for the jingle to start', (
    tester,
  ) async {
    final launch = Completer<InstalledGameLaunchContext>();
    final preferences = Completer<HubPreferencesRead>();
    final audio = _GateSplashAudioDriver();

    await tester.pumpWidget(
      MaterialApp(
        home: HubInstalledGamePlayer(
          supportRoot: Directory.systemTemp,
          saveRepositoryFactory: (_, _) => throw UnimplementedError(),
          preferencesRepository: _PendingPreferencesRepository(
            preferences.future,
          ),
          controlProfileRepository: _UnusedControlProfileRepository(),
          launchResolver: _PendingLaunchResolver(launch.future),
          game: _game(),
          hostBranding: const RuntimeHostSplashBranding(
            displayName: 'TEST',
            signature: 'RUNTIME',
          ),
          splashLogo: null,
          splashAudioDriver: audio,
          onHubRequested: () async {},
          diagnosticLogFile: File('/dev/null'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester
          .widget<PlayerRuntimeStartupShell>(
            find.byType(PlayerRuntimeStartupShell),
          )
          .splashAnimationReady,
      isFalse,
    );
    expect(
      tester
          .widget<PlayerSplashTimeline>(find.byType(PlayerSplashTimeline))
          .progress,
      0,
    );
    expect(audio.playCalls, 0);

    preferences.complete(
      const HubPreferencesRead(
        preferences: PlayerPreferences(masterVolume: .5, musicVolume: .4),
        source: HubPreferencesSource.current,
        currentCorrupt: false,
        backupCorrupt: false,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(audio.playCalls, 1);
    expect(audio.lastVolume, closeTo(.12, .0001));
    expect(
      tester
          .widget<PlayerRuntimeStartupShell>(
            find.byType(PlayerRuntimeStartupShell),
          )
          .splashAnimationReady,
      isFalse,
    );

    audio.start();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester
          .widget<PlayerRuntimeStartupShell>(
            find.byType(PlayerRuntimeStartupShell),
          )
          .splashAnimationReady,
      isTrue,
    );
    expect(
      tester
          .widget<PlayerSplashTimeline>(find.byType(PlayerSplashTimeline))
          .progress,
      greaterThan(0),
    );
    expect(launch.isCompleted, isFalse);

    launch.completeError(StateError('bootstrap test completed'));
    await tester.pump();
  });

  testWidgets('mounts the runtime splash on the first frame', (tester) async {
    final launch = Completer<InstalledGameLaunchContext>();
    const logo = AssetImage('assets/avelune/logo/avelune_moon.png');
    const wordmark = AssetImage(
      'assets/avelune/logo/avelune_glass_wordmark.png',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: PokeMapPlayerTheme.light(),
        home: HubInstalledGamePlayer(
          supportRoot: Directory.systemTemp,
          saveRepositoryFactory: (_, _) => throw UnimplementedError(),
          preferencesRepository: _UnusedPreferencesRepository(),
          controlProfileRepository: _UnusedControlProfileRepository(),
          launchResolver: _PendingLaunchResolver(launch.future),
          game: _game(),
          hostBranding: const RuntimeHostSplashBranding(
            displayName: 'TEST',
            signature: 'RUNTIME',
          ),
          splashLogo: logo,
          splashWordmark: wordmark,
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
    expect(
      Localizations.localeOf(
        tester.element(find.byType(PlayerRuntimeStartupShell)),
      ),
      const Locale('fr'),
    );
    expect(find.byType(PlayerLoadingSurface), findsNothing);
    final timeline = tester.widget<PlayerSplashTimeline>(
      find.byType(PlayerSplashTimeline),
    );
    expect(timeline.logo, logo);
    expect(timeline.wordmark, wordmark);
    expect(
      tester
          .widget<Image>(
            find.byKey(const ValueKey<String>('startup-splash-wordmark-image')),
          )
          .image,
      wordmark,
    );
    final splash = find.byKey(
      const ValueKey<String>('startup-splash-timeline'),
    );
    final background =
        tester
            .widgetList<ColoredBox>(
              find.descendant(of: splash, matching: find.byType(ColoredBox)),
            )
            .first;
    expect(background.color, const Color(0xFF02040A));

    launch.completeError(StateError('bootstrap test completed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
  });
}

final class _GateSplashAudioDriver implements FlameCinematicAudioDriver {
  final Completer<Object> _started = Completer<Object>();
  int playCalls = 0;
  double? lastVolume;

  void start() => _started.complete(Object());

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) {
    playCalls++;
    lastVolume = volume;
    return _started.future;
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {}
}

final class _PendingPreferencesRepository
    implements PlayerPreferencesRepositoryInterface {
  const _PendingPreferencesRepository(this.pending);

  final Future<HubPreferencesRead> pending;

  @override
  Future<HubPreferencesRead> load() => pending;

  @override
  Future<void> save(PlayerPreferences preferences) =>
      throw UnimplementedError();
}

final class _PendingLaunchResolver implements SessionLaunchRepositoryInterface {
  _PendingLaunchResolver(this.pending);

  final Future<InstalledGameLaunchContext> pending;
  int resolveCalls = 0;

  @override
  Future<InstalledGameLaunchContext> resolve(InstalledGame game) {
    resolveCalls++;
    return pending;
  }
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
