import 'package:map_core/map_core.dart';

import '../border/border_runtime_preparation.dart';

class RuntimeMapBundle {
  RuntimeMapBundle({
    required this.manifest,
    required this.map,
    required this.projectRootDirectory,
    required this.tilesetAbsolutePathsById,
    this.characterAnimationAbsolutePathsByAssetId = const <String, String>{},
    this.borderRuntimePreparation,
  });

  final ProjectManifest manifest;
  final MapData map;
  final String projectRootDirectory;
  final Map<String, String> tilesetAbsolutePathsById;
  final Map<String, String> characterAnimationAbsolutePathsByAssetId;
  final BorderRuntimePreparation? borderRuntimePreparation;

  Map<String, String> get runtimeImageAbsolutePathsById => <String, String>{
        ...tilesetAbsolutePathsById,
        for (final entry in characterAnimationAbsolutePathsByAssetId.entries)
          'character-animation:${entry.key}': entry.value,
      };

  RuntimeMapBundle copyWith({
    ProjectManifest? manifest,
    MapData? map,
    String? projectRootDirectory,
    Map<String, String>? tilesetAbsolutePathsById,
    Map<String, String>? characterAnimationAbsolutePathsByAssetId,
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
      characterAnimationAbsolutePathsByAssetId:
          characterAnimationAbsolutePathsByAssetId ??
              this.characterAnimationAbsolutePathsByAssetId,
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
