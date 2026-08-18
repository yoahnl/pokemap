import 'package:map_battle/src/data/psdk_fight_parity_audit.dart';
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  test('effect parity exposes hook families for PSDK migration gates',
      () async {
    final sources = resolvePsdkSourceDirectories();
    final effects = await loadPsdkEffectParityEntries(
      sources.psdkBattleDirectory,
    );
    final effectsByName = <String, List<PsdkEffectParityEntry>>{};
    for (final effect in effects) {
      effectsByName.putIfAbsent(effect.effectName, () => []).add(effect);
    }

    final hookFamilies =
        effects.expand((effect) => effect.hookFamilies).toSet();
    expect(
      hookFamilies,
      containsAll(<String>{
        'move_prevention',
        'ability_immunity',
        'accuracy',
        'two_turn_shortcut',
      }),
    );

    for (final effectName in <String>{
      'Attract',
      'HealBlock',
      'Imprison',
      'Protect',
      'Nightmare',
      'PerishSong',
      'Disable',
      'Encore',
      'Taunt',
      'Torment',
      'Imposter',
      'Leftovers',
      'BlackSludge',
      'AirBalloon',
      'ChoiceItemMultiplier',
      'ExpertBelt',
      'StatusBerry',
      'Burn',
      'Embargo',
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
      'WonderRoom',
    }) {
      final matchingEffects = effectsByName[effectName];
      expect(matchingEffects, isNotNull, reason: effectName);
      expect(
        matchingEffects,
        everyElement(
          isA<PsdkEffectParityEntry>().having(
            (effect) => effect.status,
            'status',
            PsdkPortStatus.ported,
          ),
        ),
        reason: effectName,
      );
    }
  },
    skip: psdkSourcesAvailable()
        ? null
        : 'Sources PSDK absentes : ce cas lit un checkout hors depot.',
  );
}
