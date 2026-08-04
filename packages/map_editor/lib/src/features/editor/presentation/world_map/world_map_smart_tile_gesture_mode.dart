import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WorldMapSmartTileGestureMode {
  brush,
  line,
  rectangle,
  floodFill,
}

final worldMapSmartTileGestureModeProvider = NotifierProvider<
    WorldMapSmartTileGestureModeController, WorldMapSmartTileGestureMode>(
  WorldMapSmartTileGestureModeController.new,
);

final class WorldMapSmartTileGestureModeController
    extends Notifier<WorldMapSmartTileGestureMode> {
  @override
  WorldMapSmartTileGestureMode build() => WorldMapSmartTileGestureMode.brush;

  void select(WorldMapSmartTileGestureMode mode) {
    if (state == mode) return;
    state = mode;
  }
}

/// Session-only material selected for Smart Tile painting on the World Map.
///
/// The value is intentionally not persisted in the project: switching maps or
/// presets resolves it against the active preset and falls back to that
/// preset's default material when it is no longer compatible.
final worldMapSmartTileMaterialIdProvider =
    NotifierProvider<WorldMapSmartTileMaterialIdController, String?>(
  WorldMapSmartTileMaterialIdController.new,
);

final class WorldMapSmartTileMaterialIdController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String materialId) {
    if (state == materialId) return;
    state = materialId;
  }
}
