import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_spec.dart';

Future<ui.Image> _tinyImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  return recorder.endRecording().toImage(4, 4);
}

Future<BattleTransitionOverlayComponent> _loadedOverlay({
  required BattleTransitionSpec spec,
  required void Function() onBlackHeld,
  void Function()? onDismissed,
  Future<ui.Image?> Function(String sheetName)? loadSheet,
}) async {
  final overlay = BattleTransitionOverlayComponent(
    spec: spec,
    viewportSize: Vector2(960, 540),
    onBlackHeld: onBlackHeld,
    onDismissed: onDismissed,
    loadSheet: loadSheet ?? (_) async => _tinyImage(),
  );
  await overlay.onLoad();
  return overlay;
}

Future<void> _flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le rideau couvre la scène de combat (97), le post-combat (99) et le '
      'dialogue (100)', () async {
    final overlay = await _loadedOverlay(
      spec: battleTransitionRbyWild,
      onBlackHeld: () {},
    );
    expect(
      overlay.priority,
      greaterThan(100),
      reason: 'recette 2026-08-23 (19-51-35) : à 96 le flash, la planche et '
          'le noir jouaient intégralement DERRIÈRE la scène montée à 97',
    );
    expect(
      overlay.priority,
      lessThan(150000),
      reason: 'les notifications système du runtime restent au-dessus',
    );
  });

  test('joue les phases dans l’ordre et notifie le noir une seule fois',
      () async {
    var blackHeldCount = 0;
    final overlay = await _loadedOverlay(
      spec: battleTransitionRbyWild,
      onBlackHeld: () => blackHeldCount += 1,
    );

    overlay.update(1.4);
    expect(overlay.debugPhaseIndex, 0, reason: 'le flash dure 1,5 s');
    expect(overlay.isHoldingBlack, isFalse);

    overlay.update(0.4);
    expect(overlay.debugPhaseIndex, 1, reason: 'la planche a pris le relais');

    overlay.update(0.4);
    expect(overlay.debugPhaseIndex, 2, reason: 'le noir tenu de 0,25 s');
    expect(blackHeldCount, 0);

    overlay.update(0.2);
    await _flushMicrotasks();
    expect(blackHeldCount, 1);
    expect(overlay.isHoldingBlack, isTrue);

    overlay.update(1.0);
    await _flushMicrotasks();
    expect(blackHeldCount, 1, reason: 'le noir tenu ne renotifie jamais');
    expect(overlay.isHoldingBlack, isTrue, reason: 'il tient sans limite');
  });

  test('revealAndDismiss est ignoré avant le noir, honoré après', () async {
    var dismissed = false;
    final overlay = await _loadedOverlay(
      spec: battleTransitionRbyWild,
      onBlackHeld: () {},
      onDismissed: () => dismissed = true,
    );

    overlay.update(0.5);
    overlay.revealAndDismiss();
    overlay.update(0.5);
    expect(dismissed, isFalse, reason: 'pas de reveal pendant le flash');

    overlay.update(2.0);
    await _flushMicrotasks();
    expect(overlay.isHoldingBlack, isTrue);
    overlay.revealAndDismiss();
    overlay.update(0.1);
    await _flushMicrotasks();
    expect(dismissed, isFalse, reason: 'le fondu dure 0,25 s');
    overlay.update(0.2);
    await _flushMicrotasks();
    expect(dismissed, isTrue);
  });

  test('une planche introuvable saute sa phase, le noir arrive quand même',
      () async {
    var blackHeldCount = 0;
    final overlay = await _loadedOverlay(
      spec: battleTransitionRbyWild,
      onBlackHeld: () => blackHeldCount += 1,
      loadSheet: (_) async => null,
    );

    // Flash 1,5 s puis directement le noir tenu 0,25 s : la planche absente
    // ne casse pas l'entrée en combat (critère 2).
    overlay.update(1.5);
    overlay.update(0.3);
    await _flushMicrotasks();
    expect(blackHeldCount, 1);
    expect(overlay.isHoldingBlack, isTrue);
  });

  test('la séquence dresseur DPP traverse zoom, rotation et deux planches',
      () async {
    var blackHeldCount = 0;
    final overlay = await _loadedOverlay(
      spec: battleTransitionDppTrainer,
      onBlackHeld: () => blackHeldCount += 1,
    );

    overlay.update(0.7);
    expect(overlay.debugPhaseIndex, 1, reason: 'après le flash, le zoom');
    overlay.update(0.4);
    expect(overlay.debugPhaseIndex, 2, reason: 'puis la rotation');
    overlay.update(0.4);
    expect(overlay.debugPhaseIndex, 3, reason: 'puis la première planche');
    overlay.update(0.2);
    expect(overlay.debugPhaseIndex, 4, reason: 'puis la seconde');
    overlay.update(0.2);
    expect(overlay.debugPhaseIndex, 5, reason: 'puis le noir tenu');
    overlay.update(0.25);
    await _flushMicrotasks();
    expect(blackHeldCount, 1);
  });
}
