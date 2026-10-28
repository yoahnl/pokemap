import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../domains/assets/asset_store.dart';
import '../domains/assets/project_media_store.dart';
import '../support/authoring_fingerprint.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/workspace_handle_store.dart';

Future<AuthoringQueryPage> queryProjectMediaLibrary({
  required ProjectSnapshotLoader loader,
  required ProjectQueryService queries,
  required ProjectHandle projectHandle,
  required AuthoringQueryRequest request,
}) async {
  final media = request.resourceKind == 'presentationMedia';
  final path = media ? projectMediaCatalogStorageKey : assetCatalogStorageKey;
  final identity = media
      ? projectMediaCatalogResourceIdentity
      : assetCatalogResourceIdentity;
  final bytes = await loader.readOptionalResourceBytes(projectHandle, path,
      maximumBytes: 32 * 1024 * 1024);
  final encoded = bytes ??
      utf8.encode(
          jsonEncode({'schemaVersion': 1, media ? 'entries' : 'records': []}));
  final revision = computeAuthoringBytesFingerprint(encoded, logicalName: path);
  ProjectSnapshot snapshot(List<int> content) => ProjectSnapshot(
        projectHandle: projectHandle,
        revision: revision,
        manifest: const ProjectManifest(
            name: 'Media library', maps: [], tilesets: []),
        maps: const [],
        resourceFingerprints: {identity: revision},
        resourceBytes: {identity: content},
      );
  if (request.sort.isNotEmpty ||
      request.extensions.isNotEmpty ||
      request.filters.keys.any((key) => key != 'kind')) {
    return queries.queryAsync(snapshot(encoded), request);
  }
  final document = jsonDecode(utf8.decode(encoded));
  final field = media ? 'entries' : 'records';
  if (document is! Map ||
      document['schemaVersion'] != 1 ||
      document[field] is! List) {
    throw const AuthoringQueryException('query.media_catalog_invalid',
        'The selected media catalog is invalid.');
  }
  final search = request.operation == AuthoringQueryOperation.search
      ? request.searchTerm!.toLowerCase()
      : null;
  final rows = (document[field] as List)
      .whereType<Map>()
      .where(
        (row) =>
            (request.ids.isEmpty || request.ids.contains(row['id'])) &&
            (!request.filters.containsKey('kind') ||
                row['kind'] == request.filters['kind']) &&
            (search == null ||
                '${row['id']}'.toLowerCase().contains(search) ||
                '${media ? row['label'] : row['logicalPath']}'
                    .toLowerCase()
                    .contains(search)),
      )
      .toList()
    ..sort((left, right) =>
        (left['id'] as String).compareTo(right['id'] as String));
  final criteria = request.toJson()
    ..remove('cursor')
    ..remove('pageSize');
  final query = jsonEncode(criteria);
  var offset = 0;
  if (request.cursor case final cursor?) {
    Map cursorData;
    try {
      cursorData =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(cursor))))
              as Map;
    } catch (_) {
      throw const AuthoringQueryException(
          'query.cursor_invalid', 'The media cursor is invalid.');
    }
    if (cursorData['revision'] != revision || cursorData['query'] != query) {
      throw const AuthoringQueryException('query.cursor_stale',
          'The media library or query changed. Restart this page.');
    }
    final value = cursorData['offset'];
    if (value is! int || value < 0 || value > rows.length) {
      throw const AuthoringQueryException(
          'query.cursor_invalid', 'The media cursor offset is invalid.');
    }
    offset = value;
  }
  final end = (offset + request.pageSize).clamp(0, rows.length);
  final selected = rows.sublist(offset, end);
  final projected =
      utf8.encode(jsonEncode({'schemaVersion': 1, field: selected}));
  final result = await queries.queryAsync(
      snapshot(projected),
      AuthoringQueryRequest(
        resourceKind: request.resourceKind,
        operation: request.operation == AuthoringQueryOperation.search
            ? AuthoringQueryOperation.list
            : request.operation,
        ids: request.ids,
        view: request.view,
        fieldMask: request.fieldMask,
        pageSize: request.pageSize,
      ));
  return AuthoringQueryPage(
      snapshotRevision: revision,
      items: result.items,
      totalAvailable: rows.length,
      nextCursor: end < rows.length
          ? base64Url
              .encode(utf8.encode(jsonEncode({
                'revision': revision,
                'offset': end,
                'query': query,
              })))
              .replaceAll('=', '')
          : null);
}
