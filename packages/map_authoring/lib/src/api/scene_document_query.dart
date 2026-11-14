import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../catalog_storage/catalog_storage_store.dart';
import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../ports/transaction_file_gateway.dart';
import '../workspace/catalog/catalog_metadata_documents.dart';
import '../workspace/catalog/catalog_narrative_event_documents.dart';
import '../workspace/catalog/catalog_project_reader.dart';
import '../workspace/project_query_service.dart';
import 'map_directory_query.dart';

const sceneDocumentResourceKind = 'sceneDocument';

const _dialogueKeys = {
  'dialogueId',
  'alternateDialogueId',
  'preBattleDialogueId',
  'victoryDialogueId',
  'defeatDialogueId'
};
const _mapKeys = {'mapId', 'destinationMapId', 'targetMapId', 'sourceMapId'};

Future<AuthoringQueryPage> querySceneDocument({
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
    throw const AuthoringQueryException('query.scene_document_scope_invalid',
        'Get exactly one scene id with view detail.');
  }
  if (catalog == null) {
    throw const AuthoringQueryException('query.scene_document_catalog_required',
        'Scene documents are read from a working catalog project.');
  }
  final sceneId = request.ids.single;
  return catalog.read((projection) async {
    final snapshot = projection.snapshot;
    final base = projection.projectMetadata;
    final scenes = (await CatalogMetadataDocuments.readDocuments(
            snapshot: snapshot,
            project: base,
            ids: {
          'scenes': {sceneId}
        }))
        .project
        .scenes;
    if (scenes.isEmpty) {
      throw AuthoringQueryException(
          'query.resource_not_found', 'Unknown scene $sceneId.');
    }
    final scene = scenes.single;
    final sceneJson = scene.toJson();
    final ownerIds = await CatalogNarrativeEventDocuments.readSceneOwnerIds(
        snapshot, catalog.store.projectRoot, {sceneId});
    final NarrativeEventRegistry? registry;
    try {
      registry = ownerIds.isEmpty
          ? null
          : await CatalogNarrativeEventDocuments.read(snapshot, ownerIds);
    } on CatalogStorageException catch (error) {
      if (error.code != 'catalog.preparation_required') rethrow;
      throw const AuthoringQueryException(
          'query.narrative_events_preparation_required',
          'The narrative event index is not prepared. Prepare the workshop catalog, then retry.');
    }
    final events = [
      for (final record in registry?.records ?? const <NarrativeEventRecord>[])
        record.toJson()
    ];
    final dialogueEntries = (await CatalogMetadataDocuments.readDocuments(
            snapshot: snapshot,
            project: base,
            ids: {'dialogues': _ids(sceneJson, _dialogueKeys)}))
        .project
        .dialogues;
    final dialogues = <Map<String, Object?>>[];
    for (final entry in dialogueEntries) {
      final payload = await catalog.store.gateway
          .captureResourcePayload(entry.relativePath);
      List<int>? bytes;
      if (payload != null) {
        try {
          bytes = await payload.readBytes();
        } finally {
          await payload.release();
        }
      }
      dialogues.add({
        'entry': entry.toJson(),
        'source': bytes == null ? null : utf8.decode(bytes),
        'revision':
            bytes == null ? null : narrativeEventBytesFingerprint(bytes),
      });
    }
    final mapIds = {..._ids(sceneJson, _mapKeys), ..._ids(events, _mapKeys)}
        .toList()
      ..sort();
    final directory = mapIds.isEmpty
        ? const <Map<String, Object?>>[]
        : await readMapDirectoryPages(snapshot, mapIds);
    return AuthoringQueryPage(
        snapshotRevision: 'sha256:${snapshot.root.sha256}',
        items: [
          {
            'scene': sceneJson,
            'dialogues': dialogues,
            'events': events,
            'mapDirectory': directory,
            'reads': {
              'scenes': 1,
              'dialogues': dialogues.length,
              'events': events.length,
              'maps': 0,
            },
          }
        ],
        totalAvailable: 1);
  });
}

Set<String> _ids(Object? value, Set<String> keys) {
  final result = <String>{};
  void visit(Object? item) {
    if (item is Map) {
      for (final entry in item.entries) {
        if (keys.contains(entry.key)) {
          if (entry.value is String && (entry.value as String).isNotEmpty) {
            result.add(entry.value as String);
          } else if (entry.value is List) {
            result.addAll((entry.value as List)
                .whereType<String>()
                .where((id) => id.isNotEmpty));
          }
        }
        visit(entry.value);
      }
    } else if (item is List) {
      item.forEach(visit);
    }
  }

  visit(value);
  return result;
}
