import 'package:map_core/map_core.dart';

class RuntimeMapBundle {
  RuntimeMapBundle({
    required this.manifest,
    required this.map,
    required this.projectRootDirectory,
    required this.tilesetAbsolutePathsById,
  });

  final ProjectManifest manifest;
  final MapData map;
  final String projectRootDirectory;
  final Map<String, String> tilesetAbsolutePathsById;

  double get cellWidth =>
      manifest.settings.tileWidth * manifest.settings.displayScale;

  double get cellHeight =>
      manifest.settings.tileHeight * manifest.settings.displayScale;
}
