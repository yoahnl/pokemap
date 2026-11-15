import 'package:map_core/map_core_domain.dart';

import 'narrative_authoring_exception.dart';

void requireDialogueLocalizationIdentities(
    DialogueLocalization? before, DialogueLocalization? after) {
  if (before == null || after == null) return;
  final kept = after.units.map((unit) => unit.id).toSet();
  final removedTexts = {
    for (final unit in before.units)
      if (!kept.contains(unit.id)) (unit.kind, unit.source),
  };
  final oldIds = before.units.map((unit) => unit.id).toSet();
  for (final unit in after.units) {
    if (!oldIds.contains(unit.id) &&
        removedTexts.contains((unit.kind, unit.source))) {
      throw NarrativeAuthoringException(
          'dialogue.localization_identity_changed',
          'Unchanged dialogue text must retain its existing identity.');
    }
  }
}
