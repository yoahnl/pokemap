import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/player_collision_hitbox_preview.dart';

void main() {
  group('buildPlayerCollisionHitboxPreview', () {
    test('uses PlayerCollisionConventionsV1 defaults', () {
      final preview = buildPlayerCollisionHitboxPreview();

      expect(
        preview.spriteWidthPx,
        PlayerCollisionConventionsV1.defaultSpriteWidthPx,
      );
      expect(
        preview.spriteHeightPx,
        PlayerCollisionConventionsV1.defaultSpriteHeightPx,
      );
      expect(
        preview.hitboxWidthPx,
        PlayerCollisionConventionsV1.playerHitboxWidthPx,
      );
      expect(
        preview.hitboxHeightPx,
        PlayerCollisionConventionsV1.playerHitboxHeightPx,
      );
      expect(preview.hitboxLeftPx, 10);
      expect(preview.hitboxTopPx, 24);
    });

    test('explains the foot hitbox without saying the full sprite blocks', () {
      final preview = buildPlayerCollisionHitboxPreview();

      expect(preview.title, 'Hitbox joueur');
      expect(preview.description, contains('zone aux pieds'));
      expect(preview.description, contains('déplacement'));
      expect(preview.description, isNot(contains('tout le sprite bloque')));
      expect(preview.dimensionsLabel, '12 × 8 px');
      expect(preview.positionLabel, contains('centrée en bas'));
    });

    test('centers hitbox for custom sprite size', () {
      final preview = buildPlayerCollisionHitboxPreview(
        spriteWidthPx: 48,
        spriteHeightPx: 40,
      );

      expect(preview.spriteWidthPx, 48);
      expect(preview.spriteHeightPx, 40);
      expect(preview.hitboxLeftPx, 18);
      expect(preview.hitboxTopPx, 32);
      expect(preview.hitboxWidthPx, 12);
      expect(preview.hitboxHeightPx, 8);
    });
  });
}
