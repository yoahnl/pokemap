import 'border_ground_footprint.dart';

const maximumSpatialTerrainSurfaces = 128;
const maximumSpatialTerrainSurfaceFootprints = 32;

final class SpatialTerrainSurface {
  SpatialTerrainSurface({
    required this.id,
    required this.x,
    required this.z,
    required this.height,
    this.gradientX = 0,
    this.gradientZ = 0,
    required Iterable<BorderGroundFootprint> footprints,
  }) : footprints = List.unmodifiable(footprints) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(id) ||
        ![x, z, height, gradientX, gradientZ].every((v) => v.isFinite) ||
        this.footprints.isEmpty ||
        this.footprints.length > maximumSpatialTerrainSurfaceFootprints) {
      throw const FormatException('Invalid continuous terrain surface.');
    }
    for (final footprint in this.footprints) {
      for (final point in footprint.points) {
        final h = height + gradientX * point.x + gradientZ * point.z;
        if (!(x + point.x).isFinite ||
            !(z + point.z).isFinite ||
            !h.isFinite ||
            h < 0 ||
            h > 1024) {
          throw const FormatException(
            'Continuous terrain heights must remain within 0 to 1024 world units.',
          );
        }
      }
    }
  }

  final String id;
  final double x, z, height, gradientX, gradientZ;
  final List<BorderGroundFootprint> footprints;
  late final bounds = _surfaceBounds(this);

  double heightAt(double worldX, double worldZ) =>
      height + gradientX * (worldX - x) + gradientZ * (worldZ - z);

  bool contains(double worldX, double worldZ) =>
      worldX.isFinite &&
      worldZ.isFinite &&
      footprints.any((footprint) => footprint.contains(worldX - x, worldZ - z));

  bool fits(int width, int depth) => footprints.every(
    (footprint) => footprint.points.every(
      (point) =>
          x + point.x >= 0 &&
          x + point.x <= width &&
          z + point.z >= 0 &&
          z + point.z <= depth,
    ),
  );

  bool overlapsCell(int cellX, int cellZ) => footprints.any((footprint) {
    final left = cellX - x, top = cellZ - z;
    final right = left + 1, bottom = top + 1;
    final points = footprint.points;
    final axes = <(double, double)>[
      (1, 0),
      (0, 1),
      for (var i = 0; i < points.length; i++)
        (
          points[i].z - points[(i + 1) % points.length].z,
          points[(i + 1) % points.length].x - points[i].x,
        ),
    ];
    for (final (dx, dz) in axes) {
      var minimum = double.infinity, maximum = double.negativeInfinity;
      for (final point in points) {
        final projected = point.x * dx + point.z * dz;
        if (projected < minimum) minimum = projected;
        if (projected > maximum) maximum = projected;
      }
      final cellMinimum =
          (dx >= 0 ? left : right) * dx + (dz >= 0 ? top : bottom) * dz;
      final cellMaximum =
          (dx >= 0 ? right : left) * dx + (dz >= 0 ? bottom : top) * dz;
      if (maximum <= cellMinimum || minimum >= cellMaximum) return false;
    }
    return true;
  });

  SpatialTerrainSurface copyWith({
    double? x,
    double? z,
    double? height,
    double? gradientX,
    double? gradientZ,
    Iterable<BorderGroundFootprint>? footprints,
  }) => SpatialTerrainSurface(
    id: id,
    x: x ?? this.x,
    z: z ?? this.z,
    height: height ?? this.height,
    gradientX: gradientX ?? this.gradientX,
    gradientZ: gradientZ ?? this.gradientZ,
    footprints: footprints ?? this.footprints,
  );

  factory SpatialTerrainSurface.fromJson(Map<String, dynamic> json) {
    _fields(json, const {
      'id',
      'x',
      'z',
      'height',
      'gradientX',
      'gradientZ',
      'footprints',
    });
    final id = json['id'];
    if (id is! String) {
      throw const FormatException(
        'Terrain surface identities must be strings.',
      );
    }
    final raw = json['footprints'];
    if (raw is! List ||
        raw.isEmpty ||
        raw.length > maximumSpatialTerrainSurfaceFootprints) {
      throw const FormatException(
        'Terrain surfaces require 1 to 32 convex footprints.',
      );
    }
    final footprints = <BorderGroundFootprint>[];
    for (final polygon in raw) {
      if (polygon is! List || polygon.length < 3 || polygon.length > 16) {
        throw const FormatException(
          'Terrain footprints require 3 to 16 convex vertices.',
        );
      }
      footprints.add(
        BorderGroundFootprint(
          points: [
            for (final rawPoint in polygon)
              (() {
                final point = _object(rawPoint);
                _fields(point, const {'x', 'z'});
                return BorderGroundPoint(
                  x: _number(point, 'x'),
                  z: _number(point, 'z'),
                );
              })(),
          ],
        ),
      );
    }
    return SpatialTerrainSurface(
      id: id,
      x: _number(json, 'x'),
      z: _number(json, 'z'),
      height: _number(json, 'height'),
      gradientX: _number(json, 'gradientX', fallback: 0),
      gradientZ: _number(json, 'gradientZ', fallback: 0),
      footprints: footprints,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'x': x,
    'z': z,
    'height': height,
    'gradientX': gradientX,
    'gradientZ': gradientZ,
    'footprints': [
      for (final footprint in footprints)
        [
          for (final point in footprint.points) {'x': point.x, 'z': point.z},
        ],
    ],
  };

  @override
  bool operator ==(Object other) =>
      other is SpatialTerrainSurface &&
      id == other.id &&
      x == other.x &&
      z == other.z &&
      height == other.height &&
      gradientX == other.gradientX &&
      gradientZ == other.gradientZ &&
      footprints.length == other.footprints.length &&
      Iterable<int>.generate(
        footprints.length,
      ).every((i) => footprints[i] == other.footprints[i]);

  @override
  int get hashCode => Object.hash(
    id,
    x,
    z,
    height,
    gradientX,
    gradientZ,
    Object.hashAll(footprints),
  );
}

final class SpatialTerrainSurfaceSet {
  static const capabilityId = 'map3d.terrain-surfaces@1';

  const SpatialTerrainSurfaceSet.empty()
    : surfaces = const [],
      _chunks = const {};

  factory SpatialTerrainSurfaceSet({
    required Iterable<SpatialTerrainSurface> surfaces,
  }) {
    final immutable = List<SpatialTerrainSurface>.unmodifiable(surfaces);
    if (immutable.length > maximumSpatialTerrainSurfaces ||
        immutable.map((s) => s.id).toSet().length != immutable.length) {
      throw const FormatException(
        'Invalid continuous terrain surface count or duplicate identities.',
      );
    }
    final chunks = <(int, int), List<SpatialTerrainSurface>>{};
    for (final surface in immutable) {
      final bounds = surface.bounds;
      final left = (bounds.left / 8).floor().clamp(0, 31);
      final top = (bounds.top / 8).floor().clamp(0, 31);
      final right = (bounds.right / 8).floor().clamp(0, 31);
      final bottom = (bounds.bottom / 8).floor().clamp(0, 31);
      for (var z = top; z <= bottom; z++) {
        for (var x = left; x <= right; x++) {
          chunks.putIfAbsent((x, z), () => []).add(surface);
        }
      }
    }
    return SpatialTerrainSurfaceSet._(
      immutable,
      Map.unmodifiable({
        for (final entry in chunks.entries)
          entry.key: List<SpatialTerrainSurface>.unmodifiable(entry.value),
      }),
    );
  }

  const SpatialTerrainSurfaceSet._(this.surfaces, this._chunks);

  final List<SpatialTerrainSurface> surfaces;
  final Map<(int, int), List<SpatialTerrainSurface>> _chunks;

  List<SpatialTerrainSurface> candidatesAtCell(int x, int z) =>
      _chunks[((x ~/ 8).clamp(0, 31), (z ~/ 8).clamp(0, 31))] ?? const [];

  double? heightAt(double x, double z) {
    if (surfaces.isEmpty) return null;
    double? highest;
    if (!x.isFinite || !z.isFinite || x < 0 || z < 0 || x > 256 || z > 256) {
      return null;
    }
    for (final surface in candidatesAtCell(x.floor(), z.floor())) {
      if (!surface.contains(x, z)) continue;
      final height = surface.heightAt(x, z);
      if (highest == null || height > highest) highest = height;
    }
    return highest;
  }

  factory SpatialTerrainSurfaceSet.fromJson(Map<String, dynamic> json) {
    _fields(json, const {'schemaVersion', 'surfaces'});
    if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
      throw const FormatException(
        'Unsupported continuous terrain surface version.',
      );
    }
    final raw = json['surfaces'];
    if (raw is! List || raw.length > maximumSpatialTerrainSurfaces) {
      throw const FormatException(
        'Continuous terrain supports at most 128 surfaces.',
      );
    }
    return SpatialTerrainSurfaceSet(
      surfaces: [
        for (final surface in raw)
          SpatialTerrainSurface.fromJson(_object(surface)),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'surfaces': [for (final surface in surfaces) surface.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is SpatialTerrainSurfaceSet &&
      surfaces.length == other.surfaces.length &&
      Iterable<int>.generate(
        surfaces.length,
      ).every((i) => surfaces[i] == other.surfaces[i]);

  @override
  int get hashCode => Object.hashAll(surfaces);
}

({double left, double top, double right, double bottom}) _surfaceBounds(
  SpatialTerrainSurface surface,
) {
  var left = double.infinity, top = double.infinity;
  var right = double.negativeInfinity, bottom = double.negativeInfinity;
  for (final footprint in surface.footprints) {
    for (final point in footprint.points) {
      final x = surface.x + point.x, z = surface.z + point.z;
      if (x < left) left = x;
      if (x > right) right = x;
      if (z < top) top = z;
      if (z > bottom) bottom = z;
    }
  }
  return (left: left, top: top, right: right, bottom: bottom);
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException(
      'Terrain surface data must contain JSON objects.',
    );
  }
  return Map<String, dynamic>.from(value);
}

void _fields(Map<String, dynamic> json, Set<String> fields) {
  if (json.keys.any((key) => !fields.contains(key))) {
    throw const FormatException('Unknown continuous terrain surface field.');
  }
}

double _number(Map<String, dynamic> json, String key, {double? fallback}) {
  if (!json.containsKey(key) && fallback != null) return fallback;
  final value = json[key];
  if (value is! num || !value.isFinite) {
    throw FormatException('Terrain surface $key must be a finite number.');
  }
  return value.toDouble();
}
