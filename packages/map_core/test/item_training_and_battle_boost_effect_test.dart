import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final value in <Map<String, dynamic>>[
    {
      'kind': 'vitamin',
      'stat': 'attack',
      'amount': 10,
      'maximumPerStat': 100,
      'maximumTotal': 510,
      'friendshipGainLow': 5,
      'friendshipGainMedium': 3,
      'friendshipGainHigh': 2,
    },
    {'kind': 'battle_boost', 'stat': 'attack', 'stages': 1},
    {'kind': 'battle_preparation', 'effect': 'focusEnergy', 'turns': null},
    {'kind': 'battle_preparation', 'effect': 'mist', 'turns': 5},
  ]) {
    test('${value['kind']} retains its authored settings', () {
      final effect = ProjectItemEffectDefinition.fromJson(value);
      expect(effect.toJson(), value);
      expect(ProjectItemEffectDefinition.fromJson(effect.toJson()), effect);
    });
  }

  for (final value in <Map<String, dynamic>>[
    {'kind': 'vitamin', 'stat': 'attack', 'amount': 0, 'maximumPerStat': 100},
    {'kind': 'vitamin', 'stat': 'attack', 'amount': 10, 'maximumPerStat': 256},
    {'kind': 'battle_boost', 'stat': 'attack', 'stages': 7},
    {'kind': 'battle_boost', 'stat': 'hp', 'stages': 1},
    {'kind': 'battle_preparation', 'effect': 'mist', 'turns': 0},
    {'kind': 'battle_preparation', 'effect': 'focusEnergy', 'turns': 5},
  ]) {
    test('rejects malformed training or battle boost $value', () {
      expect(() => ProjectItemEffectDefinition.fromJson(value), throwsA(anything));
    });
  }
}
