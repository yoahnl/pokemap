part of 'map_workspace_screen.dart';

extension _WorkspacePresentationBinding on _MapWorkspaceScreenState {
  void _openPresentations() {
    _presentationOrigin = WorkspaceReturn.story;
    _show(WorkspaceSpace.presentation);
  }

  void _navigationNotice(String? problem) {
    if (problem == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(problem)));
  }

  Future<void> _returnToPresentation(String? id) async =>
      _navigationNotice(await _navigation.returnToPresentation(id));

  Future<void> _returnFromPresentation() async =>
      _navigationNotice(_navigation.returnFromPresentation());

  Future<void> _openScenePresentation(
    ScenePresentationCinematicPayload payload,
  ) => _navigation.openScenePresentation(payload);

  Future<void> _createScenePresentation(
    ScenePresentationCreationRequest request,
  ) async {
    final navigation = await _prepareWorkshopRoute(
      MapWorkspaceWorkshop.presentation,
    );
    if (!mounted || navigation == null) return;
    final owner = _presentations;
    if (owner == null) return;
    final name = await askNarrativeName(context, 'Créer une présentation liée');
    if (!mounted || name == null || navigation != _navigationRequest) return;
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
    if (created && mounted && navigation == _navigationRequest) {
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
        _navigation.openPresentationConsumer(sceneId, nodeId);
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
