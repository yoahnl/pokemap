part of 'spatial_scene_view.dart';

typedef _RetainedSceneChunk = ({
  String mapId,
  _SceneChunk chunk,
  MapData source,
});

extension _SpatialSceneChunkRetention on SpatialSceneGame {
  _SceneChunk? _retainedChunkFor(String mapId) {
    final retained = _retainedSceneChunk;
    if (retained == null || retained.mapId != mapId) return null;
    if (_invalidatedModelChunks.contains(retained.chunk)) return null;
    return retained.chunk;
  }

  _SceneChunk? _takeRetainedChunk(
    String mapId,
    _SceneChunkSignature signature,
  ) {
    final chunk = _retainedChunkFor(mapId);
    if (chunk == null || chunk.signature != signature) return null;
    for (final id in _retainedModelSourceIds) {
      modelReservations[id]?.retainRequired();
    }
    final images = _retainedGroundImageIds;
    _wantedGroundImages.addAll(images);
    for (final id in images) {
      _retainedGroundImages.remove(id);
      groundReservations[id]?.retainRequired();
    }
    _retainedSceneChunk = null;
    return chunk;
  }

  void _retainDepartingChunk(Map<String, _SceneChunk> nextChunks) {
    final source = renderedConfiguration?.groundMap;
    final departingMapId = source?.id;
    if (source == null || nextChunks.containsKey(departingMapId)) return;
    final departing = sceneChunks[departingMapId];
    if (departing == null || _invalidatedModelChunks.contains(departing)) {
      return;
    }
    _retainedSceneChunk = (mapId: source.id, chunk: departing, source: source);
  }

  Set<String> get _retainedModelSourceIds => {
    for (final model
        in _retainedSceneChunk?.chunk.models.values ??
            const <_ScenePlacedModel>[])
      model.component.definition.sourceAssetId,
  };

  Set<String> get _retainedGroundImageIds {
    final ground = _retainedSceneChunk?.chunk.ground;
    if (ground == null) return const {};
    return {...ground.renderedImageIds, ...ground.currentImageIds};
  }

  void _protectModelReservations(
    Set<String?> requiredIds,
    Set<String> retainedIds,
  ) {
    for (final id in requiredIds.nonNulls) {
      modelReservations[id]?.retainRequired();
    }
    for (final id in retainedIds) {
      modelReservations[id]?.retainOptionally(_evictRetainedChunk);
    }
  }

  bool _retainGroundImageOptionally(String id) {
    if (_retainedSceneChunk == null) return false;
    if (!_retainedGroundImageIds.contains(id)) return false;
    _retainedGroundImages.remove(id);
    groundReservations[id]?.retainOptionally(_evictRetainedChunk);
    return true;
  }

  bool _retainedChunkCovers(SpatialScenePreparation request) {
    final retained = _retainedSceneChunk;
    if (retained == null || _retainedChunkFor(request.map.id) == null) {
      return false;
    }
    return retained.chunk.signature.$3 == request.project &&
        retained.source == request.map;
  }

  void _evictRetainedChunk() {
    if (_retainedSceneChunk == null) return;
    final models = _retainedModelSourceIds.difference({
      ..._sceneModelAssetIds,
      for (final component in decorationAnimationModels.values)
        component.definition.sourceAssetId,
    });
    final images = _retainedGroundImageIds.difference(_wantedGroundImages);
    _retainedSceneChunk = null;
    for (final id in models) {
      cache.remove(id);
      modelReservations.remove(id)?.release();
      final source = loadedModelSources.remove(id);
      if (source != null) clippedModelCache.releaseSource(source);
    }
    images.forEach(_removeGroundTexture);
  }

  void _dropRetainedChunk() => _retainedSceneChunk = null;
}
