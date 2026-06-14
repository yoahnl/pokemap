import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_timeline_zoom_controller.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_timeline_zoom_state.dart';

void main() {
  test('starts at 100 percent by default', () {
    final controller = CinematicTimelineZoomController();
    addTearDown(controller.dispose);

    expect(controller.value.scale, 1);
    expect(controller.value.percentage, 100);
  });

  test('zooms in out and resets by fixed steps', () {
    final controller = CinematicTimelineZoomController();
    addTearDown(controller.dispose);

    controller.zoomIn();
    expect(controller.value.scale, 1.25);
    expect(controller.value.percentage, 125);

    controller.zoomOut();
    expect(controller.value.scale, 1);

    controller.zoomOut();
    expect(controller.value.scale, 0.75);

    controller.zoomOut();
    expect(controller.value.scale, 0.5);

    controller.zoomOut();
    expect(controller.value.scale, 0.25);
    expect(controller.value.percentage, 25);
    expect(controller.value.canZoomOut, isFalse);

    controller.reset();
    expect(controller.value.scale, CinematicTimelineZoomState.defaultScale);
  });

  test('clamps zoom to the editor-only bounds', () {
    final controller = CinematicTimelineZoomController();
    addTearDown(controller.dispose);

    controller.setScale(-10);
    expect(controller.value.scale, CinematicTimelineZoomState.minScale);
    expect(controller.value.canZoomOut, isFalse);

    controller.setScale(99);
    expect(controller.value.scale, CinematicTimelineZoomState.maxScale);
    expect(controller.value.canZoomIn, isFalse);
  });

  test('applies pinch scale from a stable start zoom', () {
    final controller = CinematicTimelineZoomController();
    addTearDown(controller.dispose);

    controller.applyScale(1.5, baseScale: 1);
    expect(controller.value.scale, 1.5);

    controller.applyScale(0.5, baseScale: 1.5);
    expect(controller.value.scale, 0.75);

    controller.applyScale(0);
    expect(controller.value.scale, 0.75);
  });
}
