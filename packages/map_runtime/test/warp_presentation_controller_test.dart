import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/warp_presentation_controller.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);
SceneWarpPresentation presentation({SceneWarpPresentationMode mode = SceneWarpPresentationMode.illustrated}) =>
    SceneWarpPresentation(mode: mode,
      illustrationElementId: mode == SceneWarpPresentationMode.illustrated ||
          mode == SceneWarpPresentationMode.caveEntrance ? 'picture' : null);

void main() {
  test('transfer occurs at400ms while fade completes at300ms', () async {
    var transfers = 0;
    final controller = RuntimeWarpPresentationController(presentation: presentation(),
      transfer: () async { transfers++; return true; });
    controller.start();
    controller.advance(const Duration(milliseconds: 150));
    expect(controller.frame.worldOpacity, closeTo(.5, .001));
    controller.advance(const Duration(milliseconds: 150));
    expect(controller.frame.worldOpacity, 1);
    expect(transfers, 0);
    controller.advance(const Duration(milliseconds: 99));
    expect(transfers, 0);
    controller.advance(const Duration(milliseconds: 1));
    await flush();
    expect(transfers, 1);
    expect(controller.phase, RuntimeWarpPresentationPhase.afterTransfer);
    controller.cancel();
  });
  test('picture hold then world reveal and picture fade run together', () async {
    final controller = RuntimeWarpPresentationController(presentation: presentation(), transfer: () async => true);
    controller.start(); controller.advance(const Duration(milliseconds: 400)); await flush();
    controller.advance(const Duration(milliseconds: 1000));
    expect(controller.frame.worldOpacity, 1);
    expect(controller.frame.illustrationOpacity, 1);
    controller.advance(const Duration(milliseconds: 300));
    expect(controller.frame.worldOpacity, 0);
    expect(controller.frame.illustrationOpacity, closeTo(.8, .001));
    controller.advance(const Duration(milliseconds: 1200));
    expect(await controller.outcome, RuntimeWarpPresentationOutcome.completed);
    expect(controller.frame.illustrationOpacity, 0);
  });
  test('cave bands finish before the sole transfer', () async {
    for (final mode in [SceneWarpPresentationMode.caveEntrance, SceneWarpPresentationMode.caveExit]) {
      var transfers = 0;
      final controller = RuntimeWarpPresentationController(presentation: presentation(mode: mode),
        transfer: () async { transfers++; return true; });
      controller.start(); controller.advance(const Duration(milliseconds: 1299));
      expect(transfers, 0);
      expect(controller.frame.caveElapsedMs, 899);
      controller.advance(const Duration(milliseconds: 1)); await flush();
      expect(transfers, 1);
      controller.cancel();
    }
  });
  test('cave recovery reveals its tone without adding a second black cover', () async {
    for (final mode in [SceneWarpPresentationMode.caveEntrance, SceneWarpPresentationMode.caveExit]) {
      final controller = RuntimeWarpPresentationController(presentation: presentation(mode: mode), transfer: () async => true);
      controller.start(); controller.advance(const Duration(milliseconds: 1300)); await flush();
      expect(controller.frame.worldOpacity, 0);
      expect(controller.frame.caveRecoveryOpacity, closeTo(.75, .001));
      controller.advance(const Duration(milliseconds: 150));
      expect(controller.frame.caveRecoveryOpacity, closeTo(.375, .001));
      controller.cancel();
    }
  });
  test('pending transfer freezes presentation time and cannot be called twice', () async {
    var transfers = 0; final transfer = Completer<bool>();
    final controller = RuntimeWarpPresentationController(presentation: presentation(), transfer: () {
      transfers++; return transfer.future;
    });
    controller.start(); controller.advance(const Duration(milliseconds: 400));
    controller.advance(const Duration(seconds: 10));
    expect(transfers, 1); expect(controller.phase, RuntimeWarpPresentationPhase.transferring);
    transfer.complete(true); await flush();
    expect(controller.frame.illustrationOpacity, 1);
    controller.cancel();
  });
  test('blocked and throwing transfer never report completion', () async {
    for (final throwsError in [false, true]) {
      final controller = RuntimeWarpPresentationController(presentation: presentation(), transfer: () async {
        if (throwsError) throw StateError('load failed'); return false;
      });
      controller.start(); controller.advance(const Duration(milliseconds: 400)); await flush();
      expect(await controller.outcome, RuntimeWarpPresentationOutcome.blocked);
      expect(controller.frame.worldOpacity, 0);
      expect(controller.frame.illustrationOpacity, 0);
    }
  });
  test('cancel before transfer is final and leaves no visual', () async {
    var calls = 0;
    final controller = RuntimeWarpPresentationController(presentation: presentation(), transfer: () async { calls++; return true; });
    controller.start(); controller.advance(const Duration(milliseconds: 200)); controller.cancel();
    controller.advance(const Duration(seconds: 20)); await flush();
    expect(await controller.outcome, RuntimeWarpPresentationOutcome.cancelled);
    expect(calls, 0); expect(controller.frame.worldOpacity, 0);
  });
  test('cancel during transfer cannot be overwritten by late success or failure', () async {
    for (final success in [true, false]) {
      final transfer = Completer<bool>();
      final controller = RuntimeWarpPresentationController(presentation: presentation(), transfer: () => transfer.future);
      controller.start(); controller.advance(const Duration(milliseconds: 400)); controller.cancel();
      var settled = false;
      controller.outcome.then((_) => settled = true);
      await flush();
      expect(settled, isFalse, reason: 'Owner must not restore before pending transfer settles');
      transfer.complete(success); await flush();
      expect(await controller.outcome, RuntimeWarpPresentationOutcome.cancelled);
      expect(controller.phase, RuntimeWarpPresentationPhase.cancelled);
    }
  });
  test('plain fade finishes after reveal without picture delays', () async {
    final controller = RuntimeWarpPresentationController(presentation: presentation(mode: SceneWarpPresentationMode.fade), transfer: () async => true);
    controller.start(); controller.advance(const Duration(milliseconds: 400)); await flush();
    controller.advance(const Duration(milliseconds: 299));
    expect(controller.phase, RuntimeWarpPresentationPhase.afterTransfer);
    controller.advance(const Duration(milliseconds: 1));
    expect(await controller.outcome, RuntimeWarpPresentationOutcome.completed);
  });
  test('unstarted and negative advances cannot trigger a transfer', () {
    var calls = 0;
    final controller = RuntimeWarpPresentationController(presentation: presentation(), transfer: () async { calls++; return true; });
    controller.advance(const Duration(seconds: 20));
    expect(calls, 0);
    expect(() => controller.advance(const Duration(milliseconds: -1)), throwsArgumentError);
    controller.cancel();
  });
}
