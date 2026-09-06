import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_options.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('Space remapped to Back closes a choice without saving',
      (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    final profile = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.secondary,
          inputId: 'space',
        )
        .profile;
    await _pumpOptions(tester, profile: profile, onChanged: changes.add);
    await tester.tap(find.byKey(const ValueKey('options-text-speed-choice')));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(find.byKey(const ValueKey('options-choice-back')), findsNothing);
    expect(
        find.byKey(const ValueKey('runtime-player-options')), findsOneWidget);
  });

  testWidgets('Down leaves an audio slider without changing its value',
      (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    await _pumpOptions(tester, onChanged: changes.add);
    await tester.tap(find.byKey(const ValueKey('options-category-audio')));
    await tester.pumpAndSettle();
    final master = tester
        .widget<Slider>(find.byKey(const ValueKey('options-master-slider')));
    final music = tester
        .widget<Slider>(find.byKey(const ValueKey('options-music-slider')));
    master.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(music.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(master.focusNode!.hasFocus, isTrue);
  });

  testWidgets('a remapped slider direction invokes Back instead of adjusting',
      (tester) async {
    final changes = <PlayerPreferencesSnapshot>[];
    var backs = 0;
    final profile = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.left,
          inputId: 'keyA',
        )
        .profile
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.secondary,
          inputId: 'arrowLeft',
        )
        .profile;
    await _pumpOptions(tester,
        profile: profile, onChanged: changes.add, onBack: () => backs++);
    await tester.tap(find.byKey(const ValueKey('options-category-audio')));
    await tester.pumpAndSettle();
    tester
        .widget<Slider>(find.byKey(const ValueKey('options-master-slider')))
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    expect(backs, 1);
    expect(changes, isEmpty);
  });
}

Future<void> _pumpOptions(
  WidgetTester tester, {
  PlayerControlProfile? profile,
  required ValueChanged<PlayerPreferencesSnapshot> onChanged,
  VoidCallback? onBack,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    theme: PokeMapPlayerTheme.dark(),
    home: Scaffold(
      body: RuntimePlayerActions(
        onBack: onBack ?? () {},
        onMenu: () {},
        onInputSourceChanged: (_) {},
        child: PlayerMenuThemeScope(
          child: RuntimePlayerInputBindings(
            controlProfile: profile,
            child: RuntimePlayerOptions(
              preferences: const PlayerPreferencesSnapshot(
                locale: 'fr',
                accessibility: GameSessionAccessibilityOptions(),
              ),
              controlProfile: profile,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}
