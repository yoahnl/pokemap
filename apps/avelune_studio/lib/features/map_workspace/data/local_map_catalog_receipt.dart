import 'dart:convert';

import 'package:map_authoring/map_authoring_api.dart';
import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_core/map_core.dart';

import '../domain/map_catalog_port.dart';
import '../domain/map_workspace_port.dart';

MapCatalogReceipt mapCatalogReceipt(
  ProjectManifest before,
  String beforeRevision,
  AuthoringPlan plan,
  String actionId,
) {
  final changes = plan.changeSet.changes;
  final manifestBytes = changes
      .where((change) => change.storageKey == 'project.json')
      .firstOrNull
      ?.afterBytes;
  final manifest = manifestBytes == null
      ? before
      : ProjectManifest.fromJson(
          jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>,
        );
  final documents = <String, MapWorkspaceDocument>{};
  for (final change in changes.where(
    (change) => change.resource.kind == 'map',
  )) {
    final bytes = change.afterBytes;
    if (bytes == null) continue;
    final map = decodeValidatedMapDocument(
      bytes,
      change.storageKey,
      validateMap: (map) =>
          MapValidator.validate(map, projectDialogueContext: manifest),
    );
    documents[map.id] = MapWorkspaceDocument(
      map: map,
      mapId: map.id,
      revision: narrativeEventBytesFingerprint(bytes),
    );
  }
  return MapCatalogReceipt(
    before: before,
    manifest: manifest,
    beforeRevision: beforeRevision,
    revision: manifestBytes == null
        ? beforeRevision
        : narrativeEventBytesFingerprint(manifestBytes),
    changedPaths: List.unmodifiable(changes.map((change) => change.storageKey)),
    documents: Map.unmodifiable(documents),
    createdMapId: actionId == 'map.create' || actionId == 'map.duplicate'
        ? documents.keys
              .where((id) => !before.maps.any((map) => map.id == id))
              .firstOrNull
        : null,
  );
}
