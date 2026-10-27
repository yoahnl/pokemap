import 'package:flutter/foundation.dart';

import 'spatial_ground.dart';

final class SpatialSceneGroundImageReferences {
  List<SpatialGroundVisual>? _visuals;
  Set<String> _visualImageIds = const {};
  String? _cliffImageId;
  Set<String> _occlusionImageIds = const {};
  Set<String> _renderedImageIds = const {};

  Set<String> resolve(
    List<SpatialGroundVisual> visuals, {
    String? cliffImageId,
    required Set<String> occlusionImageIds,
  }) {
    final visualsChanged = !identical(_visuals, visuals);
    if (!visualsChanged &&
        _cliffImageId == cliffImageId &&
        setEquals(_occlusionImageIds, occlusionImageIds)) {
      return _renderedImageIds;
    }
    if (visualsChanged) {
      _visualImageIds = {for (final item in visuals) item.visual.tilesetId};
      _visuals = visuals;
    }
    _cliffImageId = cliffImageId;
    _occlusionImageIds = Set.unmodifiable(occlusionImageIds);
    _renderedImageIds = Set.unmodifiable({
      ..._visualImageIds,
      if (cliffImageId != null) cliffImageId,
      ..._occlusionImageIds,
    });
    return _renderedImageIds;
  }
}
