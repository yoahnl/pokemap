part of 'character_studio_controller.dart';

extension _CharacterStudioSaving on CharacterStudioController {
  Future<bool> _save(CharacterStudioDraft draft) async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyStateChanged();
    var completed = 0;
    try {
      var current = project().characters
          .where((character) => character.id == draft.saved.id)
          .firstOrNull;
      if (current != draft.saved) {
        throw StateError(
          'Ce personnage a changé depuis son ouverture. Le brouillon est conservé.',
        );
      }
      final clips = draft.changedClips.toList();
      for (final key in clips) {
        final problem = draft.problemFor(key);
        if (problem != null) throw StateError(problem);
      }
      final boundsProblem = characterStudioFrameBoundsProblem(project(), draft);
      if (boundsProblem != null) throw StateError(boundsProblem);
      if (draft.name != draft.saved.name ||
          draft.frameWidth != draft.saved.frameWidth ||
          draft.frameHeight != draft.saved.frameHeight ||
          draft.contactShadow != draft.saved.contactShadow) {
        final manifest = await mutate('characterStudio.character.update', {
          'characterId': draft.saved.id,
          if (draft.name != draft.saved.name) 'name': draft.name,
          if (draft.frameWidth != draft.saved.frameWidth)
            'frameWidth': draft.frameWidth,
          if (draft.frameHeight != draft.saved.frameHeight)
            'frameHeight': draft.frameHeight,
          if (draft.contactShadow != draft.saved.contactShadow)
            'contactShadow': draft.contactShadow,
        });
        completed++;
        current = manifest.characters.firstWhere(
          (character) => character.id == draft.saved.id,
        );
        draft.accept(current);
      }
      for (final key in clips) {
        if (!draft.clipChanged(key)) continue;
        final frames = draft.completeFrames(key);
        final manifest = await mutate(
          frames.isEmpty
              ? 'characterStudio.animationClip.delete'
              : 'characterStudio.animationClip.upsert',
          {
            'characterId': draft.saved.id,
            'kind': 'system',
            'state': key.$1 == CharacterAnimationState.bicycleIdle
                ? 'bicycle_idle'
                : key.$1.name,
            'direction': key.$2.name,
            if (frames.isNotEmpty) 'sourceAssetId': draft.sourceAssetIdFor(key),
            if (frames.isNotEmpty)
              'frames': [for (final frame in frames) frame.toJson()],
          },
        );
        completed++;
        current = manifest.characters.firstWhere(
          (character) => character.id == draft.saved.id,
        );
        draft.accept(current);
      }
      return !draft.dirty;
    } catch (failure) {
      error = completed == 0
          ? '$failure'
          : '$completed modification(s) enregistrée(s), puis échec : $failure';
      return false;
    } finally {
      saving = false;
      notifyStateChanged();
    }
  }
}
