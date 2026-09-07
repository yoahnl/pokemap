import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamepads/gamepads.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('options footer keeps two aligned touch buttons at $size',
        (tester) async {
      await _pumpSurface(tester, size: size, scale: 1, onChanged: (_) {});
      final defaults = find.byKey(const ValueKey('options-defaults-surface'));
      final back = find.byKey(const ValueKey('pause-frame-return-surface'));
      expect(defaults.hitTestable(), findsOneWidget);
      expect(back.hitTestable(), findsOneWidget);
      final first = tester.getRect(defaults);
      final second = tester.getRect(back);
      expect(first.height, greaterThanOrEqualTo(48));
      expect(second.height, first.height);
      expect(second.width, closeTo(first.width, .1));
      expect(second.top, closeTo(first.top, .1));
      expect(second.left - first.right, closeTo(8, .1));
      expect(second.right, lessThanOrEqualTo(size.width));
      expect(second.bottom, lessThanOrEqualTo(size.height));
      await tester.tap(defaults);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('options-reset-cancel')).hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (size, scale) in [
    (const Size(1440, 900), 1.0),
    (const Size(844, 390), 2.0),
    (const Size(390, 844), 2.0),
  ]) {
    testWidgets(
        'routed options footer resets its category at $size text $scale',
        (tester) async {
      final changes = <PlayerPreferencesSnapshot>[];
      await _pumpSurface(tester,
          size: size, scale: scale, onChanged: changes.add);
      await _category(tester, 'audio');
      final defaults = find.byKey(const ValueKey('options-defaults'));
      final footer = find.byType(PlayerMenuFooter);
      expect(find.descendant(of: footer, matching: defaults), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const ValueKey('runtime-player-options')),
              matching: defaults),
          findsNothing);
      expect(defaults.hitTestable(), findsOneWidget);
      expect(tester.getSize(defaults).height, greaterThanOrEqualTo(48));
      expect(
          find
              .byKey(const ValueKey('pause-frame-return-surface'))
              .hitTestable(),
          findsOneWidget);
      await _tap(tester, 'options-defaults');
      await _tap(tester, 'options-reset-cancel');
      expect(changes, isEmpty);
      await _tap(tester, 'options-defaults');
      await _tap(tester, 'options-reset-confirm');
      expect(changes.single.audioMix, const RuntimeAudioMix());
      expect(changes.single.highContrast, isTrue);
      expect(
          find.byKey(const ValueKey('options-master-slider')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'standalone defaults is compact and choice keeps a trailing arrow',
      (tester) async {
    await _pump(tester);
    expect(find.text('Choisissez la vitesse d’affichage des dialogues.'),
        findsOneWidget);
    final defaults = find.byKey(const ValueKey('options-defaults'));
    final body = find.byKey(const ValueKey('runtime-player-options'));
    expect(tester.getSize(defaults).width,
        lessThan(tester.getSize(body).width / 2));
    expect(tester.getRect(defaults).right,
        closeTo(tester.getRect(body).right, .01));
    final choice = find.byKey(const ValueKey('options-text-speed-choice'));
    final arrow = find.descendant(
        of: choice, matching: find.byIcon(Icons.expand_more_rounded));
    expect(arrow, findsOneWidget);
    expect(
        tester.getCenter(arrow).dx, greaterThan(tester.getCenter(choice).dx));
    expect(tester.getRect(choice).right - tester.getRect(arrow).right,
        closeTo(13.5, .01));
    expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
    await _tap(tester, 'options-text-speed-choice');
    expect(find.byKey(const ValueKey('options-choice-back')), findsOneWidget);
  });

  testWidgets('footer reset follows remapped input and blocks pending writes',
      (tester) async {
    final completion = Completer<void>();
    var writes = 0;
    final profile = PlayerControlProfile.standard
        .rebind(
            device: PlayerControlDevice.keyboard,
            control: RuntimeInputControl.primary,
            inputId: 'keyQ')
        .profile;
    await _pumpSurface(tester,
        size: const Size(1440, 900),
        scale: 1,
        profile: profile, onChanged: (_) {
      writes++;
      return completion.future;
    });
    Focus.of(tester
            .element(find.byKey(const ValueKey('options-defaults-surface'))))
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-reset-confirm')), findsOneWidget);
    await _tap(tester, 'options-reset-confirm');
    expect(writes, 1);
    final defaults = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('options-defaults')));
    expect(defaults.onPressed, isNull);
    expect(defaults.busy, isTrue);
    completion.completeError(
        const RuntimePlayerOptionsFailure('Le stockage est indisponible.'));
    await tester.pumpAndSettle();
    expect(find.text('Le stockage est indisponible.'), findsOneWidget);
    expect(
        tester
            .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('options-defaults')))
            .onPressed,
        isNotNull);
    expect(writes, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gamepad Y keeps its binding and A opens the focused reset',
      (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    final bridge = RuntimePlayerGamepadBridge();
    await _pumpSurface(tester,
        size: const Size(1440, 900), scale: 1, onChanged: changes.add);
    Focus.of(tester
            .element(find.byKey(const ValueKey('options-defaults-surface'))))
        .requestFocus();
    await tester.pump();
    Future<void> press(GamepadButton button) async {
      final event = bridge
          .handleButton(gamepadId: 'options-test', button: button, value: 1)
          .single;
      final command = playerInputCommandFromRuntimeEvent(event,
          source: PlayerInputSource.controller);
      Actions.invoke(FocusManager.instance.primaryFocus!.context!,
          RuntimePlayerLogicalIntent(command.action, source: command.source));
      await tester.pumpAndSettle();
    }

    await press(GamepadButton.y);
    expect(find.byType(Dialog), findsNothing);
    expect(changes, isEmpty);
    await press(GamepadButton.a);
    expect(find.byKey(const ValueKey('options-reset-confirm')), findsOneWidget);
    await press(GamepadButton.b);
    expect(find.byType(Dialog), findsNothing);
    expect(changes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final dialog in ['choice', 'reset']) {
    testWidgets('removing Options dismisses its $dialog dialog',
        (tester) async {
      late StateSetter rebuild;
      var visible = true;
      final changes = <PlayerPreferencesSnapshot>[];
      await tester.pumpWidget(MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        home: StatefulBuilder(builder: (context, setState) {
          rebuild = setState;
          return Scaffold(
              body: PlayerMenuThemeScope(
                  child: visible
                      ? RuntimePlayerOptions(
                          preferences: _preferences, onChanged: changes.add)
                      : const SizedBox()));
        }),
      ));
      await tester.pumpAndSettle();
      await _tap(
          tester,
          dialog == 'choice'
              ? 'options-text-speed-choice'
              : 'options-defaults');
      expect(find.byType(Dialog), findsOneWidget);
      rebuild(() => visible = false);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(changes, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('touch controls can exchange confirm and back', (tester) async {
    final changes = <PlayerControlProfile>[];
    await _pump(tester,
        activeInputSource: PlayerInputSource.touch,
        onControlChanged: changes.add);
    await _category(tester, 'controls');
    await _tap(tester, 'options-controls-touch-swap');
    expect(
        changes.single
            .bindingFor(PlayerControlDevice.touch, RuntimeInputControl.primary),
        'secondaryButton');
    expect(
        changes.single.bindingFor(
            PlayerControlDevice.touch, RuntimeInputControl.secondary),
        'primaryButton');
    expect(changes.single.keyboard, PlayerControlProfile.standard.keyboard);
    expect(changes.single.gamepad, PlayerControlProfile.standard.gamepad);
    expect(
        tester
            .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('options-binding-up-choice')))
            .onPressed,
        isNull);
    expect(changes.single.touch[RuntimeInputControl.up], 'joystickUp');
  });

  testWidgets('options has six categories and separate return to title',
      (tester) async {
    await _pump(tester, onReturnToTitle: () {});
    for (final category in _categories) {
      expect(
          find.byKey(ValueKey('options-category-$category')), findsOneWidget);
    }
    final sidebar =
        tester.getRect(find.byKey(const ValueKey('options-categories')));
    final settings =
        tester.getRect(find.byKey(const ValueKey('options-settings')));
    expect(sidebar.width, 320);
    expect(settings.left - sidebar.right, 24);
    expect(find.text('Vitesse des textes'), findsOneWidget);
    expect(find.text('Plein écran'), findsNothing);
    expect(find.text('Luminosité'), findsNothing);
    final access = tester
        .getRect(find.byKey(const ValueKey('options-category-accessibility')));
    final exit =
        tester.getRect(find.byKey(const ValueKey('options-return-title')));
    expect(exit.top - access.bottom, greaterThanOrEqualTo(24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio sliders persist their channels without changing category',
      (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    await _category(tester, 'audio');
    for (final channel in ['master', 'music', 'effects']) {
      final slider = tester
          .widget<Slider>(find.byKey(ValueKey('options-$channel-slider')));
      expect(slider.divisions, 20);
      slider.onChanged!(.35);
      slider.onChangeEnd!(.35);
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('options-master-slider')), findsOneWidget);
    }
    expect(changes.last.audioMix.masterVolume, .35);
    expect(changes.last.audioMix.musicVolume, .35);
    expect(changes.last.audioMix.effectsVolume, .35);
    expect(changes.last.locale, 'fr');
  });

  testWidgets('failed persistence restores slider and keeps a visible error',
      (tester) async {
    final completion = Completer<void>();
    await _pump(tester, onChanged: (_) => completion.future);
    await _category(tester, 'audio');
    var slider = tester
        .widget<Slider>(find.byKey(const ValueKey('options-master-slider')));
    slider.onChanged!(.2);
    slider.onChangeEnd!(.2);
    await tester.pump();
    expect(find.byKey(const ValueKey('options-saving')), findsOneWidget);
    slider = tester
        .widget<Slider>(find.byKey(const ValueKey('options-master-slider')));
    expect(slider.onChanged, isNull);
    expect(
        tester
            .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('options-defaults')))
            .onPressed,
        isNull);
    completion.completeError(StateError('secret_path_should_not_leak'));
    await tester.pumpAndSettle();
    slider = tester
        .widget<Slider>(find.byKey(const ValueKey('options-master-slider')));
    expect(slider.value, 1);
    expect(find.byKey(const ValueKey('options-save-error')), findsOneWidget);
    expect(find.textContaining('secret_path'), findsNothing);
    await _category(tester, 'display');
    expect(find.byKey(const ValueKey('options-save-error')), findsOneWidget);
  });

  testWidgets('cancelled category reset never writes preferences',
      (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    await _category(tester, 'audio');
    await _tap(tester, 'options-defaults');
    expect(find.textContaining('Son'), findsWidgets);
    await _tap(tester, 'options-reset-cancel');
    expect(changes, isEmpty);
  });

  testWidgets('confirmed reset only restores current category', (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester,
        preferences: _preferences.copyWith(
          audioMix: const RuntimeAudioMix(
              masterVolume: .2, musicVolume: .3, effectsVolume: .4),
          highContrast: true,
          showInputHints: false,
        ),
        onChanged: changes.add);
    await _category(tester, 'audio');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.single.audioMix, const RuntimeAudioMix());
    expect(changes.single.highContrast, isTrue);
    expect(changes.single.showInputHints, isFalse);
  });

  testWidgets('interface language keeps selected category after reload',
      (tester) async {
    final current = ValueNotifier(_preferences);
    addTearDown(current.dispose);
    await _pump(tester,
        notifier: current, onChanged: (value) => current.value = value);
    await _category(tester, 'language');
    await _tap(tester, 'options-locale-choice');
    await _tap(tester, 'options-choice-en');
    expect(current.value.locale, 'en');
    expect(find.text('Interface language'), findsOneWidget);
    expect(find.textContaining('story'), findsOneWidget);
    expect(find.byKey(const ValueKey('options-locale-choice')), findsOneWidget);
  });

  testWidgets('category reset restores the host defaults', (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    const defaults = PlayerPreferencesSnapshot(
      locale: 'en',
      accessibility: GameSessionAccessibilityOptions(),
      audioMix: RuntimeAudioMix(musicVolume: .8, effectsVolume: .8),
    );
    await _pump(tester, defaultPreferences: defaults, onChanged: changes.add);
    await _category(tester, 'language');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.single.locale, 'en');
    await _category(tester, 'audio');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.last.audioMix, defaults.audioMix);
    expect(changes.last.locale, 'en');
  });

  testWidgets('choice dialog back leaves preference unchanged', (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    await _tap(tester, 'options-text-speed-choice');
    await _tap(tester, 'options-choice-back');
    expect(changes, isEmpty);
  });

  testWidgets('return to title delegates to existing confirmation flow',
      (tester) async {
    var exits = 0;
    await _pump(tester, onReturnToTitle: () => exits++);
    await _tap(tester, 'options-return-title');
    expect(exits, 1);
  });

  testWidgets('desktop accessibility omits unsupported vibrations',
      (tester) async {
    await _pump(tester);
    await _category(tester, 'accessibility');
    expect(find.byKey(const ValueKey('runtime-player-haptics-toggle')),
        findsNothing);
    expect(find.byKey(const ValueKey('runtime-player-reduced-motion-toggle')),
        findsOneWidget);
  });

  testWidgets('help sits at the bottom of the desktop settings panel',
      (tester) async {
    await _pump(tester);
    final settings =
        tester.getRect(find.byKey(const ValueKey('options-settings')));
    final help = tester.getRect(find.byKey(const ValueKey('options-help')));
    expect(settings.bottom - help.bottom, 24);
    expect(help.height, inInclusiveRange(96, 144));
  });

  testWidgets(
      'keyboard and controller adjust the focused audio slider by five percent',
      (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    await _category(tester, 'audio');
    final slider = find.byKey(const ValueKey('options-master-slider'));
    await tester.tap(slider);
    await tester.pumpAndSettle();
    changes.clear();
    final before = tester.widget<Slider>(slider).value;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(changes.last.audioMix.masterVolume, closeTo(before - .05, .001));
    Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        const RuntimePlayerLogicalIntent(PlayerInputAction.right,
            source: PlayerInputSource.controller));
    await tester.pumpAndSettle();
    expect(changes.last.audioMix.masterVolume, closeTo(before, .001));
  });

  testWidgets('control binding conflict never writes the profile',
      (tester) async {
    final changes = <PlayerControlProfile>[];
    await _pump(tester, onControlChanged: changes.add);
    await _category(tester, 'controls');
    await _tap(tester, 'options-binding-primary-choice');
    await _tap(tester, 'options-choice-escape');
    expect(changes, isEmpty);
    expect(find.text('Cette entrée est déjà utilisée.'), findsOneWidget);
  });

  testWidgets(
      'control persistence waits and restores the confirmed binding on failure',
      (tester) async {
    final completion = Completer<void>();
    await _pump(tester, onControlChanged: (_) => completion.future);
    await _category(tester, 'controls');
    await _tap(tester, 'options-binding-primary-choice');
    await _tap(tester, 'options-choice-space');
    expect(
        tester
            .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('options-binding-primary-choice')))
            .label,
        'E');
    expect(find.byKey(const ValueKey('options-saving')), findsOneWidget);
    completion.completeError(
        const RuntimePlayerOptionsFailure('Le stockage est indisponible.'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<PlayerMenuSelectableRow>(
                find.byKey(const ValueKey('options-binding-primary-choice')))
            .label,
        'E');
    expect(find.text('Le stockage est indisponible.'), findsOneWidget);
  });

  testWidgets(
      'device binding reset requires confirmation and preserves other devices',
      (tester) async {
    final changes = <PlayerControlProfile>[];
    final profile = PlayerControlProfile.standard
        .rebind(
            device: PlayerControlDevice.keyboard,
            control: RuntimeInputControl.primary,
            inputId: 'space')
        .profile;
    await _pump(tester, profile: profile, onControlChanged: changes.add);
    await _category(tester, 'controls');
    await _tap(tester, 'options-controls-reset');
    await _tap(tester, 'options-reset-cancel');
    expect(changes, isEmpty);
    await _tap(tester, 'options-controls-reset');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.single.keyboard, PlayerControlProfile.standard.keyboard);
    expect(changes.single.gamepad, profile.gamepad);
    expect(changes.single.touch, profile.touch);
  });

  testWidgets(
      'large text choice and reset popups stay inside portrait and landscape',
      (tester) async {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      await _pump(tester, size: size, scale: 2);
      await _tap(tester, 'options-text-speed-choice');
      expect(find.byKey(const ValueKey('options-choice-back')).hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, 'options-choice-back');
      await _tap(tester, 'options-defaults');
      expect(find.byKey(const ValueKey('options-reset-cancel')).hitTestable(),
          findsOneWidget);
      expect(tester.takeException(), isNull);
      await _tap(tester, 'options-reset-cancel');
    }
  });

  testWidgets(
      'dialogs preserve the local player text scale above the navigator',
      (tester) async {
    await _pump(tester, localScale: 1.6);
    await _tap(tester, 'options-text-speed-choice');
    expect(
        MediaQuery.textScalerOf(tester
                .element(find.byKey(const ValueKey('options-choice-back'))))
            .scale(1),
        1.6);
    await _tap(tester, 'options-choice-back');
    await _tap(tester, 'options-defaults');
    expect(
        MediaQuery.textScalerOf(tester
                .element(find.byKey(const ValueKey('options-reset-cancel'))))
            .scale(1),
        1.6);
    await _tap(tester, 'options-reset-cancel');
  });

  testWidgets('option dialogs use remapped confirm and back keys',
      (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    final profile = PlayerControlProfile.standard
        .rebind(
            device: PlayerControlDevice.keyboard,
            control: RuntimeInputControl.primary,
            inputId: 'keyQ')
        .profile
        .rebind(
            device: PlayerControlDevice.keyboard,
            control: RuntimeInputControl.secondary,
            inputId: 'keyW')
        .profile;
    await _pump(tester, profile: profile, onChanged: changes.add);
    await _tap(tester, 'options-text-speed-choice');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('options-choice-back')), findsNothing);
    expect(changes, isEmpty);
    await _tap(tester, 'options-text-speed-choice');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pumpAndSettle();
    expect(changes.single.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);
    await _tap(tester, 'options-defaults');
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pumpAndSettle();
    expect(changes, hasLength(1));
    await _tap(tester, 'options-defaults');
    final confirm = tester.widget<PlayerActionButton>(
        find.byKey(const ValueKey('options-reset-confirm')));
    final focusable = find
        .descendant(
            of: find.byKey(const ValueKey('options-reset-confirm')),
            matching: find.byType(Focus))
        .first;
    tester.widget<Focus>(focusable).focusNode!.requestFocus();
    await tester.pump();
    expect(confirm.onPressed, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.pumpAndSettle();
    expect(changes.last.dialogueTextSpeed, RuntimeDialogueTextSpeed.normal);
    expect(changes, hasLength(2));
  });

  for (final size in [
    const Size(1440, 900),
    const Size(844, 390),
    const Size(390, 844)
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('all options remain reachable at $size text $scale',
          (tester) async {
        await _pump(tester, size: size, scale: scale);
        for (final category in _categories) {
          await _category(tester, category);
          expect(tester.takeException(), isNull);
          expect(
              find
                  .byKey(const ValueKey('pause-frame-return-surface'))
                  .hitTestable(),
              findsOneWidget);
          expect(find.byKey(const ValueKey('options-defaults')).hitTestable(),
              findsOneWidget);
        }
      });
    }
  }
}

const _categories = [
  'general',
  'display',
  'audio',
  'controls',
  'language',
  'accessibility'
];
const _preferences = PlayerPreferencesSnapshot(
    locale: 'fr', accessibility: GameSessionAccessibilityOptions());

Future<void> _pumpSurface(WidgetTester tester,
    {required Size size,
    required double scale,
    PlayerControlProfile? profile,
    required FutureOr<void> Function(PlayerPreferencesSnapshot)
        onChanged}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    theme: PokeMapPlayerTheme.dark().copyWith(platform: TargetPlatform.macOS),
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
    home: RuntimePlayerSurfaceRouter(
      snapshot: RuntimePlayerSnapshot(
          revision: 1,
          phase: RuntimePlayerPhase.paused,
          gameTitle: 'Voyage',
          pauseSection: RuntimePlayerPauseSection.options,
          preferences: _preferences.copyWith(
              highContrast: true,
              audioMix: const RuntimeAudioMix(masterVolume: .2)),
          actions: const [
            RuntimePlayerActionAvailability.enabled(
                RuntimePlayerAction.openOptions),
            RuntimePlayerActionAvailability.enabled(
                RuntimePlayerAction.updatePreferences),
          ]),
      titlePresentation: const RuntimePlayerTitlePresentation(author: 'Train'),
      pausePresentation: const PlayerPausePresentation(
          style: ProjectPauseMenuStyle.nightIllustrated),
      hardwareGamepadEnabled: false,
      controlProfile: profile,
      gameSceneBuilder: (_) => const SizedBox.expand(),
      onPreferencesChanged: onChanged,
      onAction: (_) async => const RuntimePlayerCommandResult(
          status: RuntimePlayerCommandStatus.accepted),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _category(WidgetTester tester, String category) async {
  if (find.byKey(ValueKey('options-category-$category')).evaluate().isEmpty) {
    await _tap(tester, 'options-category-picker');
  }
  await _tap(tester, 'options-category-$category');
}

Future<void> _pump(WidgetTester tester,
    {PlayerPreferencesSnapshot preferences = _preferences,
    PlayerPreferencesSnapshot defaultPreferences = _preferences,
    ValueNotifier<PlayerPreferencesSnapshot>? notifier,
    FutureOr<void> Function(PlayerPreferencesSnapshot)? onChanged,
    FutureOr<void> Function(PlayerControlProfile)? onControlChanged,
    PlayerControlProfile? profile,
    PlayerInputSource activeInputSource = PlayerInputSource.keyboard,
    VoidCallback? onReturnToTitle,
    Size size = const Size(1440, 900),
    double scale = 1,
    double? localScale}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  Widget build(PlayerPreferencesSnapshot current) => MaterialApp(
        locale: Locale(current.locale),
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        theme:
            PokeMapPlayerTheme.dark().copyWith(platform: TargetPlatform.macOS),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: PlayerMenuThemeScope(
            child: Scaffold(
                body: RuntimePlayerPauseShell(
          gameTitle: 'Le train de 17h42',
          pauseSection: RuntimePlayerPauseSection.options,
          actions: {
            for (final action in PlayerPauseAction.values)
              action: PlayerActionAvailability.enabled
          },
          onSelected: (_) {},
          onBackToRoot: () {},
          presentation: const PlayerPausePresentation(
              style: ProjectPauseMenuStyle.nightIllustrated),
          detailOwnsScroll: true,
          detail: Builder(
              builder: (context) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: localScale == null
                          ? MediaQuery.textScalerOf(context)
                          : TextScaler.linear(localScale)),
                  child: RuntimePlayerDetailRouter(
                    snapshot: RuntimePlayerSnapshot(
                        revision: 1,
                        phase: RuntimePlayerPhase.paused,
                        gameTitle: 'Voyage',
                        pauseSection: RuntimePlayerPauseSection.options,
                        preferences: current,
                        defaultPreferences: defaultPreferences,
                        actions: const [
                          RuntimePlayerActionAvailability.enabled(
                              RuntimePlayerAction.openOptions),
                          RuntimePlayerActionAvailability.enabled(
                              RuntimePlayerAction.updatePreferences)
                        ]),
                    onPreferencesChanged: onChanged ?? (_) {},
                    onReturnToTitle: onReturnToTitle,
                    controlProfile: profile,
                    activeInputSource: activeInputSource,
                    onControlProfileChanged: onControlChanged,
                  ))),
        ))),
      );
  await tester.pumpWidget(notifier == null
      ? build(preferences)
      : ValueListenableBuilder<PlayerPreferencesSnapshot>(
          valueListenable: notifier,
          builder: (context, value, child) => build(value)));
  await tester.pumpAndSettle();
}
