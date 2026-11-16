import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../ports/transaction_file_gateway.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/project_query_service.dart';

const dialogueDocumentResourceKind = 'dialogueDocument';

Future<AuthoringQueryPage> queryDialogueDocument({
  required CatalogProjectReader? catalog,
  required AuthoringQueryRequest request,
}) async {
  if (request.operation != AuthoringQueryOperation.get ||
      request.view != AuthoringQueryView.detail ||
      request.ids.length != 1 ||
      request.ids.single.isEmpty ||
      request.ids.single.trim() != request.ids.single ||
      request.filters.isNotEmpty ||
      request.searchTerm != null ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.extensions.isNotEmpty ||
      request.cursor != null) {
    throw const AuthoringQueryException('query.dialogue_document_scope_invalid',
        'Get exactly one dialogue id with view detail.');
  }
  if (catalog == null) {
    throw const AuthoringQueryException(
        'query.dialogue_document_catalog_required',
        'Dialogue documents are read from a working catalog project.');
  }
  final id = request.ids.single;
  return catalog.read((projection) async {
    final snapshot = projection.snapshot;
    final List<ProjectDialogueEntry> entries;
    try {
      entries = (await CatalogMetadataDocuments.readDocuments(
              snapshot: snapshot,
              project: projection.projectMetadata,
              ids: {
            'dialogues': {id}
          }))
          .project
          .dialogues;
    } on FormatException catch (error) {
      if (!_indexUnavailable(error)) rethrow;
      throw const AuthoringQueryException(
          'query.dialogue_document_preparation_required',
          'The dialogue metadata index is unavailable. Prepare the workshop catalog, then retry.');
    }
    if (entries.isEmpty) {
      throw AuthoringQueryException(
          'query.resource_not_found', 'Unknown dialogue $id.');
    }
    final entry = entries.single;
    final payload =
        await catalog.store.gateway.captureResourcePayload(entry.relativePath);
    List<int>? bytes;
    if (payload != null) {
      try {
        bytes = await payload.readBytes();
      } finally {
        await payload.release();
      }
    }
    var sceneIds = <String>[];
    final notCovered = <String>[
      'alternativeSceneDialogues',
      'legacyMapDialogues',
      'cinematics',
    ];
    try {
      sceneIds = (await CatalogMetadataDocuments.readSceneIdsForDialogue(
              snapshot: snapshot, dialogueId: id))
          .toList()
        ..sort();
    } on FormatException catch (error) {
      if (!_indexUnavailable(error)) rethrow;
      notCovered.add('sceneDialogueIndex');
    }
    return AuthoringQueryPage(
        snapshotRevision: 'sha256:${snapshot.root.sha256}',
        items: [
          {
            'entry': entry.toJson(),
            'source': bytes == null ? null : utf8.decode(bytes),
            'revision':
                bytes == null ? null : narrativeEventBytesFingerprint(bytes),
            'usages': {'sceneIds': sceneIds, 'notCovered': notCovered},
            'reads': {'dialogues': 1, 'scenes': 0, 'maps': 0},
          }
        ],
        totalAvailable: 1);
  });
}

bool _indexUnavailable(FormatException error) => const {
      'catalog.metadata_documents.preparation_required',
      'catalog.metadata_documents.index_stale',
    }.contains(error.message);
