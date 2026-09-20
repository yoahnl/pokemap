part of 'narrative_workspace_controller.dart';

extension NarrativeSessionCoexistence on NarrativeWorkspaceController {
  String? interactionAccessProblem(String eventId) {
    final session = sessions[eventId];
    return session != null &&
            (session.dirty || _publishingInteractions.contains(eventId))
        ? 'Cette interaction possède un brouillon simplifié. Enregistrez-le ou abandonnez explicitement ses modifications avant de modifier cet événement.'
        : null;
  }

  String? interactionBaseProblem(InteractionEditSession edit) {
    final eventId = edit.current.interaction.id;
    final stored = project.eventRegistry?.records
        .where((record) => record.id == eventId)
        .firstOrNull;
    return eventAccessProblem?.call(eventId) ??
        (edit.eventBaseKnown && stored != edit.baseEvent
            ? 'L’événement a changé ou a disparu. Votre brouillon simplifié est conservé ; abandonnez-le explicitement pour recharger la version actuelle.'
            : null);
  }

  void reconcileCleanInteractionSessions() {
    if (_disposed || workspace.isDisposed || saving) return;
    final removed = sessions.values.where((session) {
      if (session.dirty) return false;
      final record = project.eventRegistry?.records
          .where((record) => record.id == session.current.interaction.id)
          .firstOrNull;
      final scene = project.scenes
          .where((scene) => scene.id == session.current.interaction.sceneId)
          .firstOrNull;
      return (session.eventBaseKnown && session.baseEvent != record) ||
          (session.sceneBaseKnown && session.baseScene != scene);
    }).toSet();
    if (removed.isEmpty) return;
    sessions.removeWhere((_, session) => removed.contains(session));
    if (removed.contains(active)) {
      active = null;
      error =
          'L’interaction a changé ou a disparu. Rouvrez sa version actuelle depuis la bibliothèque.';
    }
    changed();
  }

  bool discardInteraction(String id) {
    if (saving) return false;
    final removed = sessions.remove(id);
    if (identical(active, removed)) active = null;
    changed();
    return removed != null;
  }
}
