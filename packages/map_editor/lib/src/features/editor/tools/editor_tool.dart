enum EditorToolType {
  selection,
  tilePaint,
  terrainPaint,
  collisionPaint,
  entityPlacement,
  warpPlacement,
  triggerPlacement,
  eraser,
}

abstract class EditorTool {
  final EditorToolType type;

  const EditorTool(this.type);
}
