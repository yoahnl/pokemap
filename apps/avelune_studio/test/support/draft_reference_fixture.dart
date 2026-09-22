import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:map_core/map_core.dart';

import 'ui12_world_harness.dart';

/// What the screen feeds the index: the events still dirty in their editor and
/// the world rules not written yet.
MapDraftReferenceSources sourcesOf(
  Ui12WorldHarness h, {
  EventWorkspaceController? events,
}) => MapDraftReferenceSources(
  eventDrafts: [
    if (events != null)
      for (final id in events.dirtyIds) ?events.record(id),
  ],
  ruleTargets: [
    for (final draft in h.world.pendingRules.values)
      if (draft.target?.entityId case final entityId?)
        (
          mapId: draft.target!.mapId,
          kind: MapDraftReferenceKind.entity,
          id: entityId,
        ),
  ],
);

Future<MapEntity> signOn(Ui12WorldHarness h, String mapId) async {
  await h.maps.activate(
    h.maps.project!.maps.firstWhere((entry) => entry.id == mapId),
  );
  return MapEntityEditingCommands(
    h.maps.active!,
    h.maps.project!,
  ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
}
