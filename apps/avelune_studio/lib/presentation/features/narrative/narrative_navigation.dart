import 'package:map_core/map_core_domain.dart';
import '../../../features/map_workspace/application/trigger_editing_commands.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';

String? workspaceNarrativeError(
  NarrativeWorkspaceController? controller, {
  required bool narrativePage,
}) =>
    controller?.publicationError ?? (narrativePage ? controller?.error : null);

String? guardNarrativeHistory(
  NarrativeWorkspaceController narrative,
  MapData before,
  MapData after,
) {
  for (final edit in narrative.sessions.values.where(
    (s) => s.dirty && s.document.current.id == before.id,
  )) {
    final source = edit.current.interaction.source.toJson();
    if (source['entityId'] != null &&
            !after.entities.any((e) => e.id == source['entityId']) ||
        source['triggerId'] != null &&
            !after.triggers.any((t) => t.id == source['triggerId'])) {
      return 'Cette action supprimerait la source d’une interaction en cours. Enregistrez ou annulez son brouillon.';
    }
  }
  return null;
}

Future<void> openNarrativeZone(
  NarrativeWorkspaceController narrative,
  MapRect area,
) async {
  final document = narrative.workspace.active;
  if (document == null) return;
  final trigger = MapTrigger(
    id: narrative.identity('zone'),
    name: 'Zone d’histoire',
    type: TriggerType.event,
    area: area,
  );
  TriggerEditingCommands(document, narrative.project).add(trigger);
  await narrative.openSource(
    document,
    NarrativeEventSourceRef.triggerEnter(document.current.id, trigger.id),
    trigger.name,
  );
}
