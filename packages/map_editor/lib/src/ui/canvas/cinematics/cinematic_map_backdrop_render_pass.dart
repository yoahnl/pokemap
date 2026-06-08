enum CinematicMapBackdropRenderPass {
  terrain,
  path,
  tileBackground,
  surface,
  placedBackground,
  tileForeground,
  placedForeground,
}

extension CinematicMapBackdropRenderPassX on CinematicMapBackdropRenderPass {
  int get order => switch (this) {
        CinematicMapBackdropRenderPass.terrain => 0,
        CinematicMapBackdropRenderPass.path => 1,
        CinematicMapBackdropRenderPass.tileBackground => 2,
        CinematicMapBackdropRenderPass.surface => 3,
        CinematicMapBackdropRenderPass.placedBackground => 4,
        CinematicMapBackdropRenderPass.tileForeground => 5,
        CinematicMapBackdropRenderPass.placedForeground => 6,
      };

  bool get paintsBeforeActorOverlay =>
      order < CinematicMapBackdropRenderPass.tileForeground.order;

  bool get paintsAfterActorOverlay => !paintsBeforeActorOverlay;
}
