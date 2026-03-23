import 'package:map_core/map_core.dart';

import '../use_cases/path_layer_use_cases.dart';

class PathLayerBrushFootprint {
  const PathLayerBrushFootprint({
    required this.size,
    required this.failureLabel,
  });

  final GridSize size;
  final String failureLabel;
}

class PathLayerEditingCoordinator {
  const PathLayerEditingCoordinator({
    required PaintPathOnMapUseCase paintPathOnMapUseCase,
    required PaintPathPatternOnMapUseCase paintPathPatternOnMapUseCase,
    required ErasePathOnMapUseCase erasePathOnMapUseCase,
    required ErasePathPatternOnMapUseCase erasePathPatternOnMapUseCase,
    required AssignPathPresetToLayerUseCase assignPathPresetToLayerUseCase,
  })  : _paintPathOnMapUseCase = paintPathOnMapUseCase,
        _paintPathPatternOnMapUseCase = paintPathPatternOnMapUseCase,
        _erasePathOnMapUseCase = erasePathOnMapUseCase,
        _erasePathPatternOnMapUseCase = erasePathPatternOnMapUseCase,
        _assignPathPresetToLayerUseCase = assignPathPresetToLayerUseCase;

  final PaintPathOnMapUseCase _paintPathOnMapUseCase;
  final PaintPathPatternOnMapUseCase _paintPathPatternOnMapUseCase;
  final ErasePathOnMapUseCase _erasePathOnMapUseCase;
  final ErasePathPatternOnMapUseCase _erasePathPatternOnMapUseCase;
  final AssignPathPresetToLayerUseCase _assignPathPresetToLayerUseCase;

  PathLayerBrushFootprint resolveFootprint() {
    return const PathLayerBrushFootprint(
      size: GridSize(width: 1, height: 1),
      failureLabel: 'path',
    );
  }

  MapData paint({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
  }) {
    if (patternSize.width == 1 && patternSize.height == 1) {
      return _paintPathOnMapUseCase.execute(
        map,
        layerId: layerId,
        pos: pos,
      );
    }
    return _paintPathPatternOnMapUseCase.execute(
      map,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      cells: List<bool>.filled(
        patternSize.width * patternSize.height,
        true,
        growable: false,
      ),
      clipToMapBounds: true,
    );
  }

  MapData erase({
    required MapData map,
    required String layerId,
    required GridPos pos,
    required GridSize patternSize,
  }) {
    if (patternSize.width == 1 && patternSize.height == 1) {
      return _erasePathOnMapUseCase.execute(
        map,
        layerId: layerId,
        pos: pos,
      );
    }
    return _erasePathPatternOnMapUseCase.execute(
      map,
      layerId: layerId,
      pos: pos,
      patternSize: patternSize,
      clipToMapBounds: true,
    );
  }

  MapData assignPreset({
    required MapData map,
    required String layerId,
    required String presetId,
  }) {
    return _assignPathPresetToLayerUseCase.execute(
      map,
      layerId: layerId,
      presetId: presetId,
    );
  }
}
