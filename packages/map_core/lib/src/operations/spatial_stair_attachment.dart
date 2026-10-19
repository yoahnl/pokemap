import 'dart:math' as math;

import '../models/map_spatial_scene.dart';
import '../models/project_model3d.dart';
import '../models/spatial_navigation.dart';

final class SpatialStairAttachment {
  const SpatialStairAttachment();

  SpatialRamp fromModel(
    ProjectModel3dEntry model,
    SpatialModelInstance instance,
    double levelHeight, {
    required String rampId,
  }) {
    final profile = model.rampProfile!;
    final turns = _turns(instance.rotationDegrees);
    final scale = model.scale * instance.scale;
    final rectangle = _rectangle(
      profile.x,
      profile.z,
      profile.width,
      profile.depth,
      (x, z) => _rotate(
        (x - model.pivot.x) * scale,
        (z - model.pivot.z) * scale,
        turns,
        instance.position,
      ),
    );
    return SpatialRamp(
      id: rampId,
      x: rectangle.x,
      z: rectangle.z,
      width: rectangle.width,
      depth: rectangle.depth,
      lowLevel: _level(
        instance.position.y + (profile.lowHeight - model.pivot.y) * scale,
        levelHeight,
      ),
      highLevel: _level(
        instance.position.y + (profile.highHeight - model.pivot.y) * scale,
        levelHeight,
      ),
      direction: _direction(profile.direction, turns),
      surfaceInstanceId: instance.id,
    );
  }

  SpatialRamp transform(
    SpatialRamp ramp,
    SpatialModelInstance before,
    SpatialModelInstance after,
    double levelHeight, {
    double? sourceLevelHeight,
  }) {
    final turns = _turns(after.rotationDegrees - before.rotationDegrees);
    final scale = after.scale / before.scale;
    final rectangle = _rectangle(
      ramp.x,
      ramp.z,
      ramp.width,
      ramp.depth,
      (x, z) => _rotate(
        (x - before.position.x) * scale,
        (z - before.position.z) * scale,
        turns,
        after.position,
      ),
    );
    return ramp.copyWith(
      x: rectangle.x,
      z: rectangle.z,
      width: rectangle.width,
      depth: rectangle.depth,
      lowLevel: _level(
        after.position.y +
            (ramp.lowLevel * (sourceLevelHeight ?? levelHeight) -
                    before.position.y) *
                scale,
        levelHeight,
      ),
      highLevel: _level(
        after.position.y +
            (ramp.highLevel * (sourceLevelHeight ?? levelHeight) -
                    before.position.y) *
                scale,
        levelHeight,
      ),
      direction: _direction(ramp.direction, turns),
    );
  }

  int _turns(double degrees) {
    final turns = degrees / 90;
    if ((turns - turns.round()).abs() > .000001) {
      throw const FormatException(
        'Attached stairs require quarter-turn rotations.',
      );
    }
    return turns.round() % 4;
  }

  double _level(double height, double levelHeight) => height / levelHeight;

  SpatialRampDirection _direction(SpatialRampDirection direction, int turns) {
    const order = [
      SpatialRampDirection.north,
      SpatialRampDirection.west,
      SpatialRampDirection.south,
      SpatialRampDirection.east,
    ];
    return order[(order.indexOf(direction) + turns) % 4];
  }

  ({double x, double z}) _rotate(
    double x,
    double z,
    int turns,
    Model3dVector3 origin,
  ) {
    final point = switch (turns) {
      0 => (x: x, z: z),
      1 => (x: z, z: -x),
      2 => (x: -x, z: -z),
      _ => (x: -z, z: x),
    };
    return (x: origin.x + point.x, z: origin.z + point.z);
  }

  ({double x, double z, double width, double depth}) _rectangle(
    double x,
    double z,
    double width,
    double depth,
    ({double x, double z}) Function(double, double) transform,
  ) {
    final points = [
      transform(x, z),
      transform(x + width, z),
      transform(x, z + depth),
      transform(x + width, z + depth),
    ];
    final minX = points.map((p) => p.x).reduce(math.min);
    final minZ = points.map((p) => p.z).reduce(math.min);
    return (
      x: minX,
      z: minZ,
      width: points.map((p) => p.x).reduce(math.max) - minX,
      depth: points.map((p) => p.z).reduce(math.max) - minZ,
    );
  }
}
