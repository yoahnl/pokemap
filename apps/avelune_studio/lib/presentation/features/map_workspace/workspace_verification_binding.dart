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
      // The pages that own an input validate it themselves before a snapshot.
    )..flushEdits = () => _worldView.invalidFields.isEmpty;
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
          item.sceneId == null || _scenes == null ? null : 'Éditeur de scène',
        NarrativeProjectDiagnosticDestination.dialogue =>
          item.dialogueId == null || _dialogues == null
              ? null
              : 'Éditeur de dialogue',
        NarrativeProjectDiagnosticDestination.cinematic =>
          item.cinematicId == null || _cinematics == null
              ? null
              : 'Cinématique sur carte',
        NarrativeProjectDiagnosticDestination.event =>
          item.eventId == null || _events == null
              ? null
              : 'Événements et déclencheurs',
        NarrativeProjectDiagnosticDestination.storyline =>
          item.storylineId == null || _stories == null
              ? null
              : 'Histoires et progression (le retour rejoint Histoire)',
        NarrativeProjectDiagnosticDestination.fact =>
          item.factId == null || _world == null ? null : 'États du monde',
        NarrativeProjectDiagnosticDestination.worldRule =>
          item.worldRuleId == null || _world == null ? null : 'Règles du monde',
        NarrativeProjectDiagnosticDestination.map =>
          item.mapId == null ? null : 'Carte',
        NarrativeProjectDiagnosticDestination.overview => null,
      };

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
        if (!_stories!.open(item.storylineId!)) {
          return _stories!.error ?? 'Cette histoire n’est plus disponible.';
        }
        _show(WorkspaceSpace.progression);
        return null;
      case NarrativeProjectDiagnosticDestination.fact:
      case NarrativeProjectDiagnosticDestination.worldRule:
        return _openWorldDocument(item);
      case NarrativeProjectDiagnosticDestination.map:
        return _openDiagnosticMap(item.mapId!);
      case NarrativeProjectDiagnosticDestination.overview:
        return null;
    }
  }

  String? _openWorldDocument(NarrativeProjectDiagnostic item) {
    final world = _world!;
    final rule = item.worldRuleId;
    if (rule != null) {
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
    _show(WorkspaceSpace.map);
    return null;
  }
}
