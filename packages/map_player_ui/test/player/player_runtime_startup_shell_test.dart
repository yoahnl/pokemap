import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

RuntimeStartupSnapshot _startup(
  RuntimeStartupPhase phase, {
  int revision = 5,
  RuntimePlayerSnapshot? player,
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
