import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const payload = <String, dynamic>{
    'kind': 'givePokemonFromCatalog',
    'speciesId': 'fixture_species',
    'formId': 'fixture_form',
    'level': 5,
  };

  test('catalog gift has a closed typed round trip', () {
    final consequence = SceneConsequence.fromJson(payload);
    expect(consequence.kind.name, 'givePokemonFromCatalog');
    expect(consequence.toJson(), payload);
    expect(SceneConsequence.fromJson(consequence.toJson()), consequence);
  });

  test('guided catalog gift builder rejects individual overrides', () {
    const parameters = {
      'speciesId': 'fixture_species',
      'formId': 'fixture_form',
      'level': '5',
    };
    expect(
      buildScenePayloadForNarrativeCommand(
        commandId: NarrativeCommandIds.givePokemonFromCatalog,
        parameters: parameters,
      ),
      SceneActionPayload.consequence(SceneConsequence.fromJson(payload)),
    );
    for (final field in ['currentHp', 'natureId', 'abilityId']) {
      expect(
        () => buildScenePayloadForNarrativeCommand(
          commandId: NarrativeCommandIds.givePokemonFromCatalog,
          parameters: {...parameters, field: 'override'},
        ),
        throwsFormatException,
      );
    }
  });

  test(
    'catalog gift rejects authored individual overrides and invalid values',
    () {
      for (final field in ['currentHp', 'natureId', 'abilityId', 'nickname']) {
        expect(
          () => SceneConsequence.fromJson({...payload, field: 1}),
          throwsFormatException,
        );
      }
      for (final value in [0, 101, '5', 5.5]) {
        expect(
          () => SceneConsequence.fromJson({...payload, 'level': value}),
          throwsFormatException,
        );
      }
      for (final field in ['speciesId', 'formId']) {
        expect(
          () => SceneConsequence.fromJson({...payload, field: ''}),
          throwsFormatException,
        );
      }
    },
  );
}
