import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:avelune_player_host/features/library/domain/entities/game_library.dart';
import 'package:avelune_player_host/features/preferences/domain/entities/hub_preferences_read.dart';
import 'package:avelune_player_host/features/preferences/domain/repositories/player_preferences_repository_interface.dart';
import 'package:avelune_player_host/features/session/application/services/hub_runtime_startup_bootstrap.dart';
import 'package:avelune_player_host/features/session/domain/entities/installed_game_launch_context.dart';
import 'package:avelune_player_host/features/session/domain/repositories/control_profile_repository_interface.dart';
import 'package:avelune_player_host/features/session/domain/repositories/session_launch_repository_interface.dart';
import 'package:avelune_player_host/presentation/features/player/pages/hub_installed_game_player.dart';
import 'package:avelune_player_host/presentation/features/player/splash/avelune_splash.dart';
import 'package:avelune_player_host/presentation/features/player/splash/avelune_splash_palette.dart';

import '../../../support/runtime_player_hub_fixture.dart';

void main() {
  test(
    'closing cancels the splash frame gate without waiting for the launch',
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
      expect(resolver.resolveCalls, 1);
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

  test('launch resolution starts before the splash gate releases', () async {
    final root = await Directory.systemTemp.createTemp('avelune-early-launch-');
    addTearDown(() => root.delete(recursive: true));
    final context = await createRuntimePlayerLaunchContext(root);
    final gate = Completer<void>();
    final launch = Completer<InstalledGameLaunchContext>();
    final resolver = _PendingLaunchResolver(launch.future);
    final stages = <RuntimeStartupBootstrapStage>[];
    final bootstrap = HubRuntimeStartupBootstrap(
      supportRoot: root,
      saveRepositoryFactory: (_, _) => throw UnimplementedError(),
      preferencesRepository: _UnusedPreferencesRepository(),
      controlProfileRepository: _UnusedControlProfileRepository(),
      launchResolver: resolver,
      game: context.game,
      onHubRequested: () async {},
      mountGame: (_) async {},
      unmountGame: (_) async {},
      stopIntroPlayback: () async {},
      defaultProfileDisplayNameForLocale: (_) => 'Joueur',
      diagnosticLogFile: File('/dev/null'),
      startupWorkGate: gate.future,
    );

    final preparation = bootstrap.prepare(onStageCompleted: stages.add);
    final failed = expectLater(
      preparation,
      throwsA(isA<RuntimeStartupBootstrapException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(resolver.resolveCalls, 1);

    launch.complete(context);
    await Future<void>.delayed(Duration.zero);
    expect(stages, isEmpty);

    gate.complete();
    await failed;
    expect(stages.first, RuntimeStartupBootstrapStage.projectResolution);
  });

  test('a launch failure before the gate releases surfaces after it', () async {
    final gate = Completer<void>();
    final resolver = _FailingLaunchResolver(
      const InstalledGameLaunchException(
        InstalledGameLaunchErrorCode.installationUnhealthy,
        'The current installed version must be repaired before launch.',
      ),
    );
    final stages = <RuntimeStartupBootstrapStage>[];
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
      startupWorkGate: gate.future,
    );

    final uncaught = <Object>[];
    final settled = Completer<Object>();
    runZonedGuarded(() {
      final preparation = bootstrap.prepare(onStageCompleted: stages.add);
      preparation.then<void>(
        (_) => settled.complete(StateError('prepared')),
        onError: (Object error) => settled.complete(error),
      );
    }, (error, _) => uncaught.add(error));
    final resolveCallsBeforeGate = resolver.resolveCalls;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final settledBeforeGate = settled.isCompleted;
    gate.complete();
    final failure = await settled.future.timeout(const Duration(seconds: 10));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(resolveCallsBeforeGate, 1);
    expect(settledBeforeGate, isFalse);
    expect(uncaught, isEmpty);
    expect(stages, isEmpty);
    expect(failure, isA<RuntimeStartupBootstrapException>());
    expect(
      (failure as RuntimeStartupBootstrapException).failure.code,
      'hub.installationUnhealthy',
    );
  });

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

  for (final platform in [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    testWidgets(
      'keeps the Flutter splash moving through resizing on ${platform.name}',
      (tester) async {
        final mobile =
            platform == TargetPlatform.android || platform == TargetPlatform.iOS;
        final portrait = mobile ? const Size(390, 844) : const Size(440, 640);
        final landscape = mobile ? const Size(844, 390) : const Size(1040, 620);
        await tester.binding.setSurfaceSize(portrait);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final launch = Completer<InstalledGameLaunchContext>();
        final preferences = Completer<HubPreferencesRead>();
        final audio = _GateSplashAudioDriver();
        final bundle = _SplashAssets();
        final palette = platform == TargetPlatform.android
            ? AveluneSplashPalette.android
            : AveluneSplashPalette.ios;
        await tester.runAsync(() async {
          final stream = palette.wordmark.resolve(
            ImageConfiguration(bundle: bundle),
          );
          final image = Completer<void>();
          final listener = ImageStreamListener((info, _) {
            info.dispose();
            image.complete();
          }, onError: image.completeError);
          stream.addListener(listener);
          try {
            await image.future;
          } finally {
            stream.removeListener(listener);
          }
        });
        await tester.pumpWidget(
          DefaultAssetBundle(
            bundle: bundle,
            child: MaterialApp(
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
                  displayName: 'AVELUNE',
                  signature: 'RUNTIME',
                ),
                splashLogo: null,
                splashAudioDriver: audio,
                onHubRequested: () async {},
                diagnosticLogFile: File('/dev/null'),
              ),
            ),
          ),
        );
        final splash = find.byKey(const ValueKey('avelune-splash'));
        expect(splash, findsOneWidget);
        expect(tester.getSize(splash), portrait);
        final state = tester.state(splash);
        await tester.binding.setSurfaceSize(landscape);
        await tester.pump();
        expect(tester.getSize(splash), landscape);
        expect(tester.state(splash), same(state));
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
        expect(audio.lastAsset, 'avelune_lagune_jingle.wav');
        audio.start();
        await tester.pump();
        await tester.pump();
        expect(
          tester.widget<PlayerRuntimeStartupShell>(
            find.byType(PlayerRuntimeStartupShell),
          ).splashAnimationReady,
          isTrue,
        );
        await tester.pump(const Duration(milliseconds: 900));
        final cinematic = tester.widget<AveluneSplash>(splash);
        expect(cinematic.palette, palette);
        final progress = cinematic.progress;
        final beforeRotation = progress.value;
        expect(beforeRotation, inExclusiveRange(0, 1));
        await tester.binding.setSurfaceSize(portrait);
        await tester.pump();
        expect(tester.state(splash), same(state));
        expect(progress.value, closeTo(beforeRotation, .002));
        expect(audio.playCalls, 1);
        await tester.pump(const Duration(milliseconds: 3500));
        expect(progress.value, 1);

        final restingPortrait = await _splashPixels(tester, splash);
        await tester.pump(const Duration(milliseconds: 900));
        expect(await _splashPixels(tester, splash), isNot(restingPortrait));
        await tester.binding.setSurfaceSize(landscape);
        await tester.pump();
        expect(tester.state(splash), same(state));
        final restingLandscape = await _splashPixels(tester, splash);
        await tester.pump(const Duration(milliseconds: 900));
        expect(await _splashPixels(tester, splash), isNot(restingLandscape));
        expect(progress.value, 1);
        expect(audio.playCalls, 1);

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        final paused = await _splashPixels(tester, splash);
        await tester.pump(const Duration(seconds: 2));
        expect(await _splashPixels(tester, splash), paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 900));
        expect(await _splashPixels(tester, splash), isNot(paused));
        expect(audio.playCalls, 1);

        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await tester.pump();
        final reducedMotion = await _splashPixels(tester, splash);
        await tester.pump(const Duration(seconds: 2));
        expect(await _splashPixels(tester, splash), reducedMotion);

        launch.completeError(StateError('bootstrap test completed'));
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
      },
      variant: TargetPlatformVariant({platform}),
    );
  }

  testWidgets('mounts the runtime splash in the host locale on the first frame', (tester) async {
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
      const Locale('en'),
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
    final background = tester
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

Future<int> _splashPixels(WidgetTester tester, Finder splash) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(splash);
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: .5);
    try {
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      return Object.hashAll(bytes.buffer.asUint32List());
    } finally {
      image.dispose();
    }
  }))!;
}

final class _SplashAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      rootBundle.load(key.replaceFirst('packages/avelune_player_host/', ''));
}

final class _GateSplashAudioDriver implements FlameCinematicAudioDriver {
  final Completer<Object> _started = Completer<Object>();
  int playCalls = 0;
  String? lastAsset;
  double? lastVolume;

  void start() => _started.complete(Object());

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) {
    playCalls++;
    lastAsset = path;
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

  @override
  Future<void> update(PlayerPreferences Function(PlayerPreferences) change) =>
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

final class _FailingLaunchResolver implements SessionLaunchRepositoryInterface {
  _FailingLaunchResolver(this.error);

  final Object error;
  int resolveCalls = 0;

  @override
  Future<InstalledGameLaunchContext> resolve(InstalledGame game) {
    resolveCalls++;
    return Future<InstalledGameLaunchContext>.error(error);
  }
}

final class _UnusedPreferencesRepository
    implements PlayerPreferencesRepositoryInterface {
  @override
  Future<HubPreferencesRead> load() => throw UnimplementedError();

  @override
  Future<void> save(PlayerPreferences preferences) =>
      throw UnimplementedError();

  @override
  Future<void> update(PlayerPreferences Function(PlayerPreferences) change) =>
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
