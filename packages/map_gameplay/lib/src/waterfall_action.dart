import 'package:map_core/map_core.dart';

import 'field_traversal_geometry.dart';

bool isWaterfallZone(MapGameplayZone zone) =>
    isFieldTraversalZone(zone) &&
    zone.fieldAction!.actionKind == FieldActionZoneKind.waterfall;

MapGameplayZone? findWaterfallTarget(
        {required MapData map, required GameState gameState}) =>
    findAllGameplayZonesAtPos(map, gameState.playerPosition)
        .where(isWaterfallZone)
        .where((zone) =>
            fieldTraversalRouteCells(zone).first == gameState.playerPosition)
        .firstOrNull;
