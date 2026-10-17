import 'spatial_navigation.dart';

final class Model3dRampProfile {
  Model3dRampProfile({
    required this.x,
    required this.z,
    required this.width,
    required this.depth,
    required this.lowHeight,
    required this.highHeight,
    required this.direction,
  }) {
    if (![x, z, width, depth, lowHeight, highHeight].every((v) => v.isFinite) ||
        width <= 0 ||
        depth <= 0 ||
        highHeight <= lowHeight) {
      throw const FormatException('Invalid model ramp profile.');
    }
  }

  final double x, z, width, depth, lowHeight, highHeight;
  final SpatialRampDirection direction;

  factory Model3dRampProfile.fromJson(Map<String, dynamic> json) {
    const fields = {
      'x',
      'z',
      'width',
      'depth',
      'lowHeight',
      'highHeight',
      'direction',
    };
    if (json.length != fields.length ||
        json.keys.any((key) => !fields.contains(key))) {
      throw const FormatException('Invalid model ramp profile fields.');
    }
    if (!SpatialRampDirection.values.any(
      (value) => value.name == json['direction'],
    )) {
      throw const FormatException('Invalid model ramp direction.');
    }
    double number(String key) {
      final value = json[key];
      if (value is! num) {
        throw const FormatException('Invalid model ramp number.');
      }
      return value.toDouble();
    }

    return Model3dRampProfile(
      x: number('x'),
      z: number('z'),
      width: number('width'),
      depth: number('depth'),
      lowHeight: number('lowHeight'),
      highHeight: number('highHeight'),
      direction: SpatialRampDirection.values.byName(
        json['direction'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'z': z,
    'width': width,
    'depth': depth,
    'lowHeight': lowHeight,
    'highHeight': highHeight,
    'direction': direction.name,
  };

  @override
  bool operator ==(Object other) =>
      other is Model3dRampProfile &&
      x == other.x &&
      z == other.z &&
      width == other.width &&
      depth == other.depth &&
      lowHeight == other.lowHeight &&
      highHeight == other.highHeight &&
      direction == other.direction;

  @override
  int get hashCode =>
      Object.hash(x, z, width, depth, lowHeight, highHeight, direction);
}
