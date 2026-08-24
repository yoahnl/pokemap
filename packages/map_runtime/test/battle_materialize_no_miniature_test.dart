import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';

/// Recette du 2026-08-24 : « l'animation avec les pokéballs continue à
/// transformer le pokémon en tout petit mais ça reste visible ».
///
/// BETA-BAT-031 avait ajouté la lueur pleine pour masquer les détails, mais
/// gardé le `zoom = 0 → sprite_zoom` de PSDK : une lueur de quelques pixels
/// reste une miniature. La vidéo de référence (Platine) ne montre jamais le
/// Pokémon rapetissé — la forme apparaît à sa taille et prend ses couleurs.
///
/// Cette garde interdit à l'échelle de redescendre en zone « miniature »
/// pendant toute la matérialisation, entrée comme sortie.
BattleSceneCombatantComponent _combatant() {
  return BattleSceneCombatantComponent(
    sceneSpriteRect: const Rect.fromLTWH(40, 30, 120, 120),
    scenePlatformRect: const Rect.fromLTWH(52, 136, 110, 18),
    sceneFootAnchor: const Offset(102, 140),
    spriteFootXRatio: 0.5,
    isPlayerSide: true,
    speciesLabel: 'sparkitten',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const duration = 0.4;

  List<double> scalesDuring(void Function(BattleSceneCombatantComponent) start) {
    final component = _combatant();
    start(component);
    final scales = <double>[component.currentVisualScaleX];
    for (var i = 0; i < 40; i++) {
      component.update(duration / 40);
      scales.add(component.currentVisualScaleX);
    }
    return scales;
  }

  group('la matérialisation ne montre jamais de miniature', () {
    test('à la sortie de Ball, l\'échelle ne descend pas sous le plancher',
        () {
      final scales = scalesDuring(
        (c) => c.playMaterializeIn(durationSeconds: duration),
      );
      expect(
        scales.reduce((a, b) => a < b ? a : b),
        greaterThanOrEqualTo(
          BattleSceneCombatantComponent.debugMaterializeFloorScale - 0.001,
        ),
      );
      expect(scales.last, closeTo(1, 0.001));
    });

    test('au retour en Ball, l\'échelle ne descend pas sous le plancher', () {
      final scales = scalesDuring(
        (c) => c.playMaterializeOut(durationSeconds: duration),
      );
      expect(
        scales.reduce((a, b) => a < b ? a : b),
        greaterThanOrEqualTo(
          BattleSceneCombatantComponent.debugMaterializeFloorScale - 0.001,
        ),
      );
    });

    test('le plancher reste très au-dessus de la zone miniature', () {
      // Le défaut d'origine partait de 0 : tout ce qui est sous ~0,5 rend le
      // sprite détaillé lisible en réduction, ce que la recette a vu.
      expect(
        BattleSceneCombatantComponent.debugMaterializeFloorScale,
        greaterThan(0.8),
      );
    });

    test('l\'apparition est portée par l\'opacité, pas par la taille', () {
      final component = _combatant();
      component.playMaterializeIn(durationSeconds: duration);
      expect(component.currentVisualOpacity, closeTo(0, 0.001));
      for (var i = 0; i < 40; i++) {
        component.update(duration / 40);
      }
      expect(component.currentVisualOpacity, closeTo(1, 0.001));
    });

    test('le retour en Ball se termine invisible', () {
      final component = _combatant();
      component.playMaterializeOut(durationSeconds: duration);
      for (var i = 0; i < 45; i++) {
        component.update(duration / 40);
      }
      expect(component.currentVisualOpacity, closeTo(0, 0.001));
    });

    test('la lueur de matérialisation reste active pendant l\'animation', () {
      final component = _combatant();
      component.playMaterializeIn(durationSeconds: duration);
      expect(component.debugMaterializeGlowActive, isTrue);
      expect(component.debugVisualToneMaxMix, 1);
    });
  });
}
