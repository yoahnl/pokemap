import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('shows all device profiles and resets one section',
      (tester) async {
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
