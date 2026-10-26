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
import 'spatial_renderer_initialization.dart';

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

  @override
  void initState() {
    super.initState();
    _createGame();
  }

  void _createGame() {
    widget.controller._previewGeneration++;
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

class _ModelPreviewGame extends FlameGame3D<World3D, CameraComponent3D> {
  @override
  late final GraphicsDevice device = FlutterFrameGraphicsDevice();

  @override
  late final RenderContext3D context = SpatialRenderContext(device);

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
  MeshComponent? _lightFloor;
  double _lightElapsed = 0;
  Offset? projectPoint(Model3dVector3 point) {
    if (size.x <= 0 || size.y <= 0 || component == null) return null;
    final clip = camera.viewProjectionMatrix.transform(
      Vector4(point.x, point.y, point.z, 1),
    );
    if (clip.w <= .00001) return null;
    return Offset(
      (clip.x / clip.w + 1) * size.x / 2,
      (1 - clip.y / clip.w) * size.y / 2,
    );
  }

  int? activeAnimation;
  int activeAnimationVersion = -1;
  bool closed = false;

  @override
  Color backgroundColor() => background;

  @override
  Future<void> onLoad() async {
    await initializeSpatialRenderer();
    if (closed) return;
    await super.onLoad();
    if (closed) return;
    final model = await ModelByteLoader.load(bytes);
    if (closed) return;
    controls._projectionGame = this;
    component = _PreviewModelComponent(model: model);
    world.add(LightComponent.ambient(intensity: 0.85));
    world.add(component!);
    if (closed) return;
    controls.addListener(_sync);
    _sync();
    controls._projectionReady();
  }

  void _sync() {
    _syncLight();
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

  void _syncLight() {
    final light = controls.light;
    final renderContext = context as SpatialRenderContext;
    final night = controls.nightPreview;
    renderContext.lighting = light == null
        ? SpatialLightingProfile.disabled
        : SpatialLightingProfile.stylized(
            ambientStrength: night ? .2 : .82,
            sunStrength: night ? 0 : .3,
            sceneTint: night
                ? spatialDayNightFrame(0).tint
                : const Color(0xffffffff),
            pointLights: [
              spatialPlacedPointLight(
                light,
                Matrix4.identity(),
                daylight: night ? 0 : 1,
                elapsedSeconds: _lightElapsed,
              ),
            ],
          );
    if (light != null && _lightFloor == null) {
      final span = math.max((maximum - minimum).length, 2.0) * 2;
      final y = minimum.y - .02,
          x = (minimum.x + maximum.x) / 2,
          z = (minimum.z + maximum.z) / 2;
      final material = SpatialPixelMaterial(
        Texture.standard,
        lightingRole: SpatialPixelLightingRole.ground,
        preserveUnlitColor: true,
      );
      final mesh = Mesh()
        ..addSurface(
          Surface(
            vertices: [
              for (final p in [
                Vector3(x - span, y, z - span),
                Vector3(x + span, y, z - span),
                Vector3(x + span, y, z + span),
                Vector3(x - span, y, z + span),
              ])
                Vertex(
                  position: p,
                  normal: Vector3(0, 1, 0),
                  texCoord: Vector2.zero(),
                ),
            ],
            indices: [0, 2, 1, 0, 3, 2],
            material: material,
          ),
        );
      _lightFloor = MeshComponent(mesh: mesh);
      world.add(_lightFloor!);
    } else if (light == null && _lightFloor != null) {
      _lightFloor!.removeFromParent();
      _lightFloor = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt.isFinite && dt > 0) _lightElapsed += dt;
    if (controls.light?.colorCycle != null) _syncLight();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (component != null) _sync();
  }

  @override
  void onRemove() {
    closed = true;
    if (identical(controls._projectionGame, this))
      controls._projectionGame = null;
    controls.removeListener(_sync);
    super.onRemove();
  }
}

class _PreviewModelComponent extends AnimatedModelComponent {
  _PreviewModelComponent({required super.model});

  @override
  bool isVisible(CameraComponent3D camera) => true;
}
