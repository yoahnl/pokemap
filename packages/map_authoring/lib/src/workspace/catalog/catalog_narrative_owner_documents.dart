import 'package:map_core/map_core.dart';

import 'catalog_metadata_documents.dart';

abstract final class CatalogNarrativeOwnerDocuments {
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
