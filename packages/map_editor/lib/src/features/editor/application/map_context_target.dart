import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import 'map_canvas_object_hit_test.dart';

@immutable
sealed class MapContextTarget {
  const MapContextTarget();
}

@immutable
final class MapObjectContextTarget extends MapContextTarget {
  const MapObjectContextTarget(this.target);

  final MapCanvasObjectTarget target;

  @override
  bool operator ==(Object other) {
    return other is MapObjectContextTarget && other.target == target;
  }

  @override
  int get hashCode => target.hashCode;
}

@immutable
final class MapCellContextTarget extends MapContextTarget {
  const MapCellContextTarget({
    required this.position,
    required this.layerId,
    required this.isPainted,
  });

  final GridPos position;
  final String? layerId;
  final bool isPainted;

  @override
  bool operator ==(Object other) {
    return other is MapCellContextTarget &&
        other.position == position &&
        other.layerId == layerId &&
        other.isPainted == isPainted;
  }

  @override
  int get hashCode => Object.hash(position, layerId, isPainted);
}

@immutable
final class MapLayerContextTarget extends MapContextTarget {
  const MapLayerContextTarget(this.layerId);

  final String layerId;

  @override
  bool operator ==(Object other) {
    return other is MapLayerContextTarget && other.layerId == layerId;
  }

  @override
  int get hashCode => layerId.hashCode;
}
