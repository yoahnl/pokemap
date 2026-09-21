part of 'map_workspace_screen.dart';

extension _WorkspaceVerificationBinding on _MapWorkspaceScreenState {
  void _initializeVerification() {
    final narrative = _narrative, port = widget.verificationPort;
    if (narrative == null || port == null) return;
    _verification = VerificationWorkspaceController(
      narrative,
      port,
      changed: _changed,
      world: () => _world,
      scenes: () => _scenes,
      dialogues: () => _dialogues,
      events: () => _events,
      cinematics: () => _cinematics,
      presentations: () => _presentations,
    )..flushEdits = _actions.flushEditors;
  }

  void _openVerification() {
    _verificationOrigin = WorkspaceReturn.story;
    _show(WorkspaceSpace.verification);
  }

  Widget _verificationPage() {
    final owner = _verification;
    if (owner == null) {
      return const Center(
        child: Text('La vérification est indisponible sur cet hôte.'),
      );
    }
    return VerificationWorkspacePage(
      controller: owner,
      view: _verificationView,
      backLabel: 'Histoire',
      onBack: () => _show(_verificationOrigin.space),
      openLabel: _destinationLabel,
      onOpen: _openDiagnostic,
    );
  }

  /// Names the editor a diagnostic can reach, or null when the report only
  /// carries a family this host cannot open precisely.
  String? _destinationLabel(NarrativeProjectDiagnostic item) =>
      switch (item.destination) {
        NarrativeProjectDiagnosticDestination.scene =>
          _empty(item.sceneId) || _scenes == null ? null : 'Éditeur de scène',
        NarrativeProjectDiagnosticDestination.dialogue =>
          _empty(item.dialogueId) || _dialogues == null
              ? null
              : 'Éditeur de dialogue',
        NarrativeProjectDiagnosticDestination.cinematic =>
          _empty(item.cinematicId) || _cinematics == null
              ? null
              : 'Cinématique sur carte',
        NarrativeProjectDiagnosticDestination.event =>
          _empty(item.eventId) || _events == null
              ? null
              : 'Événements et déclencheurs',
        NarrativeProjectDiagnosticDestination.storyline =>
          _empty(item.storylineId) || _stories == null
              ? null
              : _progressionLabel(item),
        NarrativeProjectDiagnosticDestination.fact =>
          _empty(item.factId) || _world == null ? null : 'États du monde',
        NarrativeProjectDiagnosticDestination.worldRule =>
          _empty(item.worldRuleId) || _world == null ? null : 'Règles du monde',
        NarrativeProjectDiagnosticDestination.map =>
          _empty(item.mapId) ? null : 'Carte',
        NarrativeProjectDiagnosticDestination.overview => null,
      };

  bool _empty(String? value) => value == null || value.isEmpty;

  /// The page only promises the precision the diagnostic actually carries.
  String _progressionLabel(NarrativeProjectDiagnostic item) =>
      _empty(item.stepId) && _empty(item.chapterId)
      ? 'Histoires et progression (l’histoire, sans étape précise)'
      : 'Histoires et progression (étape ciblée)';

  /// Opens the document responsible for the diagnostic. A destination that
  /// fails explains itself and never changes the selection or a draft.
  Future<void> _openDiagnostic(NarrativeProjectDiagnostic item) async {
    final owner = _verification;
    if (owner == null || _destinationLabel(item) == null) return;
    final problem = await _route(item);
    if (!mounted || problem == null) return;
    owner.error = problem;
    _changed();
  }

  Future<String?> _route(NarrativeProjectDiagnostic item) async {
    switch (item.destination) {
      case NarrativeProjectDiagnosticDestination.scene:
        return _openScene(item.sceneId!);
      case NarrativeProjectDiagnosticDestination.dialogue:
        if (await _dialogues!.open(item.dialogueId!) != true) {
          return _dialogues!.error ?? 'Ce dialogue n’est plus disponible.';
        }
        _dialogueOrigin = WorkspaceSpace.verification;
        _show(WorkspaceSpace.dialogue);
        return null;
      case NarrativeProjectDiagnosticDestination.cinematic:
        if (await _cinematics!.open(item.cinematicId!) != true) {
          return _cinematics!.error ?? 'Cette cinématique n’est plus là.';
        }
        _cinematicOrigin = WorkspaceSpace.verification;
        _show(WorkspaceSpace.cinematic);
        return null;
      case NarrativeProjectDiagnosticDestination.event:
        if (!_events!.open(item.eventId!)) {
          return _events!.error ?? 'Cet événement n’est plus disponible.';
        }
        _eventOrigin = WorkspaceSpace.verification;
        _show(WorkspaceSpace.events);
        return null;
      case NarrativeProjectDiagnosticDestination.storyline:
        return _openProgressionTarget(item);
      case NarrativeProjectDiagnosticDestination.fact:
      case NarrativeProjectDiagnosticDestination.worldRule:
        return _openWorldDocument(item);
      case NarrativeProjectDiagnosticDestination.map:
        return _openDiagnosticMap(item.mapId!);
      case NarrativeProjectDiagnosticDestination.overview:
        return null;
    }
  }

  /// A diagnostic that names a chapter or a step selects it; one that only
  /// names the story opens the story and claims nothing more.
  String? _openProgressionTarget(NarrativeProjectDiagnostic item) {
    final stories = _stories!;
    final storyId = item.storylineId!;
    if (!stories.open(storyId)) {
      return stories.error ?? 'Cette histoire n’est plus disponible.';
    }
    final step = item.stepId, chapter = item.chapterId;
    if (!_empty(step) || !_empty(chapter)) {
      final projection = buildStorylineProgressionProjection(
        project: stories.project,
        storylineId: storyId,
      );
      final node = projection.nodes
          .where(
            (candidate) => _empty(step)
                ? candidate.chapterId == chapter
                : candidate.stepId == step,
          )
          .firstOrNull;
      if (node != null) {
        _progressionViews.forStory(stories.project, storyId).selection =
            StoryGraphSelection.node(node);
      }
    }
    _progressionOrigin = const WorkspaceReturn(WorkspaceSpace.verification);
    _show(WorkspaceSpace.progression);
    return null;
  }

  String? _openWorldDocument(NarrativeProjectDiagnostic item) {
    final world = _world!;
    final rule = item.worldRuleId;
    if (!_empty(rule)) {
      if (!world.rules.any((candidate) => candidate.id == rule)) {
        return 'Cette règle n’existe plus dans la version de travail.';
      }
      _worldView.view = WorldView.rules;
      world.selectRule(rule);
    } else {
      final fact = item.factId!;
      if (!world.facts.any((candidate) => candidate.id == fact)) {
        return 'Cet état n’existe plus dans la version de travail.';
      }
      _worldView.view = WorldView.states;
      world.selectFact(fact);
    }
    _worldOrigin = const WorkspaceReturn(WorkspaceSpace.verification);
    if (!world.initialized && !world.loading) {
      unawaited(world.initialize());
    }
    _show(WorkspaceSpace.world);
    return null;
  }

  String? _openDiagnosticMap(String mapId) {
    final entry = _controller.project?.maps
        .where((candidate) => candidate.id == mapId)
        .firstOrNull;
    if (entry == null) return 'Cette carte n’est plus dans le projet.';
    unawaited(_controller.activate(entry));
    _verificationMapReturn = true;
    _show(WorkspaceSpace.map);
    return null;
  }
}
