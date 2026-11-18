import 'package:map_core/map_core.dart';

import 'catalog_metadata_documents.dart';

abstract final class CatalogNarrativeOwnerDocuments {
  static Future<bool> containsDependencies(
    PortableProjectCatalog catalog, {
    required Set<String> storylineIds,
    required Set<String> factIds,
    required Set<String> sceneIds,
  }) async {
    final ids = {
      if (storylineIds.isNotEmpty) 'storylines': storylineIds,
      if (factIds.isNotEmpty) 'facts': factIds,
      if (sceneIds.isNotEmpty) 'scenes': sceneIds,
    };
    final selection = await CatalogMetadataDocuments.readDocuments(
      snapshot: catalog.snapshot,
      project: catalog.projectMetadata,
      ids: ids,
    );
    return ids.entries.every(
      (entry) => selection.documents[entry.key]!.keys.toSet().containsAll(entry.value),
    );
  }

  static Future<StorylineAsset?> readStoryline(
      PortableProjectCatalog catalog, String id) async {
    final selection = await CatalogMetadataDocuments.readDocuments(
      snapshot: catalog.snapshot,
      project: const ProjectManifest(name: 'owner', maps: [], tilesets: []),
      ids: {
        'storylines': {id}
      },
    );
    return selection.project.storylines.singleOrNull;
  }
}
