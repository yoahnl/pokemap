enum StudioMapTool {
  select,
  place,
  paint,
  terrain,
  character,
  warp,
  connection,
  spawn,
  sign,
  fieldObstacle,
  zone,
  gameplayZone,
  encounterPaint,
  encounterErase,
  collisionPaint,
  collisionErase,
  border,
  environment,
  erase,
  eraseDecor,
  pan,
}

bool isExteriorDecorationTool(StudioMapTool tool) => switch (tool) {
  StudioMapTool.select ||
  StudioMapTool.pan ||
  StudioMapTool.place ||
  StudioMapTool.terrain ||
  StudioMapTool.border ||
  StudioMapTool.environment ||
  StudioMapTool.erase ||
  StudioMapTool.eraseDecor => true,
  _ => false,
};
