import 'package:map_core/map_core.dart';

enum Direction { north, south, east, west }

extension EntityFacingX on EntityFacing {
  Direction get asDirection => switch (this) {
        EntityFacing.north => Direction.north,
        EntityFacing.south => Direction.south,
        EntityFacing.east => Direction.east,
        EntityFacing.west => Direction.west,
      };
}

extension DirectionX on Direction {
  int get dx => switch (this) {
        Direction.east => 1,
        Direction.west => -1,
        Direction.north || Direction.south => 0,
      };

  int get dy => switch (this) {
        Direction.south => 1,
        Direction.north => -1,
        Direction.east || Direction.west => 0,
      };

  EntityFacing get asFacing => switch (this) {
        Direction.north => EntityFacing.north,
        Direction.south => EntityFacing.south,
        Direction.east => EntityFacing.east,
        Direction.west => EntityFacing.west,
      };
}
