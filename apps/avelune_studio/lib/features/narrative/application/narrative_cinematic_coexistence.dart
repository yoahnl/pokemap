part of 'narrative_workspace_controller.dart';

extension NarrativeCinematicCoexistence on NarrativeWorkspaceController {
  Set<String> interactionCinematicIds(InteractionEditSession s) {
    final projection = NarrativeSequenceProjection(s.current.interaction)
      ..build();
    return {
      ...projection.cinematics.map((c) => c.id),
      ...s.baseScene?.graph.nodes
              .map((n) => n.payload)
              .whereType<SceneCinematicPayload>()
              .map((p) => p.cinematicId) ??
          const <String>[],
    };
  }

  String? cinematicInteractionAccessProblem(String id) =>
      sessions.values.any(
        (s) =>
            interactionCinematicIds(s).contains(id) &&
            (s.dirty ||
                _publishingInteractions.contains(s.current.interaction.id)),
      )
      ? 'Cette cinématique appartient à une interaction simplifiée modifiée. Enregistrez ou abandonnez explicitement ce brouillon.'
      : null;
  String? cinematicInteractionProblem(InteractionEditSession s) {
    for (final id in interactionCinematicIds(s)) {
      final problem = cinematicAccessProblem?.call(id);
      if (problem != null) return problem;
      final base = s.baseCatalog?.cinematics
          .where((a) => a.id == id)
          .firstOrNull;
      final current = project.cinematics.where((a) => a.id == id).firstOrNull;
      if (s.baseCatalog != null && base != current) {
        return 'La cinématique liée a changé. Le brouillon simplifié est conservé ; rechargez explicitement sa source.';
      }
    }
    return null;
  }

  void invalidateCleanCinematicSessions(
    String id, {
    Set<InteractionEditSession> except = const {},
  }) {
    final removed = sessions.values
        .where(
          (s) =>
              !s.dirty &&
              !except.contains(s) &&
              interactionCinematicIds(s).contains(id),
        )
        .toSet();
    sessions.removeWhere((_, s) => removed.contains(s));
    if (removed.contains(active)) active = null;
  }
}
