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
      expect(options.single.displayName, 'Léo');
      expect(options.single.portraitPath, 'characters/leo/happy.png');
      expect(options.single.expressionId, 'happy');
    },
  );

  test('character preview data never enters presentation json', () {
    const option = PersonalizationCharacterPreviewOption(
      characterId: 'leo',
      displayName: 'Léo',
      portraitPath: 'characters/leo/happy.png',
      expressionId: 'happy',
    );
    final encoded = jsonEncode(const ProjectPresentationProfile().toJson());

    expect(option.characterId, 'leo');
    expect(encoded, isNot(contains('characterId')));
    expect(encoded, isNot(contains('portraitPath')));
    expect(encoded, isNot(contains('expressionId')));
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
      final projectRoot = p.join(
        Directory.current.parent.parent.path,
        'examples',
        'playable_runtime_host',
        'golden_personalization_v3',
      );

      final contexts = await source.load(projectRoot);

      expect(
        contexts.map((context) => context.id),
        containsAll(<String>{
          'map:vermeil_village',
          'dialogue:welcome_leo',
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
      expect(
        contexts.map((context) => context.id),
        isNot(contains('character-studio-placeholder')),
      );
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
        characterId: 'leo',
        displayName: 'Léo',
        portraitPath: 'characters/leo/happy.png',
        expressionId: 'happy',
      ),
    ];
  }
}
