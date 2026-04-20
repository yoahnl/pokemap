import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

void main() {
  double intersectionRatio(Rect rect, Rect container) {
    final intersection = rect.intersect(container);
    if (intersection.isEmpty) {
      return 0;
    }
    return intersection.width *
        intersection.height /
        (rect.width * rect.height);
  }

  bool rectInside(Rect rect, Rect bounds) {
    return rect.left >= bounds.left &&
        rect.top >= bounds.top &&
        rect.right <= bounds.right &&
        rect.bottom <= bounds.bottom;
  }

  group('BattleSceneLayout viewport contract', () {
    const viewports = <Size>[
      Size(390, 844),
      Size(528, 467),
      Size(640, 360),
      Size(844, 390),
      Size(960, 540),
      Size(1012, 467),
      Size(1280, 720),
      Size(1600, 900),
      Size(1024, 768),
    ];

    for (final viewport in viewports) {
      test('keeps a valid composition at ${viewport.width}x${viewport.height}',
          () {
        final layout = BattleSceneLayout.forViewport(viewportSize: viewport);

        expect(layout.sceneRect.width, greaterThan(0));
        expect(layout.sceneRect.height, greaterThan(0));
        expect(layout.stageRect.width, greaterThan(0));
        expect(layout.stageRect.height, greaterThan(0));
        expect(layout.commandPanelRect.width, greaterThan(0));
        expect(layout.commandPanelRect.height, greaterThan(0));

        expect(rectInside(layout.commandPanelRect, layout.sceneRect), isTrue);
        expect(rectInside(layout.enemyHudRect, layout.sceneRect), isTrue);
        expect(rectInside(layout.playerHudRect, layout.sceneRect), isTrue);

        expect(layout.playerSpriteRect.height,
            greaterThan(layout.enemySpriteRect.height));
        expect(layout.playerSpriteRect.width,
            greaterThan(layout.enemySpriteRect.width));
        expect(
            layout.playerFootAnchor.dy, greaterThan(layout.enemyFootAnchor.dy));
        expect(
            layout.enemyFootAnchor.dx, greaterThan(layout.playerFootAnchor.dx));

        expect(
          intersectionRatio(layout.playerSpriteRect, layout.stageRect),
          greaterThanOrEqualTo(0.72),
        );
        expect(
          intersectionRatio(layout.enemySpriteRect, layout.stageRect),
          greaterThanOrEqualTo(0.9),
        );

        expect(
          layout.playerSpriteRect.bottom,
          lessThanOrEqualTo(layout.commandPanelRect.top),
        );
        expect(
          layout.enemySpriteRect.bottom,
          lessThanOrEqualTo(layout.commandPanelRect.top),
        );
        expect(
          layout.playerHudRect.bottom,
          lessThanOrEqualTo(layout.commandPanelRect.top),
        );

        expect(
          layout.playerSpriteRect.overlaps(layout.enemyHudRect.inflate(8)),
          isFalse,
        );
        expect(
          layout.enemySpriteRect.overlaps(layout.enemyHudRect.inflate(8)),
          isFalse,
        );
        expect(layout.playerHudRect.overlaps(layout.playerSpriteRect), isFalse);
        expect(layout.enemyHudRect.overlaps(layout.enemySpriteRect), isFalse);

        expect(
          layout.playerPlatformRect.center.dx,
          closeTo(layout.playerFootAnchor.dx, 0.01),
        );
        expect(
          layout.enemyPlatformRect.center.dx,
          closeTo(layout.enemyFootAnchor.dx, 0.01),
        );
        expect(
          layout.playerPlatformRect.top,
          greaterThanOrEqualTo(layout.playerFootAnchor.dy - 6),
        );
        expect(
          layout.enemyPlatformRect.top,
          greaterThanOrEqualTo(layout.enemyFootAnchor.dy - 6),
        );
        expect(
          layout.playerSpriteRect.top,
          greaterThan(layout.enemyHudRect.bottom),
        );
      });
    }

    test('uses stacked command panel layout on mobile portrait', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(390, 844),
      );

      expect(
          layout.commandPanelLayoutMode, BattleCommandPanelLayoutMode.stacked);
    });

    test('keeps split command panel layout when landscape space allows it', () {
      expect(
        BattleSceneLayout.forViewport(
          viewportSize: const Size(844, 390),
        ).commandPanelLayoutMode,
        BattleCommandPanelLayoutMode.split,
      );
      expect(
        BattleSceneLayout.forViewport(
          viewportSize: const Size(1280, 720),
        ).commandPanelLayoutMode,
        BattleCommandPanelLayoutMode.split,
      );
    });

    test('prevents battlers from inflating on wide desktop viewports', () {
      final reference = BattleSceneLayout.forViewport(
        viewportSize: const Size(960, 540),
      );
      final wide = BattleSceneLayout.forViewport(
        viewportSize: const Size(1600, 900),
      );

      expect(wide.playerSpriteRect.width,
          closeTo(reference.playerSpriteRect.width, 0.01));
      expect(wide.playerSpriteRect.height,
          closeTo(reference.playerSpriteRect.height, 0.01));
      expect(wide.enemySpriteRect.width,
          closeTo(reference.enemySpriteRect.width, 0.01));
      expect(wide.enemySpriteRect.height,
          closeTo(reference.enemySpriteRect.height, 0.01));
    });

    test('keeps the product validation viewport 528x467 readable', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(528, 467),
      );

      expect(
        layout.playerSpriteRect.overlaps(layout.enemyHudRect.inflate(8)),
        isFalse,
      );
      expect(
        layout.enemySpriteRect.overlaps(layout.enemyHudRect.inflate(8)),
        isFalse,
      );
      expect(layout.playerHudRect.overlaps(layout.commandPanelRect), isFalse);
      expect(layout.playerSpriteRect.overlaps(layout.commandPanelRect), isFalse);
    });

    test('keeps the product validation viewport 1012x467 readable', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(1012, 467),
      );

      expect(
        layout.playerSpriteRect.overlaps(layout.enemyHudRect.inflate(8)),
        isFalse,
      );
      expect(
        layout.enemySpriteRect.overlaps(layout.enemyHudRect.inflate(8)),
        isFalse,
      );
      expect(layout.playerHudRect.overlaps(layout.commandPanelRect), isFalse);
      expect(layout.playerSpriteRect.overlaps(layout.commandPanelRect), isFalse);
    });

    group('portrait hardening', () {
      const portraitSafeMargin = 14.0;
      const portraitViewports = <Size>[
        Size(390, 844),
        Size(430, 932),
        Size(480, 854),
      ];

      for (final viewport in portraitViewports) {
        test('keeps portrait HUDs off the screen edges at ${viewport.width}x${viewport.height}',
            () {
          final layout = BattleSceneLayout.forViewport(viewportSize: viewport);

          expect(
            layout.enemyHudRect.left,
            greaterThanOrEqualTo(portraitSafeMargin),
          );
          expect(
            layout.sceneRect.right - layout.playerHudRect.right,
            greaterThanOrEqualTo(portraitSafeMargin),
          );
          expect(
            layout.enemyHudRect.overlaps(layout.enemySpriteRect.inflate(4)),
            isFalse,
          );
          expect(
            layout.enemyHudRect.overlaps(layout.playerSpriteRect.inflate(4)),
            isFalse,
          );
          expect(layout.playerHudRect.overlaps(layout.commandPanelRect), isFalse);
        });
      }

      test('gives portrait HUDs more breathing room than the 4e baseline', () {
        final layout = BattleSceneLayout.forViewport(
          viewportSize: const Size(390, 844),
        );

        expect(layout.enemyHudRect.width, greaterThanOrEqualTo(110));
        expect(layout.playerHudRect.width, greaterThanOrEqualTo(128));
      });
    });
  });
}
