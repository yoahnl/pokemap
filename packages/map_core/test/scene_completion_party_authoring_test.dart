import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, String> parameters() => {
  'endingName': 'Victoire',
  'outcome': 'victory',
  'resultTitle': 'Bravo',
  'resultSummary': 'Parcours accompli',
  'includeCredits': 'false',
  'postGamePolicy': 'continueGame',
};

void main() {
  test('finishGame exposes an optional party recording boolean', () {
    final command = NarrativeCommandCatalog.canonical().byId(
      NarrativeCommandIds.finishGame,
    )!;
    final parameter = command.parameters
        .where((value) => value.id == 'recordParty')
        .single;
    expect(parameter.kind, NarrativeCommandParameterKind.boolean);
    expect(parameter.required, isFalse);
  });

  test(
    'finishGame builds true explicitly and defaults party recording off',
    () {
      Map<String, dynamic> build(Map<String, String> values) =>
          (buildScenePayloadForNarrativeCommand(
                    commandId: NarrativeCommandIds.finishGame,
                    parameters: values,
                  )
                  as SceneActionPayload)
              .consequence!
              .toJson();
      expect(build(parameters()).containsKey('recordParty'), isFalse);
      expect(
        build({
          ...parameters(),
          'recordParty': 'false',
        }).containsKey('recordParty'),
        isFalse,
      );
      expect(
        build({...parameters(), 'recordParty': 'true'})['recordParty'],
        isTrue,
      );
    },
  );

  test('finishGame refuses malformed authoring booleans', () {
    for (final value in ['', 'TRUE', 'yes', '1', 'null']) {
      expect(
        () => buildScenePayloadForNarrativeCommand(
          commandId: NarrativeCommandIds.finishGame,
          parameters: {...parameters(), 'recordParty': value},
        ),
        throwsFormatException,
      );
    }
  });

  test('rich finishGame projects and rebuilds without any loss', () {
    final original = richFinishGame();
    final values = sceneFinishGameAuthoringParameters(original);
    expect(values['recordParty'], 'false');
    expect(
      updateSceneFinishGameAuthoringParameters(original, values),
      original,
    );
  });

  test('changing party recording preserves every other finishGame field', () {
    final original = richFinishGame();
    final updated = updateSceneFinishGameAuthoringParameters(original, {
      ...sceneFinishGameAuthoringParameters(original),
      'recordParty': 'true',
    });
    expect(updated.toJson(), {...original.toJson(), 'recordParty': true});
  });

  test('editing result text preserves other locales details and credits', () {
    final original = richFinishGame();
    final updated = updateSceneFinishGameAuthoringParameters(original, {
      ...sceneFinishGameAuthoringParameters(original),
      'resultTitle': 'Nouveau titre',
      'resultTitleEn': 'New title',
    });
    final expected = original.toJson();
    (expected['result'] as Map)['title'] = {
      'fallback': 'Nouveau titre',
      'translations': {'en': 'New title', 'de': 'Sieg'},
    };
    expect(updated.toJson(), expected);
  });

  test('only an explicit ending name change creates a new ending identity', () {
    final original = richFinishGame();
    final updated = updateSceneFinishGameAuthoringParameters(original, {
      ...sceneFinishGameAuthoringParameters(original),
      'endingName': 'Autre fin',
    });
    expect(updated.toJson(), {
      ...original.toJson(),
      'endingId': 'ending.autre-fin',
    });
  });

  test('credits may be disabled explicitly without changing the result', () {
    final original = richFinishGame();
    final updated = updateSceneFinishGameAuthoringParameters(original, {
      ...sceneFinishGameAuthoringParameters(original),
      'includeCredits': 'false',
    });
    expect(
      updated.toJson(),
      Map<String, dynamic>.from(original.toJson())..remove('credits'),
    );
  });
}

SceneFinishGameConsequence richFinishGame() =>
    SceneConsequence.fromJson({
          'kind': 'finishGame',
          'contractVersion': 1,
          'endingId': 'custom.ending:champion',
          'outcome': 'victory',
          'commitPolicy': 'persistBeforePresentation',
          'result': {
            'title': {
              'fallback': 'Victoire',
              'translations': {'en': 'Victory', 'de': 'Sieg'},
            },
            'summary': {
              'fallback': 'Parcours accompli',
              'translations': {'de': 'Geschafft'},
            },
            'details': [
              {
                'fallback': 'Équipe gagnante',
                'translations': {'en': 'Winning team'},
              },
            ],
          },
          'credits': {
            'title': {
              'fallback': 'Crédits',
              'translations': {'de': 'Mitwirkende'},
            },
            'author': 'Auteur',
            'contributors': ['Une équipe'],
            'licenses': ['Une licence'],
            'endingLabel': {
              'fallback': 'Champion',
              'translations': {'de': 'Meister'},
            },
            'skippable': false,
          },
          'postGamePolicy': 'continueGame',
          'label': 'Titre conservé',
          'notes': 'Notes conservées',
        })
        as SceneFinishGameConsequence;
