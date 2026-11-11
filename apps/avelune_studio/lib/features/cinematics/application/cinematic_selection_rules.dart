import 'package:map_core/map_core_domain.dart';

import 'cinematic_preview_transport.dart';
import 'cinematic_timeline_rules.dart';

void selectOnlyCinematicStep(
  Set<String> selection,
  CinematicPreviewTransport transport,
  String stepId,
) {
  selection
    ..clear()
    ..add(stepId);
  seekCinematicStep(transport, stepId);
}

String? reconcileCinematicSelection(
  CinematicAsset asset,
  Set<String> selection,
  String? actorId,
) {
  final ids = asset.timeline.steps.map((step) => step.id).toSet();
  selection.removeWhere((id) => !ids.contains(id));
  if (asset.requiredActors.any((actor) => actor.actorId == actorId)) {
    return actorId;
  }
  return asset.requiredActors.firstOrNull?.actorId;
}

int cinematicPasteIndex(CinematicAsset asset, String? anchorStepId) {
  final steps = asset.timeline.steps;
  final index = steps.indexWhere((step) => step.id == anchorStepId);
  return index < 0 ? steps.length : index + 1;
}
