import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
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

  Widget controllerShell(
    RuntimeStartupSnapshot snapshot, {
    required Stream<NormalizedGamepadEvent> events,
    ValueChanged<RuntimeStartupCommand>? onStartup,
    ValueChanged<RuntimePlayerCommand>? onPlayer,
    PlayerControlProfile? profile,
    Widget Function(BuildContext, RuntimePlayerSnapshot?)? sessionBuilder,
  }) => _app(
    PlayerRuntimeStartupShell(
      branding: branding,
      snapshot: snapshot,
      titlePresentation: presentation,
      normalizedControllerInputEvents: events,
      controlProfile: profile,
      reducedMotion: true,
      sessionBuilder: sessionBuilder,
      onStartupCommand: onStartup ?? (_) {},
      onPlayerCommand: (command) {
        onPlayer?.call(command);
        return _acceptPlayerCommand(command);
      },
      onIntroPlaybackCompleted: (_) {},
      onIntroPlaybackFailed: (_, _) {},
    ),
  );

  testWidgets(
    'normalized held confirm does not cross the title prompt into a menu action',
    (tester) async {
      final events = StreamController<NormalizedGamepadEvent>.broadcast(
        sync: true,
      );
      addTearDown(events.close);
      final startup = <RuntimeStartupCommand>[];
      final commands = <RuntimePlayerCommand>[];
      Widget shell(RuntimeStartupSnapshot snapshot) => controllerShell(
        snapshot,
        events: events.stream,
        onStartup: startup.add,
        onPlayer: commands.add,
      );
      await _pumpMeasuredStartupWidget(
        tester,
        shell(_startup(RuntimeStartupPhase.titlePrompt)),
      );
      events.add(_startupPad(button: GamepadButton.a));
      await tester.pump();
      expect(startup.map((command) => command.action), [
        RuntimeStartupAction.pressStart,
      ]);
      await _pumpMeasuredStartupWidget(
        tester,
        shell(
          _startup(
            RuntimeStartupPhase.titleMenu,
            revision: 6,
            player: _titlePlayer(),
          ),
        ),
      );
      events.add(_startupPad(button: GamepadButton.a));
      await tester.pump();
      expect(commands, isEmpty);
      events.add(_startupPad(button: GamepadButton.a, value: 0));
      events.add(_startupPad(button: GamepadButton.dpadDown));
      events.add(_startupPad(button: GamepadButton.dpadDown, value: 0));
      await tester.pump();
      events.add(_startupPad(button: GamepadButton.a));
      await tester.pump();
      expect(commands.map((command) => command.action), [
        RuntimePlayerAction.newGame,
      ]);
      final title = tester.widget<PlayerTitleScreen>(
        find.byType(PlayerTitleScreen),
      );
      expect(
        title.focusController!.activeInputSource,
        PlayerInputSource.controller,
      );
    },
  );

  for (final normalizedFirst in [true, false]) {
    testWidgets(
      'title coalesces both gamepad channels normalizedFirst=$normalizedFirst',
      (tester) async {
        final events = StreamController<NormalizedGamepadEvent>.broadcast(
          sync: true,
        );
        addTearDown(events.close);
        final commands = <RuntimePlayerCommand>[];
        await _pumpMeasuredStartupWidget(
          tester,
          controllerShell(
            _startup(RuntimeStartupPhase.titleMenu, player: _titlePlayer()),
            events: events.stream,
            onPlayer: commands.add,
          ),
        );
        if (normalizedFirst) events.add(_startupPad(button: GamepadButton.a));
        await _startupGamepadPress(
          tester,
          LogicalKeyboardKey.gameButtonA,
          PhysicalKeyboardKey.gameButtonA,
          whileHeld: () async {
            if (!normalizedFirst) {
              events.add(_startupPad(button: GamepadButton.a));
            }
            await tester.pump();
            expect(commands.length, 1);
          },
        );
        events.add(_startupPad(button: GamepadButton.a, value: 0));
        await tester.pump();
        expect(commands.length, 1);
        events.add(_startupPad(button: GamepadButton.a));
        await tester.pump();
        expect(commands.length, 2);
      },
    );
  }

  testWidgets('startup gamepad honors remapping pause and session handoff', (
    tester,
  ) async {
    final events = StreamController<NormalizedGamepadEvent>.broadcast(
      sync: true,
    );
    addTearDown(events.close);
    final commands = <RuntimeStartupCommand>[];
    final profile = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.gamepad,
          control: RuntimeInputControl.primary,
          inputId: 'x',
        )
        .profile;
    Widget shell(RuntimeStartupSnapshot snapshot) => controllerShell(
      snapshot,
      events: events.stream,
      onStartup: commands.add,
      profile: profile,
      sessionBuilder: (_, _) => const Text('Session en cours'),
    );
    await _pumpMeasuredStartupWidget(
      tester,
      shell(_startup(RuntimeStartupPhase.titlePrompt)),
    );
    events.add(_startupPad(button: GamepadButton.a));
    events.add(_startupPad(button: GamepadButton.a, value: 0));
    await tester.pump();
    expect(commands, isEmpty);
    await _pumpMeasuredStartupWidget(
      tester,
      shell(_startupPaused(RuntimeStartupPhase.titlePrompt)),
    );
    events.add(_startupPad(button: GamepadButton.x));
    await tester.pump();
    expect(commands, isEmpty);
    await _pumpMeasuredStartupWidget(
      tester,
      shell(_startup(RuntimeStartupPhase.titlePrompt, revision: 7)),
    );
    events.add(_startupPad(button: GamepadButton.x));
    await tester.pump();
    expect(commands, isEmpty);
    events.add(_startupPad(button: GamepadButton.x, value: 0));
    events.add(_startupPad(button: GamepadButton.x));
    await tester.pump();
    expect(commands.length, 1);
    await _pumpMeasuredStartupWidget(
      tester,
      shell(_startup(RuntimeStartupPhase.completed, revision: 8)),
    );
    expect(events.hasListener, isFalse);
    events.add(_startupPad(button: GamepadButton.x, value: 0));
    events.add(_startupPad(button: GamepadButton.x));
    await tester.pump();
    expect(commands.length, 1);
    expect(find.text('Session en cours'), findsOneWidget);
  });

  testWidgets('returning to the title rearms controls released during gameplay', (tester) async {
    final events = StreamController<NormalizedGamepadEvent>.broadcast(sync: true);
    addTearDown(events.close);
    final commands = <RuntimePlayerCommand>[];
    Widget shell(RuntimeStartupSnapshot snapshot) => controllerShell(snapshot,
      events: events.stream, onPlayer: commands.add,
      sessionBuilder: (_, _) => const Text('Session en cours'));
    await _pumpMeasuredStartupWidget(tester, shell(_startup(RuntimeStartupPhase.titleMenu, player: _titlePlayer())));
    events.add(_startupPad(button: GamepadButton.a));
    await tester.pump();
    expect(commands.length, 1);
    await _pumpMeasuredStartupWidget(tester, shell(_startup(RuntimeStartupPhase.completed, revision: 7)));
    events.add(_startupPad(button: GamepadButton.a, value: 0));
    await tester.pump();
    await _pumpMeasuredStartupWidget(tester, shell(_startup(RuntimeStartupPhase.titleMenu, revision: 8, player: _titlePlayer())));
    events.add(_startupPad(button: GamepadButton.a));
    await tester.pump();
    expect(commands.length, 2);
  });

  testWidgets('title options accept controller shoulder tabs and back', (
    tester,
  ) async {
    final events = StreamController<NormalizedGamepadEvent>.broadcast(
      sync: true,
    );
    addTearDown(events.close);
    final commands = <RuntimePlayerCommand>[];
    await _pumpMeasuredStartupWidget(
      tester,
      controllerShell(
        _startup(
          RuntimeStartupPhase.titleMenu,
          player: _optionsPlayer().next(
            pauseSection: RuntimePlayerPauseSection.options,
            preferences: const PlayerPreferencesSnapshot(
              locale: 'fr',
              accessibility: GameSessionAccessibilityOptions(),
            ),
          ),
        ),
        events: events.stream,
        onPlayer: commands.add,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('options-settings-general-bindings')),
      findsOneWidget,
    );
    final footer = find.byKey(
      const ValueKey('runtime-player-title-options-back'),
    );
    Focus.of(
      tester.element(
        find.descendant(of: footer, matching: find.byType(Text)).first,
      ),
    ).requestFocus();
    await tester.pump();
    events.add(_startupPad(button: GamepadButton.rightBumper));
    events.add(_startupPad(button: GamepadButton.rightBumper, value: 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('options-settings-display-bindings')),
      findsOneWidget,
    );
    events.add(_startupPad(button: GamepadButton.leftBumper));
    events.add(_startupPad(button: GamepadButton.leftBumper, value: 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('options-settings-general-bindings')),
      findsOneWidget,
    );
    events.add(_startupPad(button: GamepadButton.b));
    events.add(_startupPad(button: GamepadButton.b, value: 0));
    await tester.pumpAndSettle();
    expect(commands.map((command) => command.action), [
      RuntimePlayerAction.returnToTitle,
    ]);
  });

  testWidgets('physical gamepad starts the title and selects a menu action', (
    tester,
  ) async {
    final startupCommands = <RuntimeStartupCommand>[];
    final playerCommands = <RuntimePlayerCommand>[];
    Widget shell(RuntimeStartupSnapshot snapshot) => _app(
      PlayerRuntimeStartupShell(
        branding: branding,
        snapshot: snapshot,
        titlePresentation: presentation,
        onStartupCommand: startupCommands.add,
        onPlayerCommand: (command) {
          playerCommands.add(command);
          return _acceptPlayerCommand(command);
        },
        onIntroPlaybackCompleted: (_) {},
        onIntroPlaybackFailed: (_, _) {},
      ),
    );
    await _pumpMeasuredStartupWidget(
      tester,
      shell(_startup(RuntimeStartupPhase.titlePrompt)),
    );
    await _startupGamepadPress(
      tester,
      LogicalKeyboardKey.gameButtonA,
      PhysicalKeyboardKey.gameButtonA,
    );
    await tester.pump();
    expect(startupCommands.map((command) => command.action), [
      RuntimeStartupAction.pressStart,
    ]);
    await _pumpMeasuredStartupWidget(
      tester,
      shell(
        _startup(
          RuntimeStartupPhase.titleMenu,
          revision: 6,
          player: _titlePlayer(),
        ),
      ),
    );
    await _startupGamepadPress(
      tester,
      LogicalKeyboardKey.gameButtonA,
      PhysicalKeyboardKey.gameButtonA,
    );
    await tester.pump();
    expect(playerCommands.map((command) => command.action), [
      RuntimePlayerAction.continueGame,
    ]);
  });
  testWidgets(
    'delegated title keeps one input owner and restores local actions after detach',
    (tester) async {
      final controller = PlayerRuntimeStartupShellController();
      final commands = <RuntimePlayerCommand>[];
      final startupCommands = <RuntimeStartupCommand>[];
      final inputs = <RuntimeInputEvent>[];
      Widget shell(bool attached) => _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.titleMenu,
            player: _titlePlayer(),
          ),
          titlePresentation: presentation,
          companionTitleAttached: attached,
          onCompanionInput: (input) {
            inputs.add(input);
            return true;
          },
          onStartupCommand: startupCommands.add,
          onPlayerCommand: (command) {
            commands.add(command);
            return _acceptPlayerCommand(command);
          },
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      );
      await _pumpMeasuredStartupWidget(tester, shell(true));
      expect(
        tester
            .widget<PlayerTitleScreen>(find.byType(PlayerTitleScreen))
            .sceneOnly,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('title.newGame')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('player-title-continue-save')),
        findsNothing,
      );
      expect(find.text('Le Train de 17h42'), findsOneWidget);
      expect(find.text('Une aventure ferroviaire.'), findsOneWidget);
      expect(
        controller.handle(
          const PlayerInputCommand.press(
            PlayerInputAction.confirm,
            source: PlayerInputSource.controller,
          ),
        ),
        isTrue,
      );
      expect(
        controller.handle(
          const PlayerInputCommand.release(
            PlayerInputAction.confirm,
            source: PlayerInputSource.controller,
          ),
        ),
        isTrue,
      );
      expect(inputs.map((event) => event.control), [
        RuntimeInputControl.primary,
        RuntimeInputControl.primary,
      ]);
      expect(inputs.map((event) => event.isPress), [true, false]);
      inputs.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        inputs.where(
          (event) =>
              event.isPress && event.control == RuntimeInputControl.primary,
        ),
        hasLength(1),
      );
      expect(commands, isEmpty);
      expect(startupCommands, isEmpty);
      await _pumpMeasuredStartupWidget(tester, shell(false));
      expect(
        tester
            .widget<PlayerTitleScreen>(find.byType(PlayerTitleScreen))
            .sceneOnly,
        isFalse,
      );
      expect(
        find.byKey(const ValueKey('title.newGame')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('player-title-continue-save')),
        findsOneWidget,
      );
      inputs.clear();
      await tester.tap(
        find.byKey(const ValueKey('title.newGame')),
      );
      await tester.pump();
      expect(commands, hasLength(1));
      expect(commands.single.action, RuntimePlayerAction.newGame);
      expect(commands.single.snapshotRevision, 9);
      expect(inputs, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final attached in [false, true]) {
    testWidgets(
      'title transition blocks new commands until acknowledged, delegated=$attached',
      (tester) async {
        final controller = PlayerRuntimeStartupShellController();
        final commands = <RuntimePlayerCommand>[];
        final startupCommands = <RuntimeStartupCommand>[];
        final inputs = <RuntimeInputEvent>[];
        Widget shell(bool transitioning) => _app(
          PlayerRuntimeStartupShell(
            controller: controller,
            branding: branding,
            snapshot: _startup(
              RuntimeStartupPhase.titleMenu,
              player: _titlePlayer(),
            ).next(isTransitioning: transitioning),
            titlePresentation: presentation,
            companionTitleAttached: attached,
            onCompanionInput: (input) {
              inputs.add(input);
              return true;
            },
            onStartupCommand: startupCommands.add,
            onPlayerCommand: (command) {
              commands.add(command);
              return _acceptPlayerCommand(command);
            },
            onIntroPlaybackCompleted: (_) {},
            onIntroPlaybackFailed: (_, _) {},
          ),
        );
        await _pumpMeasuredStartupWidget(tester, shell(true));
        if (!attached) {
          await tester.tap(
            find.byKey(const ValueKey('title.newGame')),
            warnIfMissed: false,
          );
          tester
              .widget<PlayerTitleScreen>(find.byType(PlayerTitleScreen))
              .onSelected(PlayerTitleMenuAction.newGame);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(
          controller.handle(
            const PlayerInputCommand.press(
              PlayerInputAction.confirm,
              source: PlayerInputSource.controller,
            ),
          ),
          isTrue,
        );
        controller.handle(
          const PlayerInputCommand.release(
            PlayerInputAction.confirm,
            source: PlayerInputSource.controller,
          ),
        );
        await tester.binding.handlePopRoute();
        await tester.pump();
        expect(commands, isEmpty);
        expect(startupCommands, isEmpty);
        expect(inputs.where((event) => event.isPress), isEmpty);
        if (attached) {
          expect(inputs, isNotEmpty);
          expect(inputs.every((event) => !event.isPress), isTrue);
        }

        await _pumpMeasuredStartupWidget(tester, shell(false));
        inputs.clear();
        if (attached) {
          controller.handle(
            const PlayerInputCommand.press(
              PlayerInputAction.confirm,
              source: PlayerInputSource.controller,
            ),
          );
          controller.handle(
            const PlayerInputCommand.release(
              PlayerInputAction.confirm,
              source: PlayerInputSource.controller,
            ),
          );
          expect(inputs.map((event) => event.isPress), [true, false]);
          expect(commands, isEmpty);
        } else {
          await tester.tap(find.byKey(const ValueKey('title.newGame')));
          await tester.pump();
          expect(commands, hasLength(1));
          expect(commands.single.action, RuntimePlayerAction.newGame);
          expect(commands.single.snapshotRevision, 9);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('splash motion waits for its audio start signal', (tester) async {
    Widget shell(bool ready) => _app(PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(RuntimeStartupPhase.splash),
          titlePresentation: presentation,
          splashAnimationReady: ready,
          onStartupCommand: (_) {},
          onPlayerCommand: _acceptPlayerCommand,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ));

    await _pumpMeasuredStartupWidget(tester, shell(false));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
        tester
            .widget<PlayerSplashTimeline>(find.byType(PlayerSplashTimeline))
            .progress,
        0);

    await _pumpMeasuredStartupWidget(tester, shell(true));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
        tester
            .widget<PlayerSplashTimeline>(find.byType(PlayerSplashTimeline))
            .progress,
        greaterThan(0));
  });

  testWidgets('startup title options apply player locale and language changes',
      (tester) async {
    var player = _optionsPlayer().next(
      pauseSection: RuntimePlayerPauseSection.options,
      preferences: const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(),
      ),
    );
    await _pumpMeasuredStartupWidget(tester, _app(
      StatefulBuilder(builder: (context, setState) {
        return PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(RuntimeStartupPhase.titleMenu, player: player),
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: (command) {
            if (command.action == RuntimePlayerAction.updatePreferences) {
              setState(() {
                player = player.next(
                  preferences: command.payload! as PlayerPreferencesSnapshot,
                );
              });
            }
            return _acceptPlayerCommand(command);
          },
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );
      }),
      locale: const Locale('en'),
    ));
    await tester.pumpAndSettle();
    final options = find.byType(RuntimePlayerOptions);
    expect(Localizations.localeOf(tester.element(options)).languageCode, 'fr');
    expect(find.text('Général'), findsWidgets);
    final language = find.byKey(const ValueKey('options-category-language'));
    final picker = find.byKey(const ValueKey('options-category-picker'));
    if (language.evaluate().isEmpty && picker.evaluate().isNotEmpty) {
      await tester.tap(picker);
      await tester.pumpAndSettle();
    }
    await _revealPagedTarget(tester, language, scope: find.byKey(const ValueKey('options-categories')));
    await tester.tap(language);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-locale-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-choice-en')));
    await tester.pumpAndSettle();
    expect(player.preferences!.locale, 'en');
    expect(Localizations.localeOf(tester.element(options)).languageCode, 'en');
    expect(find.text('Language'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('options-locale-choice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('options-choice-fr')));
    await tester.pumpAndSettle();
    expect(player.preferences!.locale, 'fr');
    expect(Localizations.localeOf(tester.element(options)).languageCode, 'fr');
    expect(find.text('Langue'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'startup title options apply player accessibility and menu effects',
      (tester) async {
    const preferences = PlayerPreferencesSnapshot(
      locale: 'fr',
      accessibility: GameSessionAccessibilityOptions(
        textScale: 1.4,
        reducedMotion: true,
      ),
      highContrast: true,
      menuEffects: RuntimePlayerMenuEffects.opaque,
    );
    Future<void> pump(PlayerPreferencesSnapshot value) async {
      await _pumpMeasuredStartupWidget(tester, _app(
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.titleMenu,
            player: _optionsPlayer().next(
              pauseSection: RuntimePlayerPauseSection.options,
              preferences: value,
            ),
          ),
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: _acceptPlayerCommand,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
        textScale: 1.2,
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
    }

    await pump(preferences);
    var context = tester.element(find.byType(RuntimePlayerOptions));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(16.8, .001));
    expect(MediaQuery.disableAnimationsOf(context), isTrue);
    expect(Theme.of(context).extension<PokeMapPlayerColors>()!.highContrast,
        isTrue);
    expect(PlayerMenuEffectsScope.of(context), RuntimePlayerMenuEffects.opaque);
    await pump(const PlayerPreferencesSnapshot(
      locale: 'en',
      accessibility: GameSessionAccessibilityOptions(),
    ));
    context = tester.element(find.byType(RuntimePlayerOptions));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(12, .001));
    expect(MediaQuery.disableAnimationsOf(context), isFalse);
    expect(Theme.of(context).extension<PokeMapPlayerColors>()!.highContrast,
        isFalse);
    expect(PlayerMenuEffectsScope.of(context), RuntimePlayerMenuEffects.full);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'startup title options await rejected persistence and restore values',
      (tester) async {
    final completion = Completer<RuntimePlayerCommandResult>();
    addTearDown(() {
      if (!completion.isCompleted) {
        completion.complete(const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.failed,
          safeMessage: 'Les préférences n’ont pas pu être enregistrées.',
        ));
      }
    });
    final commands = <RuntimePlayerCommand>[];
    final player = _optionsPlayer().next(
      pauseSection: RuntimePlayerPauseSection.options,
      preferences: const PlayerPreferencesSnapshot(
        locale: 'fr',
        accessibility: GameSessionAccessibilityOptions(),
      ),
    );
    final confirmed = player.preferences;
    Future<RuntimePlayerCommandResult> dispatch(RuntimePlayerCommand command) {
      commands.add(command);
      return completion.future;
    }

    await _pumpMeasuredStartupWidget(tester, _app(PlayerRuntimeStartupShell(
      branding: branding,
      snapshot: _startup(RuntimeStartupPhase.titleMenu, player: player),
      titlePresentation: presentation,
      onStartupCommand: (_) {},
      onPlayerCommand: dispatch,
      onIntroPlaybackCompleted: (_) {},
      onIntroPlaybackFailed: (_, __) {},
    )));
    await tester.pumpAndSettle();
    final audio = find.byKey(const ValueKey('options-category-audio'));
    final picker = find.byKey(const ValueKey('options-category-picker'));
    if (audio.evaluate().isEmpty && picker.evaluate().isNotEmpty) {
      await tester.tap(picker);
      await tester.pumpAndSettle();
    }
    await _revealPagedTarget(tester, audio, scope: find.byKey(const ValueKey('options-categories')));
    await tester.tap(audio);
    await tester.pumpAndSettle();
    final sliderFinder = find.byKey(const ValueKey('options-master-slider'));
    var slider = tester.widget<Slider>(sliderFinder);
    slider.onChanged!(.2);
    slider.onChangeEnd!(.2);
    await tester.pump();
    expect(commands, hasLength(1));
    expect(commands.single.action, RuntimePlayerAction.updatePreferences);
    expect(find.byKey(const ValueKey('options-saving')), findsOneWidget);
    await tester.pump();
    await tester.pump();
    expect(tester.widget<Slider>(sliderFinder).onChanged, isNull);
    expect(player.preferences, same(confirmed));
    completion.complete(const RuntimePlayerCommandResult(
      status: RuntimePlayerCommandStatus.failed,
      safeMessage: 'Les préférences n’ont pas pu être enregistrées.',
    ));
    await tester.pumpAndSettle();
    slider = tester.widget<Slider>(sliderFinder);
    expect(slider.value, 1);
    expect(slider.onChanged, isNotNull);
    expect(player.preferences, same(confirmed));
    expect(find.byKey(const ValueKey('options-saving')), findsNothing);
    expect(find.byKey(const ValueKey('options-save-error')), findsOneWidget);
    expect(find.text('Les préférences n’ont pas pu être enregistrées.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps host loading progress monotonic during bootstrap handoff',
      (tester) async {
    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: _acceptPlayerCommand,
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
    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: _acceptPlayerCommand,
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
    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: _acceptPlayerCommand,
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
          onPlayerCommand: _acceptPlayerCommand,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );

    await _pumpMeasuredStartupWidget(tester,
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
    expect(surface.ambientProgress, ambientAtHold);

    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: _acceptPlayerCommand,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );

    await _pumpMeasuredStartupWidget(tester,
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

    await _pumpMeasuredStartupWidget(tester,
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

    await _pumpMeasuredStartupWidget(tester,
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

    await _pumpMeasuredStartupWidget(tester,
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: _startup(RuntimeStartupPhase.titlePrompt, revision: 12),
          titlePresentation: presentation,
          onStartupCommand: commands.add,
          onPlayerCommand: _acceptPlayerCommand,
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

      await _pumpMeasuredStartupWidget(tester,
        _app(
          PlayerRuntimeStartupShell(
            branding: branding,
            snapshot: _startup(
              RuntimeStartupPhase.titleMenu,
              player: player,
            ),
            titlePresentation: presentation,
            onStartupCommand: (_) {},
            onPlayerCommand: _acceptPlayerCommand,
            onIntroPlaybackCompleted: (_) {},
            onIntroPlaybackFailed: (_, __) {},
          ),
        ),
      );

      expect(find.text('Continuer', skipOffstage: false), findsOneWidget);
      expect(find.text('Nouveau jeu', skipOffstage: false), findsOneWidget);
      expect(find.text('Options', skipOffstage: false), findsOneWidget);
      expect(find.text('Retour au Hub', skipOffstage: false), findsOneWidget);
      expect(find.text('Charger', skipOffstage: false), findsOneWidget);
      expect(find.text('Crédits / À propos', skipOffstage: false), findsOneWidget);
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

    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: (command) {
            commands.add(command);
            return _acceptPlayerCommand(command);
          },
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('player-title-startup-menu')),
      findsOneWidget,
    );
    await _revealPagedTarget(tester, find.text('Retour au Hub'));
    await tester.tap(find.text('Retour au Hub'));

    expect(commands, hasLength(1));
    expect(commands.single.action, RuntimePlayerAction.returnToHost);
  });

  testWidgets('controller follows authored title order and runtime identity', (
    tester,
  ) async {
    final controller = PlayerRuntimeStartupShellController();
    final commands = <RuntimePlayerCommand>[];

    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: (command) {
            commands.add(command);
            return _acceptPlayerCommand(command);
          },
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
    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: _acceptPlayerCommand,
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

  testWidgets('title prompt uses authored title copy without host branding',
      (tester) async {
    await _pumpMeasuredStartupWidget(tester, _app(PlayerRuntimeStartupShell(
      branding: branding,
      snapshot: _startup(RuntimeStartupPhase.titlePrompt, player: _titlePlayer()),
      titlePresentation: const RuntimePlayerTitlePresentation(
        title: 'Le voyage', author: 'Équipe du voyage',
        description: 'Appuyez pour voyager',
      ),
      onStartupCommand: (_) {}, onPlayerCommand: _acceptPlayerCommand,
      onIntroPlaybackCompleted: (_) {}, onIntroPlaybackFailed: (_, _) {},
    )));
    final surface = tester.widget<PlayerTitlePromptSurface>(
      find.byType(PlayerTitlePromptSurface),
    );
    expect(surface.gameTitle, 'Le voyage');
    expect(find.text('ÉQUIPE DU VOYAGE'), findsOneWidget);
    expect(find.text('Appuyez pour voyager'), findsOneWidget);
    expect(find.text(branding.signature.toUpperCase()), findsNothing);
    expect(find.text(branding.displayName.toUpperCase()), findsNothing);
  });

  testWidgets('preserves authored cinematic layout in the startup menu',
      (tester) async {
    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: _acceptPlayerCommand,
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

  testWidgets('delegates New Game overwrite authority to the Player',
      (tester) async {
    final commands = <RuntimePlayerCommand>[];

    await _pumpMeasuredStartupWidget(tester,
      _app(
        PlayerRuntimeStartupShell(
          branding: branding,
          snapshot: _startup(
            RuntimeStartupPhase.titleMenu,
            player: _titlePlayer(),
          ),
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: (command) {
            commands.add(command);
            return _acceptPlayerCommand(command);
          },
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );

    await _revealPagedTarget(tester, find.text('Nouveau jeu'));
    await tester.tap(find.text('Nouveau jeu'));
    await tester.pumpAndSettle();
    expect(find.text('Remplacer la partie actuelle ?'), findsNothing);
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

    await _pumpMeasuredStartupWidget(tester,
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: menuSnapshot,
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: (command) {
            commands.add(command);
            return _acceptPlayerCommand(command);
          },
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        ),
      ),
    );
    await _revealPagedTarget(tester, find.text('Options'));
    await tester.tap(find.text('Options'));
    expect(commands.last.action, RuntimePlayerAction.openOptions);

    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: (command) {
            commands.add(command);
            return _acceptPlayerCommand(command);
          },
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

    await _pumpMeasuredStartupWidget(tester,
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: menuSnapshot,
          titlePresentation: presentation,
          onStartupCommand: (_) {},
          onPlayerCommand: (command) {
            commands.add(command);
            return _acceptPlayerCommand(command);
          },
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
        await _pumpMeasuredStartupWidget(tester,
          _app(
            PlayerRuntimeStartupShell(
              branding: branding,
              snapshot: _startup(
                RuntimeStartupPhase.titleMenu,
                player: _titlePlayer(),
              ),
              titlePresentation: presentation,
              onStartupCommand: (_) {},
              onPlayerCommand: _acceptPlayerCommand,
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

    await _pumpMeasuredStartupWidget(tester,
      _app(
        PlayerRuntimeStartupShell(
          controller: controller,
          branding: branding,
          snapshot: _startupPaused(RuntimeStartupPhase.titlePrompt),
          titlePresentation: presentation,
          onStartupCommand: commands.add,
          onPlayerCommand: _acceptPlayerCommand,
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

  testWidgets('intro takes focus from a previously focused host close button', (
    tester,
  ) async {
    var closed = 0;
    final commands = <RuntimeStartupCommand>[];
    final pauseGate = Completer<void>()..complete();
    final driver = _GatePlaybackDriver(pauseGate);
    Widget host({required bool intro}) => _app(
      Scaffold(
        body: Column(
          children: [
            OutlinedButton(
              autofocus: true,
              onPressed: () => closed++,
              child: const Text('Retour à Studio'),
            ),
            Expanded(
              child: intro
                  ? PlayerRuntimeStartupShell(
                      branding: branding,
                      snapshot: _startup(
                        RuntimeStartupPhase.intro,
                        introPhase: RuntimeIntroPhase.playing,
                      ),
                      titlePresentation: presentation,
                      introSource: PlayerIntroVideoSource(
                        videoUri: Uri.parse('file:///installed/intro.mp4'),
                      ),
                      introDriverFactory: (_) => driver,
                      onStartupCommand: commands.add,
                      onPlayerCommand: _acceptPlayerCommand,
                      onIntroPlaybackCompleted: (_) {},
                      onIntroPlaybackFailed: (_, _) {},
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
    await _pumpMeasuredStartupWidget(tester, host(intro: false));
    await tester.pump();
    final before = FocusManager.instance.primaryFocus?.context;
    expect(before?.findAncestorWidgetOfExactType<OutlinedButton>(), isNotNull);
    await _pumpMeasuredStartupWidget(tester, host(intro: true));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      closed,
      0,
      reason: 'the new intro owns Enter after the asynchronous startup mounts',
    );
    expect(commands, hasLength(1));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(closed, 0);
    expect(commands, hasLength(1));
    expect(commands.single.action, RuntimeStartupAction.skipIntro);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final after = FocusManager.instance.primaryFocus?.context;
    expect(after?.findAncestorWidgetOfExactType<OutlinedButton>(), isNotNull,
      reason: 'deliberate traversal must still reach the host close control');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(closed, 1);
  });

  testWidgets('host stop bridge awaits the active intro pause', (tester) async {
    final controller = PlayerRuntimeStartupShellController();
    final pauseGate = Completer<void>();
    final playback = _GatePlaybackDriver(pauseGate);

    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: _acceptPlayerCommand,
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
    await _pumpMeasuredStartupWidget(tester,
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
          onPlayerCommand: _acceptPlayerCommand,
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
          onPlayerCommand: _acceptPlayerCommand,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );

    await _pumpMeasuredStartupWidget(tester, _app(shell(RuntimeStartupPhase.titlePrompt)));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('player-title-motion-video')),
      findsOneWidget,
    );
    expect(drivers, hasLength(1));
    expect(drivers.single.playCalls, 1);

    await _pumpMeasuredStartupWidget(tester, _app(shell(RuntimeStartupPhase.titleMenu)));
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
          onPlayerCommand: _acceptPlayerCommand,
          onIntroPlaybackCompleted: (_) {},
          onIntroPlaybackFailed: (_, __) {},
        );

    await _pumpMeasuredStartupWidget(tester, _app(shell()));
    expect(orientations, <RuntimePresentationOrientation>[
      RuntimePresentationOrientation.portrait,
    ]);

    tester.view.physicalSize = const Size(844, 390);
    await _pumpMeasuredStartupWidget(tester, _app(shell()));
    expect(orientations.last, RuntimePresentationOrientation.landscape);
  });
}

RuntimePlayerCommandResult _acceptPlayerCommand(RuntimePlayerCommand _) =>
    const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.accepted);

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

Widget _app(Widget child,
        {double textScale = 1, Locale locale = const Locale('fr')}) =>
    MaterialApp(
      locale: locale,
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

Future<void> _pumpMeasuredStartupWidget(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump();
}

Future<void> _revealPagedTarget(WidgetTester tester, Finder target, {Finder? scope}) async {
  await tester.pump();
  await tester.pump();
  Finder buttons(String key) => scope == null
      ? find.byKey(ValueKey(key)).hitTestable()
      : find.descendant(of: scope, matching: find.byKey(ValueKey(key))).hitTestable();
  for (final direction in ['player-page-previous', 'player-page-next']) {
    for (var step = 0; step < 40 && target.evaluate().isEmpty; step++) {
      final candidates = buttons(direction);
      final enabled = [for (final element in candidates.evaluate())
        if ((element.widget as IconButton).onPressed != null) element];
      if (enabled.isEmpty) break;
      await tester.tap(find.byElementPredicate((element) => identical(element, enabled.last)));
      await tester.pumpAndSettle();
    }
  }
  expect(target, findsOneWidget);
}

Future<void> _startupGamepadPress(
  WidgetTester tester,
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical, {
  Future<void> Function()? whileHeld,
}) async {
  Future<bool> send(bool down) async {
    tester.binding.platformDispatcher.onKeyData!(
      ui.KeyData(
        timeStamp: Duration.zero,
        type: down ? ui.KeyEventType.down : ui.KeyEventType.up,
        physical: physical.usbHidUsage,
        logical: logical.keyId,
        character: null,
        synthesized: false,
        deviceType: ui.KeyEventDeviceType.gamepad,
      ),
    );
    final response = Completer<bool>();
    final data = KeyEventSimulator.getKeyData(
      logical,
      platform: 'android',
      isDown: down,
      physicalKey: physical,
    )..['source'] = 0x00000401;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.keyEvent.name,
      SystemChannels.keyEvent.codec.encodeMessage(data),
      (reply) {
        final value = SystemChannels.keyEvent.codec.decodeMessage(
          reply,
        ) as Map<Object?, Object?>?;
        response.complete(value?['handled'] == true);
      },
    );
    return response.future;
  }

  try {
    expect(await send(true), isTrue);
    await whileHeld?.call();
  } finally {
    await send(false);
  }
}

NormalizedGamepadEvent _startupPad({
  required GamepadButton button,
  double value = 1,
}) => NormalizedGamepadEvent(
  gamepadId: 'startup-pad',
  timestamp: 1,
  value: value,
  button: button,
  rawEvent: GamepadEvent(
    gamepadId: 'startup-pad',
    timestamp: 1,
    type: KeyType.button,
    key: button.name,
    value: value,
  ),
);
