import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const branding = RuntimeHostSplashBranding(
    displayName: 'PokeMap Runtime',
    signature: 'Une aventure prend vie',
  );
  const presentation = RuntimePlayerTitlePresentation(
    author: 'PokeMap',
    description: 'Une aventure ferroviaire.',
  );

  testWidgets('keeps host loading progress monotonic during bootstrap handoff',
      (tester) async {
    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: RuntimeStartupSnapshot(
            revision: 0,
            phase: RuntimeStartupPhase.splash,
            progress: .05,
            currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
            isPreparationReady: false,
            isMinimumElapsed: false,
            isLifecycleActive: true,
          ),
          splashLoadingProgress: .35,
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey<String>('startup-splash-progress')),
    );
    expect(indicator.value, .35);
  });

  testWidgets('Start and primary consume one title prompt revision',
      (tester) async {
    final controller = PlayerRuntimeStartupShellController();
    final commands = <RuntimeStartupCommand>[];

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: _startup(RuntimeStartupPhase.titlePrompt, revision: 12),
          titlePresentation: presentation,
          onStartupCommand: commands.add,
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    expect(
      controller.handle(
        const PlayerInputCommand.press(
          PlayerInputAction.menu,
          source: PlayerInputSource.controller,
        ),
      ),
      isTrue,
    );
    controller.handle(
      const PlayerInputCommand.press(
        PlayerInputAction.confirm,
        source: PlayerInputSource.controller,
      ),
    );

    expect(commands, hasLength(1));
    expect(commands.single.action, RuntimeStartupAction.pressStart);
    expect(commands.single.snapshotRevision, 12);
  });

  testWidgets('projects only three actions in mobile and desktop layouts',
      (tester) async {
    for (final size in <Size>[const Size(390, 844), const Size(1280, 720)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final player = _titlePlayer();

      await tester.pumpWidget(
        _app(
          PlayerRuntimeStartupShell(
            branding: branding,
            snapshot: _startup(
              RuntimeStartupPhase.titleMenu,
              player: player,
            ),
            titlePresentation: presentation,
            onStartupCommand: (_) {},
            onPlayerCommand: (_) {},
            onIntroPlaybackCompleted: (_) {},
            onIntroPlaybackFailed: (_, __) {},
          ),
        ),
      );

      expect(find.text('Continuer'), findsOneWidget);
      expect(find.text('Nouvelle partie'), findsOneWidget);
      expect(find.text('Options'), findsOneWidget);
      expect(find.text('Charger'), findsNothing);
      expect(find.text('Crédits & à propos'), findsNothing);
      expect(
        find.byKey(
          ValueKey<String>(
            size.width < 760
                ? 'player-title-startup-compact'
                : 'player-title-startup-expanded',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('preserves authored cinematic layout in the startup menu',
      (tester) async {
    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.titleMenu,
            player: _titlePlayer(),
          ),
          titlePresentation: const RuntimePlayerTitlePresentation(
            author: 'PokeMap',
            layoutVariant: PlayerTitleLayoutVariant.cinematic,
          ),
          onStartupCommand: (_) {},
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    final screen = tester.widget<PlayerTitleScreen>(
      find.byType(PlayerTitleScreen),
    );
    expect(
      screen.data.layoutVariant,
      PlayerTitleLayoutVariant.runtimeStartupCinematic,
    );
  });

  testWidgets('asks before replacing the single save with New Game',
      (tester) async {
    final commands = <RuntimePlayerCommand>[];

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.titleMenu,
            player: _titlePlayer(),
          ),
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: commands.add,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    await tester.tap(find.text('Nouvelle partie'));
    await tester.pumpAndSettle();
    expect(find.text('Remplacer la partie actuelle ?'), findsOneWidget);
    expect(commands, isEmpty);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();
    expect(commands.single.action, RuntimePlayerAction.newGame);
    expect(commands.single.snapshotRevision, 9);
  });

  testWidgets('Options returns to the exact title menu selection',
      (tester) async {
    final controller = PlayerRuntimeStartupShellController();
    final commands = <RuntimePlayerCommand>[];
    final menuSnapshot = _startup(
      RuntimeStartupPhase.titleMenu,
      player: _titlePlayer(),
    );

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: menuSnapshot,
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: commands.add,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );
    await tester.tap(find.text('Options'));
    expect(commands.last.action, RuntimePlayerAction.openOptions);

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.titleMenu,
            player: _optionsPlayer(),
          ),
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: commands.add,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );
    expect(find.byType(PlayerTitleOptionsSurface), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('runtime-player-title-options-back'),
      ),
    );
    expect(commands.last.action, RuntimePlayerAction.returnToTitle);

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: menuSnapshot,
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: commands.add,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );
    final title = tester.widget<PlayerTitleScreen>(
      find.byType(PlayerTitleScreen),
    );
    expect(title.focusController?.logicalSelectionId, 'title.openOptions');
  });

  testWidgets('responsive matrix and text scaling remain overflow-free',
      (tester) async {
    const sizes = <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(412, 915),
      Size(768, 1024),
      Size(1280, 720),
      Size(1920, 1080),
    ];
    for (final size in sizes) {
      for (final scale in <double>[1, 1.3, 2]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          _app(
            PlayerRuntimeStartupShell(
              branding: branding,
              snapshot: _startup(
                RuntimeStartupPhase.titleMenu,
                player: _titlePlayer(),
              ),
              titlePresentation: presentation,
              onStartupCommand: (_) {},
              onPlayerCommand: (_) {},
              onIntroPlaybackCompleted: (_) {},
              onIntroPlaybackFailed: (_, __) {},
            ),
            textScale: scale,
          ),
        );
        expect(tester.takeException(), isNull, reason: '$size at $scale');
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('lifecycle-paused shell consumes no startup input',
      (tester) async {
    final controller = PlayerRuntimeStartupShellController();
    final commands = <RuntimeStartupCommand>[];

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: _startupPaused(RuntimeStartupPhase.titlePrompt),
          titlePresentation: presentation,
          onStartupCommand: commands.add,
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    expect(
      controller.handle(
        const PlayerInputCommand.press(
          PlayerInputAction.menu,
          source: PlayerInputSource.controller,
        ),
      ),
      isFalse,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(commands, isEmpty);
  });

  testWidgets('host stop bridge awaits the active intro pause', (tester) async {
    final controller = PlayerRuntimeStartupShellController();
    final pauseGate = Completer<void>();
    final playback = _GatePlaybackDriver(pauseGate);

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.intro,
            introPhase: RuntimeIntroPhase.playing,
          ),
          titlePresentation: presentation,
          introSource: PlayerIntroVideoSource(
            videoUri: Uri.parse('file:///installed/intro.mp4'),
          ),
          introDriverFactory: (_) => playback,
          onStartupCommand: (_) {},
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );
    await tester.pump();

    var stopped = false;
    final stop = controller.stopIntroPlayback().then((_) => stopped = true);
    await tester.pump();

    expect(playback.pauseCalls, 1);
    expect(stopped, isFalse);
    final playCallsBeforeResume = playback.playCalls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(playback.playCalls, playCallsBeforeResume);

    pauseGate.complete();
    await stop;
    expect(stopped, isTrue);
  });

  testWidgets('uses distinct looping media for prompt and menu',
      (tester) async {
    final drivers = <_GatePlaybackDriver>[];
    _GatePlaybackDriver createDriver(PlayerIntroVideoSource _) {
      final gate = Completer<void>()..complete();
      final driver = _GatePlaybackDriver(gate);
      drivers.add(driver);
      return driver;
    }

    Widget shell(RuntimeStartupPhase phase) => PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(
            phase,
            player:
                phase == RuntimeStartupPhase.titleMenu ? _titlePlayer() : null,
          ),
          titlePresentation: presentation,
          titlePromptSource: PlayerIntroVideoSource(
            videoUri: Uri.parse('file:///installed/prompt.mp4'),
            looping: true,
          ),
          titleMenuSource: PlayerIntroVideoSource(
            videoUri: Uri.parse('file:///installed/menu.mp4'),
            looping: true,
          ),
          titleMotionDriverFactory: createDriver,
          onStartupCommand: (_) {},
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );

    await tester.pumpWidget(_app(shell(RuntimeStartupPhase.titlePrompt)));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('player-title-motion-video')),
      findsOneWidget,
    );
    expect(drivers, hasLength(1));
    expect(drivers.single.playCalls, 1);

    await tester.pumpWidget(_app(shell(RuntimeStartupPhase.titleMenu)));
    await tester.pump();
    expect(drivers, hasLength(2));
    expect(drivers.last.playCalls, 1);
    expect(drivers.first.disposeCalls, 1);
  });

  testWidgets('reports portrait and landscape viewport changes',
      (tester) async {
    final orientations = <RuntimePresentationOrientation>[];
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Widget shell() => PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(RuntimeStartupPhase.titlePrompt),
          titlePresentation: presentation,
          onPresentationOrientationChanged: orientations.add,
          onStartupCommand: (_) {},
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );

    await tester.pumpWidget(_app(shell()));
    expect(orientations, <RuntimePresentationOrientation>[
      RuntimePresentationOrientation.portrait,
    ]);

    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpWidget(_app(shell()));
    expect(orientations.last, RuntimePresentationOrientation.landscape);
  });
}

RuntimeStartupSnapshot _startup(
  RuntimeStartupPhase phase, {
  int revision = 5,
  RuntimePlayerSnapshot? player,
  RuntimeIntroPhase introPhase = RuntimeIntroPhase.completed,
}) =>
    RuntimeStartupSnapshot(
      revision: revision,
      phase: phase,
      progress: 1,
      currentStage: RuntimeStartupPreparationStage.titleMenuAndMusic,
      isPreparationReady: true,
      isMinimumElapsed: true,
      isLifecycleActive: true,
      playerSnapshot: player,
      introPhase: introPhase,
    );

RuntimeStartupSnapshot _startupPaused(RuntimeStartupPhase suspended) =>
    RuntimeStartupSnapshot(
      revision: 4,
      phase: RuntimeStartupPhase.lifecyclePaused,
      progress: 1,
      currentStage: RuntimeStartupPreparationStage.titleMenuAndMusic,
      isPreparationReady: true,
      isMinimumElapsed: true,
      isLifecycleActive: false,
      suspendedPhase: suspended,
    );

RuntimePlayerSnapshot _titlePlayer() => RuntimePlayerSnapshot(
      revision: 9,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Le Train de 17h42',
      hasDiscoveredSave: true,
      continueSave: PlayerSaveSummary(
        address: SaveSlotAddress(
          gameId: 'com.pokemap.train1742',
          profileId: 'default',
          slotId: 'slot-1',
        ),
        updatedAt: DateTime(2026, 8, 9),
        playTimeSeconds: 6386,
        status: SaveStatus.active,
        canContinue: true,
        locationLabel: 'Vallée d’Hisui',
      ),
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.newGame,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openOptions,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.showCredits,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.continueGame,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.load,
        ),
      ],
    );

RuntimePlayerSnapshot _optionsPlayer() => RuntimePlayerSnapshot(
      revision: 10,
      phase: RuntimePlayerPhase.title,
      gameTitle: 'Le Train de 17h42',
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.openOptions,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.updatePreferences,
        ),
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.returnToTitle,
        ),
      ],
    );

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
      builder: (context, builtChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: builtChild!,
      ),
    );

final class _GatePlaybackDriver implements PlayerIntroPlaybackDriver {
  _GatePlaybackDriver(this.pauseGate);

  final Completer<void> pauseGate;
  final ValueNotifier<PlayerIntroPlaybackSnapshot> _snapshots =
      ValueNotifier<PlayerIntroPlaybackSnapshot>(
    const PlayerIntroPlaybackSnapshot(),
  );
  int pauseCalls = 0;
  int playCalls = 0;
  int disposeCalls = 0;

  @override
  ValueListenable<PlayerIntroPlaybackSnapshot> get snapshots => _snapshots;

  @override
  Widget buildVideo() => const SizedBox();

  @override
  Future<void> initialize() async {
    _snapshots.value = const PlayerIntroPlaybackSnapshot(isInitialized: true);
  }

  @override
  Future<void> play() async {
    playCalls++;
  }

  @override
  Future<void> pause() {
    pauseCalls++;
    return pauseGate.future;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    _snapshots.dispose();
  }
}
