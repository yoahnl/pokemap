import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../workspace/catalog/catalog_narrative_usages.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/project_query_service.dart';

const narrativeFactUsersResourceKind = 'narrativeFactUsers';
const narrativeMapElementOwnersResourceKind = 'narrativeMapElementOwners';
const narrativeUsageResourceKinds = {
  narrativeFactUsersResourceKind,
  narrativeMapElementOwnersResourceKind,
};

Future<AuthoringQueryPage> queryNarrativeUsages({
  required CatalogProjectReader? catalog,
  required AuthoringQueryRequest request,
}) async {
  final facts = request.resourceKind == narrativeFactUsersResourceKind;
  final mapId = request.filters['mapId'];
  if (!const {AuthoringQueryOperation.get, AuthoringQueryOperation.batchGet}
          .contains(request.operation) ||
      request.view != AuthoringQueryView.summary ||
      request.ids.isEmpty ||
      request.ids.length > 50 ||
      request.ids.toSet().length != request.ids.length ||
      request.ids.any((id) => id.isEmpty || id.trim() != id) ||
      request.searchTerm != null ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.extensions.isNotEmpty ||
      request.cursor != null ||
      (facts
          ? request.filters.isNotEmpty
          : request.filters.length != 1 ||
              mapId is! String ||
              mapId.isEmpty ||
              mapId.trim() != mapId)) {
    throw AuthoringQueryException(
        'query.narrative_usage_scope_invalid',
        facts
            ? 'Get 1 to 50 explicit Fact ids.'
            : 'Get 1 to 50 explicit map element ids with filters.mapId.');
  }
  if (catalog == null) {
    throw const AuthoringQueryException(
        'query.narrative_usages_catalog_required',
        'Narrative usages are read from a working catalog project.');
  }
  return catalog.read((projection) async {
    final snapshot = projection.snapshot;
    final items = <Map<String, Object?>>[];
    for (final id in request.ids) {
      final read = facts
          ? await CatalogNarrativeUsages.readFactUsers(snapshot, id)
          : await CatalogNarrativeUsages.readMapElementOwners(
              snapshot, mapId as String, id);
      final entries = switch (read) {
        CatalogNarrativeUsageEntries(:final entries) => entries,
        CatalogNarrativeUsagesPreparationRequired(:final reason) =>
          throw AuthoringQueryException(
              'query.narrative_usages_preparation_required',
              'The narrative usage indexes are ${reason == 'stale' ? 'stale' : 'not prepared'}. Prepare the workshop catalog with scope ${CatalogNarrativeUsages.preparationScope}, then retry.'),
      };
      items.add({
        if (facts) 'factId': id else ...{'mapId': mapId, 'elementId': id},
        facts ? 'users' : 'owners': entries,
        'coverage': CatalogNarrativeUsages.coverage,
      });
    }
    return AuthoringQueryPage(
        snapshotRevision: 'sha256:${snapshot.root.sha256}',
        items: items,
        totalAvailable: items.length);
  });
}
