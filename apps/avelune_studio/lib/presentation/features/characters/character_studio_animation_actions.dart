import 'package:map_core/map_core_domain.dart';

import 'character_studio_controller.dart';

extension CharacterStudioAnimationActions on CharacterStudioController {
  void setFrameDuration(EntityFacing direction, int index, int durationMs) {
    selectedDraft?.setDuration((animationState, direction), index, durationMs);
    notifyStateChanged();
  }
}
