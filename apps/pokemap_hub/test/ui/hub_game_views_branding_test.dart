import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/src/ui/hub_game_views.dart';

void main() {
  testWidgets('artwork fallback consumes the project accent color',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.light(),
        home: const HubArtwork(
          path: null,
          icon: Icons.explore,
          accentColor: Color(0xFF123456),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.explore));
    expect(icon.color, const Color(0xFF123456));
  });
}
