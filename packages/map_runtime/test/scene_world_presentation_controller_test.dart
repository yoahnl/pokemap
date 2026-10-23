import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_world_presentation_controller.dart';

SceneWorldPresentationInteractiveCommand picture(
  SceneWorldPresentationOperation operation, {
  SceneVisualScope scope = SceneVisualScope.map,
  double x = 0,
  double opacity = 1,
  int durationMs = 0,
}) => SceneInteractiveCommand.worldPresentation(
  operation: operation,
  scope: scope,
  slotId: 1,
  mediaAssetId: operation == SceneWorldPresentationOperation.showPicture
      ? 'portrait'
      : null,
  referenceWidth: 100,
  referenceHeight: 100,
  x: x,
  y: 20,
  opacity: opacity,
  durationMs: durationMs,
) as SceneWorldPresentationInteractiveCommand;

void main() {
  test('a different Scene owner cannot overwrite a map picture slot', () {
    final controller = SceneWorldPresentationController();
    expect(
      controller.apply(picture(SceneWorldPresentationOperation.showPicture)),
      isTrue,
    );
    expect(
      controller.apply(
        picture(
          SceneWorldPresentationOperation.showPicture,
          scope: SceneVisualScope.scene,
          x: 50,
        ),
        sceneOwner: Object(),
      ),
      isFalse,
    );
    controller.clearScene();
    expect(controller.frame.pictures.single.scope, SceneVisualScope.map);
  });

  test('map pictures move on simulation time and survive scene cleanup', () {
    final controller = SceneWorldPresentationController();
    controller.apply(picture(SceneWorldPresentationOperation.showPicture));
    controller.apply(
      picture(
        SceneWorldPresentationOperation.movePicture,
        x: 100,
        opacity: .5,
        durationMs: 1000,
      ),
    );
    controller.advance(.5);
    expect(controller.frame.pictures.single.composition.translateX, .5);
    expect(controller.frame.pictures.single.composition.opacity, .75);
    controller.clearScene();
    expect(controller.frame.pictures, hasLength(1));
    controller.advance(.5);
    expect(controller.frame.pictures.single.composition.translateX, 1);
    controller.reset();
    expect(controller.frame.pictures, isEmpty);
  });
  test(
    'scene checkpoint compensates replacement and scene scope is cleaned',
    () {
      final controller = SceneWorldPresentationController();
      controller.apply(picture(SceneWorldPresentationOperation.showPicture));
      final checkpoint = controller.captureCheckpoint();
      controller.apply(
        picture(
          SceneWorldPresentationOperation.showPicture,
          scope: SceneVisualScope.map,
          x: 50,
        ),
      );
      controller.clearScene();
      expect(controller.frame.pictures.single.composition.translateX, .5);
      controller.restoreCheckpoint(checkpoint);
      expect(controller.frame.pictures.single.scope, SceneVisualScope.map);
      expect(controller.frame.pictures.single.composition.translateX, 0);
    },
  );
  test('flash decays and shake ends without wall clock timers', () {
    final controller = SceneWorldPresentationController();
    controller.apply(
      SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.flash,
        red: 255,
        green: 0,
        blue: 0,
        alpha: 200,
        durationMs: 1000,
      ) as SceneWorldPresentationInteractiveCommand,
    );
    controller.advance(.5);
    expect(controller.frame.flashes.single.alpha, 100);
    controller.advance(.5);
    expect(controller.frame.flashes, isEmpty);
    controller.apply(
      SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.shake,
        power: 10,
        speed: 2,
        referenceWidth: 100,
        referenceHeight: 100,
        durationMs: 500,
      ) as SceneWorldPresentationInteractiveCommand,
    );
    controller.advance(.125);
    expect(controller.frame.shakeOffset, closeTo(10, .0001));
    controller.advance(.375);
    expect(controller.frame.shakeOffset, 0);
  });
}
