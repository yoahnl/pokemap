part of 'model_preview.dart';

class _ModelPreviewGame extends FlameGame3D<World3D, CameraComponent3D> {
  @override
  late final GraphicsDevice device = FlutterFrameGraphicsDevice(
    onPresented: onFirstFrame == null ? null : _firstFrame,
  );

  @override
  late final RenderContext3D context = SpatialRenderContext(device);

  _ModelPreviewGame(
    this.bytes,
    this.controls,
    this.minimum,
    this.maximum,
    this.background,
    this.onFirstFrame,
  ) : super(world: World3D(), camera: AdaptiveCamera3D(fovY: 40));

  final Uint8List bytes;
  final ModelPreviewController controls;
  final Vector3 minimum;
  final Vector3 maximum;
  final Color background;
  final ValueChanged<ui.Image>? onFirstFrame;
  bool _firstFrameDelivered = false;
  AnimatedModelComponent? component;
  MeshComponent? _lightFloor;
  double _lightElapsed = 0;
  late final _flames = SpatialFlameEffects(world);
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

  void _firstFrame(ui.Image image) {
    if (_firstFrameDelivered || component?.isMounted != true) return;
    _firstFrameDelivered = true;
    onFirstFrame?.call(image);
  }

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
    _flames.sync(
      sources: light == null
          ? const []
          : [
              SpatialFlameSource(
                key: controls,
                light: light,
                transform: Matrix4.identity(),
              ),
            ],
      elapsedSeconds: _lightElapsed,
      daylight: night ? 0 : 1,
      cameraPitch: controls.pitch,
      cameraYaw: controls.yaw,
    );
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
    if (controls.light?.colorCycle != null || controls.light?.flame != null)
      _syncLight();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (component != null) _sync();
  }

  @override
  void onRemove() {
    closed = true;
    _flames.clear();
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
