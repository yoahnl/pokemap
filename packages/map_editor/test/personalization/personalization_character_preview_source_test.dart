import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  test(
    'character preview fixture is replaceable through its provider',
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
