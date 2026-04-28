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

abstract class EditorTool {
  final EditorToolType type;

  const EditorTool(this.type);
}
