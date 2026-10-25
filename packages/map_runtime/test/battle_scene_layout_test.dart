import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/map_runtime.dart'
    show BattleCommandPanelPlacement, BattleCommandOverlayMode;
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

/// Un viewport par classe, pour ne pas croire qu'une règle vérifiée sur un
/// desktop vaut sur un portrait compact.
const _certifiedViewports = <Size>[
  Size(1280, 720),
  Size(844, 390),
  Size(390, 844),
];

void main() {
  test(
    'compact portrait sprite bounds stay finite at enlarged text limits',
    () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(320, 568),
        controllerLayout: true,
        textScale: 2,
      );
      expect(layout.playerSpriteRect.isFinite, isTrue);
      expect(layout.playerSpriteRect.overlaps(layout.playerHudRect), isFalse);
      expect(
        layout.playerSpriteRect.bottom,
        lessThanOrEqualTo(layout.playerHudRect.top - 8 + .1),
      );
    },
  );

  test('compact portrait root and fight share every scene anchor with distinct natural docks', () {
    for (final viewport in [const Size(390, 844), const Size(320, 568), const Size(430, 932)]) {
      for (final textScale in [1.0, 2.0]) {
        final root = BattleSceneLayout.forViewport(viewportSize: viewport,
          safePadding: const EdgeInsets.only(top: 32, bottom: 24), controllerLayout: true,
          textScale: textScale, commandPanelMode: BattleCommandOverlayMode.root);
        final fight = BattleSceneLayout.forViewport(viewportSize: viewport,
          safePadding: const EdgeInsets.only(top: 32, bottom: 24), controllerLayout: true,
          textScale: textScale, commandPanelMode: BattleCommandOverlayMode.fight);
        expect(root.commandPanelRect.height, lessThan(fight.commandPanelRect.height));
        expect(root.commandPanelRect.height, lessThanOrEqualTo(128 * textScale.clamp(1.0, 1.6)));
        expect(root.enemyHudRect, fight.enemyHudRect, reason: '$viewport text$textScale enemy HUD');
        expect(root.playerHudRect, fight.playerHudRect, reason: '$viewport text$textScale player HUD');
        expect(root.enemySpriteRect, fight.enemySpriteRect, reason: '$viewport text$textScale enemy sprite');
        expect(root.playerSpriteRect, fight.playerSpriteRect, reason: '$viewport text$textScale player sprite');
        expect(root.enemyFootAnchor, fight.enemyFootAnchor);
        expect(root.playerFootAnchor, fight.playerFootAnchor);
        expect(root.enemyPlatformRect, fight.enemyPlatformRect);
        expect(root.playerPlatformRect, fight.playerPlatformRect);
        expect(root.stageRect, fight.stageRect);
        expect(root.arenaRect, fight.arenaRect);
      }
    }
  });

  test('single screen controller leaves the arena free with a bounded proportional dock', () {
    for (final viewport in [const Size(844, 390), const Size(1280, 590)]) {
      for (final safe in [
        EdgeInsets.zero,
        const EdgeInsets.fromLTRB(44, 32, 44, 20),
      ]) {
        final layouts = [
          for (final mode in [
            BattleCommandOverlayMode.root,
            BattleCommandOverlayMode.fight,
          ])
            BattleSceneLayout.forViewport(
              viewportSize: viewport,
              safePadding: safe,
              controllerLayout: true,
              commandPanelPlacement: BattleCommandPanelPlacement.end,
              commandPanelMode: mode,
            ),
        ];
        for (final layout in layouts) {
          expect(
            layout.commandPanelRect.width,
            lessThanOrEqualTo(viewport.width * .33),
          );
          expect(layout.commandPanelRect.width, lessThanOrEqualTo(340));
          expect(
            layout.commandPanelRect.top,
            greaterThanOrEqualTo(layout.enemyHudRect.bottom + 7),
          );
          expect(
            layout.commandPanelRect.bottom,
            lessThanOrEqualTo(viewport.height - safe.bottom),
          );
          expect(
            layout.commandPanelRect.left,
            greaterThanOrEqualTo(viewport.width * .60),
          );
        }
        expect(layouts[0].playerSpriteRect, layouts[1].playerSpriteRect);
        expect(layouts[0].enemySpriteRect, layouts[1].enemySpriteRect);
        expect(layouts[0].playerHudRect, layouts[1].playerHudRect);
        expect(layouts[0].enemyHudRect, layouts[1].enemyHudRect);
      }
    }
  });

  test('portrait controller budget uses the available height while touch and Thor keep their recipe', () {
    for (final viewport in [
      const Size(390, 844),
      const Size(320, 568),
      const Size(430, 932),
    ]) {
      for (final mode in [
        BattleCommandOverlayMode.root,
        BattleCommandOverlayMode.fight,
      ]) {
        final layout = BattleSceneLayout.forViewport(
          viewportSize: viewport,
          safePadding: const EdgeInsets.only(top: 32, bottom: 24),
          controllerLayout: true,
          commandPanelMode: mode,
        );
        expect(
          layout.commandPanelRect.height,
          lessThanOrEqualTo(mode == BattleCommandOverlayMode.root ? 128 : 236),
        );
        expect(
          layout.commandPanelRect.bottom,
          lessThanOrEqualTo(viewport.height - 24),
        );
        expect(
          layout.commandPanelRect.height,
          lessThanOrEqualTo((viewport.height - 56) * .46),
        );
      }
    }
    final touch = BattleSceneLayout.forViewport(
      viewportSize: const Size(390, 844),
    );
    expect(touch.commandPanelRect.height, 300);
    final thor = BattleSceneLayout.forViewport(
      viewportSize: const Size(768, 432),
      controllerLayout: true,
      commandPanelPlacement: BattleCommandPanelPlacement.detached,
    );
    expect(thor.commandPanelRect, Rect.zero);
    expect(thor.playerSpriteRect.width, 185);
  });

  test(
    'opaque collections reserve their measured panel and arena in every layout',
    () {
      for (final mode in [
        BattleCommandOverlayMode.bag,
        BattleCommandOverlayMode.pokemon,
        BattleCommandOverlayMode.bagMedicineTarget,
        BattleCommandOverlayMode.moveTarget,
      ]) {
        for (final viewport in [const Size(844, 390), const Size(390, 844)]) {
          for (final controller in [false, true]) {
            final layout = BattleSceneLayout.forViewport(
              viewportSize: viewport,
              commandPanelMode: mode,
              controllerLayout: controller,
              commandPanelPlacement: controller
                  ? BattleCommandPanelPlacement.end
                  : BattleCommandPanelPlacement.bottom,
            );
            expect(layout.sceneRect, Offset.zero & viewport);
            if (layout.isPortrait) {
              expect(layout.commandPanelRect.height, 560);
              expect(layout.commandPanelRect.width, viewport.width);
              expect(layout.arenaRect.bottom, layout.commandPanelRect.top);
              expect(
                layout.playerSpriteRect.bottom,
                lessThan(layout.commandPanelRect.top),
              );
            } else {
              expect(
                layout.commandPanelRect.width,
                mode == BattleCommandOverlayMode.moveTarget ? 310 : 460,
              );
              expect(layout.arenaRect.right, layout.commandPanelRect.left);
              expect(
                layout.playerHudRect.right,
                lessThan(layout.commandPanelRect.left),
              );
            }
            expect(layout.enemyHudRect.height, closeTo(40.5, .01));
            expect(layout.playerHudRect.height, closeTo(68.25, .01));
          }
        }
        final detached = BattleSceneLayout.forViewport(
          viewportSize: const Size(768, 432),
          commandPanelMode: mode,
          commandPanelPlacement: BattleCommandPanelPlacement.detached,
        );
        expect(detached.commandPanelRect, Rect.zero);
        expect(detached.sceneRect, const Rect.fromLTWH(0, 0, 768, 432));
      }
    },
  );

  test(
    'decision uses the journey panel geometry and portrait artwork frame',
    () {
      final landscape = BattleSceneLayout.forViewport(
        viewportSize: const Size(844, 390),
        safePadding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
        commandPanelMode: BattleCommandOverlayMode.decision,
      );
      expect(
        landscape.commandPanelRect,
        const Rect.fromLTWH(400, 20, 400, 350),
      );
      expect(landscape.commandPanelPlacement, BattleCommandPanelPlacement.end);
      final portrait = BattleSceneLayout.forViewport(
        viewportSize: const Size(390, 844),
        commandPanelMode: BattleCommandOverlayMode.decision,
      );
      expect(portrait.commandPanelRect, const Rect.fromLTWH(0, 464, 390, 380));
      expect(portrait.backdropArtworkRect, const Rect.fromLTWH(0, 0, 390, 464));
      expect(
        portrait.playerHudRect.bottom,
        lessThan(portrait.commandPanelRect.top),
      );
    },
  );

  test('double battler budgets use renderer foot ratios and stay inside their field', () {
    for (final viewport in [
      const Size(390, 844),
      const Size(844, 390),
      const Size(768, 432),
    ]) {
      for (final placement in BattleCommandPanelPlacement.values) {
        for (final mode in [
          BattleCommandOverlayMode.fight,
          BattleCommandOverlayMode.moveTarget,
        ]) {
          final layout = BattleSceneLayout.forViewport(
            viewportSize: viewport,
            commandPanelMode: mode,
            commandPanelPlacement: placement,
          );
          final field = Rect.fromLTRB(
            layout.arenaRect.left + 8,
            layout.arenaRect.top + 8,
            layout.arenaRect.right - 8,
            (layout.commandPanelPlacement == BattleCommandPanelPlacement.bottom
                    ? layout.commandPanelRect.top
                    : layout.arenaRect.bottom) -
                8,
          );
          for (final side in BattleSideId.values) {
            for (var index = 0; index < 2; index++) {
              final geometry = layout.combatantGeometry(
                BattleSlotRef(side: side, slotIndex: index),
                doubles: true,
              );
              final ratio = side == BattleSideId.player ? .68 : .5;
              expect(
                geometry.footAnchor.dx,
                closeTo(
                  geometry.spriteRect.left + geometry.spriteRect.width * ratio,
                  .0001,
                ),
              );
              expect(
                geometry.footAnchor.dy,
                closeTo(geometry.spriteRect.bottom, .0001),
              );
              for (final bounds in [
                geometry.spriteRect,
                geometry.platformRect,
              ]) {
                expect(bounds.left, greaterThanOrEqualTo(field.left - .0001));
                expect(bounds.top, greaterThanOrEqualTo(field.top - .0001));
                expect(bounds.right, lessThanOrEqualTo(field.right + .0001));
                expect(bounds.bottom, lessThanOrEqualTo(field.bottom + .0001));
              }
              for (final aspect in [.5, 1.0, 2.0]) {
                final width = (geometry.spriteRect.height * aspect).clamp(
                  0.0,
                  geometry.spriteRect.width,
                );
                final height = width / aspect;
                final painted = Rect.fromLTWH(
                  geometry.footAnchor.dx - width * ratio,
                  geometry.footAnchor.dy - height,
                  width,
                  height,
                );
                expect(painted.left, greaterThanOrEqualTo(field.left - .0001));
                expect(painted.right, lessThanOrEqualTo(field.right + .0001));
                expect(painted.top, greaterThanOrEqualTo(field.top - .0001));
                expect(painted.bottom, lessThanOrEqualTo(field.bottom + .0001));
              }
            }
          }
        }
      }
    }
  });

  for (final scenario in [
    (const Size(390, 844), const EdgeInsets.fromLTRB(0, 32, 0, 24)),
    (const Size(844, 390), const EdgeInsets.fromLTRB(44, 12, 44, 20)),
    (const Size(768, 432), const EdgeInsets.fromLTRB(0, 20, 0, 0)),
  ]) {
    test(
      'double HUDs and sprites respect actual safe insets at ${scenario.$1}',
      () {
        for (final placement in BattleCommandPanelPlacement.values) {
          for (final mode in [
            BattleCommandOverlayMode.fight,
            BattleCommandOverlayMode.moveTarget,
          ]) {
            final layout = BattleSceneLayout.forViewport(
              viewportSize: scenario.$1,
              safePadding: scenario.$2,
              commandPanelPlacement: placement,
              commandPanelMode: mode,
            );
            final safe = Rect.fromLTRB(
              scenario.$2.left,
              scenario.$2.top,
              scenario.$1.width - scenario.$2.right,
              scenario.$1.height - scenario.$2.bottom,
            );
            for (final side in BattleSideId.values) {
              for (var index = 0; index < 2; index++) {
                final actor = layout.combatantGeometry(
                  BattleSlotRef(side: side, slotIndex: index),
                  doubles: true,
                );
                for (final rect in [
                  actor.hudRect,
                  actor.spriteRect,
                  actor.platformRect,
                ]) {
                  expect(rect.left, greaterThanOrEqualTo(safe.left - .0001));
                  expect(rect.top, greaterThanOrEqualTo(safe.top - .0001));
                  expect(rect.right, lessThanOrEqualTo(safe.right + .0001));
                  expect(rect.bottom, lessThanOrEqualTo(safe.bottom + .0001));
                  expect(
                    rect.left,
                    greaterThanOrEqualTo(layout.arenaRect.left),
                  );
                  expect(rect.right, lessThanOrEqualTo(layout.arenaRect.right));
                  expect(
                    rect.bottom,
                    lessThanOrEqualTo(layout.arenaRect.bottom),
                  );
                }
              }
            }
          }
        }
      },
    );
  }

  test('root and fight keep the same HUD and sprite geometry for every presentation', () {
    for (final viewport in const [
      Size(390, 844),
      Size(844, 390),
      Size(1280, 720),
    ]) {
      for (final placement in BattleCommandPanelPlacement.values) {
        final root = BattleSceneLayout.forViewport(
          viewportSize: viewport,
          commandPanelPlacement: placement,
          commandPanelMode: BattleCommandOverlayMode.root,
        );
        final fight = BattleSceneLayout.forViewport(
          viewportSize: viewport,
          commandPanelPlacement: placement,
          commandPanelMode: BattleCommandOverlayMode.fight,
        );
        expect(root.enemyHudRect, fight.enemyHudRect);
        expect(root.playerHudRect, fight.playerHudRect);
        expect(root.enemySpriteRect, fight.enemySpriteRect);
        expect(root.playerSpriteRect, fight.playerSpriteRect);
        if (root.commandPanelPlacement == BattleCommandPanelPlacement.end) {
          expect(root.commandPanelRect.width, 310);
          expect(fight.commandPanelRect.width, 293);
        } else {
          expect(root.commandPanelRect, fight.commandPanelRect);
        }
      }
    }
  });

  test('controller opaque budgets follow normalized Ligue proportions with bounded overlap', () {
    for (final viewport in const [
      Size(844, 390),
      Size(760, 351),
      Size(1280, 720),
    ]) {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: viewport,
        commandPanelPlacement: BattleCommandPanelPlacement.end,
      );
      final scale = (viewport.width / 844)
          .clamp(0.0, viewport.height / 390)
          .clamp(0.0, 1.0);
      expect(layout.playerSpriteRect.left, closeTo(169 * scale, .01));
      expect(layout.playerSpriteRect.width, closeTo(148 * scale, .01));
      expect(layout.playerSpriteRect.height, closeTo(134 * scale, .01));
      expect(
        viewport.height - layout.playerSpriteRect.bottom,
        closeTo(77 * scale, .01),
      );
      expect(
        layout.enemySpriteRect.right,
        closeTo(
          (viewport.width - 343.5 * scale).clamp(0.0, layout.arenaRect.right),
          .01,
        ),
      );
      expect(
        viewport.height - layout.enemySpriteRect.bottom,
        closeTo(159 * scale, .01),
      );
      expect(
        layout.playerHudRect.intersect(layout.playerSpriteRect).height,
        lessThanOrEqualTo(layout.playerSpriteRect.height * .083),
      );
      expect(layout.playerHudRect.overlaps(layout.playerPlatformRect), isFalse);
    }
  });

  test('non-controller Ligue profiles use opaque silhouette budgets and measured HUD heights', () {
    final portrait = BattleSceneLayout.forViewport(
      viewportSize: const Size(390, 844),
    );
    expect(portrait.commandPanelRect, const Rect.fromLTWH(18, 520, 354, 300));
    expect(portrait.enemyHudRect, const Rect.fromLTWH(14, 48, 216, 40.5));
    expect(
      portrait.playerHudRect,
      const Rect.fromLTWH(158, 421.75, 218, 68.25),
    );
    expect(portrait.playerSpriteRect, const Rect.fromLTWH(28, 270.5, 147, 137));
    expect(portrait.enemySpriteRect.left, 254);
    expect(portrait.enemySpriteRect.top, closeTo(260, .01));
    expect(portrait.enemySpriteRect.width, closeTo(98.7, .01));
    expect(portrait.enemySpriteRect.height, closeTo(109.3, .01));
    final tactile = BattleSceneLayout.forViewport(
      viewportSize: const Size(844, 390),
    );
    expect(tactile.commandPanelRect, const Rect.fromLTWH(24, 270, 796, 108));
    expect(tactile.enemyHudRect, const Rect.fromLTWH(20, 12, 216, 40.5));
    expect(tactile.playerHudRect, const Rect.fromLTWH(610, 179.75, 210, 68.25));
    expect(tactile.playerSpriteRect.left, closeTo(140.6, .01));
    expect(tactile.playerSpriteRect.width, closeTo(134.7, .01));
    expect(tactile.playerSpriteRect.height, closeTo(126.3, .01));
    expect(tactile.playerSpriteRect.bottom, closeTo(257.8, .01));
    expect(tactile.enemySpriteRect.width, closeTo(84.8, .01));
    expect(tactile.enemySpriteRect.height, closeTo(94, .01));
    expect(tactile.enemyHudRect.overlaps(tactile.enemySpriteRect), isFalse);
    expect(tactile.playerHudRect.overlaps(tactile.enemyPlatformRect), isFalse);
    final primary = BattleSceneLayout.forViewport(
      viewportSize: const Size(768, 432),
      commandPanelPlacement: BattleCommandPanelPlacement.detached,
    );
    expect(primary.enemyHudRect, const Rect.fromLTWH(24, 22, 244, 40.5));
    expect(primary.playerHudRect, const Rect.fromLTWH(494, 343.75, 250, 68.25));
    expect(primary.playerSpriteRect, const Rect.fromLTWH(99, 184, 185, 174));
    expect(primary.enemySpriteRect, const Rect.fromLTWH(469, 128.5, 128, 142));
    for (final layout in [portrait, tactile, primary]) {
      expect(
        layout.playerFootAnchor.dx,
        closeTo(
          layout.playerSpriteRect.left + layout.playerSpriteRect.width * .68,
          .01,
        ),
      );
      expect(layout.playerFootAnchor.dy, layout.playerSpriteRect.bottom);
      expect(layout.enemyFootAnchor.dy, layout.enemySpriteRect.bottom);
    }
  });

  test(
    'Ligue docks take the greater CSS or system inset without adding both',
    () {
      final tactile = BattleSceneLayout.forViewport(
        viewportSize: const Size(844, 390),
        safePadding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
      );
      expect(tactile.commandPanelRect, const Rect.fromLTWH(44, 262, 756, 108));
      expect(tactile.enemyHudRect.top, 12);
      final portrait = BattleSceneLayout.forViewport(
        viewportSize: const Size(390, 844),
        safePadding: const EdgeInsets.only(top: 32, bottom: 24),
      );
      expect(portrait.commandPanelRect, const Rect.fromLTWH(18, 520, 354, 300));
      expect(portrait.enemyHudRect.top, 48);
    },
  );

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

  for (final size in [
    const Size(844, 390),
    const Size(960, 540),
    const Size(1280, 720),
  ]) {
    for (final placement in [
      BattleCommandPanelPlacement.end,
      BattleCommandPanelPlacement.detached,
    ]) {
      test(
        'reserved $placement arena keeps HUDs and single or double sprites clear at $size',
        () {
          final layout = BattleSceneLayout.forViewport(
            viewportSize: size,
            commandPanelPlacement: placement,
          );
          expect(layout.commandPanelPlacement, placement);
          if (placement == BattleCommandPanelPlacement.detached) {
            expect(layout.commandPanelRect.isEmpty, isTrue);
            expect(layout.arenaRect, layout.sceneRect);
          } else {
            expect(
              layout.arenaRect.right,
              lessThan(layout.commandPanelRect.left),
            );
          }
          for (final doubleBattle in [false, true]) {
            for (final side in BattleSideId.values) {
              for (var slot = 0; slot < (doubleBattle ? 2 : 1); slot++) {
                final geometry = layout.combatantGeometry(
                  BattleSlotRef(side: side, slotIndex: slot),
                  doubles: doubleBattle,
                );
                expect(geometry.spriteRect.width, greaterThan(0));
                expect(geometry.spriteRect.height, greaterThan(0));
                expect(
                  rectInside(geometry.spriteRect, layout.arenaRect),
                  isTrue,
                );
                expect(rectInside(geometry.hudRect, layout.sceneRect), isTrue);
                if (placement == BattleCommandPanelPlacement.end &&
                    !doubleBattle &&
                    side == BattleSideId.player) {
                  expect(
                    geometry.hudRect.intersect(geometry.spriteRect).height,
                    lessThanOrEqualTo(geometry.spriteRect.height * .083),
                  );
                  expect(
                    geometry.hudRect.contains(geometry.footAnchor),
                    isFalse,
                  );
                } else {
                  expect(
                    geometry.hudRect.overlaps(geometry.spriteRect),
                    isFalse,
                  );
                }
                if (!layout.commandPanelRect.isEmpty) {
                  expect(
                    geometry.spriteRect.overlaps(layout.commandPanelRect),
                    isFalse,
                  );
                  expect(
                    geometry.hudRect.overlaps(layout.commandPanelRect),
                    isFalse,
                  );
                }
              }
            }
          }
        },
      );
    }
  }
  test('side and detached HUDs clear every sprite and platform at large text', () {
    for (final placement in [
      BattleCommandPanelPlacement.end,
      BattleCommandPanelPlacement.detached,
    ]) {
      for (final scale in [1.0, 1.6]) {
        final layout = BattleSceneLayout.forViewport(
          viewportSize: const Size(844, 390),
          commandPanelPlacement: placement,
          textScale: scale,
        );
        for (final doubles in [false, true]) {
          final geometry = [
            for (final side in BattleSideId.values)
              for (var slot = 0; slot < (doubles ? 2 : 1); slot++)
                layout.combatantGeometry(
                  BattleSlotRef(side: side, slotIndex: slot),
                  doubles: doubles,
                ),
          ];
          for (final hud in geometry.map((g) => g.hudRect)) {
            expect(rectInside(hud, layout.sceneRect), isTrue);
            expect(hud.overlaps(layout.commandPanelRect), isFalse);
            for (final actor in geometry) {
              final referencePlayerOverlap =
                  placement == BattleCommandPanelPlacement.end &&
                  !doubles &&
                  hud == layout.playerHudRect &&
                  actor.spriteRect == layout.playerSpriteRect;
              if (referencePlayerOverlap) {
                expect(
                  hud.intersect(actor.spriteRect).height,
                  lessThanOrEqualTo(actor.spriteRect.height * .083),
                );
                expect(hud.contains(actor.footAnchor), isFalse);
              } else {
                expect(
                  hud.overlaps(actor.spriteRect),
                  isFalse,
                  reason:
                      '$placement scale $scale doubles $doubles HUD $hud sprite ${actor.spriteRect}',
                );
              }
              expect(
                hud.overlaps(actor.platformRect),
                isFalse,
                reason:
                    '$placement scale $scale doubles $doubles HUD $hud platform ${actor.platformRect}',
              );
            }
          }
        }
      }
    }
  });
  group('BattleSceneLayout viewport contract', () {
    const viewports = <Size>[
      Size(360, 800),
      Size(375, 812),
      Size(390, 844),
      Size(412, 915),
      Size(528, 467),
      Size(540, 960),
      Size(640, 360),
      Size(700, 420),
      Size(844, 390),
      Size(834, 1194),
      Size(960, 540),
      Size(1012, 467),
      Size(1194, 834),
      Size(1280, 720),
      Size(1600, 900),
      Size(1024, 768),
    ];

    for (final viewport in viewports) {
      test('keeps a valid composition at ${viewport.width}x${viewport.height}', () {
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

        expect(
          layout.playerSpriteRect.height,
          greaterThan(layout.enemySpriteRect.height),
        );
        expect(
          layout.playerSpriteRect.width,
          greaterThan(layout.enemySpriteRect.width),
        );
        expect(
          layout.playerFootAnchor.dy,
          greaterThan(layout.enemyFootAnchor.dy),
        );
        expect(
          layout.enemyFootAnchor.dx,
          greaterThan(layout.playerFootAnchor.dx),
        );

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
        // La quatrieme paire, la seule qui manquait, et la seule qui cassait :
        // le HUD joueur est place en pixels d'ecran au-dessus du panneau tandis
        // que l'ennemi est place en pixels de scene, donc les deux se croisaient
        // sous une echelle d'environ 0,5 - tous les telephones en portrait,
        // 390x844 inclus, deja present dans cette liste et deja au vert.
        expect(layout.playerHudRect.overlaps(layout.enemySpriteRect), isFalse);

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

    test('classifies battle viewports', () {
      expect(
        BattleSceneLayout.forViewport(viewportSize: const Size(390, 844))
            .viewportClass,
        BattleViewportClass.compactPortrait,
      );
      expect(
        BattleSceneLayout.forViewport(viewportSize: const Size(844, 390))
            .viewportClass,
        BattleViewportClass.mediumLandscape,
      );
      expect(
        BattleSceneLayout.forViewport(viewportSize: const Size(1280, 720))
            .viewportClass,
        BattleViewportClass.wideDesktop,
      );
    });

    test('uses stacked command panel layout on mobile portrait', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(390, 844),
      );

      expect(
        layout.commandPanelLayoutMode,
        BattleCommandPanelLayoutMode.stacked,
      );
    });

    test('keeps split command panel layout when landscape space allows it', () {
      expect(
        BattleSceneLayout.forViewport(viewportSize: const Size(844, 390))
            .commandPanelLayoutMode,
        BattleCommandPanelLayoutMode.split,
      );
      expect(
        BattleSceneLayout.forViewport(viewportSize: const Size(1280, 720))
            .commandPanelLayoutMode,
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

      expect(
        wide.playerSpriteRect.width,
        closeTo(reference.playerSpriteRect.width, 0.01),
      );
      expect(
        wide.playerSpriteRect.height,
        closeTo(reference.playerSpriteRect.height, 0.01),
      );
      expect(
        wide.enemySpriteRect.width,
        closeTo(reference.enemySpriteRect.width, 0.01),
      );
      expect(
        wide.enemySpriteRect.height,
        closeTo(reference.enemySpriteRect.height, 0.01),
      );
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
      expect(
        layout.playerSpriteRect.overlaps(layout.commandPanelRect),
        isFalse,
      );
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
      expect(
        layout.playerSpriteRect.overlaps(layout.commandPanelRect),
        isFalse,
      );
    });

    test('keeps compact portrait staging protected at 390x844', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(390, 844),
      );

      expect(layout.viewportClass, BattleViewportClass.compactPortrait);
      expect(
        layout.commandPanelLayoutMode,
        BattleCommandPanelLayoutMode.stacked,
      );
      expect(layout.commandPanelRect.height, 300.0);
      expect(
        layout.stageRect.bottom,
        lessThanOrEqualTo(layout.commandPanelRect.top - 10),
      );
      expect(
        layout.enemyHudRect.left,
        greaterThanOrEqualTo(layout.portraitSafeMargin),
      );
    });

    test('portrait staging fills the arena without HUD or panel occlusion', () {
      for (final size in [
        const Size(360, 640),
        const Size(390, 844),
        const Size(430, 932),
      ]) {
        for (final scale in [1.0, 1.6]) {
          final layout = BattleSceneLayout.forViewport(
            viewportSize: size,
            safePadding: size.height > 800
                ? const EdgeInsets.fromLTRB(0, 59, 0, 34)
                : EdgeInsets.zero,
            textScale: scale,
          );
          for (final hud in [layout.enemyHudRect, layout.playerHudRect]) {
            expect(rectInside(hud, layout.arenaRect), isTrue);
            for (final sprite in [
              layout.playerSpriteRect,
              layout.enemySpriteRect,
              layout.playerPlatformRect,
              layout.enemyPlatformRect,
            ]) {
              expect(
                hud.overlaps(sprite),
                isFalse,
                reason: '$size/$scale: $hud overlaps $sprite',
              );
              expect(rectInside(sprite, layout.arenaRect), isTrue);
              expect(sprite.overlaps(layout.commandPanelRect), isFalse);
            }
          }
          if (size.width == 390) {
            expect(layout.commandPanelRect.top, closeTo(510, 16));
            expect(layout.playerSpriteRect.height, closeTo(137, .01));
            expect(layout.enemySpriteRect.height, closeTo(109.3, .01));
          }
        }
      }
    });

    test('keeps medium landscape split at 844x390', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(844, 390),
      );

      expect(layout.viewportClass, BattleViewportClass.mediumLandscape);
      expect(layout.commandPanelLayoutMode, BattleCommandPanelLayoutMode.split);
      expect(layout.commandPanelRect.height, 108.0);
      expect(layout.commandPanelRect.width, greaterThanOrEqualTo(796.0));
      expect(
        layout.playerHudRect.bottom,
        lessThanOrEqualTo(layout.commandPanelRect.top - 8),
      );
    });

    test('keeps wide desktop airy at 1280x720', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(1280, 720),
      );

      expect(layout.viewportClass, BattleViewportClass.wideDesktop);
      expect(layout.commandPanelLayoutMode, BattleCommandPanelLayoutMode.split);
      expect(layout.commandPanelRect.height, inInclusiveRange(140.0, 184.0));
      expect(layout.scale, closeTo(1.0, 0.001));
      expect(
        layout.stageRect.bottom,
        lessThanOrEqualTo(layout.commandPanelRect.top - 14),
      );
    });

    group('portrait hardening', () {
      const portraitSafeMargin = 14.0;
      const portraitViewports = <Size>[
        Size(390, 844),
        Size(430, 932),
        Size(480, 854),
      ];

      for (final viewport in portraitViewports) {
        test(
          'keeps portrait HUDs off the screen edges at ${viewport.width}x${viewport.height}',
          () {
            final layout = BattleSceneLayout.forViewport(
              viewportSize: viewport,
            );

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
            expect(
              layout.playerHudRect.overlaps(layout.commandPanelRect),
              isFalse,
            );
          },
        );
      }

      test('gives portrait HUDs more breathing room than the 4e baseline', () {
        final layout = BattleSceneLayout.forViewport(
          viewportSize: const Size(390, 844),
        );

        expect(layout.enemyHudRect.width, greaterThanOrEqualTo(110));
        expect(layout.playerHudRect.width, greaterThanOrEqualTo(128));
        expect(layout.enemyHudRect.height, greaterThanOrEqualTo(40));
        expect(layout.playerHudRect.height, greaterThanOrEqualTo(54));
      });
    });
  });

  /// BETA-BAT-007. Les rectangles de HUD grandissent quand le joueur demande du
  /// texte plus grand.
  ///
  /// Autorisé par Yoahn le 2026-08-20 après un constat chiffré : à hauteur fixe,
  /// le HUD n'accordait que 1.03 à 1.29 sur une demande de 1.6, quel que soit le
  /// soin apporté aux polices. La hauteur du rectangle ÉTAIT le plafond.
  ///
  /// Le HUD est en priorité 20, donc il recouvre le décor : la contrainte n'est
  /// pas la place, c'est l'occultation, et c'est le titre même de BETA-BAT-009.
  group('BETA-BAT-007 the HUD rects grow with the requested text scale', () {
    test('the certified geometry does not move at scale 1.0', () {
      // Le garde le plus important du lot : l'accessibilité texte ne doit rien
      // changer à l'écran de quelqu'un qui ne l'a pas demandée.
      for (final viewport in _certifiedViewports) {
        final implicit = BattleSceneLayout.forViewport(viewportSize: viewport);
        final explicit = BattleSceneLayout.forViewport(
          viewportSize: viewport,
          textScale: 1.0,
        );

        expect(
          explicit.enemyHudRect,
          implicit.enemyHudRect,
          reason: '$viewport',
        );
        expect(
          explicit.playerHudRect,
          implicit.playerHudRect,
          reason: '$viewport',
        );
        // Et un texte plus PETIT ne rétrécit pas la boîte : la police suffit.
        final smaller = BattleSceneLayout.forViewport(
          viewportSize: viewport,
          textScale: 0.8,
        );
        expect(
          smaller.enemyHudRect,
          implicit.enemyHudRect,
          reason: '$viewport',
        );
      }
    });

    test('a grown HUD never occludes a sprite or the command panel', () {
      // L'invariant produit. Le chevauchement est comparé À LA BASE et non à
      // zéro, parce qu'il en existe déjà un : en portrait compact, le HUD joueur
      // recouvre 8 px du bas du sprite ennemi avant toute mise à l'échelle.
      // Exiger l'absence totale de chevauchement échouerait sur du rendu en
      // service et masquerait la vraie question, qui est « est-ce que MOI j'en
      // ajoute un ».
      for (final viewport in _certifiedViewports) {
        final base = BattleSceneLayout.forViewport(viewportSize: viewport);
        for (final requested in const <double>[1.1, 1.3, 1.6, 4.0]) {
          final grown = BattleSceneLayout.forViewport(
            viewportSize: viewport,
            textScale: requested,
          );
          final obstacles = <String, Rect>{
            'playerSprite': grown.playerSpriteRect,
            'enemySprite': grown.enemySpriteRect,
            'commandPanel': grown.commandPanelRect,
          };

          for (final side in const <String>['enemy', 'player']) {
            final baseRect = side == 'enemy'
                ? base.enemyHudRect
                : base.playerHudRect;
            final grownRect = side == 'enemy'
                ? grown.enemyHudRect
                : grown.playerHudRect;

            for (final obstacle in obstacles.entries) {
              if (baseRect.overlaps(obstacle.value)) continue;
              expect(
                grownRect.overlaps(obstacle.value),
                isFalse,
                reason: '$viewport $side at $requested hides ${obstacle.key}',
              );
            }
            expect(
              rectInside(grownRect, grown.sceneRect),
              isTrue,
              reason: '$viewport $side at $requested left the scene',
            );
          }

          expect(
            grown.enemyHudRect.overlaps(grown.playerHudRect),
            isFalse,
            reason: '$viewport at $requested: the two HUDs collided',
          );
        }
      }
    });
  });
}
