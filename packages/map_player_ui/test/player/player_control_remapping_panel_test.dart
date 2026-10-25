import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'unbound optional tab binding remains selectable without assertion',
    (tester) async {
      final data = PlayerControlProfile.standard.toJson();
      for (final device in ['keyboard', 'gamepad', 'touch']) {
        final bindings = data[device] as Map<String, String>;
        bindings.remove('previousTab');
        bindings.remove('nextTab');
      }
      (data['gamepad'] as Map<String, String>)['sprint'] = 'leftBumper';
      final profile = PlayerControlProfile.fromJson(data);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          theme: PokeMapPlayerTheme.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlayerControlRemappingPanel(
                profile: profile,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      final field = find.byKey(
        const ValueKey<String>('controls-gamepad-previousTab'),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<DropdownButtonFormField<String>>(field).initialValue,
        isNull,
      );
      expect(
        find.descendant(of: field, matching: find.text('—')),
        findsOneWidget,
      );
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
      expect(find.text('L'), findsWidgets);
      expect(tester.takeException(), isNull);
      expect(
        profile.bindingFor(
          PlayerControlDevice.gamepad,
          RuntimeInputControl.previousTab,
        ),
        isEmpty,
      );
    },
  );

  testWidgets('shows all device profiles and resets one section', (
    tester,
  ) async {
    PlayerControlProfile? changed;
    final customized = PlayerControlProfile.standard
        .rebind(
          device: PlayerControlDevice.keyboard,
          control: RuntimeInputControl.primary,
          inputId: 'keyZ',
        )
        .profile;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PlayerControlRemappingPanel(
              profile: customized,
              onChanged: (profile) => changed = profile,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Keyboard'), findsOneWidget);
    expect(find.text('Gamepad'), findsOneWidget);
    expect(find.text('Touch'), findsOneWidget);
    expect(find.text('Z'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey<String>('controls-reset-keyboard')),
    );
    expect(changed, PlayerControlProfile.standard);
  });
}
