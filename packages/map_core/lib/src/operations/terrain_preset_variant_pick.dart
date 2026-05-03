import '../models/project_manifest.dart';

/// Picks which [TerrainPresetVariant] applies at [mapX], [mapY].
///
/// Expands each variant by its [TerrainPresetVariant.weight] (minimum 1),
/// then selects with index `(mapX + mapY + phase) mod expandedLength`.
/// This is **deterministic** and varies smoothly along diagonals (x+y),
/// unlike XOR-based hashing which looked pseudo-random per cell.
TerrainPresetVariant pickTerrainPresetVariantForMapCell({
  required List<TerrainPresetVariant> variants,
  required int mapX,
  required int mapY,
  int phase = 0,
}) {
  if (variants.isEmpty) {
    throw ArgumentError.value(variants, 'variants', 'must be non-empty');
  }
  if (variants.length == 1) {
    return variants.first;
  }
  final expanded = <TerrainPresetVariant>[];
  for (final v in variants) {
    final w = v.weight <= 0 ? 1 : v.weight;
    for (var i = 0; i < w; i++) {
      expanded.add(v);
    }
  }
  if (expanded.isEmpty) {
    return variants.first;
  }
  final idx = _positiveModulo(mapX + mapY + phase, expanded.length);
  return expanded[idx];
}

int _positiveModulo(int n, int m) {
  assert(m > 0);
  var r = n % m;
  if (r < 0) {
    r += m;
  }
  return r;
}
