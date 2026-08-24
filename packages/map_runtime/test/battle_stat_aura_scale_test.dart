import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:map_runtime/src/presentation/flame/battle_stat_aura_component.dart';

/// Recette du 2026-08-24 : « l'animation de baisse de stats est vraiment trop
/// petite et pas à la hauteur ».
///
/// L'oracle est `UI::StatAnimation` croisé avec `display_config.json` du
/// projet PSDK : cellule de 200 px, `zoom = 0.75`, écran de 320×240. L'aura
/// couvre donc 150 px sur 240 de hauteur — 62,5 % de la scène, et la MÊME
/// taille pour les deux camps.
void main() {
  BattleStatAuraComponent auraFor({
    required Size viewport,
    required bool player,
  }) {
    final layout = BattleSceneLayout.forViewport(viewportSize: viewport);
    return BattleStatAuraComponent(
      sheet: _stubImage,
      targetSpriteRect:
          player ? layout.playerSpriteRect : layout.enemySpriteRect,
      durationSeconds: 1.5,
      auraSize: layout.playerSpriteRect.height *
          BattleStatAuraComponent.auraToPlayerSpriteRatio,
    );
  }

  group('taille de l\'aura de stats', () {
    for (final viewport in const <Size>[
      Size(640, 360),
      Size(844, 390),
      Size(390, 844),
      Size(1280, 800),
    ]) {
      test('dépasse le Pokémon de moitié en ${viewport.width.toInt()}x'
          '${viewport.height.toInt()}', () {
        final layout = BattleSceneLayout.forViewport(viewportSize: viewport);
        final aura = auraFor(viewport: viewport, player: true).debugAuraSize;
        expect(aura, greaterThan(layout.playerSpriteRect.height * 1.4));
        // Et jamais la fraction d'écran de la référence, qui donnerait 528 px
        // pour un Pokémon de 94 px en portrait.
        expect(aura, lessThan(viewport.height * 0.625));
      });

      test('est identique pour les deux camps en '
          '${viewport.width.toInt()}x${viewport.height.toInt()}', () {
        // La référence ne rétrécit jamais l'aura parce que le sprite visé est
        // plus petit : c'est le défaut exact de la première version.
        expect(
          auraFor(viewport: viewport, player: false).debugAuraSize,
          closeTo(auraFor(viewport: viewport, player: true).debugAuraSize, 0.001),
        );
      });
    }

    test('dépasse largement l\'ancien dimensionnement lié au sprite', () {
      const viewport = Size(640, 360);
      final layout = BattleSceneLayout.forViewport(viewportSize: viewport);
      final previous = layout.playerSpriteRect.height * 0.75;
      final current = auraFor(viewport: viewport, player: true).debugAuraSize;
      expect(current, greaterThan(previous * 1.9));
    });

    test('englobe le Pokémon visé', () {
      const viewport = Size(640, 360);
      final layout = BattleSceneLayout.forViewport(viewportSize: viewport);
      final aura = auraFor(viewport: viewport, player: true).debugAuraSize;
      expect(aura, greaterThan(layout.enemySpriteRect.height));
    });
  });
}

final Image _stubImage = _makeImage();

Image _makeImage() {
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(
    const Rect.fromLTWH(0, 0, 2400, 2000),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  return recorder.endRecording().toImageSync(2400, 2000);
}
