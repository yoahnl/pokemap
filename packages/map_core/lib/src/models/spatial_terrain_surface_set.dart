part of 'spatial_terrain_surface.dart';

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
