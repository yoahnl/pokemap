import 'package:map_core/map_core.dart';

import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../workspace/catalog/catalog_map_directory.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/project_query_service.dart';

const mapDirectoryResourceKind = 'mapDirectory';

Future<AuthoringQueryPage> queryMapDirectory({
  required CatalogProjectReader? catalog,
  required AuthoringQueryRequest request,
}) async {
  if (!const {AuthoringQueryOperation.get, AuthoringQueryOperation.batchGet}
          .contains(request.operation) ||
      request.view != AuthoringQueryView.summary ||
      request.ids.isEmpty ||
      request.ids.length > 50 ||
      request.ids.toSet().length != request.ids.length ||
      request.ids.any((id) => id.isEmpty || id.trim() != id) ||
      request.filters.isNotEmpty ||
      request.searchTerm != null ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.extensions.isNotEmpty ||
      request.cursor != null) {
    throw const AuthoringQueryException(
        'query.map_directory_scope_invalid', 'Get 1 to 50 explicit map ids.');
  }
  if (catalog == null) {
    throw const AuthoringQueryException('query.map_directory_catalog_required',
        'The map directory is read from a working catalog project.');
  }
  return catalog.read((projection) async {
    final snapshot = projection.snapshot;
    final pages = await readMapDirectoryPages(snapshot, request.ids);
    return AuthoringQueryPage(
        snapshotRevision: 'sha256:${snapshot.root.sha256}',
        items: pages,
        totalAvailable: pages.length);
  });
}

Future<List<Map<String, Object?>>> readMapDirectoryPages(
    CatalogSnapshot snapshot, Iterable<String> mapIds) async {
  switch (await CatalogMapDirectory.read(snapshot, mapIds)) {
    case CatalogMapDirectoryPreparationRequired(:final reason):
      throw AuthoringQueryException('query.map_directory_preparation_required',
          'The map directory is ${reason == 'stale' ? 'stale' : 'not prepared'}. Prepare the workshop catalog with scope ${CatalogMapDirectory.preparationScope}, then retry.');
    case CatalogMapDirectoryPages(:final pages, :final unknownMapIds):
      if (unknownMapIds.isNotEmpty) {
        throw AuthoringQueryException('query.resource_not_found',
            'Unknown maps: ${unknownMapIds.join(', ')}.');
      }
      return [
        for (final page in pages)
          {'mapId': page.mapId, 'name': page.name, 'elements': page.elements}
      ];
  }
}
