import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

const maximumSpatialTerrainLevel = 64;
const _unsetRampSurface = Object();

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
  static const fractionalLevelsCapabilityId = 'map3d.fractional-ramps@1';

  SpatialRamp({
    required this.id,
    required super.x,
    required super.z,
    required super.width,
    required super.depth,
    required num lowLevel,
    required num highLevel,
    required this.direction,
    this.surfaceInstanceId,
  }) : lowLevel = lowLevel.toDouble(),
       highLevel = highLevel.toDouble() {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        !lowLevel.isFinite ||
        !highLevel.isFinite ||
        lowLevel < 0 ||
        highLevel > maximumSpatialTerrainLevel ||
        highLevel <= lowLevel) {
      throw const FormatException('Invalid spatial ramp levels or identity.');
    }
    if (surfaceInstanceId != null &&
        !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(surfaceInstanceId!)) {
      throw const FormatException('Invalid spatial ramp surface identity.');
    }
  }
  final String id;
  final double lowLevel, highLevel;
  final SpatialRampDirection direction;
  final String? surfaceInstanceId;
  bool get hasFractionalLevels =>
      lowLevel != lowLevel.truncateToDouble() ||
      highLevel != highLevel.truncateToDouble();
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
    num? lowLevel,
    num? highLevel,
    SpatialRampDirection? direction,
    Object? surfaceInstanceId = _unsetRampSurface,
  }) => SpatialRamp(
    id: id,
    x: x ?? this.x,
    z: z ?? this.z,
    width: width ?? this.width,
    depth: depth ?? this.depth,
    lowLevel: lowLevel ?? this.lowLevel,
    highLevel: highLevel ?? this.highLevel,
    direction: direction ?? this.direction,
    surfaceInstanceId: identical(surfaceInstanceId, _unsetRampSurface)
        ? this.surfaceInstanceId
        : surfaceInstanceId as String?,
  );
  factory SpatialRamp.fromJson(Map<String, dynamic> json) => SpatialRamp(
    id: json['id'] as String,
    x: (json['x'] as num).toDouble(),
    z: (json['z'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    depth: (json['depth'] as num).toDouble(),
    lowLevel: json['lowLevel'] as num,
    highLevel: json['highLevel'] as num,
    direction: SpatialRampDirection.values.byName(json['direction'] as String),
    surfaceInstanceId: json['surfaceInstanceId'] as String?,
  );
  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'id': id,
    'lowLevel': lowLevel == lowLevel.truncateToDouble()
        ? lowLevel.toInt()
        : lowLevel,
    'highLevel': highLevel == highLevel.truncateToDouble()
        ? highLevel.toInt()
        : highLevel,
    'direction': direction.name,
    if (surfaceInstanceId != null) 'surfaceInstanceId': surfaceInstanceId,
  };
  @override
  bool operator ==(Object other) =>
      super == other &&
      other is SpatialRamp &&
      id == other.id &&
      lowLevel == other.lowLevel &&
      highLevel == other.highLevel &&
      direction == other.direction &&
      surfaceInstanceId == other.surfaceInstanceId;
  @override
  int get hashCode => Object.hash(
    super.hashCode,
    id,
    lowLevel,
    highLevel,
    direction,
    surfaceInstanceId,
  );
}

final class SpatialLedge {
  static const capabilityId = 'map3d.directional-ledges@1';

  SpatialLedge({
    required this.id,
    required this.x,
    required this.z,
    required this.direction,
    this.distance = 2,
    this.durationMs = 400,
    this.height = .65,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        x < 0 ||
        z < 0 ||
        x > 255 ||
        z > 255 ||
        distance < 2 ||
        distance > 4 ||
        durationMs < 100 ||
        durationMs > 2000 ||
        !height.isFinite ||
        height <= 0 ||
        height > 4) {
      throw const FormatException('Invalid directional ledge.');
    }
  }

  final String id;
  final int x, z, distance, durationMs;
  final double height;
  final SpatialRampDirection direction;
  int get dx => switch (direction) {
    SpatialRampDirection.east => 1,
    SpatialRampDirection.west => -1,
    _ => 0,
  };
  int get dz => switch (direction) {
    SpatialRampDirection.south => 1,
    SpatialRampDirection.north => -1,
    _ => 0,
  };
  int get landingX => x + dx * distance;
  int get landingZ => z + dz * distance;
  bool containsBarrier(double px, double pz) {
    for (var step = 1; step < distance; step++) {
      final bx = x + dx * step, bz = z + dz * step;
      if (px >= bx && px < bx + 1 && pz >= bz && pz < bz + 1) return true;
    }
    return false;
  }

  factory SpatialLedge.fromJson(Map<String, dynamic> json) => SpatialLedge(
    id: json['id'] as String,
    x: json['x'] as int,
    z: json['z'] as int,
    direction: SpatialRampDirection.values.byName(json['direction'] as String),
    distance: json['distance'] as int? ?? 2,
    durationMs: json['durationMs'] as int? ?? 400,
    height: (json['height'] as num?)?.toDouble() ?? .65,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'z': z,
    'direction': direction.name,
    'distance': distance,
    'durationMs': durationMs,
    'height': height,
  };
  @override
  bool operator ==(Object other) =>
      other is SpatialLedge &&
      id == other.id &&
      x == other.x &&
      z == other.z &&
      direction == other.direction &&
      distance == other.distance &&
      durationMs == other.durationMs &&
      height == other.height;
  @override
  int get hashCode =>
      Object.hash(id, x, z, direction, distance, durationMs, height);
}

final class SpatialNavigationProfile {
  SpatialNavigationProfile({
    SpatialSpawn? spawn,
    this.allowDiagonalMovement = false,
    this.maximumFishingDropWorld = defaultMaximumFishingDropWorld,
    Iterable<SpatialRamp> ramps = const [],
    Iterable<SpatialLedge> ledges = const [],
    Iterable<SpatialBlockedArea> blockedAreas = const [],
  }) : spawn = spawn ?? SpatialSpawn(x: .5, z: .5),
       ramps = List.unmodifiable(ramps),
       ledges = List.unmodifiable(ledges),
       blockedAreas = List.unmodifiable(blockedAreas) {
    if (!maximumFishingDropWorld.isFinite ||
        maximumFishingDropWorld < 0 ||
        maximumFishingDropWorld > 4) {
      throw const FormatException(
        'Fishing drop must be finite and between 0 and 4.',
      );
    }
    if (this.ledges.length > 4096 ||
        this.ledges.map((ledge) => ledge.id).toSet().length !=
            this.ledges.length ||
        this.ledges
                .map((ledge) => (ledge.x, ledge.z, ledge.direction))
                .toSet()
                .length !=
            this.ledges.length ||
        this.ramps.length > 256 ||
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
  static const defaultMaximumFishingDropWorld = .25;
  static const fishingDropCapabilityId = 'map3d.fishing-drop@1';
  final double maximumFishingDropWorld;
  final SpatialSpawn spawn;
  final bool allowDiagonalMovement;
  final List<SpatialRamp> ramps;
  final List<SpatialLedge> ledges;
  final List<SpatialBlockedArea> blockedAreas;
  SpatialNavigationProfile copyWith({
    SpatialSpawn? spawn,
    bool? allowDiagonalMovement,
    double? maximumFishingDropWorld,
    Iterable<SpatialRamp>? ramps,
    Iterable<SpatialLedge>? ledges,
    Iterable<SpatialBlockedArea>? blockedAreas,
  }) => SpatialNavigationProfile(
    spawn: spawn ?? this.spawn,
    maximumFishingDropWorld:
        maximumFishingDropWorld ?? this.maximumFishingDropWorld,
    allowDiagonalMovement: allowDiagonalMovement ?? this.allowDiagonalMovement,
    ramps: ramps ?? this.ramps,
    ledges: ledges ?? this.ledges,
    blockedAreas: blockedAreas ?? this.blockedAreas,
  );
  factory SpatialNavigationProfile.fromJson(Map<String, dynamic> json) =>
      SpatialNavigationProfile(
        spawn: SpatialSpawn.fromJson(
          Map<String, dynamic>.from(json['spawn'] as Map),
        ),
        allowDiagonalMovement: json['allowDiagonalMovement'] as bool,
        maximumFishingDropWorld:
            (json['maximumFishingDropWorld'] as num?)?.toDouble() ??
            defaultMaximumFishingDropWorld,
        ramps: (json['ramps'] as List).map(
          (v) => SpatialRamp.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
        ledges: (json['ledges'] as List? ?? const []).map(
          (value) =>
              SpatialLedge.fromJson(Map<String, dynamic>.from(value as Map)),
        ),
        blockedAreas: (json['blockedAreas'] as List).map(
          (v) =>
              SpatialBlockedArea.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      );
  Map<String, dynamic> toJson() => {
    'spawn': spawn.toJson(),
    if (maximumFishingDropWorld != defaultMaximumFishingDropWorld)
      'maximumFishingDropWorld': maximumFishingDropWorld,
    'allowDiagonalMovement': allowDiagonalMovement,
    'ramps': ramps.map((v) => v.toJson()).toList(),
    if (ledges.isNotEmpty) 'ledges': ledges.map((v) => v.toJson()).toList(),
    'blockedAreas': blockedAreas.map((v) => v.toJson()).toList(),
  };
  @override
  bool operator ==(Object other) =>
      other is SpatialNavigationProfile &&
      spawn == other.spawn &&
      maximumFishingDropWorld == other.maximumFishingDropWorld &&
      allowDiagonalMovement == other.allowDiagonalMovement &&
      const DeepCollectionEquality().equals(ramps, other.ramps) &&
      const DeepCollectionEquality().equals(ledges, other.ledges) &&
      const DeepCollectionEquality().equals(blockedAreas, other.blockedAreas);
  @override
  int get hashCode => Object.hash(
    spawn,
    maximumFishingDropWorld,
    allowDiagonalMovement,
    const DeepCollectionEquality().hash(ramps),
    const DeepCollectionEquality().hash(ledges),
    const DeepCollectionEquality().hash(blockedAreas),
  );
}
