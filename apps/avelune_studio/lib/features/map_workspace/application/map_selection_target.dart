enum MapSelectionFamily { decor, character, marker, warp, zone, trigger }

class MapSelectionTarget {
  const MapSelectionTarget({
    required this.mapId,
    required this.family,
    required this.id,
  });
  final String mapId;
  final MapSelectionFamily family;
  final String id;
}
