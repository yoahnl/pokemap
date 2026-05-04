enum EditorToolType {
  selection,
  tilePaint,
  terrainPaint,
  surfacePaint,
  collisionPaint,
  entityPlacement,
  eventPlacement,
  warpPlacement,
  triggerPlacement,
  gameplayZonePlacement,
  eraser,
}

/// Lot Environment-22 : édition du masque d’une [EnvironmentArea] sur la carte.
enum EnvironmentMaskEditMode {
  paint,
  erase,
}

abstract class EditorTool {
  final EditorToolType type;

  const EditorTool(this.type);
}
