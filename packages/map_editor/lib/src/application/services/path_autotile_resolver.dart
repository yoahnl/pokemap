import 'package:map_core/map_core.dart';

import '../../features/editor/terrain/path_autotile_set.dart';

class PathAutotileResolver {
  const PathAutotileResolver();

  PathAutotileSet? resolve({
    required ProjectPathPreset? selectedPreset,
    required bool Function(String tilesetId) hasTileset,
  }) {
    if (selectedPreset == null) return null;
    final tilesetId = selectedPreset.tilesetId.trim();
    if (tilesetId.isEmpty) return null;
    if (!hasTileset(tilesetId)) return null;
    final defaults = PathAutotileSet.defaultForTileset(tilesetId);
    if (selectedPreset.variants.isEmpty) {
      return defaults;
    }
    final mapped = PathAutotileSet.fromPreset(selectedPreset);
    return PathAutotileSet(
      id: selectedPreset.id,
      tilesetId: tilesetId,
      variants: <TerrainPathVariant, TilesetSourceRect>{
        ...defaults.variants,
        ...mapped.variants,
      },
    );
  }
}
