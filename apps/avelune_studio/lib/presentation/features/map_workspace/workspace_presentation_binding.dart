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
  ) => _navigation.createScenePresentation(
    request,
    askName: () => askNarrativeName(context, 'Créer une présentation liée'),
  );

  Widget _presentationPage() {
    final owner = _presentations, factory = _visuals;
    if (owner == null || factory is! PresentationMediaWorkspaceVisuals) {
      return const Center(
        child: Text(
          'Le renderer de présentation est indisponible sur cet hôte.',
        ),
      );
    }
    final visuals = _sessions.synchronizePresentationVisuals(
      factory as PresentationMediaWorkspaceVisuals,
    );
    if (visuals == null) return const SizedBox.shrink();
    return PresentationWorkspacePage(
      controller: owner,
      views: _presentationViews,
      mediaPicker: widget.presentationMediaPicker,
      previewSceneId: _presentationOrigin.space == WorkspaceSpace.scene
          ? _presentationOrigin.documentId
          : null,
      onConsumer: null,
      visuals: visuals,
      onBack: () => unawaited(_returnFromPresentation()),
      backLabel: _presentationOrigin.space == WorkspaceSpace.scene
          ? 'la scène'
          : 'Histoire',
      onMapCinematics: _openCinematics,
    );
  }
}
