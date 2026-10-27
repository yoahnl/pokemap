import 'dart:ui';

import 'package:flame/components.dart' as flame;
import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/widgets.dart' show MediaQuery;
import 'package:meta/meta.dart';

/// {@template world_3d}
/// The root component for all 3D world elements.
///
/// The primary feature of this component is that it allows [Component3D]s to
/// render directly to a [GraphicsDevice] instead of the regular rendering.
/// {@endtemplate}
class World3D({
  super.children,
  super.priority,
}) extends flame.World with flame.HasGameRef<FlameGame3D> {
  final List<Light> _lights = [];

  RenderContext3D get context => gameRef.context;

  /// Register a [light] with this world.
  @internal
  void addLight(Light light) => _lights.add(light);

  /// Unregister a [light] from this world.
  @internal
  void removeLight(Light light) => _lights.remove(light);

  @internal
  @override
  void renderFromCamera(Canvas canvas) {
    final camera = CameraComponent3D.currentCamera!;
    final Viewport(virtualSize: size) = camera.viewport;

    final renderSize = renderSizeFor(
      size,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(gameRef.buildContext!),
      resolutionScale: gameRef.renderResolutionScale,
    );

    context
      ..lights = _lights
      ..setCamera(camera.viewMatrix, camera.projectionMatrix);

    gameRef.device.beginPass(renderSize);
    super.renderFromCamera(canvas);
    context.flush();

    final image = gameRef.device.endPass();
    canvas.drawImageRect(
      image,
      Offset.zero & renderSize,
      Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y),
      _paint,
    );
    image.dispose();
  }

  static Size renderSizeFor(
    flame.Vector2 virtualSize, {
    required double devicePixelRatio,
    required double resolutionScale,
  }) {
    final scale = resolutionScale.isFinite
        ? resolutionScale.clamp(minimumResolutionScale, 1.0)
        : 1.0;
    final pixelRatio = devicePixelRatio * scale;
    return Size(virtualSize.x * pixelRatio, virtualSize.y * pixelRatio);
  }

  static const minimumResolutionScale = .25;

  static final _paint = Paint();
}
