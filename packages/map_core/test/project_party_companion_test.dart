import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('companion configuration round trips arbitrary species and forms', () {
    final input = {
      'enabled': true,
      'mappings': [
        {'speciesId': 'clockbird', 'formId': 'bronze', 'characterId': 'guide'},
        {
          'speciesId': 'flower',
          'formId': 'night',
          'characterId': 'flower-night',
        },
      ],
    };
    final value = ProjectPartyCompanionConfig.fromJson(input);
    expect(value.toJson(), input);
    expect(value.resolve('flower', 'night')!.characterId, 'flower-night');
    expect(value.resolve('flower', 'day'), isNull);
    expect(value, ProjectPartyCompanionConfig.fromJson(input));
  });

  test(
    'unknown keys duplicate species forms and empty identities fail closed',
    () {
      for (final input in [
        {'enabled': true, 'mappings': [], 'unknown': true},
        {
          'enabled': true,
          'mappings': [
            {'speciesId': '', 'formId': 'base', 'characterId': 'guide'},
          ],
        },
        {
          'enabled': true,
          'mappings': [
            for (var i = 0; i < 2; i++)
              {
                'speciesId': 'clockbird',
                'formId': 'base',
                'characterId': 'guide',
              },
          ],
        },
        {'enabled': 'yes', 'mappings': []},
      ]) {
        expect(
          () => ProjectPartyCompanionConfig.fromJson(input),
          throwsFormatException,
        );
      }
    },
  );
}
