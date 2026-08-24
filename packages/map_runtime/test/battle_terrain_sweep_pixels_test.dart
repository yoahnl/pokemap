import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_spec.dart';

/// Recette du 2026-08-24 : « je n'ai pas compris ce que tu veux dire par le
/// balayage de terrain ». Il ne l'avait jamais vu.
///
/// La phase tient l'écran au noir et le balayage se joue PAR-DESSUS, mais
/// `_screenColor` est peint en dernier dans `render` : dessiné plus haut, le
/// balayage était intégralement recouvert. Les tests de BETA-BAT-032
/// vérifiaient l'état de la phase et la composition de la spec — jamais un
/// pixel — donc rien n'a bronché.
///
/// Ces tests lisent les pixels rendus. C'est la seule garde qui pouvait
/// attraper ce défaut, et la seule qui empêche de le réintroduire.
void main() {
  const width = 320;
  const height = 180;

  Future<ui.Image> renderMidSweep(BattleTerrainSweepKind kind) async {
    final component = BattleTransitionOverlayComponent(
      spec: battleTransitionRbyWild.withTerrainSweep(kind),
      viewportSize: Vector2(width.toDouble(), height.toDouble()),
      onBlackHeld: () {},
      loadSheet: (_) async => null,
      loadDissolveProgram: () async => null,
    );
    await component.onLoad();

    var guard = 0;
    while (component.debugTerrainSweepKind == null && guard++ < 5000) {
      component.update(1 / 120);
    }
    expect(
      component.debugTerrainSweepKind,
      kind,
      reason: 'la phase de balayage doit être atteinte',
    );
    // Au milieu de la phase : les lames ont poussé, le fondu n'a pas commencé.
    for (var i = 0; i < 40; i++) {
      component.update(1 / 120);
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    component.render(canvas);
    return recorder.endRecording().toImage(width, height);
  }

  Future<int> nonBlackPixels(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = data!.buffer.asUint8List();
    var count = 0;
    for (var i = 0; i < bytes.length; i += 4) {
      if (bytes[i] > 24 || bytes[i + 1] > 24 || bytes[i + 2] > 24) {
        count++;
      }
    }
    return count;
  }

  group('le balayage de terrain est réellement visible', () {
    for (final kind in BattleTerrainSweepKind.values) {
      test('${kind.name} peint des pixels par-dessus le noir', () async {
        final image = await renderMidSweep(kind);
        final painted = await nonBlackPixels(image);
        // Sans le correctif d'ordre de rendu, ce compte vaut exactement 0.
        expect(
          painted,
          greaterThan(width * height * 0.02),
          reason: 'le balayage ${kind.name} doit couvrir une part visible '
              "de l'écran, pas être recouvert par le rideau noir",
        );
      });
    }

    test('les trois terrains ne peignent pas la même image', () async {
      final counts = <BattleTerrainSweepKind, int>{};
      for (final kind in BattleTerrainSweepKind.values) {
        counts[kind] = await nonBlackPixels(await renderMidSweep(kind));
      }
      expect(counts.values.toSet().length, greaterThan(1));
    });

    test('le balayage occupe le bas de l\'écran, pas le haut', () async {
      final image = await renderMidSweep(BattleTerrainSweepKind.grass);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      var top = 0;
      var bottom = 0;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          final lit = bytes[i] > 24 || bytes[i + 1] > 24 || bytes[i + 2] > 24;
          if (!lit) continue;
          if (y < height / 3) {
            top++;
          } else if (y > height * 2 / 3) {
            bottom++;
          }
        }
      }
      expect(bottom, greaterThan(top));
    });
  });
}
