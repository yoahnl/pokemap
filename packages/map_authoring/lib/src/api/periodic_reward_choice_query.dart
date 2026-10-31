import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/periodic_reward_choices.dart';
import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../support/authoring_fingerprint.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/workspace_handle_store.dart';

const periodicRewardChoiceKinds = {'periodicRewardScene', 'periodicRewardNode'};

Future<AuthoringQueryPage> queryPeriodicRewardChoices({
  required CatalogProjectReader? catalog,
  required ProjectSnapshotLoader loader,
  required ProjectHandle projectHandle,
  required AuthoringQueryRequest request,
}) async {
  final nodes = request.resourceKind == 'periodicRewardNode';
  final sceneId = nodes ? request.filters['sceneId'] : request.ids.firstOrNull;
  if (request.view != AuthoringQueryView.summary ||
      request.searchTerm != null ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.extensions.keys.any((key) => !nodes || key != 'sourceRevision') ||
      (request.extensions.containsKey('sourceRevision') &&
          (request.extensions['sourceRevision'] is! String ||
              (request.extensions['sourceRevision'] as String)
                  .trim()
                  .isEmpty)) ||
      (nodes
          ? request.filters.length != 1 ||
              sceneId is! String ||
              sceneId.isEmpty ||
              sceneId.trim() != sceneId ||
              request.ids.isNotEmpty ||
              !const {
                AuthoringQueryOperation.list,
                AuthoringQueryOperation.summary
              }.contains(request.operation)
          : request.filters.isNotEmpty ||
              !const {
                AuthoringQueryOperation.list,
                AuthoringQueryOperation.summary,
                AuthoringQueryOperation.get
              }.contains(request.operation))) {
    throw const AuthoringQueryException('query.periodic_reward_scope_invalid',
        'Choose a bounded Scene page, then supply one explicit sceneId for its published reward nodes.');
  }
  final cursor = _cursor(request);
  final offset = cursor?.offset ?? 0;
  final ({
    List<Map<String, dynamic>> records,
    int total,
    String revision
  }) selected;
  if (catalog == null) {
    selected = await loader.readNativeSceneChoicePage(projectHandle,
        sceneId: sceneId as String?,
        offset: sceneId == null ? offset : 0,
        limit: request.pageSize);
  } else {
    selected = await catalog.read((projection) async {
      await catalog.store.requireMetadataIndexAdmission(projection.snapshot);
      final revision = 'sha256:${projection.snapshot.root.sha256}';
      if (cursor != null && cursor.revision != revision) {
        throw const AuthoringQueryException('query.cursor_stale',
            'The published project changed after the previous reward choice page.');
      }
      if (sceneId != null) {
        final documents = await CatalogMetadataDocuments.readDocuments(
          snapshot: projection.snapshot,
          project: projection.projectMetadata,
          ids: {
            'scenes': {sceneId as String}
          },
        );
        return (
          records:
              documents.project.scenes.map((scene) => scene.toJson()).toList(),
          total: documents.project.scenes.length,
          revision: revision
        );
      }
      final ({List<Map<String, dynamic>> records, int total}) page;
      try {
        page = await CatalogMetadataDocuments.readPage(
            snapshot: projection.snapshot,
            field: 'scenes',
            offset: offset,
            limit: request.pageSize);
      } on FormatException catch (error) {
        if (error.message != 'catalog.metadata_documents.invalid_page') rethrow;
        throw const AuthoringQueryException('query.cursor_invalid',
            'The reward choice cursor offset is invalid.');
      }
      return (records: page.records, total: page.total, revision: revision);
    });
  }
  if (cursor != null && cursor.revision != selected.revision) {
    throw const AuthoringQueryException('query.cursor_stale',
        'The published project changed after the previous reward choice page.');
  }
  if (sceneId != null && selected.records.isEmpty) {
    throw const AuthoringQueryException('query.resource_not_found',
        'The selected published Scene does not exist.');
  }
  if (sceneId != null && selected.records.length != 1) {
    throw const AuthoringQueryException('query.periodic_reward_scene_ambiguous',
        'The selected Scene identity is ambiguous.');
  }
  final List<Map<String, Object?>> rows;
  final int total;
  if (nodes) {
    final raw = selected.records.single;
    final sourceRevision = _sceneRevision(raw);
    if (request.extensions.containsKey('sourceRevision') &&
        request.extensions['sourceRevision'] != sourceRevision) {
      throw const AuthoringQueryException('query.periodic_reward_source_stale',
          'The published Scene changed after it was selected. Choose it again.');
    }
    final scene = SceneAsset.fromJson(raw);
    final choices = [
      for (final node in scene.graph.nodes)
        if (node.payload
            case SceneActionPayload(
              interactiveCommand: SceneClaimPeriodicRewardInteractiveCommand(
                :final definition
              )
            ))
          PeriodicRewardNodeChoice(
                  nodeId: node.id,
                  label: definition.label,
                  itemId: definition.itemId,
                  quantity: definition.quantity,
                  reference: PeriodicRewardReference(
                      sceneId: scene.id,
                      nodeId: node.id,
                      rewardId: definition.rewardId),
                  revision: sourceRevision)
              .toJson(),
    ];
    total = choices.length;
    _checkOffset(offset, total);
    rows = choices.sublist(offset, (offset + request.pageSize).clamp(0, total));
  } else {
    total = selected.total;
    _checkOffset(offset, total);
    rows = [
      for (final raw in selected.records)
        PeriodicRewardSceneChoice(
                sceneId: raw['id'] as String,
                label: raw['name'] as String,
                revision: _sceneRevision(raw))
            .toJson()
    ];
  }
  final end = offset + rows.length;
  return AuthoringQueryPage(
      snapshotRevision: selected.revision,
      items: rows,
      totalAvailable: total,
      nextCursor: end < total
          ? base64Url
              .encode(utf8.encode(jsonEncode({
                'version': 1,
                'revision': selected.revision,
                'signature': request.signature,
                'offset': end,
              })))
              .replaceAll('=', '')
          : null);
}

String _sceneRevision(Map<String, dynamic> raw) =>
    computeAuthoringJsonFingerprint(raw,
        logicalName: 'published-scene/${raw['id']}.json');

void _checkOffset(int offset, int total) {
  if (offset > total) {
    throw const AuthoringQueryException(
        'query.cursor_invalid', 'The reward choice cursor offset is invalid.');
  }
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
          'The reward choice cursor belongs to another query.');
    }
    return (revision: raw['revision'] as String, offset: raw['offset'] as int);
  } on AuthoringQueryException {
    rethrow;
  } on Object {
    throw const AuthoringQueryException(
        'query.cursor_invalid', 'The reward choice cursor is malformed.');
  }
}
