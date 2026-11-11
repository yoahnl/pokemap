part of 'map_workspace_screen.dart';

extension _WorkspaceSceneReturnBinding on _MapWorkspaceScreenState {
  Future<String?> _openScene(
    String sceneId, {
    String? nodeId,
    WorkspaceReturn? origin,
  }) async => 'L’éditeur de scènes est indisponible.';

  Future<String?> _openSceneAt(String sceneId, String? nodeId) =>
      _openScene(sceneId, nodeId: nodeId);

  VoidCallback? _sceneReturnAction() => switch (_sceneOrigin.space) {
    WorkspaceSpace.pokemon => _returnToPokemonReference,
    WorkspaceSpace.cinematic => () => _show(WorkspaceSpace.cinematic),
    WorkspaceSpace.map => () => _returnToMapElement(_sceneOrigin),
    _ => null,
  };

  String? _sceneReturnLabel() => switch (_sceneOrigin.space) {
    WorkspaceSpace.pokemon => 'Pokémon',
    WorkspaceSpace.cinematic => 'Cinématique',
    WorkspaceSpace.map => 'Carte',
    _ => null,
  };

  void _returnToMapElement(WorkspaceReturn origin) {
    final document = _controller.active;
    final elementId = origin.elementId;
    _show(WorkspaceSpace.map);
    if (document != null &&
        elementId != null &&
        document.current.id == origin.documentId) {
      _selectMapEntity(document, elementId);
    }
  }
}
