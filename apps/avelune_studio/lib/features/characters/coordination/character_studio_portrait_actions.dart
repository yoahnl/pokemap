import 'character_studio_controller.dart';

extension CharacterStudioPortraitActions on CharacterStudioController {
  Future<bool> createPortraitState(String name) async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyStateChanged();
    try {
      await mutate('characterStudio.portraitState.create', {
        'displayName': name.trim(),
      });
      return true;
    } catch (failure) {
      error = '$failure';
      return false;
    } finally {
      saving = false;
      notifyStateChanged();
    }
  }
}
