import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import 'collision/pixel_movement_resolver.dart';
import 'spatial_terrain_navigation.dart';

final class SpatialMovementController {
  SpatialMovementController(
      {required this.scene,
      required Iterable<ProjectModel3dEntry> models,
      Iterable<MapEntity> entities = const []})
      : entities = List.unmodifiable(entities),
        models = {for (final model in models) model.id: model},
        allowDiagonalMovement = scene.navigation.allowDiagonalMovement {
    reset();
  }
  final MapSpatialScene scene;
  final List<MapEntity> entities;
  final Map<String, ProjectModel3dEntry> models;
  static const pixelsPerCell = 16;
  late PixelPosition _position;
  double _remainderX = 0, _remainderZ = 0;
  int _inputX = 0, _inputZ = 0;
  bool _run = false, paused = false, moving = false;
  bool allowDiagonalMovement;
  int inputEpoch = 0;
  EntityFacing facing = EntityFacing.south;
  double animationSeconds = 0;
  bool get running => moving && _run;
  double get x => (_position.leftPx + 16) / pixelsPerCell;
  double get z => (_position.topPx + 31) / pixelsPerCell;
  double get y => scene.worldHeightAt(x, z);
  void setInput({required int x, required int z, bool run = false}) {
    if (_run != run) {
      animationSeconds = 0;
    }
    _inputX = x.sign;
    _inputZ = z.sign;
    _run = run;
  }

  void releaseInput() {
    inputEpoch++;
    _inputX = _inputZ = 0;
    _run = false;
    moving = false;
    _remainderX = _remainderZ = 0;
    animationSeconds = 0;
  }

  void setPaused(bool value) {
    paused = value;
    releaseInput();
  }

  void setDiagonalMovement(bool value) {
    allowDiagonalMovement = value;
    releaseInput();
  }

  void reset() {
    _position = PixelPosition(
        leftPx: (scene.navigation.spawn.x * pixelsPerCell).round() - 16,
        topPx: (scene.navigation.spawn.z * pixelsPerCell).round() - 31);
    paused = false;
    facing = EntityFacing.south;
    releaseInput();
    if (_collides(_hitbox(_position))) {
      throw StateError('Le point de départ 3D est bloqué.');
    }
  }

  PixelRect _hitbox(PixelPosition position) =>
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
          spriteTopLeftPx: position, spriteWidthPx: 32, spriteHeightPx: 32);
  void update(double dt) {
    if (!dt.isFinite || dt <= 0 || paused) return;
    final elapsed = dt.clamp(0.0, .05);
    var dx = _inputX, dz = _inputZ;
    if (!allowDiagonalMovement && dx != 0 && dz != 0) dx = 0;
    if (dx == 0 && dz == 0) {
      moving = false;
      animationSeconds = 0;
      return;
    }
    final nextFacing = dz < 0
        ? EntityFacing.north
        : dz > 0
            ? EntityFacing.south
            : dx < 0
                ? EntityFacing.west
                : EntityFacing.east;
    if (nextFacing != facing) animationSeconds = 0;
    facing = nextFacing;
    final speed = (_run ? 6.0 : 3.0) *
        pixelsPerCell *
        elapsed /
        (dx != 0 && dz != 0 ? math.sqrt2 : 1);
    _remainderX += dx * speed;
    _remainderZ += dz * speed;
    final stepX = _remainderX.truncate(), stepZ = _remainderZ.truncate();
    _remainderX -= stepX;
    _remainderZ -= stepZ;
    final before = _position;
    final originX = x, originZ = z;
    _position = PixelMovementResolverV1.resolveSeparateAxis(
        spriteTopLeftPx: before,
        deltaXPx: stepX,
        deltaYPx: stepZ,
        spriteWidthPx: 32,
        spriteHeightPx: 32,
        worldStaticObstaclesCollidePixelRect: (rect) {
          if (_collides(rect)) return true;
          final px = rect.bottomCenterPx.xPx / pixelsPerCell,
              pz = rect.bottomCenterPx.yPx / pixelsPerCell;
          final previousX = px + (originX - px).sign / pixelsPerCell;
          final previousZ = pz + (originZ - pz).sign / pixelsPerCell;
          return !canTraverseSpatialTerrainStep(
              scene, previousX, previousZ, px, pz);
        });
    if (stepX != 0 || stepZ != 0) {
      moving =
          _position.leftPx != before.leftPx || _position.topPx != before.topPx;
    }
    if (moving) {
      animationSeconds += elapsed;
    } else if (stepX != 0 || stepZ != 0) {
      animationSeconds = 0;
    }
  }

  bool _collides(PixelRect rect) {
    final left = rect.leftPx / pixelsPerCell,
        top = rect.topPx / pixelsPerCell,
        right = (rect.leftPx + rect.widthPx) / pixelsPerCell,
        bottom = (rect.topPx + rect.heightPx) / pixelsPerCell;
    if (left < 0 || top < 0 || right > scene.width || bottom > scene.depth) {
      return true;
    }
    for (final area in scene.navigation.blockedAreas) {
      if (left < area.x + area.width &&
          right > area.x &&
          top < area.z + area.depth &&
          bottom > area.z) {
        return true;
      }
    }
    for (final entity in entities.where((entity) => entity.blocksMovement)) {
      final footprint = resolveEntityCollisionRectPx(entity,
          tileWidthPx: pixelsPerCell, tileHeightPx: pixelsPerCell);
      final npcLeft = footprint.leftPx / pixelsPerCell,
          npcTop = footprint.topPx / pixelsPerCell - .5,
          npcRight = (footprint.leftPx + footprint.widthPx) / pixelsPerCell,
          npcBottom =
              (footprint.topPx + footprint.heightPx) / pixelsPerCell - .5;
      if (left < npcRight &&
          right > npcLeft &&
          top < npcBottom &&
          bottom > npcTop) {
        return true;
      }
    }
    for (final instance in scene.instances.where((v) => v.blocksMovement)) {
      final model = models[instance.modelId];
      if (model == null) {
        throw StateError('Modèle de collision absent : ${instance.modelId}');
      }
      final scale = model.scale * instance.scale;
      final bounds = model.inspection.bounds;
      final actorHeight = scene.worldHeightAt(
          rect.bottomCenterPx.xPx / pixelsPerCell,
          rect.bottomCenterPx.yPx / pixelsPerCell);
      final minY = instance.position.y + (bounds.min.y - model.pivot.y) * scale;
      final maxY = instance.position.y + (bounds.max.y - model.pivot.y) * scale;
      if (actorHeight >= maxY || actorHeight + 1.92 <= minY) continue;
      final angle = instance.rotationDegrees * math.pi / 180,
          cos = math.cos(angle),
          sin = math.sin(angle);
      final polygon = <({double x, double z})>[];
      for (final corner in [
        (bounds.min.x, bounds.min.z),
        (bounds.max.x, bounds.min.z),
        (bounds.max.x, bounds.max.z),
        (bounds.min.x, bounds.max.z)
      ]) {
        final lx = (corner.$1 - model.pivot.x) * scale,
            lz = (corner.$2 - model.pivot.z) * scale;
        polygon.add((
          x: instance.position.x + cos * lx + sin * lz,
          z: instance.position.z - sin * lx + cos * lz
        ));
      }
      final player = [
        (x: left, z: top),
        (x: right, z: top),
        (x: right, z: bottom),
        (x: left, z: bottom)
      ];
      var separated = false;
      for (final axis in [
        (x: 1.0, z: 0.0),
        (x: 0.0, z: 1.0),
        (x: cos, z: -sin),
        (x: sin, z: cos)
      ]) {
        final a = polygon.map((p) => p.x * axis.x + p.z * axis.z),
            b = player.map((p) => p.x * axis.x + p.z * axis.z);
        if (a.reduce(math.max) <= b.reduce(math.min) ||
            b.reduce(math.max) <= a.reduce(math.min)) {
          separated = true;
          break;
        }
      }
      if (!separated) return true;
    }
    return false;
  }
}
