import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

enum CinematicActorSpriteStatus {
  spriteReady,
  placeholderFallback,
  missingCharacter,
  missingTileset,
  missingIdleAnimation,
  missingDirectionFrame,
  invalidSourceRect,
  unsupported,
  hidden,
}

enum CinematicActorSpriteRendererHint {
  overlayCompatible,
  depthAwareCompatible,
  hybridRecommended,
}

@immutable
final class CinematicActorSpriteDepthHint {
  const CinematicActorSpriteDepthHint({
    required this.tileX,
    required this.tileY,
    required this.anchorTileX,
    required this.anchorTileY,
    required this.visualBottom,
    required this.footprintWidthTiles,
    required this.footprintHeightTiles,
    required this.preferredRendererHint,
  });

  final int tileX;
  final int tileY;
  final double anchorTileX;
  final double anchorTileY;
  final double visualBottom;
  final int footprintWidthTiles;
  final int footprintHeightTiles;
  final CinematicActorSpriteRendererHint preferredRendererHint;
}

@immutable
final class CinematicActorSpriteRef {
  const CinematicActorSpriteRef({
    required this.characterId,
    required this.tilesetId,
    required this.sourceTileRect,
    required this.frameWidthTiles,
    required this.frameHeightTiles,
    required this.direction,
  });

  final String characterId;
  final String tilesetId;
  final TilesetSourceRect sourceTileRect;
  final int frameWidthTiles;
  final int frameHeightTiles;
  final CinematicActorPreviewDirection direction;
}

@immutable
final class CinematicActorSpritePreviewActor {
  const CinematicActorSpritePreviewActor({
    required this.actorId,
    required this.actorLabel,
    required this.bindingKind,
    required this.position,
    required this.direction,
    required this.status,
    this.spriteRef,
    required this.placeholderFallback,
    required this.depthHint,
    required this.diagnostics,
  });

  final String actorId;
  final String actorLabel;
  final CinematicActorBindingKind bindingKind;
  final GridPos position;
  final CinematicActorPreviewDirection direction;
  final CinematicActorSpriteStatus status;
  final CinematicActorSpriteRef? spriteRef;
  final bool placeholderFallback;
  final CinematicActorSpriteDepthHint depthHint;
  final List<CinematicActorDisplayPreviewDiagnostic> diagnostics;
}

@immutable
final class CinematicActorSpritePreviewPlan {
  const CinematicActorSpritePreviewPlan({
    required this.actors,
    required this.diagnostics,
  });

  final List<CinematicActorSpritePreviewActor> actors;
  final List<CinematicActorDisplayPreviewDiagnostic> diagnostics;

  bool get hasReadySprites =>
      actors.any((actor) => actor.status == CinematicActorSpriteStatus.spriteReady);

  bool get hasFallbacks =>
      actors.any((actor) => actor.placeholderFallback);

  bool get hasErrors =>
      diagnostics.any((d) => d.severity == CinematicActorDisplayPreviewDiagnosticSeverity.error);
}
