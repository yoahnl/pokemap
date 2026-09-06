enum RuntimePlayerMapPointStatus { current, discovered, unknown }

final class RuntimePlayerRegionMapSnapshot {
  RuntimePlayerRegionMapSnapshot({
    required List<RuntimePlayerRegionSnapshot> regions,
  }) : regions = List.unmodifiable(regions);

  final List<RuntimePlayerRegionSnapshot> regions;
}

final class RuntimePlayerRegionSnapshot {
  RuntimePlayerRegionSnapshot({
    required this.id,
    required this.label,
    required List<RuntimePlayerMapPointSnapshot> points,
    this.imageFilePath,
    this.pixelArt = false,
  }) : points = List.unmodifiable(points);

  final String id;
  final String label;
  final String? imageFilePath;
  final bool pixelArt;
  final List<RuntimePlayerMapPointSnapshot> points;
}

final class RuntimePlayerMapPointSnapshot {
  const RuntimePlayerMapPointSnapshot({
    required this.id,
    required this.label,
    required this.status,
    this.u,
    this.v,
    this.description,
    this.thumbnailFilePath,
  });

  final String id;
  final String label;
  final RuntimePlayerMapPointStatus status;
  final double? u;
  final double? v;
  final String? description;
  final String? thumbnailFilePath;

  bool get isLocated =>
      u != null &&
      v != null &&
      u!.isFinite &&
      v!.isFinite &&
      u! >= 0 &&
      u! <= 1 &&
      v! >= 0 &&
      v! <= 1;
}
