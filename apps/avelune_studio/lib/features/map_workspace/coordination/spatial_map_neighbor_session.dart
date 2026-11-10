import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ChangeNotifier, listEquals;
import 'package:map_core/map_core_domain.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/map_workspace_controller.dart';
import '../domain/map_exterior_decoration_port.dart';
import '../../../platform/rendering/contracts/map_workspace_visuals.dart';

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

class SpatialMapNeighborSession extends ChangeNotifier {
  final _neighborSources = <Object, Future<_EditorNeighborSource>>{};
  List<SpatialSceneNeighbor> neighbors = const [];
  List<SpatialSceneDecoration> decorations = const [];
  List<Object?>? _neighborRequest;
  int _neighborGeneration = 0;
  Object? failure;
  bool loading = false;
  bool _disposed = false;

  bool get ready => !loading && failure == null;

  void refresh({
    required MapData map,
    required MapWorkspaceController controller,
    required ProjectManifest project,
    required MapWorkspaceVisuals visuals,
  }) {
    if (_disposed) return;
    final request = <Object?>[
      controller,
      visuals,
      project,
      map.id,
      map.size,
      ...map.connections,
      for (final connection in map.connections) ...[
        controller.documents[connection.targetMapId]?.current,
        controller
            .documents[connection.targetMapId]
            ?.exteriorDecoration
            ?.current,
      ],
    ];
    if (listEquals(request, _neighborRequest)) return;
    _neighborRequest = request;
    final ticket = ++_neighborGeneration;
    failure = null;
    loading = true;
    if (map.spatialScene == null ||
        visuals is! SpatialWorkspaceVisuals ||
        map.connections.isEmpty) {
      neighbors = const [];
      decorations = const [];
      loading = false;
      return;
    }
    final spatialVisuals = visuals as SpatialWorkspaceVisuals;
    final connections = [...map.connections];
    final pending = <Future<_EditorNeighborSource>>[];
    for (final connection in connections) {
      final entry = controller.project?.maps
          .where((entry) => entry.id == connection.targetMapId)
          .firstOrNull;
      if (entry == null) {
        failure = StateError(
          'Carte liée absente du projet : ${connection.targetMapId}',
        );
        neighbors = const [];
        decorations = const [];
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
          if (_disposed || ticket != _neighborGeneration) return;
          final nextNeighbors = <SpatialSceneNeighbor>[];
          final nextDecorations = <SpatialSceneDecoration>[];
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
            nextNeighbors.add(
              SpatialSceneNeighbor(
                map: current,
                offset: offset,
                project: source.assets.project,
                loadGroundImage: source.assets.loadGroundImage,
                loadModel: source.assets.loadModel,
              ),
            );
            if (decoration != null) {
              nextDecorations.add(
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
          neighbors = List.unmodifiable(nextNeighbors);
          decorations = List.unmodifiable(nextDecorations);
          loading = false;
          notifyListeners();
        },
        onError: (Object error, StackTrace trace) {
          if (!_disposed && ticket == _neighborGeneration) {
            failure = error;
            loading = false;
            notifyListeners();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _neighborGeneration++;
    _neighborSources.clear();
    super.dispose();
  }
}
