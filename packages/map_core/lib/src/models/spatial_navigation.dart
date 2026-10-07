import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

enum SpatialRampDirection { north, south, east, west }

final class SpatialSpawn {
  SpatialSpawn({required this.x, required this.z}) {
    if (!x.isFinite || !z.isFinite || x < 0 || z < 0) {
      throw const FormatException('Invalid spatial spawn.');
    }
  }
  final double x, z;
  factory SpatialSpawn.fromJson(Map<String, dynamic> json) => SpatialSpawn(
    x: (json['x'] as num).toDouble(),
    z: (json['z'] as num).toDouble(),
  );
  Map<String, dynamic> toJson() => {'x': x, 'z': z};
  @override
  bool operator ==(Object other) =>
      other is SpatialSpawn && x == other.x && z == other.z;
  @override
  int get hashCode => Object.hash(x, z);
}

class SpatialBlockedArea {
  SpatialBlockedArea({
    required this.x,
    required this.z,
    required this.width,
    required this.depth,
  }) {
    if (![x, z, width, depth].every((v) => v.isFinite) ||
        x < 0 ||
        z < 0 ||
        width <= 0 ||
        depth <= 0 ||
        x + width > 256 ||
        z + depth > 256) {
      throw const FormatException('Invalid spatial navigation rectangle.');
    }
  }
  final double x, z, width, depth;
  bool contains(double px, double pz) =>
      px >= x && px < x + width && pz >= z && pz < z + depth;
  bool overlaps(SpatialBlockedArea other) =>
      x < other.x + other.width &&
      x + width > other.x &&
      z < other.z + other.depth &&
      z + depth > other.z;
  factory SpatialBlockedArea.fromJson(Map<String, dynamic> json) =>
      SpatialBlockedArea(
        x: (json['x'] as num).toDouble(),
        z: (json['z'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        depth: (json['depth'] as num).toDouble(),
      );
  Map<String, dynamic> toJson() => {
    'x': x,
    'z': z,
    'width': width,
    'depth': depth,
  };
  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is SpatialBlockedArea &&
      x == other.x &&
      z == other.z &&
      width == other.width &&
      depth == other.depth;
  @override
  int get hashCode => Object.hash(runtimeType, x, z, width, depth);
}

final class SpatialRamp extends SpatialBlockedArea {
  SpatialRamp({
    required this.id,
    required super.x,
    required super.z,
    required super.width,
    required super.depth,
    required this.lowLevel,
    required this.highLevel,
    required this.direction,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        lowLevel < 0 ||
        highLevel > 32 ||
        highLevel <= lowLevel) {
      throw const FormatException('Invalid spatial ramp levels or identity.');
    }
  }
  final String id;
  final int lowLevel, highLevel;
  final SpatialRampDirection direction;
  double levelAt(double px, double pz) {
    final progress = switch (direction) {
      SpatialRampDirection.north => 1 - (pz - z) / depth,
      SpatialRampDirection.south => (pz - z) / depth,
      SpatialRampDirection.east => (px - x) / width,
      SpatialRampDirection.west => 1 - (px - x) / width,
    };
    return lowLevel + (highLevel - lowLevel) * progress.clamp(0.0, 1.0);
  }

  SpatialRamp copyWith({
    double? x,
    double? z,
    double? width,
    double? depth,
    int? lowLevel,
    int? highLevel,
    SpatialRampDirection? direction,
  }) => SpatialRamp(
    id: id,
    x: x ?? this.x,
    z: z ?? this.z,
    width: width ?? this.width,
    depth: depth ?? this.depth,
    lowLevel: lowLevel ?? this.lowLevel,
    highLevel: highLevel ?? this.highLevel,
    direction: direction ?? this.direction,
  );
  factory SpatialRamp.fromJson(Map<String, dynamic> json) => SpatialRamp(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    z: (json['z'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    depth: (json['depth'] as num).toDouble(),
    lowLevel: json['lowLevel'] as int,
    highLevel: json['highLevel'] as int,
    direction: SpatialRampDirection.values.byName(json['direction'] as String),
  );
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'id': id,
    'lowLevel': lowLevel,
    'highLevel': highLevel,
    'direction': direction.name,
  };
  @override
  bool operator ==(Object other) =>
      super == other &&
      other is SpatialRamp &&
      id == other.id &&
      lowLevel == other.lowLevel &&
      highLevel == other.highLevel &&
      direction == other.direction;
  @override
  int get hashCode =>
      Object.hash(super.hashCode, id, lowLevel, highLevel, direction);
}

final class SpatialNavigationProfile {
  SpatialNavigationProfile({
    SpatialSpawn? spawn,
    this.allowDiagonalMovement = false,
    Iterable<SpatialRamp> ramps = const [],
    Iterable<SpatialBlockedArea> blockedAreas = const [],
  }) : spawn = spawn ?? SpatialSpawn(x: .5, z: .5),
       ramps = List.unmodifiable(ramps),
       blockedAreas = List.unmodifiable(blockedAreas) {
    if (this.ramps.length > 256 ||
        this.blockedAreas.length > 4096 ||
        this.ramps.map((r) => r.id).toSet().length != this.ramps.length) {
      throw const FormatException(
        'Invalid navigation counts or ramp identities.',
      );
    }
    final regions = [...this.ramps, ...this.blockedAreas];
    for (var i = 0; i < regions.length; i++) {
      for (var j = i + 1; j < regions.length; j++) {
        if (regions[i].overlaps(regions[j])) {
          throw const FormatException(
            'Navigation rectangles must not overlap.',
          );
        }
      }
    }
  }
  final SpatialSpawn spawn;
  final bool allowDiagonalMovement;
  final List<SpatialRamp> ramps;
  final List<SpatialBlockedArea> blockedAreas;
  SpatialNavigationProfile copyWith({
    SpatialSpawn? spawn,
    bool? allowDiagonalMovement,
    Iterable<SpatialRamp>? ramps,
    Iterable<SpatialBlockedArea>? blockedAreas,
  }) => SpatialNavigationProfile(
    spawn: spawn ?? this.spawn,
    allowDiagonalMovement: allowDiagonalMovement ?? this.allowDiagonalMovement,
    ramps: ramps ?? this.ramps,
    blockedAreas: blockedAreas ?? this.blockedAreas,
  );
  factory SpatialNavigationProfile.fromJson(Map<String, dynamic> json) =>
      SpatialNavigationProfile(
        spawn: SpatialSpawn.fromJson(
          Map<String, dynamic>.from(json['spawn'] as Map),
        ),
        allowDiagonalMovement: json['allowDiagonalMovement'] as bool,
        ramps: (json['ramps'] as List).map(
          (v) => SpatialRamp.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
        blockedAreas: (json['blockedAreas'] as List).map(
          (v) =>
              SpatialBlockedArea.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
  Map<String, dynamic> toJson() => {
    'spawn': spawn.toJson(),
    'allowDiagonalMovement': allowDiagonalMovement,
    'ramps': ramps.map((v) => v.toJson()).toList(),
    'blockedAreas': blockedAreas.map((v) => v.toJson()).toList(),
  };
  @override
  bool operator ==(Object other) =>
      other is SpatialNavigationProfile &&
      spawn == other.spawn &&
      allowDiagonalMovement == other.allowDiagonalMovement &&
      const DeepCollectionEquality().equals(ramps, other.ramps) &&
      const DeepCollectionEquality().equals(blockedAreas, other.blockedAreas);
  @override
  int get hashCode => Object.hash(
    spawn,
    allowDiagonalMovement,
    const DeepCollectionEquality().hash(ramps),
    const DeepCollectionEquality().hash(blockedAreas),
  );
}
