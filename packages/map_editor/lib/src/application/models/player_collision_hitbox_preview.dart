import 'package:map_core/map_core.dart';

final class PlayerCollisionHitboxPreview {
  const PlayerCollisionHitboxPreview({
    required this.spriteWidthPx,
    required this.spriteHeightPx,
    required this.hitboxLeftPx,
    required this.hitboxTopPx,
    required this.hitboxWidthPx,
    required this.hitboxHeightPx,
    required this.title,
    required this.description,
    required this.dimensionsLabel,
    required this.positionLabel,
  });

  final int spriteWidthPx;
  final int spriteHeightPx;
  final int hitboxLeftPx;
  final int hitboxTopPx;
  final int hitboxWidthPx;
  final int hitboxHeightPx;
  final String title;
  final String description;
  final String dimensionsLabel;
  final String positionLabel;
}

PlayerCollisionHitboxPreview buildPlayerCollisionHitboxPreview({
  int spriteWidthPx = PlayerCollisionConventionsV1.defaultSpriteWidthPx,
  int spriteHeightPx = PlayerCollisionConventionsV1.defaultSpriteHeightPx,
}) {
  final hitbox =
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
    spriteTopLeftPx: const PixelPosition(leftPx: 0, topPx: 0),
    spriteWidthPx: spriteWidthPx,
    spriteHeightPx: spriteHeightPx,
  );

  return PlayerCollisionHitboxPreview(
    spriteWidthPx: spriteWidthPx,
    spriteHeightPx: spriteHeightPx,
    hitboxLeftPx: hitbox.leftPx,
    hitboxTopPx: hitbox.topPx,
    hitboxWidthPx: hitbox.widthPx,
    hitboxHeightPx: hitbox.heightPx,
    title: 'Hitbox joueur',
    description:
        'Le déplacement utilise une petite zone aux pieds du personnage. '
        'Ce rectangle touche réellement les collisions.',
    dimensionsLabel: '${hitbox.widthPx} × ${hitbox.heightPx} px',
    positionLabel: 'Zone de contact centrée en bas du sprite',
  );
}
