import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/presentation/features/player/pages/hub_installed_player_strings.dart';

void main() {
  test('installed player profile uses explicit English copy', () {
    final strings = HubInstalledPlayerStrings.forLocale('en-GB');

    expect(strings.defaultProfile, 'Player');
  });

  test('installed player profile keeps French as an authored locale', () {
    final strings = HubInstalledPlayerStrings.forLocale('fr-FR');

    expect(strings.defaultProfile, 'Joueur');
  });
}
