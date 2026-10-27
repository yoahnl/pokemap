import 'dart:typed_data';
import 'dart:ui';

import 'package:flame_3d/core.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_scene_view.dart';
import 'package:map_render_3d/src/spatial_weather_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(_UnusedBackend.new);

  test(
    'storm peak preserves the dark scene in the actual canvas overlay',
    () async {
      final fixture = _Fixture();
      final frame = spatialWeatherFrame(
        SpatialWeatherSettings(
          enabled: true,
          kind: SpatialWeatherKind.storm,
          lightning: true,
        ),
        seconds: 4.35,
      );
      fixture.context.weatherSkyFlash = frame.flash;
      final pixel = await fixture.pixel();
      expect(pixel[0], greaterThan(16));
      expect(pixel.take(3), everyElement(lessThanOrEqualTo(42)));
    },
  );

  test(
    'a paused item message cannot hold a full-screen lightning veil',
    () async {
      final fixture = _Fixture()..paused = true;
      fixture.context.weatherSkyFlash = .09;
      expect(await fixture.pixel(), [16, 24, 32, 255]);
      expect(fixture.context.weatherSkyFlash, .09);
      fixture.paused = false;
      final resumed = await fixture.pixel();
      expect(resumed[0], greaterThan(16));
      expect(resumed.take(3), everyElement(lessThanOrEqualTo(52)));
    },
  );
}

final class _UnusedBackend extends GpuBackend {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError(invocation.memberName.toString());
}

final class _Fixture {
  _Fixture() {
    game = SpatialSceneGame(
      SpatialSceneView(
        scene: MapSpatialScene(width: 2, depth: 2),
        models: const [],
        loadModel: (_) async => Uint8List(0),
        controller: controller,
        onCell: (_, _) {},
        background: const Color(0xff000000),
        ground: const Color(0xff000000),
        edge: const Color(0xff000000),
        errorBuilder: (_, _) => const SizedBox(),
        presentationPaused: () => paused,
      ),
      onPreviewStatus: (_) {},
      onSurfaceChanged: () {},
    )..onGameResize(Vector2(8, 8));
    addTearDown(game.onRemove);
    addTearDown(controller.dispose);
  }

  bool paused = false;
  final controller = SpatialSceneController();
  late final SpatialSceneGame game;
  SpatialRenderContext get context => game.context as SpatialRenderContext;

  Future<List<int>> pixel() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xff101820), BlendMode.src);
    game.renderWeatherOverlay(canvas);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(8, 8);
    picture.dispose();
    final bytes = (await image.toByteData())!;
    image.dispose();
    return [
      for (var channel = 0; channel < 4; channel++) bytes.getUint8(channel),
    ];
  }
}
