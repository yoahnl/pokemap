enum EditorToolType {
  selection,
  tilePaint,
  collisionPaint,
  entityPlacement,
  warpPlacement,
  triggerPlacement,
  eraser,
}

abstract class EditorTool {
  final EditorToolType type;
  const EditorTool(this.type);
  
  // Future methods for interaction
}
