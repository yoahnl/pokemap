import 'package:map_core/map_core.dart';

const List<GridPos> borderCanonicalOpenElbowGolden = <GridPos>[
  GridPos(x: 1, y: 1),
  GridPos(x: 2, y: 1),
  GridPos(x: 2, y: 2),
  GridPos(x: 2, y: 3),
];

const List<GridPos> borderCanonicalUnitLoopGolden = <GridPos>[
  GridPos(x: 1, y: 1),
  GridPos(x: 2, y: 1),
  GridPos(x: 2, y: 2),
  GridPos(x: 1, y: 2),
];

const List<(GridPos, GridPos, BorderCardinalDirection, int, int)>
    borderRectangularElbowLatticeGolden =
    <(GridPos, GridPos, BorderCardinalDirection, int, int)>[
  (
    GridPos(x: 1, y: 1),
    GridPos(x: 2, y: 1),
    BorderCardinalDirection.east,
    0,
    7,
  ),
  (
    GridPos(x: 2, y: 1),
    GridPos(x: 2, y: 2),
    BorderCardinalDirection.south,
    7,
    18,
  ),
  (
    GridPos(x: 2, y: 2),
    GridPos(x: 2, y: 3),
    BorderCardinalDirection.south,
    18,
    29,
  ),
];
