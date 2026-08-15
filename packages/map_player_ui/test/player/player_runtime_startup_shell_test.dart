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

    final surface = tester.widget<PlayerRuntimeSplashSurface>(
      find.byType(PlayerRuntimeSplashSurface),
    );
    expect(surface.progress, .35);
  });

  testWidgets('player input cannot shorten the runtime loading splash',
      (tester) async {
    final controller = PlayerRuntimeStartupShellController();
    final commands = <RuntimeStartupCommand>[];
    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: RuntimeStartupSnapshot(
            revision: 3,
            phase: RuntimeStartupPhase.splash,
            progress: 1,
            currentStage: RuntimeStartupPreparationStage.titleMenuAndMusic,
            isPreparationReady: true,
            isMinimumElapsed: false,
            isLifecycleActive: true,
          ),
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
          PlayerInputAction.confirm,
          source: PlayerInputSource.controller,
        ),
      ),
      isTrue,
    );
    expect(commands, isEmpty);
  });

  testWidgets('system Back is routed to the runtime startup policy',
      (tester) async {
    final commands = <RuntimeStartupCommand>[];
    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: RuntimeStartupSnapshot(
            revision: 5,
            phase: RuntimeStartupPhase.splash,
            progress: .4,
            currentStage: RuntimeStartupPreparationStage.initialMap,
            isPreparationReady: false,
            isMinimumElapsed: false,
            isLifecycleActive: true,
          ),
          titlePresentation: presentation,
          onStartupCommand: commands.add,
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(commands, hasLength(1));
    expect(commands.single.action, RuntimeStartupAction.requestBack);
    expect(commands.single.snapshotRevision, 5);
    expect(find.byType(PlayerRuntimeStartupShell), findsOneWidget);
  });

  testWidgets('holds the live timeline and plays the signed slow-load exit',
      (tester) async {
    RuntimeStartupSnapshot snapshot({
      required double progress,
      required bool ready,
      required bool minimumElapsed,
      int revision = 1,
    }) =>
        RuntimeStartupSnapshot(
          revision: revision,
          phase: RuntimeStartupPhase.splash,
          progress: progress,
          currentStage: RuntimeStartupPreparationStage.initialMap,
          isPreparationReady: ready,
          isMinimumElapsed: minimumElapsed,
          isLifecycleActive: true,
        );

    PlayerRuntimeStartupShell shell(RuntimeStartupSnapshot startup) =>
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: startup,
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );

    await tester.pumpWidget(
      _app(shell(snapshot(progress: .62, ready: false, minimumElapsed: false))),
    );
    await tester.pump(const Duration(milliseconds: 5904));

    var surface = tester.widget<PlayerRuntimeSplashSurface>(
      find.byType(PlayerRuntimeSplashSurface),
    );
    expect(surface.animationProgress, closeTo(kPlayerSplashHoldProgress, .001));
    final ambientAtHold = surface.ambientProgress!;

    await tester.pump(const Duration(milliseconds: 500));
    surface = tester.widget<PlayerRuntimeSplashSurface>(
      find.byType(PlayerRuntimeSplashSurface),
    );
    expect(surface.animationProgress, closeTo(kPlayerSplashHoldProgress, .001));
    expect(surface.ambientProgress, isNot(ambientAtHold));

    await tester.pumpWidget(
      _app(
        shell(
          snapshot(
            progress: 1,
            ready: true,
            minimumElapsed: true,
            revision: 2,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1296));

    surface = tester.widget<PlayerRuntimeSplashSurface>(
      find.byType(PlayerRuntimeSplashSurface),
    );
    expect(surface.animationProgress, 1);
    expect(surface.exitProgress, 0);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 140));
    surface = tester.widget<PlayerRuntimeSplashSurface>(
      find.byType(PlayerRuntimeSplashSurface),
    );
    expect(surface.exitProgress, closeTo(.5, .02));

    await tester.pump(const Duration(milliseconds: 140));
    surface = tester.widget<PlayerRuntimeSplashSurface>(
      find.byType(PlayerRuntimeSplashSurface),
    );
    expect(surface.exitProgress, 1);
  });

  testWidgets('pauses and resumes the splash timeline with lifecycle state',
      (tester) async {
    RuntimeStartupSnapshot snapshot({
      required RuntimeStartupPhase phase,
      required bool active,
      RuntimeStartupPhase? suspendedPhase,
      int revision = 1,
    }) =>
        RuntimeStartupSnapshot(
          revision: revision,
          phase: phase,
          progress: .4,
          currentStage: RuntimeStartupPreparationStage.initialMap,
          isPreparationReady: false,
          isMinimumElapsed: false,
          isLifecycleActive: active,
          suspendedPhase: suspendedPhase,
        );

    PlayerRuntimeStartupShell shell(RuntimeStartupSnapshot startup) =>
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: startup,
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );

    await tester.pumpWidget(
      _app(
        shell(
          snapshot(phase: RuntimeStartupPhase.splash, active: true),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final beforePause = tester
        .widget<PlayerRuntimeSplashSurface>(
          find.byType(PlayerRuntimeSplashSurface),
        )
        .animationProgress;

    await tester.pumpWidget(
      _app(
        shell(
          snapshot(
            phase: RuntimeStartupPhase.lifecyclePaused,
            active: false,
            suspendedPhase: RuntimeStartupPhase.splash,
            revision: 2,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    final whilePaused = tester
        .widget<PlayerRuntimeSplashSurface>(
          find.byType(PlayerRuntimeSplashSurface),
        )
        .animationProgress;
    expect(whilePaused, beforePause);

    await tester.pumpWidget(
      _app(
        shell(
          snapshot(
            phase: RuntimeStartupPhase.splash,
            active: true,
            revision: 3,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final afterResume = tester
        .widget<PlayerRuntimeSplashSurface>(
          find.byType(PlayerRuntimeSplashSurface),
        )
        .animationProgress;
    expect(afterResume, greaterThan(whilePaused));
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

  testWidgets('projects every runtime action in mobile and desktop layouts',
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
      expect(find.text('Nouveau jeu'), findsOneWidget);
      expect(find.text('Options'), findsOneWidget);
      expect(find.text('Retour au Hub'), findsOneWidget);
      expect(find.text('Charger'), findsOneWidget);
      expect(find.text('Crédits / À propos'), findsOneWidget);
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

  testWidgets('dispatches Return to Hub from the mobile runtime menu',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final commands = <RuntimePlayerCommand>[];

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.titleMenu,
            player: _titlePlayer(),
          ),
          titlePresentation: const RuntimePlayerTitlePresentation(
            author: 'Avelune',
            layoutVariant: PlayerTitleLayoutVariant.cinematic,
          ),
          onStartupCommand: (_) {},
          onPlayerCommand: commands.add,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('player-title-startup-menu')),
      findsOneWidget,
    );
    await tester.tap(find.text('Retour au Hub'));

    expect(commands, hasLength(1));
    expect(commands.single.action, RuntimePlayerAction.returnToHost);
  });

  testWidgets('controller follows authored title order and runtime identity', (
    tester,
  ) async {
    final controller = PlayerRuntimeStartupShellController();
    final commands = <RuntimePlayerCommand>[];

    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.titleMenu,
            player: _titlePlayer(),
          ),
          titlePresentation: const RuntimePlayerTitlePresentation(
            author: 'PokeMap',
            actions: <ProjectTitleActionProfile>[
              ProjectTitleActionProfile(id: ProjectTitleActionId.options),
              ProjectTitleActionProfile(
                id: ProjectTitleActionId.continueGame,
              ),
              ProjectTitleActionProfile(id: ProjectTitleActionId.returnToHub),
            ],
          ),
          onStartupCommand: (_) {},
          onPlayerCommand: commands.add,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    controller.handle(
      const PlayerInputCommand.press(
        PlayerInputAction.down,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pump();
    controller.handle(
      const PlayerInputCommand.press(
        PlayerInputAction.confirm,
        source: PlayerInputSource.controller,
      ),
    );

    expect(commands, hasLength(1));
    expect(commands.single.action, RuntimePlayerAction.returnToHost);
  });

  testWidgets('title prompt hides replay even when the runtime allows it',
      (tester) async {
    await tester.pumpWidget(
      _app(
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: RuntimeStartupSnapshot(
            revision: 8,
            phase: RuntimeStartupPhase.titlePrompt,
            progress: 1,
            currentStage: RuntimeStartupPreparationStage.titleMenuAndMusic,
            isPreparationReady: true,
            isMinimumElapsed: true,
            isLifecycleActive: true,
            introPhase: RuntimeIntroPhase.completed,
            introCanReplay: true,
          ),
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    expect(find.text('Rejouer l’intro'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('player-title-press-start-pill')),
      findsOneWidget,
    );
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

    await tester.tap(find.text('Nouveau jeu'));
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

  testWidgets('controller input skips the real intro through runtime policy', (
    tester,
  ) async {
    final controller = PlayerRuntimeStartupShellController();
    final commands = <RuntimeStartupCommand>[];
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
          introDriverFactory: (_) => _GatePlaybackDriver(
            Completer<void>()..complete(),
          ),
          onStartupCommand: commands.add,
          onPlayerCommand: (_) {},
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );
    await tester.pump();

    expect(
      controller.handle(
        const PlayerInputCommand.press(
          PlayerInputAction.confirm,
          source: PlayerInputSource.controller,
        ),
      ),
      isTrue,
    );
    expect(commands.single.action, RuntimeStartupAction.skipIntro);
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
        RuntimePlayerActionAvailability.enabled(
          RuntimePlayerAction.returnToHost,
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
  Future<void> setVolume(double volume) async {}

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
