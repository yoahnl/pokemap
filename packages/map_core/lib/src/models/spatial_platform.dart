import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;

final class SpatialPlatformStop {
  SpatialPlatformStop({required num x, required num z})
    : x = x.toDouble(),
      z = z.toDouble() {
    if (!this.x.isFinite ||
        !this.z.isFinite ||
        this.x.abs() > 256 ||
        this.z.abs() > 256) {
      throw const FormatException('Invalid platform stop.');
    }
  }
  final double x, z;
  factory SpatialPlatformStop.fromJson(Map<String, dynamic> json) {
    _fields(json, {'x', 'z'});
    return SpatialPlatformStop(x: _number(json, 'x'), z: _number(json, 'z'));
  }
  Map<String, dynamic> toJson() => {'x': x, 'z': z};
  @override
  bool operator ==(Object other) =>
      other is SpatialPlatformStop && x == other.x && z == other.z;
  @override
  int get hashCode => Object.hash(x, z);
}

final class SpatialPlatformCondition {
  SpatialPlatformCondition({required this.factId, required this.value}) {
    if (factId.trim().isEmpty || factId != factId.trim()) {
      throw const FormatException('Invalid platform route Fact identity.');
    }
  }
  final String factId;
  final bool value;
  Map<String, dynamic> toJson() => {'factId': factId, 'value': value};
  factory SpatialPlatformCondition.fromJson(Map<String, dynamic> json) {
    _fields(json, {'factId', 'value'});
    if (json['value'] is! bool) {
      throw const FormatException('A route condition requires a boolean.');
    }
    return SpatialPlatformCondition(
      factId: _text(json, 'factId'),
      value: json['value'] as bool,
    );
  }
}

final class SpatialPlatformRoute {
  SpatialPlatformRoute({
    required this.id,
    required Iterable<SpatialPlatformStop> waypoints,
    Iterable<SpatialPlatformCondition> conditions = const [],
  }) : waypoints = List.unmodifiable(waypoints),
       conditions = List.unmodifiable(conditions) {
    _id(id);
    if (this.waypoints.length < 2 ||
        this.waypoints.length > 32 ||
        this.waypoints.first == this.waypoints.last ||
        this.conditions.length > 8 ||
        this.conditions.map((condition) => condition.factId).toSet().length !=
            this.conditions.length) {
      throw const FormatException(
        'A platform route requires distinct docks and bounded conditions.',
      );
    }
    for (var i = 1; i < this.waypoints.length; i++) {
      if (this.waypoints[i - 1] == this.waypoints[i]) {
        throw const FormatException(
          'Platform route segments must have length.',
        );
      }
    }
  }
  final String id;
  final List<SpatialPlatformCondition> conditions;
  final List<SpatialPlatformStop> waypoints;
  factory SpatialPlatformRoute.fromJson(Map<String, dynamic> json) {
    _fields(json, {'id', 'waypoints'}, {'conditions'});
    if (json['waypoints'] is! List ||
        json.containsKey('conditions') && json['conditions'] is! List) {
      throw const FormatException('Invalid platform route fields.');
    }
    return SpatialPlatformRoute(
      id: _text(json, 'id'),
      waypoints: [
        for (final stop in json['waypoints'] as List)
          SpatialPlatformStop.fromJson(Map<String, dynamic>.from(stop as Map)),
      ],
      conditions: [
        for (final condition in json['conditions'] as List? ?? const [])
          SpatialPlatformCondition.fromJson(
            Map<String, dynamic>.from(condition as Map),
          ),
      ],
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'waypoints': [for (final stop in waypoints) stop.toJson()],
    if (conditions.isNotEmpty)
      'conditions': [for (final condition in conditions) condition.toJson()],
  };
  @override
  bool operator ==(Object other) =>
      other is SpatialPlatformRoute &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());
  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

final class SpatialPlatformDefinition {
  static const capabilityId = 'map3d.platform@1';
  SpatialPlatformDefinition({
    required this.id,
    required this.name,
    required this.instanceId,
    required num x,
    required num z,
    required num width,
    required num depth,
    required num height,
    required this.durationMs,
    required Iterable<SpatialPlatformRoute> routes,
  }) : x = x.toDouble(),
       z = z.toDouble(),
       width = width.toDouble(),
       depth = depth.toDouble(),
       height = height.toDouble(),
       routes = List.unmodifiable(routes) {
    _id(id);
    _id(instanceId);
    if (name.trim().isEmpty ||
        name.length > 200 ||
        ![
          this.x,
          this.z,
          this.width,
          this.depth,
          this.height,
        ].every((v) => v.isFinite) ||
        this.x < 0 ||
        this.z < 0 ||
        this.width <= 0 ||
        this.depth <= 0 ||
        this.width > 32 ||
        this.depth > 32 ||
        this.height < 0 ||
        this.height > 1024 ||
        durationMs < 100 ||
        durationMs > 30000 ||
        this.routes.isEmpty ||
        this.routes.length > 16 ||
        this.routes.map((v) => v.id).toSet().length != this.routes.length ||
        this.routes.where((v) => v.conditions.isEmpty).length != 1 ||
        !this.routes.any(
          (route) => [
            route.waypoints.first,
            route.waypoints.last,
          ].any((point) => point.x == 0 && point.z == 0),
        )) {
      throw const FormatException('Invalid spatial platform.');
    }
  }
  final String id, name, instanceId;
  final double x, z, width, depth, height;
  final int durationMs;
  final List<SpatialPlatformRoute> routes;
  bool contains(
    double px,
    double pz, {
    double offsetX = 0,
    double offsetZ = 0,
    double margin = 0,
  }) =>
      px - margin >= x + offsetX &&
      pz - margin >= z + offsetZ &&
      px + margin < x + offsetX + width &&
      pz + margin < z + offsetZ + depth;
  bool fits(int mapWidth, int mapDepth) => routes.every(
    (route) => route.waypoints.every(
      (stop) =>
          x + stop.x >= 0 &&
          z + stop.z >= 0 &&
          x + stop.x + width <= mapWidth &&
          z + stop.z + depth <= mapDepth,
    ),
  );
  SpatialPlatformRoute selectRoute(bool Function(String factId) readFact) =>
      routes
          .where(
            (route) =>
                route.conditions.isNotEmpty &&
                route.conditions.every(
                  (condition) => readFact(condition.factId) == condition.value,
                ),
          )
          .firstOrNull ??
      routes.singleWhere((route) => route.conditions.isEmpty);
  factory SpatialPlatformDefinition.fromJson(Map<String, dynamic> json) {
    _fields(json, {
      'id',
      'name',
      'instanceId',
      'x',
      'z',
      'width',
      'depth',
      'height',
      'durationMs',
      'routes',
    });
    if (json['durationMs'] is! int || json['routes'] is! List) {
      throw const FormatException('Invalid platform duration or routes.');
    }
    return SpatialPlatformDefinition(
      id: _text(json, 'id'),
      name: _text(json, 'name'),
      instanceId: _text(json, 'instanceId'),
      x: _number(json, 'x'),
      z: _number(json, 'z'),
      width: _number(json, 'width'),
      depth: _number(json, 'depth'),
      height: _number(json, 'height'),
      durationMs: json['durationMs'] as int,
      routes: [
        for (final route in json['routes'] as List)
          SpatialPlatformRoute.fromJson(
            Map<String, dynamic>.from(route as Map),
          ),
      ],
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'instanceId': instanceId,
    'x': x,
    'z': z,
    'width': width,
    'depth': depth,
    'height': height,
    'durationMs': durationMs,
    'routes': [for (final route in routes) route.toJson()],
  };
  @override
  bool operator ==(Object other) =>
      other is SpatialPlatformDefinition &&
      const DeepCollectionEquality().equals(toJson(), other.toJson());
  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

void _fields(
  Map<String, dynamic> json,
  Set<String> required, [
  Set<String> optional = const {},
]) {
  if (!required.every(json.containsKey) ||
      json.keys.any(
        (key) => !required.contains(key) && !optional.contains(key),
      )) {
    throw const FormatException('Invalid spatial platform fields.');
  }
}

void _id(String id) {
  if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id)) {
    throw const FormatException('Invalid platform identity.');
  }
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Invalid platform text.');
  }
  return value;
}

num _number(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num) {
    throw const FormatException('Invalid platform number.');
  }
  return value;
}
