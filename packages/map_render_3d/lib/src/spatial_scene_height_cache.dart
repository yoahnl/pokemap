import 'dart:math' as math;

final class SpatialSceneHeightCache {
  List<int>? _levels;
  int? _maximumLevel;

  double maximumHeight(List<int> immutableLevels, double levelHeight) {
    if (!identical(_levels, immutableLevels)) {
      final maximum = immutableLevels.reduce(math.max);
      _levels = immutableLevels;
      _maximumLevel = maximum;
    }
    return _maximumLevel! * levelHeight;
  }
}
