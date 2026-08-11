import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/application/personalization_preview_fixtures.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  test('projects map, dialogue and battle data from project contexts', () {
    final map = PersonalizationProjectPreviewProjection.map(_map);
    final dialogue = PersonalizationProjectPreviewProjection.dialogue(
      _dialogue,
      portrait: _portrait,
      showChoices: false,
    );
    final battle = PersonalizationProjectPreviewProjection.battle(
      _encounter,
      state: PersonalizationBattlePreviewState.commands,
    );

    expect(map?.id, 'vermeil_village');
    expect(dialogue?.speaker, 'Léo');
    expect(dialogue?.text, contains('Bienvenue à Vermeil'));
    expect(battle?.enemy.speciesLabel, 'Roucool');
    expect(battle?.enemy.level, 7);
    expect(battle?.player.speciesLabel, 'Brindibou');
    expect(battle?.player.level, 8);
  });

  test('projects authored dialogue choices without hidden demo copy', () {
    final dialogue = PersonalizationProjectPreviewProjection.dialogue(
      _dialogue,
      portrait: _portrait,
      showChoices: true,
    );

    expect(dialogue?.choices.map((choice) => choice.label), <String>[
      'Partir explorer',
      'Rester au village',
    ]);
    expect(dialogue?.choices.singleWhere((choice) => choice.selected).index, 0);
  });

  test('projects a real character line with its authored speaker', () {
    final dialogue = PersonalizationProjectPreviewProjection.dialogue(
      _characterLineScenario,
      showChoices: true,
    );

    expect(dialogue?.mode, PlayerDialogueMode.line);
    expect(dialogue?.speaker, 'Léo');
    expect(dialogue?.text, 'Bienvenue à Vermeil.');
    expect(dialogue?.choices, isEmpty);
  });

  test('projects a real text-only line without borrowing a demo portrait', () {
    final dialogue = PersonalizationProjectPreviewProjection.dialogue(
      _textLineScenario,
      portrait: _portrait,
      showChoices: true,
    );

    expect(dialogue?.mode, PlayerDialogueMode.line);
    expect(dialogue?.speaker, isNull);
    expect(dialogue?.text, 'Le vent se lève sur le village.');
  });

  test('projects a real choice branch independently from demo toggles', () {
    final dialogue = PersonalizationProjectPreviewProjection.dialogue(
      _choiceScenario,
      showChoices: false,
    );

    expect(dialogue?.mode, PlayerDialogueMode.choices);
    expect(dialogue?.choices.map((choice) => choice.label), <String>[
      'Partir explorer',
      'Rester au village',
    ]);
  });

  test('keeps an orphan character line usable without inventing media', () {
    final dialogue = PersonalizationProjectPreviewProjection.dialogue(
      _scenarioWith(
        id: 'dialogueScenario:welcome_leo:0:3',
        detail: const <String, Object?>{
          'scenarioKind': 'characterLine',
          'stepIndex': 3,
          'characterId': 'personnage_inconnu',
          'text': 'Qui suis-je ?',
        },
      ),
      showChoices: false,
    );

    expect(dialogue?.speaker, 'Personnage Inconnu');
    expect(dialogue?.text, 'Qui suis-je ?');
  });

  test(
    'returns no projection when required project content is unavailable',
    () {
      expect(
        PersonalizationProjectPreviewProjection.dialogue(
          _dialogueWith(<String, Object?>{}),
          showChoices: false,
        ),
        isNull,
      );
      expect(
        PersonalizationProjectPreviewProjection.battle(
          _encounterWith(<String, Object?>{'entries': <Object?>[]}),
          state: PersonalizationBattlePreviewState.commands,
        ),
        isNull,
      );
    },
  );

  test('does not inject demo moves when the project has none', () {
    final battle = PersonalizationProjectPreviewProjection.battle(
      _encounterWith(<String, Object?>{
        'entries': _encounter.detail['entries'],
        'playerPokemon': <String, Object?>{
          'speciesId': 'brindibou',
          'level': 8,
          'currentHp': 24,
          'knownMoveIds': <String>[],
        },
      }),
      state: PersonalizationBattlePreviewState.moves,
    );

    expect(battle?.commands, isEmpty);
    expect(battle?.interactionsEnabled, isFalse);
    expect(battle?.prompt, contains('Aucune capacité'));
    expect(battle?.prompt, isNot(contains('Éco-Sphère')));
  });
}

final _map = PersonalizationPreviewContextOption(
  id: 'map:vermeil_village',
  kind: PersonalizationPreviewContextKind.map,
  sourceId: 'vermeil_village',
  label: 'Village de Vermeil',
  availability: 'ready',
  diagnosticCodes: const <String>[],
  detail: const <String, Object?>{
    'map': <String, Object?>{
      'id': 'vermeil_village',
      'name': 'Village de Vermeil',
      'size': <String, Object?>{'width': 12, 'height': 8},
      'version': 'v6',
    },
  },
);

final _dialogue = _dialogueWith(<String, Object?>{
  'dialogue': <String, Object?>{
    'source': <String, Object?>{
      'available': true,
      'text':
          'title: Start\n---\n<<portrait leo happy>>\n'
          'Bienvenue à Vermeil.\n'
          '-> Partir explorer\n  Alors allons-y !\n'
          '-> Rester au village\n  Prends ton temps.\n===',
    },
  },
});

final _characterLineScenario = _scenarioWith(
  id: 'dialogueScenario:welcome_leo:0:0',
  detail: const <String, Object?>{
    'scenarioKind': 'characterLine',
    'stepIndex': 0,
    'characterId': 'leo',
    'characterName': 'Léo',
    'portraitStateId': 'happy',
    'portraitAssetId': 'portrait-leo-happy',
    'portraitPath': 'characters/leo/happy.png',
    'text': 'Bienvenue à Vermeil.',
  },
);

final _textLineScenario = _scenarioWith(
  id: 'dialogueScenario:welcome_leo:0:1',
  detail: const <String, Object?>{
    'scenarioKind': 'textLine',
    'stepIndex': 1,
    'text': 'Le vent se lève sur le village.',
  },
);

final _choiceScenario = _scenarioWith(
  id: 'dialogueScenario:welcome_leo:0:2',
  detail: const <String, Object?>{
    'scenarioKind': 'choice',
    'stepIndex': 2,
    'choices': <Object?>[
      <String, Object?>{'label': 'Partir explorer'},
      <String, Object?>{'label': 'Rester au village'},
    ],
  },
);

PersonalizationPreviewContextOption _scenarioWith({
  required String id,
  required Map<String, Object?> detail,
}) => PersonalizationPreviewContextOption(
  id: id,
  kind: PersonalizationPreviewContextKind.dialogueScenario,
  sourceId: 'welcome_leo',
  label: 'Scène de dialogue',
  availability: 'ready',
  diagnosticCodes: const <String>[],
  detail: detail,
);

PersonalizationPreviewContextOption _dialogueWith(
  Map<String, Object?> detail,
) => PersonalizationPreviewContextOption(
  id: 'dialogue:welcome_leo',
  kind: PersonalizationPreviewContextKind.dialogue,
  sourceId: 'welcome_leo',
  label: 'Bienvenue de Léo',
  availability: 'ready',
  diagnosticCodes: const <String>[],
  detail: detail,
);

final _portrait = PersonalizationPreviewContextOption(
  id: 'characterPortrait:leo:happy',
  kind: PersonalizationPreviewContextKind.characterPortrait,
  sourceId: 'leo',
  label: 'Léo · Heureux',
  availability: 'ready',
  diagnosticCodes: const <String>[],
  detail: const <String, Object?>{
    'characterId': 'leo',
    'characterName': 'Léo',
    'portraitStateId': 'happy',
  },
);

final _encounter = _encounterWith(<String, Object?>{
  'entries': <Object?>[
    <String, Object?>{
      'speciesId': 'roucool',
      'minLevel': 7,
      'maxLevel': 7,
      'weight': 1,
    },
  ],
  'playerPokemon': <String, Object?>{
    'speciesId': 'brindibou',
    'level': 8,
    'currentHp': 24,
  },
});

PersonalizationPreviewContextOption _encounterWith(
  Map<String, Object?> detail,
) => PersonalizationPreviewContextOption(
  id: 'encounter:vermeil_grass',
  kind: PersonalizationPreviewContextKind.encounter,
  sourceId: 'vermeil_grass',
  label: 'Herbes de Vermeil',
  availability: 'ready',
  diagnosticCodes: const <String>[],
  detail: detail,
);
