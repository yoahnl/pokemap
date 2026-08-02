import 'package:map_core/map_core.dart';

import 'map_lifecycle_adapter.dart';

const String smartTileNativeAuthoringRequiresStn03Code =
    'smart_tile_native_authoring_requires_stn03';
const String smartTileWangPaintCompilerRequiredCode =
    'smart_tile_wang_paint_compiler_required';

bool isSmartTileTransitionGuardCode(String code) =>
    code == smartTileNativeAuthoringRequiresStn03Code ||
    code == smartTileWangPaintCompilerRequiredCode;

MapAuthoringException nativeSmartTileAuthoringRequiresStn03({
  required MapData map,
  required String operation,
  String? layerId,
}) =>
    MapAuthoringException(
      code: smartTileNativeAuthoringRequiresStn03Code,
      message:
          'Native Smart Tile authoring is unavailable until STN-03 exposes '
          'the canonical atomic authoring contract.',
      details: {
        'mapId': map.id,
        'mapVersion': map.version.name,
        'operation': operation,
        if (layerId != null) 'layerId': layerId,
      },
      remediation: const [
        'Keep the Smart Tile draft in memory until STN-03 is available.',
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
