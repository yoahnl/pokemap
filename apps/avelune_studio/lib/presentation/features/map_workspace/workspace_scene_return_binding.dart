part of 'map_workspace_screen.dart';

extension _WorkspaceSceneReturnBinding on _MapWorkspaceScreenState {
  Future<String?> _openScene(
    String sceneId, {
    String? nodeId,
    WorkspaceReturn? origin,
  }) => _navigation.openScene(sceneId, nodeId: nodeId, origin: origin);

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

  Future<void> _openInteractionScene(MapEntity entity) async {
    final problem = await _navigation.openInteractionScene(
      entity,
      choose: (played) => showDialog<SceneAsset>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scènes jouées par ce personnage'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (record, scene) in played)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: StudioButton(
                        label: '${scene.name} · ${eventName(record)}',
                        secondary: true,
                        onPressed: () => Navigator.pop(context, scene),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (mounted && problem != null) {
      _interactionNotice = ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
  }
}
