part of 'workspace_navigation_session.dart';

extension WorkspacePresentationNavigation on WorkspaceNavigationSession {
  Future<void> createScenePresentation(
    ScenePresentationCreationRequest creation, {
    required Future<String?> Function() askName,
  }) async {
    final ticket = await _prepare(MapWorkspaceWorkshop.presentation);
    if (!isActive() || ticket == null) return;
    final owner = presentations?.call();
    if (owner == null) return;
    final name = await askName();
    if (!isActive() || name == null || ticket != request) return;
    final current = scenes?.call()?.sessions[creation.scene.id]?.current;
    if (current != creation.scene) return;
    final created = await owner.createLinked(
      title: name,
      link: PresentationSceneLink(
        baseScene: creation.baseScene,
        scene: creation.scene,
        nodeId: owner.narrative.identity('presentation-node'),
        targetNodeId: creation.targetNodeId,
      ),
    );
    if (created && isActive() && ticket == request) {
      presentationOrigin = WorkspaceReturn(
        WorkspaceSpace.scene,
        documentId: creation.scene.id,
      );
      show(WorkspaceSpace.presentation);
    }
  }
}
