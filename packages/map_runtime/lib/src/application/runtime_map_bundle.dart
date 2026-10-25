import 'package:map_core/map_core.dart';

import '../border/border_runtime_preparation.dart';
import 'runtime_project_catalog.dart';

class RuntimeMapBundle {
  RuntimeMapBundle({
    required this.manifest,
    required MapData map,
    required this.projectRootDirectory,
    required this.tilesetAbsolutePathsById,
    this.characterAnimationAbsolutePathsByAssetId = const <String, String>{},
    this.borderRuntimePreparation,
    this.projectCatalog,
    SpatialAtmosphereSettings? spatialAtmosphereSettings,
    RuntimeResourceBudget? resourceBudget,
  }) : spatialAtmosphereSettings =
           spatialAtmosphereSettings ?? SpatialAtmosphereSettings(),
       resourceBudget = resourceBudget ?? RuntimeResourceBudget(),
       map = projectSpatialSmartTileModels(
         map: map,
         catalog: manifest.smartTileCatalog,
         sourceCellWidth: manifest.settings.tileWidth,
         sourceCellHeight: manifest.settings.tileHeight,
       );

  final SpatialAtmosphereSettings spatialAtmosphereSettings;
  final ProjectManifest manifest;
  final MapData map;
  final String projectRootDirectory;
  final Map<String, String> tilesetAbsolutePathsById;
  final Map<String, String> characterAnimationAbsolutePathsByAssetId;
  final BorderRuntimePreparation? borderRuntimePreparation;
  final RuntimeProjectCatalog? projectCatalog;
  final RuntimeResourceBudget resourceBudget;

  Map<String, String> get runtimeImageAbsolutePathsById => <String, String>{
    ...tilesetAbsolutePathsById,
    for (final entry in characterAnimationAbsolutePathsByAssetId.entries)
      'character-animation:${entry.key}': entry.value,
  };

  RuntimeMapBundle copyWith({
    ProjectManifest? manifest,
    SpatialAtmosphereSettings? spatialAtmosphereSettings,
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
    final preparationInputsChanged =
        !identical(nextManifest, this.manifest) ||
        !identical(nextMap, this.map) ||
        nextProjectRoot != this.projectRootDirectory;
    return RuntimeMapBundle(
      manifest: nextManifest,
      spatialAtmosphereSettings:
          spatialAtmosphereSettings ??
          (nextMap.id == this.map.id
              ? this.spatialAtmosphereSettings
              : SpatialAtmosphereSettings()),
      map: nextMap,
      projectRootDirectory: nextProjectRoot,
      tilesetAbsolutePathsById:
          tilesetAbsolutePathsById ?? this.tilesetAbsolutePathsById,
      characterAnimationAbsolutePathsByAssetId:
          characterAnimationAbsolutePathsByAssetId ??
          this.characterAnimationAbsolutePathsByAssetId,
      projectCatalog: projectCatalog,
      resourceBudget: resourceBudget,
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
