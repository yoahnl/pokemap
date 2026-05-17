import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('effect matrix exposes hook families for PSDK migration gates', () {
    final matrix = File('../../reports/previous/psdk-effect-porting-matrix.md');

    expect(matrix.existsSync(), isTrue);
    final content = matrix.readAsStringSync();

    expect(content, contains('| Hook families |'));
    expect(content, contains('`Attract`'));
    expect(content, contains('`HealBlock`'));
    expect(content, contains('`Imprison`'));
    expect(content, contains('`Protect`'));
    expect(content, contains('`Nightmare`'));
    expect(content, contains('`PerishSong`'));
    expect(content, contains('`Disable`'));
    expect(content, contains('`Encore`'));
    expect(content, contains('`Taunt`'));
    expect(content, contains('`Torment`'));
    expect(content, contains('`move_prevention`'));
    expect(content, contains('`ability_immunity`'));
    expect(content, contains('`accuracy`'));
    expect(content, contains('`two_turn_shortcut`'));
    expect(content, contains('Object-backed ProtectEffect'));
    expect(content, contains('Object-backed AttractEffect'));
    expect(content, contains('Object-backed DisableEffect'));
    expect(content, contains('Object-backed EncoreEffect'));
    expect(content, contains('Object-backed HealBlockEffect'));
    expect(content, contains('Object-backed ImprisonEffect'));
    expect(content, contains('Object-backed TauntEffect'));
    expect(content, contains('Object-backed TormentEffect'));
    expect(content, contains('Object-backed NightmareEffect'));
    expect(content, contains('Object-backed PerishSongEffect'));
    expect(content, matches(RegExp(r'\| `Imposter` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `Leftovers` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `BlackSludge` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `AirBalloon` \|.*\| `ported` \|')));
    expect(
      content,
      matches(RegExp(r'\| `ChoiceItemMultiplier` \|.*\| `ported` \|')),
    );
    expect(content, matches(RegExp(r'\| `ExpertBelt` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `StatusBerry` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `Burn` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `Disable` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `Embargo` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `Torment` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `Nightmare` \|.*\| `ported` \|')));
    expect(content, matches(RegExp(r'\| `PerishSong` \|.*\| `ported` \|')));
    for (final effectName in <String>[
      'Autotomize',
      'AuroraVeil',
      'BurnUp',
      'Charge',
      'DragonCheer',
      'Electrify',
      'FocusEnergy',
      'Foresight',
      'GlaiveRush',
      'Gravity',
      'LaserFocus',
      'LightScreen',
      'LuckyChant',
      'MagicRoom',
      'MagnetRise',
      'Minimize',
      'Mist',
      'MiracleEye',
      'MudSport',
      'Rage',
      'Reflect',
      'Safeguard',
      'Spikes',
      'StealthRock',
      'StickyWeb',
      'Stockpile',
      'Tailwind',
      'TarShot',
      'Telekinesis',
      'ToxicSpikes',
      'Transform',
      'TrickRoom',
      'UpRoar',
      'WaterSport',
    ]) {
      expect(
        content,
        matches(RegExp('\\| `$effectName` \\|.*\\| `ported` \\|')),
      );
    }
    expect(content, matches(RegExp(r'\| `WonderRoom` \|.*\| `partial` \|')));
  });
}
