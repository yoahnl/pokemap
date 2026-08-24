import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_ball_capture_component.dart';

// BETA-BAT-025 — la séquence de capture de la référence, cellule par
// cellule : lancer (0-3), ouverture (4-5), fermeture (6-14 puis 3), chute à
// rebonds, secousses (17-16-15-16-17-18-19-18-17), verrouillage (27-31 puis
// 17) ou éclatement (20-26). Les cues sont les points d'ancrage de l'hôte :
// sons et absorption/libération du Pokémon.

Future<ui.Image> _fakeSheet() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 64, 2048),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  return recorder.endRecording().toImage(64, 2048);
}

Future<({BattleBallCaptureComponent ball, List<BattleBallCaptureCue> cues})>
    _mount({required int shakes, required bool caught}) async {
  final cues = <BattleBallCaptureCue>[];
  final ball = BattleBallCaptureComponent(
    sheet: await _fakeSheet(),
    shakes: shakes,
    caught: caught,
    targetCenter: const ui.Offset(700, 200),
    throwStartX: -32,
    cellSize: 64,
    onCue: cues.add,
  );
  final host = PositionComponent();
  await host.add(ball);
  host.updateTree(0);
  return (ball: ball, cues: cues);
}

void _pump(PositionComponent host, double seconds) {
  var remaining = seconds;
  while (remaining > 1e-9) {
    final dt = remaining > 0.05 ? 0.05 : remaining;
    host.updateTree(dt);
    remaining -= dt;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('un échec déroule lancer, absorption, chute, secousses, éclatement '
      'et libère le Pokémon', () async {
    final mounted = await _mount(shakes: 2, caught: false);
    final ball = mounted.ball;
    final host = ball.parent! as PositionComponent;

    _pump(host, 0.2);
    expect(ball.debugCellIndex, inInclusiveRange(0, 3),
        reason: 'le vol joue les cellules de lancer');
    expect(ball.position.x, greaterThan(-32),
        reason: 'la Ball avance vers la cible');

    _pump(host, 0.3);
    expect(ball.debugCellIndex, inInclusiveRange(4, 5),
        reason: 'l’ouverture joue les cellules 4-5');

    _pump(host, 0.2);
    expect(mounted.cues, contains(BattleBallCaptureCue.absorb),
        reason: 'le Pokémon rétrécit pendant que la Ball est ouverte');

    _pump(host, 0.3);
    expect(mounted.cues, contains(BattleBallCaptureCue.close));
    expect(ball.debugCellIndex, inInclusiveRange(6, 14),
        reason: 'la fermeture joue les cellules 6-14');

    _pump(host, 1.35);
    expect(
      mounted.cues.where((cue) => cue == BattleBallCaptureCue.bounce),
      hasLength(3),
      reason: 'la chute amortie touche le sol trois fois',
    );

    _pump(host, 0.75);
    expect(mounted.cues, contains(BattleBallCaptureCue.shake));
    expect(ball.debugCellIndex, inInclusiveRange(15, 19),
        reason: 'une secousse penche la Ball (cellules 15-19)');

    _pump(host, 1.5);
    expect(
      mounted.cues.where((cue) => cue == BattleBallCaptureCue.shake),
      hasLength(2),
      reason: 'ENC-005 : exactement les secousses transmises, rejouées',
    );

    _pump(host, 0.3);
    expect(mounted.cues, contains(BattleBallCaptureCue.verdict));
    expect(ball.debugCellIndex, inInclusiveRange(20, 26),
        reason: 'l’éclatement joue les cellules 20-26');

    _pump(host, 0.7);
    await Future<void>.delayed(Duration.zero);
    host.updateTree(0.01);
    expect(mounted.cues, contains(BattleBallCaptureCue.release),
        reason: 'l’échec libère le Pokémon');
    expect(ball.isRemoved || ball.parent == null, isTrue,
        reason: 'la Ball cassée ne survit pas à l’éclatement');
  });

  test('une réussite joue le verrouillage et laisse la Ball posée', () async {
    final mounted = await _mount(shakes: 3, caught: true);
    final ball = mounted.ball;
    final host = ball.parent! as PositionComponent;

    _pump(host, 2.8 + 3 * 1.0 + 0.25);
    expect(ball.debugCellIndex, inInclusiveRange(27, 31),
        reason: 'le verrouillage joue les cellules 27-31');

    _pump(host, 1.0);
    await Future<void>.delayed(Duration.zero);
    host.updateTree(0.01);
    expect(ball.parent, isNotNull,
        reason: 'la Ball verrouillée reste posée, comme la référence');
    expect(ball.debugCellIndex, 17,
        reason: 'la cellule finale du verrouillage de la référence');
    expect(mounted.cues, isNot(contains(BattleBallCaptureCue.release)));
    expect(
      mounted.cues.where((cue) => cue == BattleBallCaptureCue.shake),
      hasLength(3),
    );
  });

  test('la durée du step couvre exactement la séquence du composant', () {
    const failed = PlayBallCaptureSequenceStep(shakes: 2, caught: false);
    const caught = PlayBallCaptureSequenceStep(shakes: 3, caught: true);

    // 2,8 s de lancer→pause + 1,0 par secousse + 0,5 de verdict, et 0,2 de
    // réapparition sur un échec.
    expect(failed.durationSeconds, closeTo(5.5, 1e-9));
    expect(caught.durationSeconds, closeTo(6.3, 1e-9));
  });
}
