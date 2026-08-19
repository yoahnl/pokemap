import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_hud_layout.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

/// Rectangles de HUD réellement produits par `BattleSceneLayout`, transcrits
/// depuis ses trois classes de viewport.
///
/// Les tailles rondes des cas historiques ci-dessus (220x72, 286x84...) ne sont
/// PAS celles que la scène fabrique, et c'est ce qui a laissé passer un
/// chevauchement. Un invariant sur l'échelle de texte doit se mesurer sur les
/// vraies.
const Map<String, Rect> _certifiedHudRects = <String, Rect>{
  'wideDesktop enemy': Rect.fromLTWH(0, 0, 210, 70),
  'wideDesktop player': Rect.fromLTWH(0, 0, 244, 74),
  'mediumLandscape enemy': Rect.fromLTWH(0, 0, 156, 54),
  'mediumLandscape player': Rect.fromLTWH(0, 0, 184, 62),
  'compactPortrait enemy': Rect.fromLTWH(0, 0, 186, 63),
  'compactPortrait player': Rect.fromLTWH(0, 0, 203, 73),
};

BattleSceneHudLayout _hud(Rect bounds, {double textScale = 1.0}) {
  return BattleSceneHudLayout.forBounds(
    hudRect: bounds,
    isPlayerSide: true,
    speciesText: 'CHARMANDER',
    genderSymbol: '♂',
    levelText: 'Lv.100',
    hpValueText: '152/152',
    statusText: 'PAR',
    textScale: textScale,
  );
}

List<double> _fontSizes(BattleSceneHudLayout layout) => <double>[
      layout.ownerFontSize,
      layout.nameFontSize,
      layout.levelFontSize,
      layout.statusFontSize,
      layout.hpLabelFontSize,
      layout.hpValueFontSize,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Rect rectOrZero(Rect? rect) => rect ?? Rect.zero;

  void expectVisibleRectsInsideHud(
    BattleSceneHudLayout layout, {
    required bool allowMissingHpValue,
  }) {
    final visibleRects = <Rect>[
      layout.nameRect,
      layout.levelRect,
      layout.hpLabelRect,
      layout.hpBarRect,
      if (layout.genderRect != null) layout.genderRect!,
      if (layout.statusRect != null) layout.statusRect!,
      if (layout.hpValueRect != null) layout.hpValueRect!,
    ];

    for (final rect in visibleRects) {
      expect(layout.hudRect.contains(rect.topLeft), isTrue);
      expect(
        layout.hudRect.contains(rect.bottomRight - const Offset(0.01, 0.01)),
        isTrue,
      );
    }

    expect(layout.nameRect.overlaps(layout.levelRect), isFalse);
    expect(rectOrZero(layout.genderRect).overlaps(layout.levelRect), isFalse);
    expect(layout.hpBarRect.overlaps(layout.nameRect), isFalse);
    if (!allowMissingHpValue) {
      expect(layout.hpValueRect, isNotNull);
    }
  }

  group('BattleSceneHudLayout', () {
    test('keeps an enemy hud compact and overlap-free', () {
      final layout = BattleSceneHudLayout.forBounds(
        hudRect: const Rect.fromLTWH(0, 0, 220, 72),
        isPlayerSide: false,
        speciesText: 'Pikachu',
        genderSymbol: '♂',
        levelText: 'Lv.15',
        hpValueText: '100%',
      );

      expectVisibleRectsInsideHud(layout, allowMissingHpValue: true);
      expect(layout.showsHpValue, isFalse);
    });

    test('keeps a player hud robust with long text and visible hp values', () {
      final layout = BattleSceneHudLayout.forBounds(
        hudRect: const Rect.fromLTWH(0, 0, 286, 84),
        isPlayerSide: true,
        speciesText: 'very_long_species_name_that_should_not_overlap',
        genderSymbol: '♀',
        levelText: 'Lv.100',
        hpValueText: '152/152',
        statusText: 'BRN',
      );

      expectVisibleRectsInsideHud(layout, allowMissingHpValue: false);
      expect(layout.showsHpValue, isTrue);
    });

    test(
        'hides numeric hp before allowing internal overlap on compact player hud',
        () {
      final layout = BattleSceneHudLayout.forBounds(
        hudRect: const Rect.fromLTWH(0, 0, 154, 68),
        isPlayerSide: true,
        speciesText: 'very_long_species_name_that_should_not_overlap',
        genderSymbol: '♂',
        levelText: 'Lv.100',
        hpValueText: '152/152',
        statusText: 'PAR',
      );

      expectVisibleRectsInsideHud(layout, allowMissingHpValue: true);
      expect(layout.showsHpValue, isFalse);
    });

    test('drops gender before squeezing a portrait enemy HUD', () {
      final layout = BattleSceneHudLayout.forBounds(
        hudRect: const Rect.fromLTWH(0, 0, 122, 42),
        isPlayerSide: false,
        speciesText: 'caterpie_with_a_long_name',
        genderSymbol: '♂',
        levelText: 'Lv.100',
        hpValueText: '100%',
        statusText: 'PAR',
      );

      expectVisibleRectsInsideHud(layout, allowMissingHpValue: true);
      expect(layout.genderRect, isNull);
      expect(layout.statusRect, isNull);
    });

    test('drops secondary player HUD details on portrait widths before overlap',
        () {
      final layout = BattleSceneHudLayout.forBounds(
        hudRect: const Rect.fromLTWH(0, 0, 138, 46),
        isPlayerSide: true,
        speciesText: 'very_long_species_name_that_should_not_overlap',
        genderSymbol: '♀',
        levelText: 'Lv.100',
        hpValueText: '152/152',
        statusText: 'BRN',
      );

      expectVisibleRectsInsideHud(layout, allowMissingHpValue: true);
      expect(layout.genderRect, isNull);
      expect(layout.hpValueRect, isNull);
    });
  });

  /// Accessibilité texte de BETA-BAT-007, côté HUD.
  ///
  /// Le HUD ne pouvait pas se contenter du multiply appliqué au panneau de
  /// commandes : ses hauteurs de ligne dérivent des tailles de police, le bloc
  /// titre est ancré en haut, la ligne d'HP en bas, et la hauteur du rectangle
  /// est imposée par la scène. Mesuré avant d'écrire le code : à l'échelle
  /// maximale, le nom recouvrait la barre d'HP sur les SIX rectangles
  /// certifiés.
  ///
  /// D'où un plafond géométrique, et un aveu : sur une boîte de 54 à 74 px, une
  /// demande de 1.6 n'obtient que 1.03 à 1.29. `effectiveTextScale` existe pour
  /// que ça se constate au lieu de se supposer.
  group('BETA-BAT-007 the HUD honours the player text scale', () {
    test('a box with room grants the request in full', () {
      final normal = _hud(const Rect.fromLTWH(0, 0, 260, 120));
      final larger =
          _hud(const Rect.fromLTWH(0, 0, 260, 120), textScale: 1.6);

      expect(larger.effectiveTextScale, closeTo(1.6, 0.001));
      for (var index = 0; index < 6; index++) {
        expect(
          _fontSizes(larger)[index],
          closeTo(_fontSizes(normal)[index] * 1.6, 0.001),
          reason: 'font $index',
        );
      }
    });

    test('a grown title never touches the hp row on a certified rect', () {
      // LE cas qui aurait attrapé le multiply naïf : il produisait un
      // chevauchement de 2.4 à 9.2 px sur ces mêmes rectangles.
      for (final entry in _certifiedHudRects.entries) {
        for (final requested in const <double>[1.2, 1.4, 1.6]) {
          final layout = _hud(entry.value, textScale: requested);
          if (layout.effectiveTextScale <= 1.0) continue;

          expect(
            layout.nameRect.bottom,
            lessThanOrEqualTo(layout.hpBarRect.top),
            reason: '${entry.key} at $requested',
          );
          expect(
            layout.hpBarRect.overlaps(layout.nameRect),
            isFalse,
            reason: '${entry.key} at $requested',
          );
        }
      }
    });

    test('asking for more never yields less', () {
      // Défaut réel de la première version de ce plafond : le bloc bas y était
      // évalué à l'échelle DEMANDÉE, donc la demande rognait la place qu'elle
      // réclamait et 1.6 rendait un texte plus petit que 1.2.
      for (final entry in _certifiedHudRects.entries) {
        var previous = 0.0;
        for (final requested in const <double>[1.0, 1.1, 1.2, 1.4, 1.6, 3.0]) {
          final granted = _hud(entry.value, textScale: requested).nameFontSize;

          expect(
            granted,
            greaterThanOrEqualTo(previous),
            reason: '${entry.key} at $requested',
          );
          previous = granted;
        }
      }
    });

    test('a request the box cannot grant is reported, not silently promised',
        () {
      final layout =
          _hud(_certifiedHudRects['mediumLandscape enemy']!, textScale: 1.6);
      final unscaled = _hud(_certifiedHudRects['mediumLandscape enemy']!);

      expect(layout.effectiveTextScale, lessThan(1.6));
      expect(layout.effectiveTextScale, greaterThan(1.0));
      // Et le nombre annoncé est celui qui est appliqué, pas un ornement.
      expect(
        layout.nameFontSize,
        closeTo(unscaled.nameFontSize * layout.effectiveTextScale, 0.001),
      );
    });

    test('a box too short to grow anything keeps its unscaled sizes', () {
      // Le plancher de 1.0, prouvé là où il travaille VRAIMENT.
      //
      // Un premier test s'en tenait aux six rectangles certifiés et ne mesurait
      // rien : leur plafond géométrique ne descend jamais sous 1.0, donc
      // supprimer le plancher laissait la suite verte. Sabotage à l'appui.
      //
      // 122x34 est une boîte que la scène ne fabrique pas ; c'est exprès. Elle
      // documente ce qui arriverait si un rectangle se resserrait un jour :
      // sans le plancher, le plafond y vaut 0.74 et un joueur qui demande du
      // texte PLUS GROS obtiendrait du texte plus petit qu'aujourd'hui.
      const degenerate = Rect.fromLTWH(0, 0, 122, 34);
      final unscaled = _fontSizes(_hud(degenerate));

      expect(
        _hud(degenerate, textScale: 1.6).effectiveTextScale,
        1.0,
        reason: 'the box grants nothing, and nothing is exactly what it says',
      );
      expect(_fontSizes(_hud(degenerate, textScale: 1.6)), unscaled);
    });

    test('growing the text never shrinks a font below its unscaled size', () {
      for (final entry in _certifiedHudRects.entries) {
        final unscaled = _fontSizes(_hud(entry.value));
        for (final requested in const <double>[1.05, 1.3, 1.6]) {
          final grown = _fontSizes(_hud(entry.value, textScale: requested));
          for (var index = 0; index < 6; index++) {
            expect(
              grown[index],
              greaterThanOrEqualTo(unscaled[index]),
              reason: '${entry.key} at $requested, font $index',
            );
          }
        }
      }
    });

    test('shrinking is always granted, the box only limits growth', () {
      for (final entry in _certifiedHudRects.entries) {
        final smaller = _hud(entry.value, textScale: 0.8);

        expect(smaller.effectiveTextScale, closeTo(0.8, 0.001), reason: entry.key);
        expect(
          smaller.nameFontSize,
          closeTo(_hud(entry.value).nameFontSize * 0.8, 0.001),
          reason: entry.key,
        );
      }
    });

    test('an absurd request is clamped to the shared bounds', () {
      final bounds = const Rect.fromLTWH(0, 0, 260, 200);

      expect(
        _hud(bounds, textScale: 12).nameFontSize,
        _hud(bounds, textScale: battleMaximumTextScale).nameFontSize,
      );
      expect(
        _hud(bounds, textScale: 0.05).nameFontSize,
        _hud(bounds, textScale: battleMinimumTextScale).nameFontSize,
      );
    });

    test('the unscaled geometry is exactly what it was before the scale', () {
      // Ce qui protège le rendu d'aujourd'hui : sans argument et à 1.0, la
      // disposition doit être identique au pixel près.
      for (final entry in _certifiedHudRects.entries) {
        final implicit = _hud(entry.value);
        final explicit = _hud(entry.value, textScale: 1.0);

        expect(explicit.nameRect, implicit.nameRect, reason: entry.key);
        expect(explicit.hpBarRect, implicit.hpBarRect, reason: entry.key);
        expect(explicit.ownerRect, implicit.ownerRect, reason: entry.key);
        expect(_fontSizes(explicit), _fontSizes(implicit), reason: entry.key);
      }
    });

    test('the landscape enemy HUD already overlaps a hair at scale 1.0', () {
      // CONSTAT, pas une régression de l'échelle de texte : mesuré à 0.65 px de
      // recouvrement entre le nom et la barre d'HP sur le rectangle 156x54 que
      // la scène fabrique, quel que soit le nom d'espèce. Aucun cas historique
      // n'utilisait cette taille — ils prennent des tailles rondes inventées.
      //
      // Laissé en place exprès : c'est du rendu en service, et le corriger
      // changerait l'apparence d'un écran que personne n'a demandé de bouger.
      // Consigné ici pour que ça ne puisse pas empirer en silence, et pour que
      // le cas de chevauchement ci-dessus n'ait pas l'air de fermer les yeux.
      final layout = _hud(_certifiedHudRects['mediumLandscape enemy']!);

      expect(layout.nameRect.bottom - layout.hpBarRect.top, closeTo(0.65, 0.05));
    });
  });
}
