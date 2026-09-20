part of 'narrative_workspace_controller.dart';

extension NarrativeSessionCoexistence on NarrativeWorkspaceController {
  String? interactionAccessProblem(String eventId) {
    final session = sessions[eventId];
    return session != null &&
            (session.dirty || _publishingInteractions.contains(eventId))
        ? 'Cette interaction possède un brouillon simplifié. Enregistrez-le ou abandonnez explicitement ses modifications avant de modifier cet événement.'
        : null;
  }

  String? dialogueInteractionAccessProblem(String id) {
    final owners = sessions.values.where(
      (s) =>
          s.current.dialogue.entry.id == id &&
          (s.dirty ||
              _publishingInteractions.contains(s.current.interaction.id)),
    );
    return owners.isEmpty
        ? null
        : 'Ce dialogue est partagé avec une interaction simplifiée modifiée. Enregistrez-la ou abandonnez explicitement son brouillon.';
  }

  String? sharedDialogueAccessProblem(String id, String eventId) {
    return sessions.values.any(
          (s) =>
              s.current.dialogue.entry.id == id &&
              s.current.interaction.id != eventId &&
              (s.dirty ||
                  _publishingInteractions.contains(s.current.interaction.id)),
        )
        ? 'Ce dialogue possède déjà une interaction simplifiée modifiée. Reprenez cette interaction avant de continuer.'
        : null;
  }

  void invalidateCleanDialogueSessions(
    String id, {
    Set<InteractionEditSession> except = const {},
  }) {
    final removed = sessions.values
        .where(
          (s) =>
              !s.dirty &&
              s.current.dialogue.entry.id == id &&
              !except.contains(s),
        )
        .toSet();
    sessions.removeWhere((_, s) => removed.contains(s));
    if (removed.contains(active)) active = null;
    if (except.isEmpty) _sourceRevisions.remove(id);
  }

  String? interactionBaseProblem(InteractionEditSession edit) {
    final eventId = edit.current.interaction.id;
    final stored = project.eventRegistry?.records
        .where((record) => record.id == eventId)
        .firstOrNull;
    return cinematicInteractionProblem(edit) ??
        dialogueAccessProblem?.call(edit.current.dialogue.entry.id) ??
        sharedDialogueAccessProblem(edit.current.dialogue.entry.id, eventId) ??
        eventAccessProblem?.call(eventId) ??
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
