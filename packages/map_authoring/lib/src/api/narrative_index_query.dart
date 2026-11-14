import 'dart:convert';

import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../workspace/catalog/catalog_narrative_titles.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/project_query_service.dart';

export '../workspace/catalog/catalog_narrative_titles.dart'
    show
        CatalogNarrativeTitle,
        CatalogNarrativeTitleRead,
        CatalogNarrativeTitlePage,
        CatalogNarrativeTitlesPreparationRequired,
        CatalogNarrativeTitles;

const narrativeTitleResourceKind = 'narrativeTitle';

Future<AuthoringQueryPage> queryNarrativeTitles({
  required CatalogProjectReader? catalog,
  required AuthoringQueryRequest request,
}) async {
  final kind = request.filters['kind'];
  if (request.operation != AuthoringQueryOperation.list ||
      request.view != AuthoringQueryView.summary ||
      request.ids.isNotEmpty ||
      request.searchTerm != null ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.extensions.isNotEmpty ||
      request.filters.length != 1 ||
      kind is! String ||
      !CatalogNarrativeTitles.kinds.contains(kind)) {
    throw AuthoringQueryException('query.narrative_title_scope_invalid',
        'List one narrative kind with filters.kind among ${CatalogNarrativeTitles.kinds.join(', ')}.');
  }
  if (catalog == null) {
    throw const AuthoringQueryException(
        'query.narrative_titles_catalog_required',
        'Narrative title pages are read from a working catalog project.');
  }
  final cursor = _cursor(request);
  return catalog.read((projection) async {
    final snapshot = projection.snapshot;
    final revision = 'sha256:${snapshot.root.sha256}';
    if (cursor != null && cursor.revision != revision) {
      throw const AuthoringQueryException('query.cursor_stale',
          'The project changed after the previous narrative title page.');
    }
    final offset = cursor?.offset ?? 0;
    final items = <Map<String, Object?>>[];
    var total = 0;
    var page = offset ~/ CatalogNarrativeTitles.pageSize;
    do {
      final CatalogNarrativeTitleRead read;
      try {
        read = await CatalogNarrativeTitles.read(snapshot, kind, page);
      } on FormatException catch (error) {
        if (error.message != 'catalog.narrative_titles.page_out_of_range') {
          rethrow;
        }
        throw const AuthoringQueryException('query.cursor_invalid',
            'The narrative title cursor offset is invalid.');
      }
      if (read is CatalogNarrativeTitlesPreparationRequired) {
        throw AuthoringQueryException(
            'query.narrative_titles_preparation_required',
            'The $kind title index is ${read.reason == 'stale' ? 'stale' : 'not prepared'}. Prepare the workshop catalog with scope ${CatalogNarrativeTitles.preparationScope}, then retry.');
      }
      final titles = read as CatalogNarrativeTitlePage;
      total = titles.total;
      if (offset > total) {
        throw const AuthoringQueryException('query.cursor_invalid',
            'The narrative title cursor offset is invalid.');
      }
      final start = page * CatalogNarrativeTitles.pageSize;
      for (var i = 0; i < titles.entries.length; i++) {
        final position = start + i;
        if (position < offset || items.length == request.pageSize) continue;
        final entry = titles.entries[i];
        items.add({
          'kind': kind,
          'id': entry.id,
          'title': entry.title,
          'tags': entry.tags,
          if (entry.category != null) 'category': entry.category,
          if (entry.valueKind != null) 'valueKind': entry.valueKind,
          if (entry.initialValue != null) 'initialValue': entry.initialValue,
          'position': position,
        });
      }
      page++;
    } while (items.length < request.pageSize &&
        page * CatalogNarrativeTitles.pageSize < total);
    final end = offset + items.length;
    return AuthoringQueryPage(
        snapshotRevision: revision,
        items: items,
        totalAvailable: total,
        nextCursor: end < total
            ? base64Url
                .encode(utf8.encode(jsonEncode({
                  'version': 1,
                  'revision': revision,
                  'signature': request.signature,
                  'offset': end,
                })))
                .replaceAll('=', '')
            : null);
  });
}

({String revision, int offset})? _cursor(AuthoringQueryRequest request) {
  if (request.cursor == null) return null;
  try {
    if (request.cursor!.length > 4096) throw const FormatException();
    final raw = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(request.cursor!))));
    if (raw is! Map ||
        raw.length != 4 ||
        raw['version'] != 1 ||
        raw['revision'] is! String ||
        raw['offset'] is! int ||
        raw['offset'] < 0) {
      throw const FormatException();
    }
    if (raw['signature'] != request.signature) {
      throw const AuthoringQueryException('query.cursor_mismatch',
          'The narrative title cursor belongs to another query.');
    }
    return (revision: raw['revision'] as String, offset: raw['offset'] as int);
  } on AuthoringQueryException {
    rethrow;
  } on Object {
    throw const AuthoringQueryException(
        'query.cursor_invalid', 'The narrative title cursor is malformed.');
  }
}
