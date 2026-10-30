import 'dart:ui' as ui;

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/widgets.dart' hide Texture;
import 'package:map_core/map_core.dart';

import 'battle_stage_camera.dart';
import 'flutter_frame_graphics_device.dart';
import 'spatial_actor_visual.dart';
import 'spatial_pixel_material.dart';
import 'spatial_render_context.dart';
import 'spatial_renderer_initialization.dart';

final class BattleStageBillboard {
  const BattleStageBillboard({
    required this.id,
    required this.image,
    required this.source,
    required this.position,
    required this.width,
    required this.height,
    this.tint = const ui.Color(0xffffffff),
  });

  final Object id;
  final ui.Image image;
  final ui.Rect source;
  final Model3dVector3 position;
  final double width, height;
  final ui.Color tint;
}

final class BattleStageGround {
  const BattleStageGround({required this.points, required this.color});

  final List<Model3dVector3> points;
  final ui.Color color;
}

final class BattleStage3D {
  BattleStage3D._(this._game);

  final _BattleStageGame _game;
  bool _closed = false;

  static Future<BattleStage3D> create(ui.Size size) async {
    await initializeSpatialRenderer();
    final game = _BattleStageGame();
    game.onGameResize(Vector2(size.width, size.height));
    try {
      await game.load();
      game.mount();
      await game.ready();
      game.update(0);
      return BattleStage3D._(game);
    } catch (_) {
      game.close();
      rethrow;
    }
  }

  Set<Object> render({
    required ui.Canvas canvas,
    required BuildContext context,
    required ui.Rect viewport,
    required ui.Rect clip,
    required Model3dVector3 eye,
    required Model3dVector3 aim,
    required double focal,
    required ui.Offset projectionCenter,
    required List<BattleStageBillboard> billboards,
    required List<BattleStageGround> ground,
  }) {
    if (_closed || viewport.isEmpty) return const {};
    _game.hostContext = context;
    if (_game.canvasSize.x != viewport.width ||
        _game.canvasSize.y != viewport.height) {
      _game.onGameResize(Vector2(viewport.width, viewport.height));
    }
    _game.camera.setFrame(
      eye: eye,
      aim: aim,
      size: viewport.size,
      focalLength: focal,
      projectionCenter: projectionCenter - viewport.topLeft,
    );
    _game.syncGround(ground);
    final visible = _game.syncBillboards(billboards);
    _game.update(0);
    canvas.save();
    try {
      canvas.clipRect(clip);
      canvas.translate(viewport.left, viewport.top);
      (_game.device as FlutterFrameGraphicsDevice).guardFrame(
        () => _game.render(canvas),
      );
    } finally {
      canvas.restore();
    }
    return visible;
  }

  void dispose() {
    if (_closed) return;
    _closed = true;
    _game.close();
  }
}

final class _BattleStageGame extends FlameGame3D<World3D, BattleStageCamera> {
  _BattleStageGame() : super(world: World3D(), camera: BattleStageCamera());

  @override
  late final GraphicsDevice device = FlutterFrameGraphicsDevice();

  @override
  late final RenderContext3D context = SpatialRenderContext(device);

  BuildContext? hostContext;
  @override
  BuildContext? get buildContext => hostContext;

  final _textures = <ui.Image, SpatialActorTexture>{};
  final _pendingTextures = <ui.Image>{};
  final _failedTextures = <ui.Image>{};
  Set<ui.Image> _activeImages = {};
  final _actors =
      <Object, ({MeshComponent mesh, SpatialPixelMaterial material})>{};
  final _ground = <MeshComponent>[];
  List<BattleStageGround>? _groundFrame;
  bool closed = false;

  Set<Object> syncBillboards(List<BattleStageBillboard> frames) {
    final active = frames.map((frame) => frame.id).toSet();
    for (final id
        in _actors.keys.where((id) => !active.contains(id)).toList()) {
      _actors.remove(id)!.mesh.removeFromParent();
    }
    final images = frames.map((frame) => frame.image).toSet();
    _activeImages = images;
    _textures.removeWhere((image, _) => !images.contains(image));
    _failedTextures.removeWhere((image) => !images.contains(image));
    final right = camera.right.normalized();
    final forward = camera.forward.normalized();
    final up = right.cross(forward).normalized();
    final rotation = Quaternion.fromRotation(
      Matrix3.columns(right, up, -forward),
    );
    final visible = <Object>{};
    for (final frame in frames) {
      final texture = _textures[frame.image];
      if (texture == null) {
        _actors.remove(frame.id)?.mesh.removeFromParent();
        if (!_failedTextures.contains(frame.image) &&
            _pendingTextures.add(frame.image)) {
          SpatialActorTexture.fromImage(frame.image)
              .then((texture) {
                _pendingTextures.remove(frame.image);
                if (!closed && _activeImages.contains(frame.image))
                  _textures[frame.image] = texture;
              })
              .catchError((Object error, StackTrace stack) {
                _pendingTextures.remove(frame.image);
                if (!closed) {
                  _failedTextures.add(frame.image);
                  FlutterError.reportError(
                    FlutterErrorDetails(
                      exception: error,
                      stack: stack,
                      library: 'battle stage 3D',
                    ),
                  );
                }
              });
        }
        continue;
      }
      var actor = _actors[frame.id];
      if (actor == null) {
        final material = SpatialPixelMaterial(
          texture.texture,
          lightingRole: SpatialPixelLightingRole.actor,
          alphaMode: Model3dAlphaMode.blend,
          preserveUnlitColor: true,
        );
        final mesh = _quad(material);
        actor = (mesh: mesh, material: material);
        _actors[frame.id] = actor;
        world.add(mesh);
      }
      actor.material
        ..albedoTexture = texture.texture
        ..albedoColor = frame.tint.withValues(
          red: frame.tint.r * frame.tint.a,
          green: frame.tint.g * frame.tint.a,
          blue: frame.tint.b * frame.tint.a,
        );
      actor.material.uvRect.setValues(
        frame.source.left / frame.image.width,
        frame.source.top / frame.image.height,
        frame.source.width / frame.image.width,
        frame.source.height / frame.image.height,
      );
      actor.mesh.position.setValues(
        frame.position.x,
        frame.position.y,
        frame.position.z,
      );
      actor.mesh.rotation.setFrom(rotation);
      actor.mesh.scale.setValues(frame.width, frame.height, 1);
      visible.add(frame.id);
    }
    return visible;
  }

  MeshComponent _quad(SpatialPixelMaterial material) => MeshComponent(
    mesh: Mesh()
      ..addSurface(
        Surface(
          vertices: [
            Vertex(position: Vector3(-.5, 0, 0), texCoord: Vector2(0, 1)),
            Vertex(position: Vector3(.5, 0, 0), texCoord: Vector2(1, 1)),
            Vertex(position: Vector3(.5, 1, 0), texCoord: Vector2(1, 0)),
            Vertex(position: Vector3(-.5, 1, 0), texCoord: Vector2(0, 0)),
          ],
          indices: [0, 1, 2, 2, 3, 0],
          material: material,
        ),
      ),
  );

  void syncGround(List<BattleStageGround> frame) {
    if (identical(frame, _groundFrame)) return;
    _groundFrame = frame;
    for (final mesh in _ground) {
      mesh.removeFromParent();
    }
    _ground.clear();
    for (final patch in frame) {
      if (patch.points.length < 3) continue;
      final material = SpatialPixelMaterial(
        Texture.standard,
        lightingRole: SpatialPixelLightingRole.ground,
        preserveUnlitColor: true,
        alphaMode: Model3dAlphaMode.opaque,
      )..albedoColor = patch.color;
      final mesh = MeshComponent(
        mesh: Mesh()
          ..addSurface(
            Surface(
              vertices: [
                for (final point in patch.points)
                  Vertex(
                    position: Vector3(point.x, point.y, point.z),
                    normal: Vector3(0, 1, 0),
                    texCoord: Vector2.zero(),
                  ),
              ],
              indices: [
                for (var i = 1; i < patch.points.length - 1; i++) ...[
                  0,
                  i + 1,
                  i,
                ],
              ],
              material: material,
            ),
          ),
      );
      _ground.add(mesh);
      world.add(mesh);
    }
  }

  void close() {
    if (closed) return;
    closed = true;
    removeAll(children);
    processLifecycleEvents();
    finalizeRemoval();
    _actors.clear();
    _textures.clear();
    _pendingTextures.clear();
    _failedTextures.clear();
    _activeImages.clear();
    _ground.clear();
    hostContext = null;
  }
}
