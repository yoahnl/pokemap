import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/application/personalization_preview_fixtures.dart';

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
