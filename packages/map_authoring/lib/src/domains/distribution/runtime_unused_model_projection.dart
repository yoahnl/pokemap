import 'package:map_core/map_core.dart';

import '../assets/asset_store.dart';
import 'runtime_catalog_references.dart';

final class RuntimeModelResourceProjection {
  RuntimeModelResourceProjection({
    required this.project,
    required this.assets,
    Set<String> excludedLogicalPaths = const {},
  }) : excludedLogicalPaths = Set.unmodifiable(excludedLogicalPaths);

  final ProjectManifest project;
  final AssetCatalog assets;
  final Set<String> excludedLogicalPaths;
}

RuntimeModelResourceProjection projectRuntimeModelResources({
  required ProjectManifest project,
  required List<MapData> maps,
  required AssetCatalog assets,
  Iterable<Object?> additionalDocuments = const [],
}) {
  if (project.settings.dimension != ProjectDimension.threeD ||
      project.models3d.isEmpty) {
    return RuntimeModelResourceProjection(project: project, assets: assets);
  }
  final mapIds = maps.map((map) => map.id).toSet();
  if (mapIds.length != maps.length ||
      mapIds.length != project.maps.length ||
      project.maps.any((entry) => !mapIds.contains(entry.id))) {
    throw ArgumentError('Runtime model projection requires every project map');
  }
  final mapDocuments = maps.map((map) => map.toJson()).toList();
  final documents = [...mapDocuments, ...additionalDocuments];
  final externalProject = project.toJson()
    ..remove('models3d')
    ..remove('resourceLibraryCatalog')
    ..remove('resourcePackInstallations')
    ..remove('smartTileCatalog');
  final catalog = project.smartTileCatalog;
  final catalogMetadata = catalog.toJson()
    ..remove('presets')
    ..remove('patterns');
  final definitions = <String, List<Object?>>{};
  for (final preset in catalog.presets) {
    definitions.putIfAbsent(preset.id, () => []).add(preset.toJson());
  }
  for (final pattern in catalog.patterns) {
    definitions.putIfAbsent(pattern.id, () => []).add(pattern.toJson());
  }
  final definitionIds = definitions.keys.toSet();
  final retainedDefinitions = referencedRuntimeStrings(
      [externalProject, catalogMetadata, ...documents], definitionIds);
  final pending = retainedDefinitions.toList();
  for (var index = 0; index < pending.length; index++) {
    final references =
        referencedRuntimeStrings(definitions[pending[index]], definitionIds);
    for (final reference in references) {
      if (retainedDefinitions.add(reference)) pending.add(reference);
    }
  }
  final smartCatalog = ProjectSmartTileCatalog(
    categories: catalog.categories,
    atlases: catalog.atlases,
    materials: catalog.materials,
    animations: catalog.animations,
    presets: catalog.presets
        .where((preset) => retainedDefinitions.contains(preset.id))
        .toList(),
    patterns: catalog.patterns
        .where((pattern) => retainedDefinitions.contains(pattern.id))
        .toList(),
    drafts: catalog.drafts,
  );
  final modelIds = project.models3d.map((model) => model.id).toSet();
  final retainedModels = referencedRuntimeStrings(
      [externalProject, smartCatalog.toJson(), ...documents], modelIds);
  final projected = project.copyWith(
      models3d: project.models3d
          .where((model) => retainedModels.contains(model.id))
          .map((model) => model.rampProfile == null
              ? model
              : model.copyWith(clearRampProfile: true))
          .toList(),
      smartTileCatalog: smartCatalog,
      resourceLibraryCatalog: ResourceLibraryCatalog(
          families: project.resourceLibraryCatalog.families,
          entries: project.resourceLibraryCatalog.entries
              .where((entry) => switch (entry.resourceKind) {
                    'model3d' => retainedModels.contains(entry.resourceId),
                    'smartTilePreset' =>
                      retainedDefinitions.contains(entry.resourceId),
                    _ => true,
                  })));
  final removedAssetIds = project.models3d
      .where((model) => !retainedModels.contains(model.id))
      .map((model) => model.sourceAssetId)
      .toSet();
  final candidateRecords = assets.records
      .where((record) => removedAssetIds.contains(record.id))
      .toList();
  if (candidateRecords.isEmpty) {
    return RuntimeModelResourceProjection(project: projected, assets: assets);
  }
  final protectedAssetReferences = referencedRuntimeStrings([
    projected.toJson()..remove('resourcePackInstallations'),
    ...documents
  ], {
    for (final record in candidateRecords) ...modelAssetReferences(record),
  });
  final excludedIds = {
    for (final record in candidateRecords)
      if (!modelAssetReferences(record).any(protectedAssetReferences.contains))
        record.id,
  };
  return RuntimeModelResourceProjection(
      project: projected,
      assets: AssetCatalog(records: [
        for (final record in assets.records)
          if (!excludedIds.contains(record.id)) record
      ]),
      excludedLogicalPaths: {
        for (final record in candidateRecords)
          if (excludedIds.contains(record.id)) record.logicalPath
      });
}
