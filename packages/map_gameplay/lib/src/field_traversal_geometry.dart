import 'package:map_core/map_core.dart';

bool isFieldTraversalZone(MapGameplayZone zone) =>
    zone.kind == GameplayZoneKind.fieldAction &&
    const {FieldActionZoneKind.waterfall, FieldActionZoneKind.whirlpool}
        .contains(zone.fieldAction?.actionKind);

List<GridPos> fieldTraversalRouteCells(MapGameplayZone zone) {
  final field = zone.fieldAction!;
  final waterfall = field.waterfall;
  final whirlpool = field.whirlpool;
  final cells = switch (field.actionKind) {
    FieldActionZoneKind.waterfall => [
        waterfall!.entry,
        ...waterfall.path,
        waterfall.exit
      ],
    FieldActionZoneKind.whirlpool => [
        whirlpool!.entry,
        ...whirlpool.path,
        whirlpool.exit
      ],
    _ => throw StateError('A field traversal requires its typed route.'),
  };
  return List.unmodifiable(cells.map((cell) =>
      GridPos(x: zone.area.pos.x + cell.x, y: zone.area.pos.y + cell.y)));
}

EntityFacing fieldTraversalFacing(MapGameplayZone zone) =>
    switch (zone.fieldAction!.actionKind == FieldActionZoneKind.whirlpool
        ? zone.fieldAction!.whirlpool!.direction
        : zone.fieldAction!.waterfall!.direction) {
      MapConnectionDirection.north => EntityFacing.north,
      MapConnectionDirection.south => EntityFacing.south,
      MapConnectionDirection.east => EntityFacing.east,
      MapConnectionDirection.west => EntityFacing.west,
    };

bool fieldTraversalRequiresSurf(MapGameplayZone zone) =>
    zone.fieldAction!.actionKind == FieldActionZoneKind.whirlpool ||
    zone.fieldAction!.waterfall!.requiresSurf;
