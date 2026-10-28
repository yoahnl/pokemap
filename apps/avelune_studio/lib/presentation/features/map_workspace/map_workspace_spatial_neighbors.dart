part of 'map_workspace_editor_pane.dart';

final class _NeighborAssetSource {
  _NeighborAssetSource(this.project, this.visuals);
  final ProjectManifest project;
  final SpatialWorkspaceVisuals visuals;
  Future<Uint8List> loadModel(String id) {
    final scoped = visuals;
    if (scoped is! SpatialScopedWorkspaceVisuals) return visuals.readModel(id);
    final definition = project.models3d
        .where((model) => model.id == id)
        .firstOrNull;
    if (definition == null) throw StateError('Modèle voisin absent : $id');
    return (scoped as SpatialScopedWorkspaceVisuals).readModelDefinition(
      definition,
    );
  }

  Future<Uint8List> loadGroundImage(String id) {
    final scoped = visuals;
    if (scoped is! SpatialScopedWorkspaceVisuals) {
      return visuals.readGroundImage(id);
    }
    final definition = project.tilesets
        .where((tileset) => tileset.id == id)
        .firstOrNull;
    if (definition == null) throw StateError('Terrain voisin absent : $id');
    return (scoped as SpatialScopedWorkspaceVisuals).readGroundDefinition(
      definition,
    );
  }
}

final class _EditorNeighborSource {
  const _EditorNeighborSource(this.map, this.decoration, this.assets);
  final MapData map;
  final MapExteriorDecoration? decoration;
  final _NeighborAssetSource assets;
}

extension _WorkspaceSpatialNeighbors on _MapWorkspaceEditorPaneState {
  void _loadSpatialNeighbors() {
    final map = widget.document.current;
    final visuals = widget.visuals;
    final request = <Object?>[
      widget.controller,
      visuals,
      widget.project,
      map.id,
      map.size,
      ...map.connections,
      for (final connection in map.connections) ...[
        widget.controller.documents[connection.targetMapId]?.current,
        widget
            .controller
            .documents[connection.targetMapId]
            ?.exteriorDecoration
            ?.current,
      ],
    ];
    if (listEquals(request, _neighborRequest)) return;
    _neighborRequest = request;
    final ticket = ++_neighborGeneration;
    _neighborFailure = null;
    _neighborLoading = true;
    if (map.spatialScene == null ||
        visuals is! SpatialWorkspaceVisuals ||
        map.connections.isEmpty) {
      _neighbors = const [];
      _neighborDecorations = const [];
      _neighborLoading = false;
      return;
    }
    final spatialVisuals = visuals as SpatialWorkspaceVisuals;
    final controller = widget.controller;
    final project = widget.project;
    final connections = [...map.connections];
    final pending = <Future<_EditorNeighborSource>>[];
    for (final connection in connections) {
      final entry = controller.project?.maps
          .where((entry) => entry.id == connection.targetMapId)
          .firstOrNull;
      if (entry == null) {
        _neighborFailure = StateError(
          'Carte liée absente du projet : ${connection.targetMapId}',
        );
        _neighbors = const [];
        _neighborDecorations = const [];
        return;
      }
      final key = (controller, visuals, project, entry.id, entry.relativePath);
      pending.add(
        _neighborSources.putIfAbsent(key, () async {
          try {
            final neighbor = await controller.previewMap(entry.id);
            if (neighbor == null || neighbor.spatialScene == null) {
              throw StateError('Carte voisine 3D indisponible : ${entry.id}');
            }
            final definitions =
                controller.previewDefinitionsFor(entry.id) ?? project;
            final port = controller.port;
            final decoration = port is MapExteriorDecorationPort
                ? (await (port as MapExteriorDecorationPort)
                          .loadExteriorDecoration(controller.session, entry.id))
                      .decoration
                : null;
            decoration?.validateForMap(neighbor);
            return _EditorNeighborSource(
              neighbor,
              decoration,
              _NeighborAssetSource(definitions, spatialVisuals),
            );
          } on Object {
            _neighborSources.remove(key);
            rethrow;
          }
        }),
      );
    }
    unawaited(
      Future.wait(pending).then(
        (sources) {
          if (!mounted || ticket != _neighborGeneration) return;
          final neighbors = <SpatialSceneNeighbor>[];
          final decorations = <SpatialSceneDecoration>[];
          for (var i = 0; i < sources.length; i++) {
            final source = sources[i];
            final opened = controller.documents[source.map.id];
            final current = opened?.current ?? source.map;
            final decoration =
                opened?.exteriorDecoration?.current ?? source.decoration;
            final offset = spatialConnectionOffset(
              map.size,
              current.size,
              connections[i].direction,
              connections[i].offset,
            );
            neighbors.add(
              SpatialSceneNeighbor(
                map: current,
                offset: offset,
                project: source.assets.project,
                loadGroundImage: source.assets.loadGroundImage,
                loadModel: source.assets.loadModel,
              ),
            );
            if (decoration != null) {
              decorations.add(
                SpatialSceneDecoration(
                  ownerMapId: current.id,
                  decoration: decoration,
                  offset: offset,
                  project: source.assets.project,
                  loadGroundImage: source.assets.loadGroundImage,
                  loadModel: source.assets.loadModel,
                ),
              );
            }
          }
          _updateSpatialNeighbors(() {
            _neighbors = List.unmodifiable(neighbors);
            _neighborDecorations = List.unmodifiable(decorations);
            _neighborLoading = false;
          });
        },
        onError: (Object error, StackTrace trace) {
          if (mounted && ticket == _neighborGeneration) {
            _updateSpatialNeighbors(() {
              _neighborFailure = error;
              _neighborLoading = false;
            });
          }
        },
      ),
    );
  }
}
