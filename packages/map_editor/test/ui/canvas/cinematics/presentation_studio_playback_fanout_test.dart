import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_responsive_canvas.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  group('playhead fan-out', () {
    test('advancing the playhead leaves the composition listenables silent',
        () {
      final controller = PresentationStudioResponsiveCanvasController(
        durationUs: 4_000_000,
      );
      addTearDown(controller.dispose);

      var playheadNotifications = 0;
      var orientationNotifications = 0;
      var transportNotifications = 0;
      controller.playhead.addListener(() => playheadNotifications += 1);
      controller.orientation.addListener(() => orientationNotifications += 1);
      controller.transport.addListener(() => transportNotifications += 1);

      final token = controller.play();
      expect(token, isNotNull);
      transportNotifications = 0;
      playheadNotifications = 0;

      for (var frame = 0; frame < 30; frame += 1) {
        controller.advanceBy(16_666, token: token!);
      }

      expect(playheadNotifications, 30);
      // What the properties panel and the layer tree watch: nothing about the
      // composition changed, so neither may rebuild while the preview plays.
      expect(orientationNotifications, 0);
      expect(transportNotifications, 0);
    });

    test('seeking notifies the playhead alone', () {
      final controller = PresentationStudioResponsiveCanvasController(
        durationUs: 4_000_000,
      );
      addTearDown(controller.dispose);

      var playheadNotifications = 0;
      var transportNotifications = 0;
      controller.playhead.addListener(() => playheadNotifications += 1);
      controller.transport.addListener(() => transportNotifications += 1);

      controller.seekTo(1_200_000);

      expect(controller.playhead.value, 1_200_000);
      expect(playheadNotifications, 1);
      expect(transportNotifications, 0);
    });

    test('transport and orientation changes stay off the playhead', () {
      final controller = PresentationStudioResponsiveCanvasController(
        durationUs: 4_000_000,
      );
      addTearDown(controller.dispose);

      var playheadNotifications = 0;
      var orientationNotifications = 0;
      var transportNotifications = 0;
      controller.playhead.addListener(() => playheadNotifications += 1);
      controller.orientation.addListener(() => orientationNotifications += 1);
      controller.transport.addListener(() => transportNotifications += 1);

      controller.setLoop(true);
      expect(transportNotifications, 1);

      controller.setMode(PresentationStudioCanvasMode.portrait);
      expect(controller.orientation.value, PresentationFrameOrientation.portrait);
      expect(orientationNotifications, 1);

      controller.focus(PresentationFrameOrientation.landscape);
      expect(orientationNotifications, 2);

      expect(playheadNotifications, 0);
    });

    test('rewinding a paused preview moves the playhead alone', () {
      final controller = PresentationStudioResponsiveCanvasController(
        durationUs: 4_000_000,
        playheadUs: 2_000_000,
      );
      addTearDown(controller.dispose);

      var playheadNotifications = 0;
      var transportNotifications = 0;
      controller.playhead.addListener(() => playheadNotifications += 1);
      controller.transport.addListener(() => transportNotifications += 1);

      controller.stop();

      expect(controller.playhead.value, 0);
      expect(playheadNotifications, 1);
      // The clock was already at rest: only time moved.
      expect(transportNotifications, 0);
    });

    test('stopping a running preview reports both the transport and the time',
        () {
      final controller = PresentationStudioResponsiveCanvasController(
        durationUs: 4_000_000,
      );
      addTearDown(controller.dispose);

      final token = controller.play();
      controller.advanceBy(2_000_000, token: token!);

      var playheadNotifications = 0;
      var transportNotifications = 0;
      controller.playhead.addListener(() => playheadNotifications += 1);
      controller.transport.addListener(() => transportNotifications += 1);

      controller.stop();

      expect(controller.status, PresentationPlaybackStatus.ready);
      expect(controller.playhead.value, 0);
      expect(playheadNotifications, 1);
      expect(transportNotifications, 1);
    });
  });
}
