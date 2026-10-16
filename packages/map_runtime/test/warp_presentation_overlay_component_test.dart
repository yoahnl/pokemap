import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/warp_presentation_controller.dart';
import 'package:map_runtime/src/presentation/flame/warp_presentation_renderer.dart';
import 'package:map_runtime/src/presentation/flame/warp_presentation_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final p = SceneWarpPresentation(mode: SceneWarpPresentationMode.fade);
  final renderer = RuntimeWarpPresentationRenderer(presentation: p,
    project: const ProjectManifest(name: 'Warp', maps: [], tilesets: []));
  test('mounted overlay starts the timeline and advances to the sole transfer', () async {
    var transfers = 0;
    final controller = RuntimeWarpPresentationController(presentation: p, transfer: () async { transfers++; return true; });
    final overlay = WarpPresentationOverlayComponent(viewportSize: Vector2(512, 384), controller: controller, renderer: renderer);
    await overlay.onLoad(); overlay.update(.3);
    expect(controller.frame.worldOpacity, 1);
    overlay.update(.1); await Future<void>.delayed(Duration.zero);
    expect(transfers, 1); overlay.update(.3);
    expect(await controller.outcome, RuntimeWarpPresentationOutcome.completed);
    overlay.close();
  });
  test('close and external removal cancel the running presentation', () async {
    for (final external in [false, true]) {
      final controller = RuntimeWarpPresentationController(presentation: p, transfer: () async => true);
      final overlay = WarpPresentationOverlayComponent(viewportSize: Vector2(512, 384), controller: controller, renderer: renderer);
      await overlay.onLoad(); controller.start(); controller.advance(const Duration(milliseconds: 200));
      if (external) { overlay.onRemove(); } else { overlay.close(); }
      var ended = false; controller.outcome.then((_) => ended = true);
      await Future<void>.delayed(Duration.zero);
      expect(ended, isTrue); expect(await controller.outcome, RuntimeWarpPresentationOutcome.cancelled);
      expect(controller.frame.worldOpacity, 0);
    }
  });
  test('renderer identity must match the controller before mounting', () {
    final controller = RuntimeWarpPresentationController(
      presentation: SceneWarpPresentation(mode: SceneWarpPresentationMode.caveExit), transfer: () async => true);
    expect(() => WarpPresentationOverlayComponent(viewportSize: Vector2(512, 384), controller: controller, renderer: renderer), throwsArgumentError);
    controller.cancel();
  });
}
