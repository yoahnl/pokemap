import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('simple choices persist inline and never open a dialog', (
    tester,
  ) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('options-defaults')),
          )
          .onPressed,
      isNull,
    );
    await _tap(tester, 'options-text-speed-choice');
    expect(changes.single.dialogueTextSpeed, RuntimeDialogueTextSpeed.fast);
    expect(find.byType(Dialog), findsNothing);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('options-defaults')),
          )
          .onPressed,
      isNotNull,
    );
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-cancel');
    expect(changes, hasLength(1));
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.last.dialogueTextSpeed, RuntimeDialogueTextSpeed.normal);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('options-defaults')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('failed inline choice preserves the confirmed preference', (
    tester,
  ) async {
    await _pump(
      tester,
      onChanged: (_) =>
          throw const RuntimePlayerOptionsFailure('Écriture indisponible.'),
    );
    await _tap(tester, 'options-text-speed-choice');
    expect(find.text('Écriture indisponible.'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('options-defaults')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'inline persistence rejects duplicate activation until completion',
    (tester) async {
      final completion = Completer<void>();
      var writes = 0;
      await _pump(
        tester,
        onChanged: (_) {
          writes++;
          return completion.future;
        },
      );
      final row = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('options-text-speed-choice')),
      );
      row.onPressed!();
      row.onPressed!();
      await tester.pump();
      expect(writes, 1);
      completion.complete();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(1440, 900),
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(390, 844),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'all categories and critical return fit $size text $scale without content scrolling',
        (tester) async {
          await _pump(tester, size: size, scale: scale);
          for (final category in _categories) {
            await _category(tester, category);
            expect(tester.takeException(), isNull, reason: category);
            expect(find.byType(Scrollable), findsNothing);
            if (size.height == 390 && scale == 2) {
              final seen = <String>{};
              const controls = {
                'options-touch-run-mode-choice',
                'runtime-player-left-handed-touch-toggle',
                'runtime-player-input-hints-toggle',
                'touch-controls-opacity-slider',
                'options-binding-primary-choice',
              };
              var pages = 0;
              while (true) {
                for (final key in controls) {
                  if (find
                      .byKey(ValueKey(key))
                      .hitTestable()
                      .evaluate()
                      .isNotEmpty) {
                    seen.add(key);
                  }
                }
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '$category page $pages',
                );
                expect(find.byType(Scrollable), findsNothing);
                final next = find.descendant(
                  of: find.byKey(const ValueKey('options-settings')),
                  matching: find.byKey(const ValueKey('player-page-next')),
                );
                if (next.evaluate().isEmpty ||
                    tester.widget<IconButton>(next).onPressed == null) {
                  break;
                }
                expect(pages++, lessThan(40), reason: category);
                await tester.tap(next);
                await tester.pumpAndSettle();
              }
              if (category == 'controls') expect(seen, controls);
            }
            expect(
              find
                  .byKey(const ValueKey('pause-frame-return-surface'))
                  .hitTestable(),
              findsOneWidget,
            );
          }
        },
      );
    }
  }

  testWidgets('reset confirmation retains local text scale and remapped back', (
    tester,
  ) async {
    final profile = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.secondary,
          inputId: 'keyW',
        )
        .profile;
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(
      tester,
      localScale: 1.6,
      profile: profile,
      onChanged: changes.add,
    );
    await _tap(tester, 'options-text-speed-choice');
    await _tap(tester, 'options-defaults');
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.byKey(const ValueKey('options-reset-cancel'))),
      ).scale(1),
      1.6,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(changes, hasLength(1));
  });

  testWidgets(
    'touch options omit removed bindings and retain gesture settings',
    (tester) async {
      final changes = <PlayerControlProfile>[];
      await _pump(
        tester,
        activeInputSource: PlayerInputSource.touch,
        onControlChanged: changes.add,
      );
      await _category(tester, 'controls');
      for (final control in RuntimeInputControl.values) {
        expect(
          find.byKey(ValueKey('options-binding-${control.name}-choice')),
          findsNothing,
        );
      }
      expect(
        find.byKey(const ValueKey('options-controls-touch-swap')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('options-controls-reset')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('options-touch-run-mode-choice')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('runtime-player-left-handed-touch-toggle')),
        findsOneWidget,
      );
      expect(changes, isEmpty);
    },
  );

  testWidgets('touch running alternatives save and reset through controls', (
    tester,
  ) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    await _category(tester, 'controls');
    expect(tester.takeException(), isNull, reason: 'controls initial layout');
    await _tap(tester, 'options-touch-run-mode-choice');
    expect(changes.single.touchRunMode, RuntimePlayerTouchRunMode.walkOnly);
    expect(tester.takeException(), isNull, reason: 'walk-only persisted');
    await _tap(tester, 'options-touch-run-mode-choice');
    expect(changes.last.touchRunMode, RuntimePlayerTouchRunMode.automatic);
    expect(tester.takeException(), isNull, reason: 'automatic persisted');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.last.touchRunMode, RuntimePlayerTouchRunMode.gesture);
    expect(changes.last.audioMix, _preferences.audioMix);
    expect(tester.takeException(), isNull);
  });

  testWidgets('touch side setting persists and resets with controls', (
    tester,
  ) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    await _category(tester, 'controls');
    await _tap(tester, 'runtime-player-left-handed-touch-toggle');
    expect(changes.single.leftHandedTouchControls, isTrue);
    expect(changes.single.audioMix, _preferences.audioMix);
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.last.leftHandedTouchControls, isFalse);
    expect(changes.last.audioMix, _preferences.audioMix);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'audio sliders persist their channels without changing category',
    (tester) async {
      final changes = <PlayerPreferencesSnapshot>[];
      await _pump(tester, onChanged: changes.add);
      await _category(tester, 'audio');
      for (final channel in ['master', 'music', 'effects']) {
        final slider = tester.widget<Slider>(
          find.byKey(ValueKey('options-$channel-slider')),
        );
        expect(slider.divisions, 20);
        slider.onChanged!(.35);
        slider.onChangeEnd!(.35);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('options-master-slider')),
          findsOneWidget,
        );
      }
      expect(changes.last.audioMix.masterVolume, .35);
      expect(changes.last.audioMix.musicVolume, .35);
      expect(changes.last.audioMix.effectsVolume, .35);
      expect(changes.last.locale, 'fr');
    },
  );

  testWidgets('failed persistence restores slider and keeps a visible error', (
    tester,
  ) async {
    final completion = Completer<void>();
    await _pump(tester, onChanged: (_) => completion.future);
    await _category(tester, 'audio');
    var slider = tester.widget<Slider>(
      find.byKey(const ValueKey('options-master-slider')),
    );
    slider.onChanged!(.2);
    slider.onChangeEnd!(.2);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('options-saving')), findsOneWidget);
    slider = tester.widget<Slider>(
      find.byKey(const ValueKey('options-master-slider')),
    );
    expect(slider.onChanged, isNull);
    expect(
      tester
          .widget<PlayerMenuSelectableRow>(
            find.byKey(const ValueKey('options-defaults')),
          )
          .onPressed,
      isNull,
    );
    completion.completeError(StateError('secret_path_should_not_leak'));
    await tester.pumpAndSettle();
    slider = tester.widget<Slider>(
      find.byKey(const ValueKey('options-master-slider')),
    );
    expect(slider.value, 1);
    expect(find.byKey(const ValueKey('options-save-error')), findsOneWidget);
    expect(find.textContaining('secret_path'), findsNothing);
    await _category(tester, 'display');
    expect(find.byKey(const ValueKey('options-save-error')), findsOneWidget);
  });

  testWidgets('cancelled category reset never writes preferences', (
    tester,
  ) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(tester, onChanged: changes.add);
    await _category(tester, 'general');
    await _tap(tester, 'options-text-speed-choice');
    changes.clear();
    await _tap(tester, 'options-defaults');
    expect(find.byKey(const ValueKey('options-reset-cancel')), findsOneWidget);
    await _tap(tester, 'options-reset-cancel');
    expect(changes, isEmpty);
  });

  testWidgets('confirmed reset only restores current category', (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pump(
      tester,
      preferences: _preferences.copyWith(
        audioMix: const RuntimeAudioMix(
          masterVolume: .2,
          musicVolume: .3,
          effectsVolume: .4,
        ),
        highContrast: true,
        showInputHints: false,
      ),
      onChanged: changes.add,
    );
    await _category(tester, 'audio');
    await _tap(tester, 'options-defaults');
    await _tap(tester, 'options-reset-confirm');
    expect(changes.single.audioMix, const RuntimeAudioMix());
    expect(changes.single.highContrast, isTrue);
    expect(changes.single.showInputHints, isFalse);
  });

  testWidgets('interface language keeps selected category after reload', (
    tester,
  ) async {
    final current = ValueNotifier(_preferences);
    addTearDown(current.dispose);
    await _pump(
      tester,
      notifier: current,
      onChanged: (value) => current.value = value,
    );
    await _category(tester, 'language');
    await _tap(tester, 'options-locale-choice');
    expect(current.value.locale, 'en');
    expect(find.text('Interface language'), findsOneWidget);
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

  testWidgets('return to title delegates to existing confirmation flow', (
    tester,
  ) async {
    var exits = 0;
    await _pump(tester, onReturnToTitle: () => exits++);
    await _tap(tester, 'options-return-title');
    expect(exits, 1);
  });

  testWidgets('desktop accessibility omits unsupported vibrations', (
    tester,
  ) async {
    await _pump(tester);
    await _category(tester, 'accessibility');
    expect(
      find.byKey(const ValueKey('runtime-player-haptics-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('runtime-player-reduced-motion-toggle')),
      findsOneWidget,
    );
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
        const RuntimePlayerLogicalIntent(
          PlayerInputAction.right,
          source: PlayerInputSource.controller,
        ),
      );
      await tester.pumpAndSettle();
      expect(changes.last.audioMix.masterVolume, closeTo(before, .001));
    },
  );

  testWidgets('control binding conflict never writes the profile', (
    tester,
  ) async {
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
              find.byKey(const ValueKey('options-binding-primary-choice')),
            )
            .label,
        'E',
      );
      expect(find.byKey(const ValueKey('options-saving')), findsOneWidget);
      completion.completeError(
        const RuntimePlayerOptionsFailure('Le stockage est indisponible.'),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PlayerMenuSelectableRow>(
              find.byKey(const ValueKey('options-binding-primary-choice')),
            )
            .label,
        'E',
      );
      expect(find.text('Le stockage est indisponible.'), findsOneWidget);
    },
  );

  testWidgets(
    'device binding reset requires confirmation and preserves other devices',
    (tester) async {
      final changes = <PlayerControlProfile>[];
      final profile = PlayerControlProfile.standard
          .rebind(
            device: PlayerControlDevice.keyboard,
            control: RuntimeInputControl.primary,
            inputId: 'space',
          )
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
    },
  );
}

const _categories = [
  'general',
  'display',
  'audio',
  'controls',
  'language',
  'accessibility',
];
const _preferences = PlayerPreferencesSnapshot(
  locale: 'fr',
  accessibility: GameSessionAccessibilityOptions(),
);

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  Finder scope = find.byKey(const ValueKey('options-settings'));
  if (key.startsWith('options-category-')) {
    scope = find.byKey(const ValueKey('options-categories'));
  }
  if (key.startsWith('options-choice-')) scope = find.byType(Dialog);
  for (var i = 0; finder.hitTestable().evaluate().isEmpty && i < 30; i++) {
    final next = find
        .descendant(
          of: scope,
          matching: find.byKey(const ValueKey('player-page-next')),
        )
        .hitTestable();
    final enabled = next
        .evaluate()
        .where((e) => (e.widget as IconButton).onPressed != null)
        .toList();
    if (enabled.isEmpty) {
      final previous = find
          .descendant(
            of: scope,
            matching: find.byKey(const ValueKey('player-page-previous')),
          )
          .hitTestable();
      final backs = previous
          .evaluate()
          .where((e) => (e.widget as IconButton).onPressed != null)
          .toList();
      if (backs.isEmpty) break;
      while (backs.isNotEmpty) {
        await tester.tap(find.byWidget(backs.first.widget));
        await tester.pumpAndSettle();
        backs.clear();
        backs.addAll(
          previous.evaluate().where(
            (e) => (e.widget as IconButton).onPressed != null,
          ),
        );
      }
    } else {
      await tester.tap(find.byWidget(enabled.first.widget));
      await tester.pumpAndSettle();
    }
  }
  expect(finder.hitTestable(), findsOneWidget, reason: key);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _category(WidgetTester tester, String category) async {
  if (find.byKey(ValueKey('options-category-$category')).evaluate().isEmpty &&
      find
          .byKey(const ValueKey('options-category-picker'))
          .evaluate()
          .isNotEmpty) {
    await _tap(tester, 'options-category-picker');
  }
  await _tap(tester, 'options-category-$category');
}

Future<void> _pump(
  WidgetTester tester, {
  PlayerPreferencesSnapshot preferences = _preferences,
  PlayerPreferencesSnapshot defaultPreferences = _preferences,
  ValueNotifier<PlayerPreferencesSnapshot>? notifier,
  FutureOr<void> Function(PlayerPreferencesSnapshot)? onChanged,
  FutureOr<void> Function(PlayerControlProfile)? onControlChanged,
  PlayerControlProfile? profile,
  PlayerInputSource activeInputSource = PlayerInputSource.keyboard,
  VoidCallback? onReturnToTitle,
  Size size = const Size(1440, 900),
  double scale = 1,
  double? localScale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  Widget build(PlayerPreferencesSnapshot current) => MaterialApp(
    locale: Locale(current.locale),
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    theme: PokeMapPlayerTheme.dark().copyWith(platform: TargetPlatform.macOS),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: PlayerMenuThemeScope(
      child: Scaffold(
        body: RuntimePlayerPauseShell(
          gameTitle: 'Le train de 17h42',
          pauseSection: RuntimePlayerPauseSection.options,
          actions: {
            for (final action in PlayerPauseAction.values)
              action: PlayerActionAvailability.enabled,
          },
          onSelected: (_) {},
          onBackToRoot: () {},
          presentation: const PlayerPausePresentation(
            style: ProjectPauseMenuStyle.nightIllustrated,
          ),
          detailOwnsScroll: true,
          detail: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: localScale == null
                    ? MediaQuery.textScalerOf(context)
                    : TextScaler.linear(localScale),
              ),
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
                      RuntimePlayerAction.openOptions,
                    ),
                    RuntimePlayerActionAvailability.enabled(
                      RuntimePlayerAction.updatePreferences,
                    ),
                  ],
                ),
                onPreferencesChanged: onChanged ?? (_) {},
                onReturnToTitle: onReturnToTitle,
                controlProfile: profile,
                activeInputSource: activeInputSource,
                onControlProfileChanged: onControlChanged,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    notifier == null
        ? build(preferences)
        : ValueListenableBuilder<PlayerPreferencesSnapshot>(
            valueListenable: notifier,
            builder: (context, value, child) => build(value),
          ),
  );
  await tester.pumpAndSettle();
}
