import 'package:flutter/material.dart';
import '../../../features/events/application/event_workspace_controller.dart';
import '../../../features/scenes/application/scene_workspace_controller.dart';
import '../map_workspace/workspace_actions.dart';
import 'event_labels.dart';

Future<String?> launchPublishedEvent({
  required BuildContext context,
  required EventWorkspaceController events,
  required SceneWorkspaceController? scenes,
  required String mapId,
  required String eventId,
  required StudioRuntimeBuilder runtimeBuilder,
}) async {
  final workspace = events.workspace;
  try {
    await events.flushEdits?.call();
  } catch (error) {
    return 'L’édition en cours ne peut pas être validée : $error';
  }
  if (!context.mounted || workspace.isDisposed) return null;
  final project = workspace.project;
  final record = events.record(eventId);
  if (project == null) return 'Le projet n’est plus disponible.';
  if (events.activeId != eventId ||
      eventMapId(record == null ? null : eventSource(record)) != mapId) {
    return 'Le contexte a changé pendant la préparation du test.';
  }
  final sceneId = record == null ? null : eventSceneId(record);
  String? problem() {
    if (events.dirty || events.busy || workspace.saving) {
      return 'Enregistrez les événements avant de tester leur version publiée.';
    }
    if (scenes?.sessions[sceneId]?.dirty == true || scenes?.busy == true) {
      return 'La scène liée est modifiée. Ouvrez-la et enregistrez-la avant le test.';
    }
    if (workspace.documents[mapId]?.dirty == true) {
      return 'La carte source est modifiée. Enregistrez cette carte avant le test.';
    }
    if (events.narrative.dirty || events.narrative.saving) {
      return 'Des documents narratifs sont modifiés. Enregistrez-les avant le test.';
    }
    return null;
  }

  if (problem() case final error?) return error;
  if (record?.enabledOrNull != true) {
    return 'Configurez et activez cet événement, puis enregistrez-le.';
  }
  final entries = project.maps.where((e) => e.id == mapId);
  if (entries.length != 1) return 'Carte source absente ou ambiguë.';
  try {
    final freshProject = await workspace.port.loadProject(workspace.session);
    final freshMap = await workspace.port.loadMap(
      workspace.session,
      entries.single,
    );
    if (!context.mounted || workspace.isDisposed) return null;
    if (events.activeId != eventId ||
        workspace.project != project ||
        events.record(eventId) != record) {
      return 'Le contexte a changé pendant la préparation du test.';
    }
    if (problem() case final error?) return error;
    final freshRecord = freshProject.eventRegistry?.records
        .where((r) => r.id == eventId)
        .firstOrNull;
    if (freshRecord != record || freshProject != project) {
      return 'Le projet publié a changé. Rechargez ses références avant de tester.';
    }
    final document = workspace.documents[mapId];
    if (document != null && document.base.revision != freshMap.revision) {
      return 'La carte publiée a changé. Rechargez-la avant de tester.';
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (route) => runtimeBuilder(
          entries.single,
          freshMap.revision,
          () => Navigator.pop(route),
        ),
      ),
    );
    return null;
  } catch (error) {
    return 'Préparation du test impossible : $error';
  }
}
