part of 'character_studio_controller.dart';

extension CharacterStudioDraftDependencies on CharacterStudioController {
  Iterable<ProjectCharacterEntry> get dirtyCharacters => _drafts.values
      .where((draft) => draft.dirty)
      .map((draft) => draft.previewCharacter);
}
