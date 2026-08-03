import 'package:map_core/map_core.dart';

import 'map_lifecycle_adapter.dart';

const String smartTileCanonicalLayerActionRequiredCode =
    'smart_tile_canonical_layer_action_required';
const String smartTileWangGestureActionRequiredCode =
    'smart_tile_wang_gesture_action_required';

bool isSmartTileTransitionGuardCode(String code) =>
    code == smartTileCanonicalLayerActionRequiredCode ||
    code == smartTileWangGestureActionRequiredCode;

MapAuthoringException canonicalSmartTileLayerActionRequired({
  required MapData map,
  required String operation,
  String? layerId,
}) =>
    MapAuthoringException(
      code: smartTileCanonicalLayerActionRequiredCode,
      message: 'Smart Tile layer creation must use the canonical atomic '
          'smart_tile.layer.create action.',
      details: {
        'mapId': map.id,
        'mapVersion': map.version.name,
        'operation': operation,
        if (layerId != null) 'layerId': layerId,
      },
      remediation: const [
        'Plan smart_tile.layer.create against the current project revision.',
      ],
    );

MapAuthoringException smartTileWangGestureActionRequired({
  required MapData map,
  required String operation,
  required String layerId,
}) =>
    MapAuthoringException(
      code: smartTileWangGestureActionRequiredCode,
      message: 'Generic region operations cannot express an atomic Wang '
          'material gesture without ambiguous shared edges or corners.',
      details: {
        'mapId': map.id,
        'mapVersion': map.version.name,
        'operation': operation,
        'layerId': layerId,
      },
      remediation: const [
        'Use smart_tile.cell.paint or smart_tile.cell.erase so the canonical '
            'gesture compiler updates every active lattice.',
      ],
    );
