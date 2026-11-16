import '../../story_draft/domain/story_dialogue_source.dart';

final class DialogueCatalogDocument {
  const DialogueCatalogDocument({
    required this.dialogue,
    required this.sceneIds,
    required this.notCovered,
  });

  final StoryDialogueSource dialogue;
  final List<String> sceneIds;
  final List<String> notCovered;
}

final class DialogueCatalogLanguages {
  const DialogueCatalogLanguages({this.locales = const [], this.fallback});

  final List<String> locales;
  final String? fallback;
}

abstract interface class DialogueCatalogPort {
  Future<DialogueCatalogDocument> document(String id);

  Future<DialogueCatalogLanguages> languages();
}
