enum CinematicMapBackdropRenderPass {
  tileBackground,
  smartTileBackground,
  placedBackground,
  tileForeground,
  placedForeground,
}

extension CinematicMapBackdropRenderPassX on CinematicMapBackdropRenderPass {
  int get order => switch (this) {
        CinematicMapBackdropRenderPass.tileBackground => 0,
        CinematicMapBackdropRenderPass.smartTileBackground => 1,
        CinematicMapBackdropRenderPass.placedBackground => 2,
        CinematicMapBackdropRenderPass.tileForeground => 3,
        CinematicMapBackdropRenderPass.placedForeground => 4,
      };

  bool get paintsBeforeActorOverlay =>
      order < CinematicMapBackdropRenderPass.tileForeground.order;

  bool get paintsAfterActorOverlay => !paintsBeforeActorOverlay;
}
