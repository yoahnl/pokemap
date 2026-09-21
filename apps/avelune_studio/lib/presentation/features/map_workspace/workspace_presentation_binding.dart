part of 'map_workspace_screen.dart';

extension _WorkspacePresentationBinding on _MapWorkspaceScreenState {
  void _initializePresentations() {
    final narrative = _narrative, port = widget.presentationPort;
    if (narrative == null || port == null) return;
    _presentations = PresentationWorkspaceController(
      narrative,
      port,
      changed: _changed,
      sceneDrafts: () =>
          _scenes?.sessions.values.map((s) => s.current).toList() ?? [],
    );
    _presentations!.onScenePublished = (link, published) {
      final session = _scenes?.sessions[link.scene.id];
      if (session == null) return;
      if (session.current == link.scene) session.commit(published);
      session.acceptSave(published, 'presentation-publication');
      _changed();
    };
  }

  void _openPresentations() {
    _presentationOrigin = WorkspaceReturn.story;
    _show(WorkspaceSpace.presentation);
  }

  Future<void> _returnToPresentation(String? presentationId) async {
    final owner = _presentations;
    if (owner == null) return;
    if (presentationId != null &&
        owner.activeId != presentationId &&
        !await owner.open(presentationId)) {
      if (!mounted) return;
      _sceneOrigin = WorkspaceReturn.story;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette présentation n’est plus disponible.'),
        ),
      );
      _show(WorkspaceSpace.story);
      return;
    }
    if (mounted) _show(WorkspaceSpace.presentation);
  }

  Future<void> _returnFromPresentation() async {
    final origin = _presentationOrigin;
    final sceneId = origin.documentId;
    if (origin.space == WorkspaceSpace.scene && sceneId != null) {
      if (_scenes?.open(sceneId) != true) {
        _presentationOrigin = WorkspaceReturn.story;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cette scène n’est plus disponible.')),
        );
        _show(WorkspaceSpace.story);
        return;
      }
    }
    _show(origin.space);
  }

  Future<void> _openScenePresentation(
    ScenePresentationCinematicPayload payload,
  ) async {
    if (_presentations == null) return;
    _presentationOrigin = WorkspaceReturn(
      WorkspaceSpace.scene,
      documentId: _scenes?.active?.current.id,
    );
    _show(WorkspaceSpace.presentation);
    await _presentations!.open(payload.presentationCinematicId);
  }

  Future<void> _createScenePresentation(
    ScenePresentationCreationRequest request,
  ) async {
    final owner = _presentations;
    if (owner == null) return;
    final name = await askNarrativeName(context, 'Créer une présentation liée');
    if (!mounted || name == null) return;
    final current = _scenes?.sessions[request.scene.id]?.current;
    if (current != request.scene) return;
    final created = await owner.createLinked(
      title: name,
      link: PresentationSceneLink(
        baseScene: request.baseScene,
        scene: request.scene,
        nodeId: owner.narrative.identity('presentation-node'),
        targetNodeId: request.targetNodeId,
      ),
    );
    if (created && mounted) {
      _presentationOrigin = WorkspaceReturn(
        WorkspaceSpace.scene,
        documentId: request.scene.id,
      );
      _show(WorkspaceSpace.presentation);
    }
  }

  Widget _presentationPage() {
    final owner = _presentations, factory = _visuals;
    if (owner == null || factory is! PresentationMediaWorkspaceVisuals) {
      return const Center(
        child: Text(
          'Le renderer de présentation est indisponible sur cet hôte.',
        ),
      );
    }
    final session = owner.active;
    final key = (
      owner.activeId,
      session?.base?.revision,
      session?.mediaCatalog,
      session?.imports.map((m) => m.media.id).join(','),
    );
    if (_presentationVisualKey != key) {
      final previous = _presentationVisuals;
      if (previous != null) unawaited(previous.close());
      _presentationVisualKey = key;
      _presentationVisuals = (factory as PresentationMediaWorkspaceVisuals)
          .createPresentationVisuals(
            revision: session?.base?.revision ?? 'draft',
            catalog: session?.mediaCatalog ?? ProjectMediaCatalog(),
            imports: session?.imports ?? [],
          );
    }
    return PresentationWorkspacePage(
      controller: owner,
      views: _presentationViews,
      mediaPicker: widget.presentationMediaPicker,
      previewSceneId: _presentationOrigin.space == WorkspaceSpace.scene
          ? _presentationOrigin.documentId
          : null,
      onConsumer: (sceneId, nodeId) async {
        if (_scenes?.open(sceneId) != true) return;
        _sceneViews.forScene(sceneId).nodeId = nodeId;
        _sceneOrigin = WorkspaceReturn(
          WorkspaceSpace.presentation,
          documentId: owner.activeId,
        );
        _show(WorkspaceSpace.scene);
      },
      visuals: _presentationVisuals!,
      onBack: () => unawaited(_returnFromPresentation()),
      backLabel: _presentationOrigin.space == WorkspaceSpace.scene
          ? 'la scène'
          : 'Histoire',
      onMapCinematics: _openCinematics,
    );
  }
}
