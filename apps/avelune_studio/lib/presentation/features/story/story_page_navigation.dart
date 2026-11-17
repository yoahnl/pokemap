part of 'story_page.dart';

extension _StoryPageNavigation on _StoryPageState {
  Future<void> _consumeBehaviourRequest() async {
    final request = widget.behaviourRequest;
    if (request == null) return;
    await widget.beforeNavigation?.call();
    if (!mounted || widget.behaviourRequest != request) return;
    _openSection(StorySection.behaviours);
    _workspace = _workspace.select(StorySection.behaviours);
    if (widget.behaviourCatalog != null) {
      await _openCatalogBehaviour(request.id);
    }
    if (mounted && widget.behaviourRequest == request) _changed();
  }

  Future<bool> _openCatalogBehaviour(String id, {bool simulate = false}) async {
    await widget.beforeNavigation?.call();
    if (!mounted) return false;
    _selectItem(StorySection.behaviours, (kind: StoryDraftKind.event, id: id));
    final opened = await widget.behaviourCatalog!.open(id);
    if (!mounted) return false;
    if (opened && simulate) {
      widget.behaviourCatalog!.editor!.toggleSimulation(id);
    }
    _changed();
    return opened;
  }

  VoidCallback? _destination(VerificationProblem problem) {
    final behaviours = widget.behaviours;
    VoidCallback? behaviour(String? id) =>
        id != null && behaviours.available(id)
        ? () => unawaited(behaviours.open(id))
        : null;
    VoidCallback? scene(String? id) => id == null || widget.openScene == null
        ? null
        : () => widget.openScene!(id, null);
    VoidCallback? step(String? id) {
      final trame = widget.trame;
      if (id == null || trame?.view?.milestone(id) == null) return null;
      return () => _show(StorySection.trame, () => trame!.focus = id);
    }

    VoidCallback? fact(String? id) => id == null || widget.port == null
        ? null
        : () => _show(StorySection.facts, () => _memory!.select(id));
    VoidCallback? rule(String? id) => id == null || widget.port == null
        ? null
        : () => _show(StorySection.rules, () => _memory!.rules.select(id));
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

  Future<void> _show(StorySection section, void Function() select) async {
    await widget.beforeNavigation?.call();
    if (!mounted) return;
    _openSection(section);
    _workspace = _workspace.select(section);
    select();
    _changed();
  }
}
