import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/presentation/design_system/theme/avelune_theme_data.dart';

void main() {
  test('preserves Player text colors when applying Avelune typography', () {
    final playerTheme = PokeMapPlayerTheme.light();
    final theme = applyAveluneTheme(playerTheme);

    expect(
      theme.textTheme.headlineSmall?.color,
      playerTheme.textTheme.headlineSmall?.color,
    );
    expect(
      theme.textTheme.labelLarge?.color,
      playerTheme.textTheme.labelLarge?.color,
    );
  });
}
