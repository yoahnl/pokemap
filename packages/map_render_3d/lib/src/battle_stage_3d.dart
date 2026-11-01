import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame_3d/camera.dart';
import 'package:flame_3d/components.dart';
import 'package:flame_3d/game.dart';
import 'package:flame_3d/graphics.dart';
import 'package:flame_3d/resources.dart';
import 'package:flutter/widgets.dart' hide Texture;
import 'package:map_core/map_core.dart';

import 'battle_stage_camera.dart';
import 'battle_stage_underlays.dart';
import 'battle_stage_textured_quad.dart';
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
    this.shadow,
    this.trails = const [],
  });

  final Object id;
  final ui.Image image;
  final ui.Rect source;
  final Model3dVector3 position;
  final double width, height;
  final ui.Color tint;
  final BattleStageSoftShadow? shadow;
  final List<BattleStageTrail> trails;
}

final class BattleStageSoftShadow {
  const BattleStageSoftShadow({
    required this.maskSize,
    required this.position,
    required this.width,
    required this.height,
    required this.tint,
  });

  final ui.Size maskSize;
  final Model3dVector3 position;
  final double width, height;
  final ui.Color tint;

  static ({int width, int height}) imageSize(ui.Size ellipse) =>
      battleStageShadowImageSize(ellipse);
}

final class BattleStageTrail {
  const BattleStageTrail({
    required this.position,
    required this.width,
    required this.height,
    required this.tint,
  });

  final Model3dVector3 position;
  final double width, height;
  final ui.Color tint;
}

final class BattleStageGround {
  const BattleStageGround({required this.points, required this.color});

  final List<Model3dVector3> points;
  final ui.Color color;
}

final class BattleStageFrameResult {
  const BattleStageFrameResult({
    required this.presented,
    this.submittedActorIds = const {},
  });

  final bool presented;
  final Set<Object> submittedActorIds;
}

abstract interface class BattleStageRenderer {
  BattleStageFrameResult render({
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
  });

  void dispose();
}

typedef BattleStageTextureDiagnostics = ({
  int activeTextures,
  int pendingTextures,
  int failedTextures,
  int retiredTextures,
  int residentBytes,
  int transientBytes,
  int startedImports,
  int completedImports,
  int evictions,
});

final class BattleStageTextureCache {
  BattleStageTextureCache({
    RuntimeResourceBudget? resourceBudget,
    Future<SpatialActorTexture> Function(ui.Image)? importer,
    void Function(Object, StackTrace)? onError,
  }) : _budget = resourceBudget ?? RuntimeResourceBudget(),
       _ownsBudget = resourceBudget == null,
       _importer = importer ?? SpatialActorTexture.fromImage,
       _onError = onError ?? _reportError;

  final RuntimeResourceBudget _budget;
  final bool _ownsBudget;
  final Future<SpatialActorTexture> Function(ui.Image) _importer;
  final void Function(Object, StackTrace) _onError;
  final _textures =
      <
        ui.Image,
        ({SpatialActorTexture texture, RuntimeResourceReservation lease})
      >{};
  final _pending = <ui.Image, Object>{};
  final _failed = <ui.Image>{};
  final _inFlight = <Future<void>>{};
  final _obsoleteImports = <Future<void>>{};
  final _sourceRequests = <ui.Image, Set<Future<void>>>{};
  final _leases = <RuntimeResourceReservation>{};
  final _retired = <RuntimeResourceReservation>[];
  Completer<void>? _retirementPurged;
  Set<ui.Image> _active = {};
  bool _closed = false;
  int _startedImports = 0;
  int _completedImports = 0;
  int _evictions = 0;

  SpatialActorTexture? textureFor(ui.Image image) => _textures[image]?.texture;

  BattleStageTextureDiagnostics get diagnostics => (
    activeTextures: _textures.length,
    pendingTextures: _inFlight.length,
    failedTextures: _failed.length,
    retiredTextures: _retired.length,
    residentBytes: _leases.fold(0, (sum, lease) => sum + lease.residentBytes),
    transientBytes: _transientBytes,
    startedImports: _startedImports,
    completedImports: _completedImports,
    evictions: _evictions,
  );
  int _transientBytes = 0;

  Future<void> get settled async {
    while (_inFlight.isNotEmpty) {
      await Future.wait(_inFlight.toList());
    }
  }

  Future<void> sourceSettled(ui.Image image) async {
    await Future.wait(_sourceRequests[image]?.toList() ?? const []);
  }

  void sync(Set<ui.Image> images) {
    if (_closed) return;
    _active = Set.of(images);
    _pending.removeWhere((image, _) {
      if (images.contains(image)) return false;
      _obsoleteImports.addAll(_sourceRequests[image] ?? const {});
      return true;
    });
    _failed.removeWhere((image) => !images.contains(image));
    for (final image
        in _textures.keys.where((image) => !images.contains(image)).toList()) {
      _retired.add(_textures.remove(image)!.lease);
      _evictions++;
    }
    if (_retired.isNotEmpty) _retirementPurged ??= Completer<void>();
    for (final image in images) {
      if (_textures.containsKey(image) ||
          _failed.contains(image) ||
          _pending.containsKey(image))
        continue;
      final token = Object();
      _pending[image] = token;
      ui.Image owned;
      try {
        owned = image.clone();
      } catch (error, stack) {
        _pending.remove(image);
        _failed.add(image);
        _onError(error, stack);
        continue;
      }
      late final Future<void> request;
      request = _load(image, owned, token).whenComplete(() {
        _inFlight.remove(request);
        _obsoleteImports.remove(request);
        final sources = _sourceRequests[image];
        sources?.remove(request);
        if (sources?.isEmpty ?? false) _sourceRequests.remove(image);
        _disposeOwnedBudgetIfIdle();
      });
      _inFlight.add(request);
      (_sourceRequests[image] ??= {}).add(request);
    }
  }

  bool _isCurrent(ui.Image source, Object token) =>
      !_closed &&
      _active.contains(source) &&
      identical(_pending[source], token);

  Future<void> _load(ui.Image source, ui.Image owned, Object token) async {
    RuntimeResourceReservation? lease;
    var transient = 0;
    var retained = false;
    try {
      if (_obsoleteImports.isNotEmpty) {
        await Future.wait(_obsoleteImports.toList());
      }
      final retirement = _retirementPurged;
      if (retirement != null) await retirement.future;
      if (!_isCurrent(source, token)) return;
      final rgba = runtimeImageRgbaByteLength(
        owned.width,
        owned.height,
        maximumBytes: _budget.profile.maximumResidentBytes ~/ 2,
      );
      lease = await _budget.acquire(
        residentBytes: rgba * 2 + rgba ~/ 4,
        transientBytes: rgba,
        isCurrent: () => _isCurrent(source, token),
      );
      _leases.add(lease);
      transient = rgba;
      _transientBytes += transient;
      lease.ensureCurrent();
      _startedImports++;
      final texture = await _importer(owned);
      lease.ensureCurrent();
      lease.commit();
      _textures[source] = (texture: texture, lease: lease);
      retained = true;
      _completedImports++;
    } catch (error, stack) {
      if (_isCurrent(source, token)) {
        _failed.add(source);
        _onError(error, stack);
      }
    } finally {
      owned.dispose();
      _transientBytes -= transient;
      if (!retained && lease != null) {
        _leases.remove(lease);
        lease.release();
      }
      if (identical(_pending[source], token)) _pending.remove(source);
    }
  }

  void releaseRetired() {
    final retirement = _retirementPurged;
    _retirementPurged = null;
    for (final lease in _retired) {
      _leases.remove(lease);
      lease.release();
    }
    _retired.clear();
    retirement?.complete();
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _active.clear();
    _pending.clear();
    _failed.clear();
    _retired.addAll(_textures.values.map((entry) => entry.lease));
    _textures.clear();
    releaseRetired();
    _disposeOwnedBudgetIfIdle();
  }

  void _disposeOwnedBudgetIfIdle() {
    if (_closed && _ownsBudget && _inFlight.isEmpty) _budget.dispose();
  }

  static void _reportError(Object error, StackTrace stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'battle stage 3D',
      ),
    );
  }
}

final class BattleStage3D implements BattleStageRenderer {
  BattleStage3D._(this._game);

  final _BattleStageGame _game;
  bool _closed = false;

  static Future<BattleStage3D> create(
    ui.Size size, {
    RuntimeResourceBudget? resourceBudget,
  }) async {
    await initializeSpatialRenderer();
    final game = _BattleStageGame(resourceBudget: resourceBudget);
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

  BattleStageTextureDiagnostics get textureDiagnostics =>
      _game.textures.diagnostics;
  ({
    int meshes,
    int activeMasks,
    int generatedMasks,
    int failedMasks,
    int sourceResidentBytes,
  })
  get underlayDiagnostics => (
    meshes: _game._underlays.length,
    activeMasks: _game.masks.activeMasks,
    generatedMasks: _game.masks.generatedMasks,
    failedMasks: _game.masks.failedMasks,
    sourceResidentBytes: _game.masks.residentBytes,
  );
  ({int actors, int ground}) get meshCounts =>
      (actors: _game._actors.length, ground: _game._ground.length);
  int get importedTextureUploadCount =>
      (_game.device as FlutterFrameGraphicsDevice).textureAllocations;
  int get importedTextureUploadBytes =>
      (_game.device as FlutterFrameGraphicsDevice).colorTextureAllocationBytes;

  @override
  BattleStageFrameResult render({
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
    if (_closed || viewport.isEmpty) {
      return const BattleStageFrameResult(presented: false);
    }
    if (!_game.camera.setFrame(
      eye: eye,
      aim: aim,
      size: viewport.size,
      focalLength: focal,
      projectionCenter: projectionCenter - viewport.topLeft,
    )) {
      return const BattleStageFrameResult(presented: false);
    }
    _game.hostContext = context;
    if (_game.canvasSize.x != viewport.width ||
        _game.canvasSize.y != viewport.height) {
      _game.onGameResize(Vector2(viewport.width, viewport.height));
    }
    _game.syncGround(ground);
    final visible = _game.syncBillboards(billboards);
    _game.update(0);
    _game.processLifecycleEvents();
    _game.textures.releaseRetired();
    if (visible.length != billboards.length) {
      return const BattleStageFrameResult(presented: false);
    }
    final device = _game.device as FlutterFrameGraphicsDevice;
    final presentationsBefore = device.successfulPresentations;
    canvas.save();
    try {
      canvas.clipRect(clip);
      canvas.translate(viewport.left, viewport.top);
      device.guardFrame(() => _game.render(canvas));
    } finally {
      canvas.restore();
    }
    final presented = device.successfulPresentations > presentationsBefore;
    return BattleStageFrameResult(
      presented: presented,
      submittedActorIds: presented ? visible : const {},
    );
  }

  @override
  void dispose() {
    if (_closed) return;
    _closed = true;
    _game.close();
  }
}

final class _BattleStageGame extends FlameGame3D<World3D, BattleStageCamera> {
  _BattleStageGame({RuntimeResourceBudget? resourceBudget})
    : _resourceBudget = resourceBudget ?? RuntimeResourceBudget(),
      _ownsResourceBudget = resourceBudget == null,
      super(world: World3D(), camera: BattleStageCamera());

  final RuntimeResourceBudget _resourceBudget;
  final bool _ownsResourceBudget;

  @override
  late final GraphicsDevice device = FlutterFrameGraphicsDevice()
    ..depthStencilState = DepthStencilState.none;

  @override
  late final RenderContext3D context = SpatialRenderContext(
    device,
    transparentOrder: (a, b) {
      final first = _drawOrders[a];
      final second = _drawOrders[b];
      return first == null || second == null ? 0 : first.compareTo(second);
    },
  );

  BuildContext? hostContext;
  @override
  BuildContext? get buildContext => hostContext;

  late final BattleStageTextureCache textures = BattleStageTextureCache(
    resourceBudget: _resourceBudget,
    importer: (image) => SpatialActorTexture.fromImage(
      image,
      textureAllocator:
          (device as FlutterFrameGraphicsDevice).allocateRgbaTexture,
    ),
  );
  final _actors = <Object, BattleStageTexturedQuad>{};
  final _underlays = <(Object, int), BattleStageTexturedQuad>{};
  final _drawOrders = <SpatialPixelMaterial, BattleStageDrawOrder>{};
  late final masks = BattleStageShadowMaskCache(
    resourceBudget: _resourceBudget,
  );
  final _ground = <MeshComponent>[];
  List<BattleStageGround>? _groundFrame;
  bool closed = false;

  Set<Object> syncBillboards(List<BattleStageBillboard> frames) {
    final active = frames.map((frame) => frame.id).toSet();
    _drawOrders.clear();
    for (final id
        in _actors.keys.where((id) => !active.contains(id)).toList()) {
      _actors.remove(id)!.mesh.removeFromParent();
    }
    masks.sync({
      for (final frame in frames)
        if (frame.shadow != null) frame.shadow!.maskSize,
    });
    final images = frames.map((frame) => frame.image).toSet()
      ..addAll([
        for (final frame in frames)
          if (frame.shadow case final shadow?)
            if (masks.imageFor(shadow.maskSize) case final image?) image,
      ]);
    textures.sync(images);
    masks.releaseRetiredAfter(textures.sourceSettled);
    final right = camera.right.normalized();
    final forward = camera.forward.normalized();
    final up = right.cross(forward).normalized();
    final rotation = Quaternion.fromRotation(
      Matrix3.columns(right, up, -forward),
    );
    final visible = <Object>{};
    final activeUnderlays = <(Object, int)>{};
    for (final (actorIndex, frame) in frames.indexed) {
      final texture = textures.textureFor(frame.image);
      final shadow = frame.shadow;
      final mask = shadow == null ? null : masks.imageFor(shadow.maskSize);
      final shadowTexture = mask == null ? null : textures.textureFor(mask);
      if (texture == null || shadow != null && shadowTexture == null) {
        _actors.remove(frame.id)?.mesh.removeFromParent();
        continue;
      }
      var actor = _actors[frame.id];
      if (actor == null) {
        actor = BattleStageTexturedQuad(texture.texture);
        _actors[frame.id] = actor;
        world.add(actor.mesh);
      }
      actor.setTexture(texture.texture);
      actor.material.albedoColor = frame.tint.withValues(
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
      final depth = Vector3(
        frame.position.x,
        frame.position.y,
        frame.position.z,
      )..sub(camera.position);
      final actorDepth = depth.dot(forward);
      _drawOrders[actor.material] = BattleStageDrawOrder(
        shadow: false,
        actorDepth: actorDepth,
        actorIndex: actorIndex,
        partIndex: frame.trails.length,
      );
      if (shadow != null) {
        _syncUnderlay(
          (frame.id, -1),
          shadowTexture!,
          mask!,
          ui.Offset.zero &
              ui.Size(mask.width.toDouble(), mask.height.toDouble()),
          shadow.position,
          shadow.width,
          shadow.height,
          shadow.tint,
          rotation,
          BattleStageDrawOrder(
            shadow: true,
            actorDepth: actorDepth,
            actorIndex: actorIndex,
            partIndex: 0,
          ),
        );
        activeUnderlays.add((frame.id, -1));
      }
      for (final (index, trail) in frame.trails.indexed) {
        _syncUnderlay(
          (frame.id, index),
          texture,
          frame.image,
          frame.source,
          trail.position,
          trail.width,
          trail.height,
          trail.tint,
          rotation,
          BattleStageDrawOrder(
            shadow: false,
            actorDepth: actorDepth,
            actorIndex: actorIndex,
            partIndex: index,
          ),
        );
        activeUnderlays.add((frame.id, index));
      }
      visible.add(frame.id);
    }
    for (final id
        in _underlays.keys
            .where((id) => !activeUnderlays.contains(id))
            .toList()) {
      _underlays.remove(id)!.mesh.removeFromParent();
    }
    return visible;
  }

  void _syncUnderlay(
    (Object, int) id,
    SpatialActorTexture texture,
    ui.Image image,
    ui.Rect source,
    Model3dVector3 position,
    double width,
    double height,
    ui.Color tint,
    Quaternion rotation,
    BattleStageDrawOrder order,
  ) {
    final underlay = _underlays.putIfAbsent(id, () {
      final quad = BattleStageTexturedQuad(texture.texture);
      world.add(quad.mesh);
      return quad;
    });
    underlay.setTexture(texture.texture);
    underlay.material.albedoColor = tint.withValues(
      red: tint.r * tint.a,
      green: tint.g * tint.a,
      blue: tint.b * tint.a,
    );
    underlay.material.uvRect.setValues(
      source.left / image.width,
      source.top / image.height,
      source.width / image.width,
      source.height / image.height,
    );
    underlay.mesh.position.setValues(position.x, position.y, position.z);
    underlay.mesh.rotation.setFrom(rotation);
    underlay.mesh.scale.setValues(width, height, 1);
    _drawOrders[underlay.material] = order;
  }

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
    _underlays.clear();
    _drawOrders.clear();
    textures.close();
    masks.close(imports: textures.sourceSettled);
    if (_ownsResourceBudget) {
      unawaited(
        Future.wait([textures.settled, masks.settled])
            .then((_) => _resourceBudget.dispose()),
      );
    }
    _ground.clear();
    _groundFrame = null;
    hostContext = null;
  }
}
