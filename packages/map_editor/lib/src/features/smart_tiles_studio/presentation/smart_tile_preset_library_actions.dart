import 'package:map_core/map_core.dart';

typedef SmartTilePresetCommand = Future<void> Function(
  ProjectSmartTilePreset preset,
);
typedef SmartTilePresetMapCommand = Future<bool> Function(
  ProjectSmartTilePreset preset,
);

/// Canonical commands exposed by the Studio for one library preset.
final class SmartTilePresetLibraryActions {
  const SmartTilePresetLibraryActions({
    this.publish,
    this.update,
    this.duplicate,
    this.delete,
    this.addToMap,
  });

  final SmartTilePresetCommand? publish;
  final SmartTilePresetCommand? update;
  final SmartTilePresetCommand? duplicate;
  final SmartTilePresetCommand? delete;
  final SmartTilePresetMapCommand? addToMap;
}
