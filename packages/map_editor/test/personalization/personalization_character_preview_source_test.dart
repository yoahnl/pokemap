import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'character preview source is replaceable through its provider',
    () async {
      final source = _CharacterSource();
      final container = ProviderContainer(
        overrides: [
          personalizationCharacterPreviewSourceProvider.overrideWithValue(
            source,
          ),
        ],
      );
      addTearDown(container.dispose);

      final options = await container.read(
        personalizationCharacterPreviewOptionsProvider('/project').future,
      );

      expect(source.loadedRoot, '/project');
      expect(options, hasLength(1));
      expect(options.single.characterId, 'leo');
      expect(options.single.id, 'leo:happy');
      expect(options.single.displayName, 'Léo');
      expect(options.single.portraitPath, 'characters/leo/happy.png');
      expect(options.single.expressionId, 'happy');
    },
  );

  test('character preview data never enters presentation json', () {
    const option = PersonalizationCharacterPreviewOption(
      id: 'leo:happy',
      characterId: 'leo',
      displayName: 'Léo',
      portraitPath: 'characters/leo/happy.png',
      expressionId: 'happy',
      expressionLabel: 'Joyeux',
      workspaceRevision: 'revision',
    );
    final encoded = jsonEncode(const ProjectPresentationProfile().toJson());

    expect(option.characterId, 'leo');
    expect(encoded, isNot(contains('characterId')));
    expect(encoded, isNot(contains('portraitPath')));
    expect(encoded, isNot(contains('expressionId')));
  });

  test('catalog projection keeps characters whose portrait is missing', () {
    final options = PersonalizationCharacterPreviewCatalogProjection.project(
      workspaceRevision: 'revision-1',
      portraitStates: const <Map<String, Object?>>[
        <String, Object?>{
          'id': 'neutral',
          'displayName': 'Neutre',
          'sortOrder': 0,
        },
      ],
      characters: const <Map<String, Object?>>[
        <String, Object?>{
          'id': 'nox',
          'name': 'Nox',
          'sortOrder': 0,
          'portraits': <Object?>[],
        },
      ],
      assets: const <String, PersonalizationCharacterPreviewAsset>{},
    );

    expect(options, hasLength(1));
    expect(options.single.id, 'nox:neutral');
    expect(options.single.expressionLabel, 'Neutre');
    expect(options.single.portraitPath, isNull);
    expect(options.single.diagnosticCodes, contains('portraitMissing'));
  });

  test('catalog projection exposes deleted expressions without ambiguity', () {
    final options = PersonalizationCharacterPreviewCatalogProjection.project(
      workspaceRevision: 'revision-2',
      portraitStates: const <Map<String, Object?>>[
        <String, Object?>{
          'id': 'happy',
          'displayName': 'Joyeux',
          'sortOrder': 0,
        },
      ],
      characters: const <Map<String, Object?>>[
        <String, Object?>{
          'id': 'leo',
          'name': 'Léo',
          'sortOrder': 0,
          'portraits': <Object?>[
            <String, Object?>{
              'portraitStateId': 'happy',
              'assetId': 'leo-happy',
            },
            <String, Object?>{
              'portraitStateId': 'angry',
              'assetId': 'leo-angry',
            },
          ],
        },
      ],
      assets: const <String, PersonalizationCharacterPreviewAsset>{
        'leo-happy': PersonalizationCharacterPreviewAsset(
          path: 'characters/leo-happy.png',
          bytes: <int>[1],
        ),
        'leo-angry': PersonalizationCharacterPreviewAsset(
          path: 'characters/leo-angry.png',
          bytes: <int>[2],
        ),
      },
    );

    expect(options.map((option) => option.id), <String>[
      'leo:happy',
      'leo:angry',
    ]);
    expect(options.first.expressionLabel, 'Joyeux');
    expect(options.last.expressionLabel, 'angry');
    expect(options.last.diagnosticCodes, contains('portraitStateDeleted'));
  });

  test(
    'canonical source reads project contexts without demo fallback',
    () async {
      final queries = AuthoringQueryAdapter(
        fileReader: const EditorProjectFileReader(),
      );
      addTearDown(queries.closeAll);
      final source = AuthoringPersonalizationPreviewContextSource(
        queries: queries,
      );
      final characterSource = AuthoringPersonalizationCharacterPreviewSource(
        queries: queries,
      );
      final projectRoot = p.join(
        Directory.current.parent.parent.path,
        'examples',
        'playable_runtime_host',
        'golden_personalization_v3',
      );

      final contexts = await source.load(projectRoot);
      final characterOptions = await characterSource.load(projectRoot);

      expect(
        contexts.map((context) => context.id),
        containsAll(<String>{
          'map:vermeil_village',
          'dialogue:welcome_leo',
          'dialogueScenario:welcome_leo:0:0',
          'dialogueScenario:welcome_leo:0:1',
          'dialogueScenario:welcome_leo:0:2',
          'encounter:vermeil_grass',
          'characterPortrait:leo:happy',
        }),
      );
      final portrait = contexts.firstWhere(
        (context) => context.id == 'characterPortrait:leo:happy',
      );
      expect(portrait.isReady, isTrue);
      expect(
        portrait.detail['portraitPath'],
        'assets/characters/leo-happy.png',
      );
      expect(portrait.mediaBytes, isNotEmpty);
      final dialogue = contexts.firstWhere(
        (context) => context.id == 'dialogue:welcome_leo',
      );
      expect(
        ((dialogue.detail['dialogue']! as Map)['source']! as Map)['text'],
        contains('Bienvenue à Vermeil'),
      );
      final characterLine = contexts.firstWhere(
        (context) => context.id == 'dialogueScenario:welcome_leo:0:0',
      );
      expect(characterLine.detail['scenarioKind'], 'characterLine');
      expect(characterLine.detail['characterName'], 'Léo');
      expect(characterLine.detail['portraitStateId'], 'happy');
      expect(characterLine.mediaBytes, isNotEmpty);
      final textLine = contexts.firstWhere(
        (context) => context.id == 'dialogueScenario:welcome_leo:0:1',
      );
      expect(textLine.detail['scenarioKind'], 'textLine');
      expect(textLine.detail['text'], contains('Le vent se lève'));
      expect(textLine.mediaBytes, isNull);
      final choice = contexts.firstWhere(
        (context) => context.id == 'dialogueScenario:welcome_leo:0:2',
      );
      expect(choice.detail['scenarioKind'], 'choice');
      expect(
        (choice.detail['choices']! as List<Object?>).map(
          (raw) => (raw! as Map)['label'],
        ),
        <String>['Partir explorer', 'Rester au village'],
      );
      final encounter = contexts.firstWhere(
        (context) => context.id == 'encounter:vermeil_grass',
      );
      expect(
        (encounter.detail['playerPokemon']! as Map)['speciesId'],
        'brindibou',
      );
      expect(
        contexts.map((context) => context.id),
        isNot(contains('character-studio-placeholder')),
      );
      expect(
        characterOptions.map((option) => option.id),
        contains('leo:happy'),
      );
      final happy = characterOptions.firstWhere(
        (option) => option.id == 'leo:happy',
      );
      expect(happy.expressionLabel, 'Heureux');
      expect(happy.portraitPath, 'assets/characters/leo-happy.png');
      expect(happy.portraitBytes, isNotEmpty);
      expect(happy.workspaceRevision, isNotEmpty);
    },
  );
}

final class _CharacterSource implements PersonalizationCharacterPreviewSource {
  String? loadedRoot;

  @override
  Future<List<PersonalizationCharacterPreviewOption>> load(
    String projectRoot,
  ) async {
    loadedRoot = projectRoot;
    return const <PersonalizationCharacterPreviewOption>[
      PersonalizationCharacterPreviewOption(
        id: 'leo:happy',
        characterId: 'leo',
        displayName: 'Léo',
        portraitPath: 'characters/leo/happy.png',
        expressionId: 'happy',
        expressionLabel: 'Joyeux',
        workspaceRevision: 'revision',
      ),
    ];
  }
}
