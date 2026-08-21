import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_hud_layout.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

/// Un viewport par classe, pour ne pas croire qu'une règle vérifiée sur un
/// desktop vaut sur un portrait compact.
const _certifiedViewports = <Size>[
  Size(1280, 720),
  Size(844, 390),
  Size(390, 844),
];

/// Taille de police du nom réellement rendue dans un rectangle donné.
///
/// C'est la SEULE mesure comparable entre deux tailles de boîte.
/// `effectiveTextScale` ne l'est pas : il est relatif au palier de la boîte, et
/// une boîte agrandie change souvent de palier. Mesuré — en paysage 844x390 à
/// 1.2, la boîte agrandie annonce 1.10 contre 1.20 pour la petite, alors qu'elle
/// rend du 15.4 px contre 14.4. Comparer les échelles aurait donc rapporté une
/// régression qui n'existe pas.
double _renderedNameFontSize(Rect hudRect, double textScale) {
  return BattleSceneHudLayout.forBounds(
    hudRect: Offset.zero & hudRect.size,
    isPlayerSide: true,
    speciesText: 'CHARMANDER',
    genderSymbol: '♂',
    levelText: 'Lv.100',
    hpValueText: '152/152',
    statusText: 'PAR',
    textScale: textScale,
  ).nameFontSize;
}

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
        BattleSceneLayout.forViewport(
          viewportSize: const Size(390, 844),
        ).viewportClass,
        BattleViewportClass.compactPortrait,
      );
      expect(
        BattleSceneLayout.forViewport(
          viewportSize: const Size(844, 390),
        ).viewportClass,
        BattleViewportClass.mediumLandscape,
      );
      expect(
        BattleSceneLayout.forViewport(
          viewportSize: const Size(1280, 720),
        ).viewportClass,
        BattleViewportClass.wideDesktop,
      );
    });

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
      expect(
          layout.playerSpriteRect.overlaps(layout.commandPanelRect), isFalse);
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
          layout.playerSpriteRect.overlaps(layout.commandPanelRect), isFalse);
    });

    test('keeps compact portrait staging protected at 390x844', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(390, 844),
      );

      expect(layout.viewportClass, BattleViewportClass.compactPortrait);
      expect(
          layout.commandPanelLayoutMode, BattleCommandPanelLayoutMode.stacked);
      expect(layout.commandPanelRect.height, inInclusiveRange(280.0, 304.0));
      expect(
        layout.stageRect.bottom,
        lessThanOrEqualTo(layout.commandPanelRect.top - 10),
      );
      expect(
        layout.enemyHudRect.left,
        greaterThanOrEqualTo(layout.portraitSafeMargin),
      );
    });

    test('keeps medium landscape split at 844x390', () {
      final layout = BattleSceneLayout.forViewport(
        viewportSize: const Size(844, 390),
      );

      expect(layout.viewportClass, BattleViewportClass.mediumLandscape);
      expect(layout.commandPanelLayoutMode, BattleCommandPanelLayoutMode.split);
      expect(layout.commandPanelRect.height, inInclusiveRange(132.0, 170.0));
      expect(layout.commandPanelRect.width, greaterThanOrEqualTo(804.0));
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
          expect(
              layout.playerHudRect.overlaps(layout.commandPanelRect), isFalse);
        });
      }

      test('gives portrait HUDs more breathing room than the 4e baseline', () {
        final layout = BattleSceneLayout.forViewport(
          viewportSize: const Size(390, 844),
        );

        expect(layout.enemyHudRect.width, greaterThanOrEqualTo(110));
        expect(layout.playerHudRect.width, greaterThanOrEqualTo(128));
        expect(layout.enemyHudRect.height, greaterThanOrEqualTo(46));
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

        expect(explicit.enemyHudRect, implicit.enemyHudRect, reason: '$viewport');
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
        expect(smaller.enemyHudRect, implicit.enemyHudRect, reason: '$viewport');
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
            final baseRect =
                side == 'enemy' ? base.enemyHudRect : base.playerHudRect;
            final grownRect =
                side == 'enemy' ? grown.enemyHudRect : grown.playerHudRect;

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

    test('asking for bigger text never renders smaller text', () {
      // Bout en bout, scène ET disposition du HUD. Une boîte agrandie peut
      // changer de palier, donc la monotonie n'est pas acquise par construction
      // ici : elle se mesure.
      for (final viewport in _certifiedViewports) {
        for (final side in const <String>['enemy', 'player']) {
          var previous = 0.0;
          for (final requested in const <double>[
            1.0,
            1.05,
            1.1,
            1.2,
            1.3,
            1.4,
            1.5,
            1.6,
          ]) {
            final layout = BattleSceneLayout.forViewport(
              viewportSize: viewport,
              textScale: requested,
            );
            final rect = side == 'enemy'
                ? layout.enemyHudRect
                : layout.playerHudRect;
            final rendered = _renderedNameFontSize(rect, requested);

            expect(
              rendered,
              greaterThanOrEqualTo(previous),
              reason: '$viewport $side at $requested',
            );
            previous = rendered;
          }
        }
      }
    });

    test('the growth is what unlocks the full scale, not the fonts', () {
      // Le cas qui justifie tout ce lot. Sans agrandissement, ces mêmes
      // rectangles plafonnaient à 1.11 et 1.21 sur desktop.
      final base = BattleSceneLayout.forViewport(
        viewportSize: const Size(1280, 720),
      );
      final grown = BattleSceneLayout.forViewport(
        viewportSize: const Size(1280, 720),
        textScale: battleMaximumTextScale,
      );

      for (final side in const <String>['enemy', 'player']) {
        final baseRect =
            side == 'enemy' ? base.enemyHudRect : base.playerHudRect;
        final grownRect =
            side == 'enemy' ? grown.enemyHudRect : grown.playerHudRect;

        expect(
          _hudGrant(baseRect),
          lessThan(1.3),
          reason: '$side: the fixed box could not grant the scale',
        );
        expect(
          _hudGrant(grownRect),
          closeTo(battleMaximumTextScale, 0.001),
          reason: '$side: the grown box grants it in full',
        );
      }
    });

    test('the tightest landscape saturates, and says how far it got', () {
      // Honnêteté chiffrée : 844x390 n'atteint PAS l'échelle maximale, parce que
      // le sprite joueur plafonne le HUD ennemi et le panneau de commandes le
      // HUD joueur. Ce cas fige le palier atteint pour qu'une régression se
      // voie, et pour que personne ne lise « les rectangles grandissent » comme
      // « tous les viewports rendent 1.6 ».
      final grown = BattleSceneLayout.forViewport(
        viewportSize: const Size(844, 390),
        textScale: battleMaximumTextScale,
      );

      expect(_hudGrant(grown.enemyHudRect), closeTo(1.22, 0.02));
      expect(_hudGrant(grown.playerHudRect), closeTo(1.43, 0.02));
    });
  });
}

/// Échelle que ce rectangle peut réellement accorder, palier compris.
double _hudGrant(Rect hudRect) {
  return BattleSceneHudLayout.forBounds(
    hudRect: Offset.zero & hudRect.size,
    isPlayerSide: true,
    speciesText: 'CHARMANDER',
    genderSymbol: '♂',
    levelText: 'Lv.100',
    hpValueText: '152/152',
    statusText: 'PAR',
    textScale: battleMaximumTextScale,
  ).effectiveTextScale;
}
