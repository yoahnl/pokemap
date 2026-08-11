import 'personalization_preview_context_source.dart';

final class PersonalizationCharacterPreviewOption {
  const PersonalizationCharacterPreviewOption({
    required this.characterId,
    required this.displayName,
    required this.portraitPath,
    required this.expressionId,
    this.portraitBytes,
  });

  final String characterId;
  final String displayName;
  final String? portraitPath;
  final String? expressionId;
  final List<int>? portraitBytes;
}

abstract interface class PersonalizationCharacterPreviewSource {
  Future<List<PersonalizationCharacterPreviewOption>> load(String projectRoot);
}

final class PersonalizationCharacterPreviewFromContextSource
    implements PersonalizationCharacterPreviewSource {
  const PersonalizationCharacterPreviewFromContextSource({
    required PersonalizationPreviewContextSource contexts,
  }) : _contexts = contexts;

  final PersonalizationPreviewContextSource _contexts;

  @override
  Future<List<PersonalizationCharacterPreviewOption>> load(
    String projectRoot,
  ) async {
    final options = await _contexts.load(projectRoot);
    return List.unmodifiable(
      options
          .where(
            (option) =>
                option.kind ==
                PersonalizationPreviewContextKind.characterPortrait,
          )
          .map(
            (option) => PersonalizationCharacterPreviewOption(
              characterId: option.detail['characterId']! as String,
              displayName: option.detail['characterName']! as String,
              portraitPath: option.detail['portraitPath'] as String?,
              expressionId: option.detail['portraitStateId']! as String,
              portraitBytes: option.mediaBytes,
            ),
          ),
    );
  }
}
