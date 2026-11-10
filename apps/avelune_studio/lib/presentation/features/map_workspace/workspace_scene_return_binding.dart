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
    final document = _controller.active;
    if (document == null) return;
    final mapId = document.current.id;
    final request = await _prepareWorkshopRoute(MapWorkspaceWorkshop.events);
    if (!mounted || request == null) return;
    final events = _events;
    if (events == null) return;
    final source = NarrativeEventSourceRef.entityInteract(mapId, entity.id);
    final scenes = _scenes?.scenes ?? _narrative?.project.scenes ?? const [];
    final played = [
      for (final record in events.records)
        if (eventSource(record) == source)
          if (eventSceneId(record) case final sceneId?)
            if (scenes.where((scene) => scene.id == sceneId).firstOrNull
                case final scene?)
              (record, scene),
    ];
    if (played.isEmpty) {
      _interactionNotice = ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucune interaction de ce personnage ne joue encore de scène. « Écrire son interaction » en crée une.',
          ),
        ),
      );
      return;
    }
    final chosen = played.length == 1
        ? played.single.$2
        : await showDialog<SceneAsset>(
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
          );
    if (!mounted || request != _navigationRequest || chosen == null) return;
    await _openScene(
      chosen.id,
      nodeId: chosen.graph.startNodeId,
      origin: WorkspaceReturn(
        WorkspaceSpace.map,
        documentId: mapId,
        elementId: entity.id,
      ),
    );
  }
}
