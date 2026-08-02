import 'package:map_core/map_core.dart';

import 'map_lifecycle_adapter.dart';

const String smartTileCanonicalLayerActionRequiredCode =
    'smart_tile_canonical_layer_action_required';
const String smartTileWangPaintCompilerRequiredCode =
    'smart_tile_wang_paint_compiler_required';

bool isSmartTileTransitionGuardCode(String code) =>
    code == smartTileCanonicalLayerActionRequiredCode ||
    code == smartTileWangPaintCompilerRequiredCode;

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

MapAuthoringException smartTileWangPaintCompilerRequired({
  required MapData map,
  required String operation,
  required String layerId,
}) =>
    MapAuthoringException(
      code: smartTileWangPaintCompilerRequiredCode,
      message:
          'Wang Smart Tile painting requires the STN-05 compiler to project '
          'semantic gestures into edge and corner lattices.',
      details: {
        'mapId': map.id,
        'mapVersion': map.version.name,
        'operation': operation,
        'layerId': layerId,
      },
      remediation: const [
        'Use read-only inspection, normalize, or merge until STN-05 is '
            'available.',
      ],
    );
