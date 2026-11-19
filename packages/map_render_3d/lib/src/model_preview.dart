import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/gestures.dart' hide Matrix4;
import 'package:flutter/widgets.dart' hide Matrix4, Texture;

import 'model_byte_loader.dart';
import 'adaptive_camera.dart';
import 'flutter_frame_graphics_device.dart';
import 'spatial_render_context.dart';
import 'model_playback.dart';
import 'spatial_game_surface.dart';

import 'package:map_core/map_core.dart';

import 'spatial_pixel_material.dart';
import 'spatial_lighting_preview.dart';
import 'spatial_environment_lighting.dart';
import 'spatial_flame_effects.dart';
import 'spatial_renderer_initialization.dart';

part 'model_preview_game.dart';

class ModelPreviewController extends ChangeNotifier {
  Model3dPointLight? _light;
  Model3dPointLight? get light => _light;
  bool editLight = false, nightPreview = false;
  _ModelPreviewGame? _projectionGame;
  int _previewGeneration = 0;
  int get previewGeneration => _previewGeneration;
  void _projectionReady() => notifyListeners();
  Offset? projectPoint(Model3dVector3 point) =>
      _projectionGame?.projectPoint(point);
  void setLight(Model3dPointLight? value) {
    if (_light == value) return;
    _light = value;
    notifyListeners();
  }

  void configureLightEditor({bool? editing, bool? night}) {
    editLight = editing ?? editLight;
    nightPreview = night ?? nightPreview;
    notifyListeners();
  }

  void moveLight(int axis, Offset delta) {
    final current = light;
    if (current == null) return;
    final p = current.localPosition;
    final a = projectPoint(p);
    final b = projectPoint(
      Model3dVector3(
        x: p.x + (axis == 0 ? 1 : 0),
        y: p.y + (axis == 1 ? 1 : 0),
        z: p.z + (axis == 2 ? 1 : 0),
      ),
    );
    if (a == null || b == null || (b - a).distanceSquared < .01) return;
    final v = b - a;
    final amount = (delta.dx * v.dx + delta.dy * v.dy) / v.distanceSquared;
    setLight(
      current.copyWith(
        localPosition: Model3dVector3(
          x: p.x + (axis == 0 ? amount : 0),
          y: p.y + (axis == 1 ? amount : 0),
          z: p.z + (axis == 2 ? amount : 0),
        ),
      ),
    );
  }

  void moveLightOnGround(Offset delta) {
    final current = light;
    if (current == null) return;
    final p = current.localPosition;
    final a = projectPoint(p),
        x = projectPoint(Model3dVector3(x: p.x + 1, y: p.y, z: p.z)),
        z = projectPoint(Model3dVector3(x: p.x, y: p.y, z: p.z + 1));
    if (a == null || x == null || z == null) return;
    final dx = x - a, dz = z - a, det = dx.dx * dz.dy - dz.dx * dx.dy;
    if (det.abs() < .0001) return;
    setLight(
      current.copyWith(
        localPosition: Model3dVector3(
          x: p.x + (delta.dx * dz.dy - dz.dx * delta.dy) / det,
          y: p.y,
          z: p.z + (dx.dx * delta.dy - delta.dx * dx.dy) / det,
        ),
      ),
    );
  }

  double yaw = 0.5;
  double pitch = 0.5;
  double zoom = 1;
  int? animation;
  bool animationLoop = false;
  bool animationPaused = false;
  double animationSpeed = 1;
  int animationVersion = 0;

  void orbit(double dx, double dy) {
    yaw -= dx * 0.008;
    pitch = (pitch + dy * 0.008).clamp(0.05, 1.5);
    notifyListeners();
  }

  void dolly(double delta) {
    zoom = (zoom * math.exp(delta * 0.001)).clamp(0.2, 8);
    notifyListeners();
  }

  void reset() {
    yaw = 0.5;
    pitch = 0.5;
    zoom = 1;
    notifyListeners();
  }

  void play(int? index) {
    animation = index;
    animationPaused = false;
    animationVersion++;
    notifyListeners();
  }

  void restartAnimation() => play(animation);

  void toggleAnimationPause() {
    animationPaused = !animationPaused;
    notifyListeners();
  }

  void configureAnimation({bool? loop, double? speed}) {
    if (speed != null && (!speed.isFinite || speed <= 0 || speed > 16)) {
      throw ArgumentError.value(speed, 'speed');
    }
    animationLoop = loop ?? animationLoop;
    animationSpeed = speed ?? animationSpeed;
    notifyListeners();
  }
}

class ModelPreview extends StatefulWidget {
  const ModelPreview({
    super.key,
    required this.bytes,
    required this.controller,
    required this.minimum,
    required this.maximum,
    required this.background,
    required this.loadingBuilder,
    required this.errorBuilder,
    this.lightOverlayBuilder,
  });

  final Widget Function(BuildContext, ModelPreviewController)?
  lightOverlayBuilder;
  final Uint8List bytes;
  final ModelPreviewController controller;
  final List<double> minimum;
  final List<double> maximum;
  final Color background;
  final WidgetBuilder loadingBuilder;
  final Widget Function(BuildContext, Object) errorBuilder;

  @override
  State<ModelPreview> createState() => _ModelPreviewState();
}

class _ModelPreviewState extends State<ModelPreview> {
  late _ModelPreviewGame game;
  Exception? _initializationFailure;

  @override
  void initState() {
    super.initState();
    _createGame();
  }

  void _createGame() {
    widget.controller._previewGeneration++;
    try {
      game = _ModelPreviewGame(
        widget.bytes,
        widget.controller,
        Vector3.array(widget.minimum),
        Vector3.array(widget.maximum),
        widget.background,
      );
      _initializationFailure = null;
    } on Exception catch (error) {
      _initializationFailure = error;
    }
  }

  @override
  void didUpdateWidget(ModelPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.bytes, oldWidget.bytes) ||
        widget.controller != oldWidget.controller) {
      _createGame();
    }
  }

  @override
  Widget build(BuildContext context) => switch (_initializationFailure) {
    final error? => widget.errorBuilder(context, error),
    null => _surface(context),
  };

  Widget _surface(BuildContext context) => Listener(
    onPointerSignal: (event) {
      if (event is PointerScrollEvent) {
        GestureBinding.instance.pointerSignalResolver.register(
          event,
          (_) => widget.controller.dolly(event.scrollDelta.dy),
        );
      }
    },
    child: GestureDetector(
      onPanUpdate: (details) =>
          widget.controller.orbit(details.delta.dx, details.delta.dy),
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => Stack(
          fit: StackFit.expand,
          children: [
            SpatialGameSurface<_ModelPreviewGame>(
              key: ObjectKey(game),
              game: game,
              continuous:
                  widget.controller.animation != null &&
                      !widget.controller.animationPaused ||
                  (widget.controller.light?.colorCycle != null &&
                      (widget.controller.nightPreview ||
                          widget.controller.light?.nightOnly == false)),
              autofocus: true,
              loadingBuilder: widget.loadingBuilder,
              errorBuilder: (context, error) =>
                  widget.errorBuilder(context, error),
            ),
            if (widget.lightOverlayBuilder != null)
              widget.lightOverlayBuilder!(context, widget.controller),
          ],
        ),
      ),
    ),
  );
}
