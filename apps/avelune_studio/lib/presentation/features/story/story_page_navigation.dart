part of 'story_page.dart';

extension _StoryPageNavigation on _StoryPageState {
  VoidCallback? _destination(VerificationProblem problem) {
    final behaviours = widget.behaviours;
    VoidCallback? behaviour(String? id) =>
        id != null && behaviours.available(id)
        ? () => unawaited(behaviours.open(id))
        : null;
    VoidCallback? scene(String? id) => id == null
        ? null
        : behaviour(
            widget.behaviourSource.registry?.records
                .where((record) => record.sceneId == id)
                .firstOrNull
                ?.id,
          );
    VoidCallback? step(String? id) {
      final trame = widget.trame;
      if (id == null || trame?.view?.milestone(id) == null) return null;
      return () => _show(StoryTab.trame, () => trame!.focus = id);
    }

    VoidCallback? fact(String? id) => id == null || _memory == null
        ? null
        : () => _show(StoryTab.memory, () => _memory!.select(id));
    VoidCallback? rule(String? id) => id == null || _memory == null
        ? null
        : () => _show(StoryTab.memory, () => _memory!.rules.select(id));
    VoidCallback? map(String? id) =>
        id == null || !widget.maps.any((entry) => entry.id == id)
        ? null
        : () => unawaited(widget.openMapEntry(id));
    final preferred = switch (problem.destination) {
      NarrativeProjectDiagnosticDestination.event => behaviour(problem.eventId),
      NarrativeProjectDiagnosticDestination.scene => scene(problem.sceneId),
      NarrativeProjectDiagnosticDestination.storyline => step(problem.stepId),
      NarrativeProjectDiagnosticDestination.fact => fact(problem.factId),
      NarrativeProjectDiagnosticDestination.worldRule => rule(
        problem.worldRuleId,
      ),
      NarrativeProjectDiagnosticDestination.map => map(problem.mapId),
      _ => null,
    };
    return preferred ??
        behaviour(problem.eventId) ??
        scene(problem.sceneId) ??
        step(problem.stepId) ??
        fact(problem.factId) ??
        rule(problem.worldRuleId) ??
        map(problem.mapId);
  }

  void _show(StoryTab tab, void Function() select) {
    _openTab(tab);
    _tab = tab;
    select();
    _changed();
  }
}
