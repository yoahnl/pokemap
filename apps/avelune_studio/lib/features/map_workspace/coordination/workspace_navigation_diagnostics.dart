part of 'workspace_navigation_session.dart';

extension WorkspaceDiagnosticNavigation on WorkspaceNavigationSession {
  bool canOpenDiagnostic(NarrativeProjectDiagnostic item) =>
      switch (item.destination) {
        NarrativeProjectDiagnosticDestination.scene =>
          _hasId(item.sceneId) && scenes?.call() != null,
        NarrativeProjectDiagnosticDestination.dialogue =>
          _hasId(item.dialogueId) && dialogues?.call() != null,
        NarrativeProjectDiagnosticDestination.cinematic =>
          _hasId(item.cinematicId) && cinematics?.call() != null,
        NarrativeProjectDiagnosticDestination.event =>
          _hasId(item.eventId) && events?.call() != null,
        NarrativeProjectDiagnosticDestination.storyline =>
          _hasId(item.storylineId) && stories?.call() != null,
        NarrativeProjectDiagnosticDestination.fact =>
          _hasId(item.factId) && world?.call() != null,
        NarrativeProjectDiagnosticDestination.worldRule =>
          _hasId(item.worldRuleId) && world?.call() != null,
        NarrativeProjectDiagnosticDestination.map => _hasId(item.mapId),
        NarrativeProjectDiagnosticDestination.overview => false,
      };

  bool _hasId(String? id) => id != null && id.isNotEmpty;

  Future<void> openDiagnostic(NarrativeProjectDiagnostic item) async {
    final owner = verification?.call();
    if (owner == null || !canOpenDiagnostic(item)) return;
    final problem = await routeDiagnostic(item);
    if (!isActive() || problem == null) return;
    owner.error = problem;
    changed();
  }

  Future<String?> routeDiagnostic(NarrativeProjectDiagnostic item) async {
    final workshop = switch (item.destination) {
      NarrativeProjectDiagnosticDestination.scene => MapWorkspaceWorkshop.scene,
      NarrativeProjectDiagnosticDestination.dialogue =>
        MapWorkspaceWorkshop.dialogue,
      NarrativeProjectDiagnosticDestination.cinematic =>
        MapWorkspaceWorkshop.cinematic,
      NarrativeProjectDiagnosticDestination.event =>
        MapWorkspaceWorkshop.events,
      NarrativeProjectDiagnosticDestination.storyline =>
        MapWorkspaceWorkshop.progression,
      NarrativeProjectDiagnosticDestination.fact ||
      NarrativeProjectDiagnosticDestination.worldRule =>
        MapWorkspaceWorkshop.world,
      _ => null,
    };
    if (workshop != null && await _prepare(workshop) == null) return null;
    switch (item.destination) {
      case NarrativeProjectDiagnosticDestination.scene:
        return openScene(item.sceneId!);
      case NarrativeProjectDiagnosticDestination.dialogue:
        final owner = dialogues!.call()!;
        if (!await owner.open(item.dialogueId!)) {
          return owner.error ?? 'Ce dialogue n’est plus disponible.';
        }
        dialogueOrigin = WorkspaceSpace.verification;
        show(WorkspaceSpace.dialogue);
        return null;
      case NarrativeProjectDiagnosticDestination.cinematic:
        final owner = cinematics!.call()!;
        if (!await owner.open(item.cinematicId!)) {
          return owner.error ?? 'Cette cinématique n’est plus là.';
        }
        cinematicOrigin = WorkspaceSpace.verification;
        show(WorkspaceSpace.cinematic);
        return null;
      case NarrativeProjectDiagnosticDestination.event:
        final owner = events!.call()!;
        if (!owner.open(item.eventId!)) {
          return owner.error ?? 'Cet événement n’est plus disponible.';
        }
        eventOrigin = WorkspaceSpace.verification;
        show(WorkspaceSpace.events);
        return null;
      case NarrativeProjectDiagnosticDestination.storyline:
        return openProgressionTarget(item);
      case NarrativeProjectDiagnosticDestination.fact:
      case NarrativeProjectDiagnosticDestination.worldRule:
        return openWorldDocument(item);
      case NarrativeProjectDiagnosticDestination.map:
        return openDiagnosticMap(item.mapId!);
      case NarrativeProjectDiagnosticDestination.overview:
        return null;
    }
  }

  String? openProgressionTarget(NarrativeProjectDiagnostic item) {
    final owner = stories!.call()!;
    final storyId = item.storylineId!;
    if (!owner.open(storyId)) {
      return owner.error ?? 'Cette histoire n’est plus disponible.';
    }
    final step = item.stepId, chapter = item.chapterId;
    if (_hasId(step) || _hasId(chapter)) {
      final projection = buildStorylineProgressionProjection(
        project: owner.project,
        storylineId: storyId,
      );
      final node = projection.nodes
          .where(
            (candidate) => _hasId(step)
                ? candidate.stepId == step
                : candidate.chapterId == chapter,
          )
          .firstOrNull;
      if (node != null) {
        progressionNodes[storyId] = node;
        selectProgressionNode?.call(storyId, node);
      }
    }
    progressionOrigin = const WorkspaceReturn(WorkspaceSpace.verification);
    show(WorkspaceSpace.progression);
    return null;
  }

  String? openWorldDocument(NarrativeProjectDiagnostic item) {
    final owner = world!.call()!;
    final rule = item.worldRuleId;
    if (_hasId(rule)) {
      if (!owner.rules.any((candidate) => candidate.id == rule)) {
        return 'Cette règle n’existe plus dans la version de travail.';
      }
      worldRules = true;
      owner.selectRule(rule);
    } else {
      final fact = item.factId!;
      if (!owner.facts.any((candidate) => candidate.id == fact)) {
        return 'Cet état n’existe plus dans la version de travail.';
      }
      worldRules = false;
      owner.selectFact(fact);
    }
    selectWorldMode?.call(worldRules);
    worldOrigin = const WorkspaceReturn(WorkspaceSpace.verification);
    if (!owner.initialized && !owner.loading) unawaited(owner.initialize());
    show(WorkspaceSpace.world);
    return null;
  }

  String? openDiagnosticMap(String id) {
    final entry = controller.project?.maps
        .where((entry) => entry.id == id)
        .firstOrNull;
    if (entry == null) return 'Cette carte n’est plus dans le projet.';
    unawaited(controller.activate(entry));
    verificationMapReturn = true;
    show(WorkspaceSpace.map);
    return null;
  }
}
