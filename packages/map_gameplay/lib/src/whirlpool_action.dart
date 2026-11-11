import 'package:map_core/map_core.dart';

import 'field_traversal_geometry.dart';

bool isWhirlpoolZone(MapGameplayZone zone) =>
    isFieldTraversalZone(zone) &&
    zone.fieldAction!.actionKind == FieldActionZoneKind.whirlpool;

MapGameplayZone? findWhirlpoolTarget(
        {required MapData map, required GameState gameState}) =>
    findAllGameplayZonesAtPos(map, gameState.playerPosition)
        .where(isWhirlpoolZone)
        .where((zone) =>
            fieldTraversalRouteCells(zone).first == gameState.playerPosition)
        .firstOrNull;
