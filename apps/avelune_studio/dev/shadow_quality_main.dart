import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/widgets.dart' hide Texture;

import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_render_3d/src/flutter_frame_graphics_device.dart';
import 'package:map_render_3d/src/adaptive_camera.dart';
import 'package:map_render_3d/src/spatial_authored_shadows.dart';
import 'package:map_render_3d/src/spatial_environment_lighting.dart';
import 'package:map_render_3d/src/spatial_render_context.dart';
import 'package:map_render_3d/src/spatial_pixel_material.dart';
import 'package:map_render_3d/src/spatial_shadow_profile.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'marionette_main.dart' show applyStudioCaptureLifecycle;

void main() {
  MarionetteBinding.ensureInitialized();
  final game = _ShadowQualityGame();
  Timer? captureTimer;
  developer.registerExtension('ext.flutter.avelune.shadowQuality', (
    method,
    parameters,
  ) async {
    if (parameters['captureActivity'] case final value?) {
      captureTimer?.cancel();
      captureTimer = null;
      if (value == 'true') {
        applyStudioCaptureLifecycle(AppLifecycleState.resumed);
        captureTimer = Timer.periodic(
          const Duration(milliseconds: 100),
          (_) => WidgetsBinding.instance.scheduleFrame(),
        );
      }
    }
    if (parameters['running'] case final value?) game.running = value == 'true';
    for (final entry in parameters.entries) {
      final value = double.tryParse(entry.value);
      if (value == null || !value.isFinite) continue;
      switch (entry.key) {
        case 'minute':
          game.minute = value.clamp(0, 1439.99);
        case 'pan':
          game.pan = value.clamp(-8, 8);
        case 'yaw':
          game.yaw = value.clamp(-math.pi, math.pi);
        case 'pitch':
          game.pitch = value.clamp(.15, 1.4);
        case 'offset':
          game.offset = value.clamp(-10000, 10000);
        case 'slope':
          game.slope = value.clamp(-.4, .4);
        case 'resolution':
          game.shadowResolution = value.toInt().clamp(64, 2048);
        case 'radius':
          game.filterRadius = value.clamp(0, 8);
      }
    }
    if (parameters['pointLight'] case final value?) {
      game.pointLight = value == 'true';
    }
    if (parameters['antialiasing'] case final value?) {
      game.context.shadowAntialiasingEnabled = value == 'true';
    }
    if (parameters['multisampling'] case final value?) {
      game.context.preferMultisampledShadows = value == 'true';
    }
    if (game.sceneReady) game.sync();
    game.resumeEngine();
    WidgetsBinding.instance.scheduleFrame();
    return developer.ServiceExtensionResponse.result(jsonEncode(game.snapshot));
  });
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: FittedBox(
          child: SizedBox(
            width: 960,
            height: 600,
            child: RepaintBoundary(
              key: const ValueKey('shadow-quality-surface'),
              child: GameWidget(game: game),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ShadowQualityGame extends FlameGame3D<World3D, CameraComponent3D> {
  _ShadowQualityGame()
    : super(world: World3D(), camera: AdaptiveCamera3D(fovY: 40));

  late final GraphicsDevice _device = FlutterFrameGraphicsDevice();
  @override
  GraphicsDevice get device => _device;
  late final SpatialRenderContext _context = SpatialRenderContext(device);
  @override
  SpatialRenderContext get context => _context;

  final objects = <_ProbeMesh>[];
  late _ProbeMesh ground;
  bool sceneReady = false, running = false, pointLight = false;
  double minute = 590, pan = 0, yaw = 0, pitch = .85, offset = 0, slope = 0;
  int shadowResolution = 1024;
  double filterRadius = 2.5;
  int updates = 0;

  @override
  Color backgroundColor() => const Color(0xff15212d);

  @override
  Future<void> onLoad() async {
    await GpuBackend.initialize();
    await super.onLoad();
    ground = _ProbeMesh(
      'floor',
      Vector3(36, .1, 36),
      Vector3(0, -.05, 0),
      const Color(0xffdec789),
      ground: true,
    );
    objects.addAll([
      _ProbeMesh(
        'house',
        Vector3(4, 4, 3),
        Vector3(-2, 2, -1),
        const Color(0xff599bb5),
      ),
      _ProbeMesh(
        'prop',
        Vector3(1, 1.6, 1),
        Vector3(4, .8, 1),
        const Color(0xff94b75a),
      ),
      _ProbeMesh(
        'pole',
        Vector3(.14, 3.5, .14),
        Vector3(1, 1.75, -4),
        const Color(0xffc7d7e5),
      ),
      _ProbeMesh(
        'wall',
        Vector3(.3, 3, 3),
        Vector3(-5, 1.5, 4),
        const Color(0xffb77755),
      ),
    ]);
    world.addAll([ground, ...objects]);
    context.shadowCasters = objects;
    sceneReady = true;
    sync();
  }

  void sync() {
    if (!sceneReady || size.x <= 0 || size.y <= 0) return;
    final origin = Vector3(offset, 0, offset);
    for (final object in [ground, ...objects]) {
      object.position.setFrom(object.anchor + origin);
    }
    ground.rotation.setFrom(Quaternion.axisAngle(Vector3(0, 0, 1), slope));
    (camera as AdaptiveCamera3D)
      ..sceneRadius = 24
      ..frame(
        origin + Vector3(pan, 0, 1),
        pitch: pitch,
        yaw: yaw,
        distance: 27,
      );
    final frame = spatialDayNightFrame(minute);
    final direction = spatialDayNightSunDirection((
      x: -.45,
      y: 1,
      z: -.3,
    ), frame);
    final casters = [
      for (final object in objects)
        SpatialAuthoredShadowCaster(
          id: object.id,
          bounds: Model3dBounds(
            min: Model3dVector3(
              x: -object.dimensions.x / 2,
              y: -object.dimensions.y / 2,
              z: -object.dimensions.z / 2,
            ),
            max: Model3dVector3(
              x: object.dimensions.x / 2,
              y: object.dimensions.y / 2,
              z: object.dimensions.z / 2,
            ),
          ),
          worldTransform: object.worldTransformMatrix,
        ),
    ];
    final receivers = spatialShadowReceiverBounds(
      camera.viewProjectionMatrix,
      minimumY: -7,
      maximumY: 7,
    );
    final authored = spatialAuthoredShadowLighting(
      casters,
      receiverMinY: -7,
      receiverMaxY: 7,
      receiverBounds: receivers,
      sunDirection: direction,
    );
    final lighting = spatialEnvironmentLighting(
      authored,
      frame: pointLight ? spatialDayNightFrame(0) : frame,
      sunDirection: direction,
      lights: pointLight
          ? [
              SpatialPointLight(
                position: (x: offset - 3, y: 4, z: offset + 4),
                radius: 12,
              ),
            ]
          : [],
    );
    final shadow = lighting.shadow;
    context.lighting = shadow == null
        ? lighting
        : SpatialLightingProfile.stylized(
            ambientColor: lighting.ambientColor,
            sunColor: lighting.sunColor,
            ambientStrength: lighting.ambientStrength,
            sunStrength: lighting.sunStrength,
            sunDirection: lighting.sunDirection,
            groundStrength: lighting.groundStrength,
            actorStrength: lighting.actorStrength,
            surfaceStrength: lighting.surfaceStrength,
            sceneTint: lighting.sceneTint,
            shadow: SpatialShadowProfile(
              casterInstanceIds: shadow.casterInstanceIds,
              center: shadow.center,
              extent: shadow.extent,
              depth: shadow.depth,
              resolution: shadowResolution,
              bias: shadow.bias,
              opacity: shadow.opacity,
              filterRadius: filterRadius,
              actorReceivers: shadow.actorReceivers,
              receiverMinY: shadow.receiverMinY,
              receiverMaxY: shadow.receiverMaxY,
            ),
          );
  }

  Map<String, Object?> get snapshot {
    final shadow = context.lighting.shadow;
    return {
      'ready': sceneReady,
      'updates': updates,
      'running': running,
      'minute': minute,
      'pan': pan,
      'yaw': yaw,
      'pitch': pitch,
      'offset': offset,
      'slope': slope,
      'pointLight': pointLight,
      'antialiasing': context.shadowAntialiasingEnabled,
      'filterRadius': filterRadius,
      'viewport': [size.x, size.y],
      'lifecycle': WidgetsBinding.instance.lifecycleState?.name,
      'solarSamples': context.shadowFrame?.samples,
      'pointSamples': context.pointShadowFrame?.samples,
      'supersampledSolar': context.shadowFrame?.supersampled,
      'supersampledPoint': context.pointShadowFrame?.supersampled,
      'sun': context.lighting.sunDirection.toString(),
      'projection': shadow == null
          ? null
          : spatialShadowProjection(
              shadow,
              context.lighting.sunDirection,
            ).viewProjection.storage.toList(),
      'shadow': shadow == null
          ? null
          : {
              'extent': shadow.extent,
              'depth': shadow.depth,
              'center': shadow.center.toString(),
              'resolution': shadow.resolution,
            },
      'stats': {
        'casters': context.shadowStats.casterDrawCount,
        'allocations': context.shadowStats.targetAllocations,
        'pointCasters': context.shadowStats.pointCasterDrawCount,
      },
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    updates++;
    if (running) minute = (minute + dt * 1.2) % 1440;
    sync();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    sync();
  }
}

class _ProbeMesh extends MeshComponent {
  _ProbeMesh(
    this.id,
    this.dimensions,
    this.anchor,
    Color color, {
    bool ground = false,
  }) : super(
         mesh: CuboidMesh(
           size: dimensions,
           material: SpatialPixelMaterial(
             Texture.standard,
             lightingRole: ground
                 ? SpatialPixelLightingRole.ground
                 : SpatialPixelLightingRole.surface,
           )..albedoColor = color,
         ),
         position: anchor.clone(),
       );
  final String id;
  final Vector3 dimensions, anchor;

  @override
  void draw(covariant RenderContext3D context) {
    final spatial = context as SpatialRenderContext;
    spatial.sourceInstanceId = id;
    try {
      super.draw(context);
    } finally {
      spatial.sourceInstanceId = null;
    }
  }
}
