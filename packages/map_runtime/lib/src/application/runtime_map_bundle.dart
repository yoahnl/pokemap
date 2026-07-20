import 'package:map_core/map_core.dart';

import '../border/border_runtime_preparation.dart';

class RuntimeMapBundle {
  RuntimeMapBundle({
    required this.manifest,
    required this.map,
    required this.projectRootDirectory,
    required this.tilesetAbsolutePathsById,
    this.borderRuntimePreparation,
  });

  final ProjectManifest manifest;
  final MapData map;
  final String projectRootDirectory;
  final Map<String, String> tilesetAbsolutePathsById;
  final BorderRuntimePreparation? borderRuntimePreparation;

  RuntimeMapBundle copyWith({
    ProjectManifest? manifest,
    MapData? map,
    String? projectRootDirectory,
    Map<String, String>? tilesetAbsolutePathsById,
    BorderRuntimePreparation? borderRuntimePreparation,
    bool clearBorderRuntimePreparation = false,
  }) {
    final nextManifest = manifest ?? this.manifest;
    final nextMap = map ?? this.map;
    final nextProjectRoot = projectRootDirectory ?? this.projectRootDirectory;
    final preparationInputsChanged = !identical(nextManifest, this.manifest) ||
        !identical(nextMap, this.map) ||
        nextProjectRoot != this.projectRootDirectory;
    return RuntimeMapBundle(
      manifest: nextManifest,
      map: nextMap,
      projectRootDirectory: nextProjectRoot,
      tilesetAbsolutePathsById:
          tilesetAbsolutePathsById ?? this.tilesetAbsolutePathsById,
      borderRuntimePreparation:
          clearBorderRuntimePreparation || preparationInputsChanged
              ? null
              : borderRuntimePreparation ?? this.borderRuntimePreparation,
    );
  }

  double get cellWidth =>
      manifest.settings.tileWidth * manifest.settings.displayScale;

  double get cellHeight =>
      manifest.settings.tileHeight * manifest.settings.displayScale;
}
