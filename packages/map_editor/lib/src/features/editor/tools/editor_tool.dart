enum EditorToolType {
  selection,
  tilePaint,
  terrainPaint,
  collisionPaint,
  borderPaint,
  borderErase,
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
  generatedAdd,
  generatedDelete,
}

abstract class EditorTool {
  final EditorToolType type;

  const EditorTool(this.type);
}
