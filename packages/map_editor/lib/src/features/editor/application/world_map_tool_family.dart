enum WorldMapToolFamily { selection, paint, erase, place, layers }

enum WorldMapPaintSubtool {
  tile,
  terrain,
  path,
  surface,
  border,
  collision,
}

enum WorldMapPlacementSubtool {
  object,
  entity,
  event,
  trigger,
  warp,
  gameplayZone,
}

enum WorldMapInspectorKind {
  paint,
  erase,
  place,
  objectSelection,
  cellSelection,
  layers,
  environment,
  empty,
}
