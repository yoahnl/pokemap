part of 'character_studio_controller.dart';

extension CharacterStudioLifecycle on CharacterStudioController {
  CharacterStudioDraft? draftFor(String characterId) => _drafts[characterId];

  Future<bool> saveOwner(String characterId) async {
    final draft = _drafts[characterId];
    return draft == null || !draft.dirty ? true : _save(draft);
  }

  void discardOwner(String characterId) {
    _drafts[characterId]?.discard();
    notifyStateChanged();
  }

  void reconcileCatalog(
    ProjectManifest manifest, {
    Set<String> removedIds = const {},
  }) {
    final characters = {
      for (final character in manifest.characters) character.id: character,
    };
    var changed = false;
    for (final id in _drafts.keys.toList()) {
      final draft = _drafts[id]!;
      final current = characters[id];
      if (removedIds.contains(id) || (current == null && !draft.dirty)) {
        _drafts.remove(id);
        changed = true;
      } else if (!draft.dirty && current != null && current != draft.saved) {
        draft.saved = current;
        draft.name = current.name;
        draft.frameWidth = current.frameWidth;
        draft.frameHeight = current.frameHeight;
        changed = true;
      }
    }
    if (selectedId != null && !characters.containsKey(selectedId)) {
      selectedId = null;
      playing = false;
      changed = true;
    }
    if (changed) notifyStateChanged();
  }
}
