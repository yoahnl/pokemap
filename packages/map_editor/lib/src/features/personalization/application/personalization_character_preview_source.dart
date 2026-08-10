import 'package:flutter_riverpod/flutter_riverpod.dart';

final class PersonalizationCharacterPreviewOption {
  const PersonalizationCharacterPreviewOption({
    required this.characterId,
    required this.displayName,
    required this.portraitPath,
    required this.expressionId,
  });

  final String characterId;
  final String displayName;
  final String? portraitPath;
  final String? expressionId;
}

abstract interface class PersonalizationCharacterPreviewSource {
  Future<List<PersonalizationCharacterPreviewOption>> load(String projectRoot);
}

final class PersonalizationCharacterPreviewFixtureSource
    implements PersonalizationCharacterPreviewSource {
  const PersonalizationCharacterPreviewFixtureSource();

  @override
  Future<List<PersonalizationCharacterPreviewOption>> load(
    String projectRoot,
  ) => Future<List<PersonalizationCharacterPreviewOption>>.value(
    const <PersonalizationCharacterPreviewOption>[
      PersonalizationCharacterPreviewOption(
        characterId: 'character-studio-placeholder',
        displayName: 'Léo',
        portraitPath: null,
        expressionId: 'happy',
      ),
    ],
  );
}

final personalizationCharacterPreviewSourceProvider =
    Provider<PersonalizationCharacterPreviewSource>(
      (ref) => const PersonalizationCharacterPreviewFixtureSource(),
    );

final personalizationCharacterPreviewOptionsProvider = FutureProvider
    .autoDispose
    .family<List<PersonalizationCharacterPreviewOption>, String>(
      (ref, projectRoot) => ref
          .watch(personalizationCharacterPreviewSourceProvider)
          .load(projectRoot),
    );
