import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flame/game.dart' show GameWidget;
import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'model_byte_loader.dart';
import 'adaptive_camera.dart';
import 'flutter_frame_graphics_device.dart';
import 'model_playback.dart';

class ModelPreviewController extends ChangeNotifier {
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
  });

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

  @override
  void initState() {
    super.initState();
    _createGame();
  }

  void _createGame() {
    game = _ModelPreviewGame(
      widget.bytes,
      widget.controller,
      Vector3.array(widget.minimum),
      Vector3.array(widget.maximum),
      widget.background,
    );
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
  Widget build(BuildContext context) => Listener(
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
      child: GameWidget<_ModelPreviewGame>(
        key: ObjectKey(game),
        game: game,
        loadingBuilder: widget.loadingBuilder,
        errorBuilder: (context, error) => widget.errorBuilder(context, error),
      ),
    ),
  );
}

class _ModelPreviewGame extends FlameGame3D<World3D, CameraComponent3D> {
  static Future<void>? _initialization;
  @override
  late final GraphicsDevice device = FlutterFrameGraphicsDevice();

  _ModelPreviewGame(
    this.bytes,
    this.controls,
    this.minimum,
    this.maximum,
    this.background,
  ) : super(world: World3D(), camera: AdaptiveCamera3D(fovY: 40));

  final Uint8List bytes;
  final ModelPreviewController controls;
  final Vector3 minimum;
  final Vector3 maximum;
  final Color background;
  AnimatedModelComponent? component;
  int? activeAnimation;
  int activeAnimationVersion = -1;
  bool closed = false;

  @override
  Color backgroundColor() => background;

  @override
  Future<void> onLoad() async {
    await (_initialization ??= GpuBackend.initialize());
    if (closed) return;
    await super.onLoad();
    if (closed) return;
    final model = await ModelByteLoader.load(bytes);
    if (closed) return;
    component = _PreviewModelComponent(model: model);
    await world.add(LightComponent.ambient(intensity: 0.85));
    await world.add(component!);
    if (closed) return;
    controls.addListener(_sync);
    _sync();
  }

  void _sync() {
    final center = (minimum + maximum) / 2;
    final radius = math.max((maximum - minimum).length / 2, 0.01);
    (camera as AdaptiveCamera3D).sceneRadius = radius;
    final aspect = size.y > 0 ? size.x / size.y : 1.0;
    final halfFov = math.atan(math.tan(math.pi / 9) * math.min(1.0, aspect));
    final distance = radius / math.sin(halfFov) * 1.2 * controls.zoom;
    (camera as AdaptiveCamera3D).frame(
      center,
      pitch: controls.pitch,
      yaw: controls.yaw,
      distance: distance,
    );
    if (controls.animation != activeAnimation ||
        controls.animationVersion != activeAnimationVersion) {
      activeAnimation = controls.animation;
      activeAnimationVersion = controls.animationVersion;
      if (activeAnimation == null) {
        component?.stopAnimation();
      } else if (activeAnimation! < (component?.animationCount ?? 0)) {
        component?.play(
          activeAnimation!,
          loop: controls.animationLoop,
          speed: controls.animationSpeed,
        );
      }
    }
    component?.playback
      ?..loop = controls.animationLoop
      ..speed = controls.animationSpeed
      ..paused = controls.animationPaused;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (component != null) _sync();
  }

  @override
  void onRemove() {
    closed = true;
    controls.removeListener(_sync);
    super.onRemove();
  }
}

class _PreviewModelComponent extends AnimatedModelComponent {
  _PreviewModelComponent({required super.model});

  @override
  bool isVisible(CameraComponent3D camera) => true;
}
