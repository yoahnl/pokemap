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
  String actionId, {
  ProjectManifest? projectedProject,
  String? projectedRevision,
}) {
  final changes = plan.changeSet.changes;
  final manifestBytes = changes
      .where((change) => change.storageKey == 'project.json')
      .firstOrNull
      ?.afterBytes;
  final manifest =
      projectedProject ??
      (manifestBytes == null
          ? before
          : ProjectManifest.fromJson(
              jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>,
            ));
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
    revision:
        projectedRevision ??
        (manifestBytes == null
            ? beforeRevision
            : narrativeEventBytesFingerprint(manifestBytes)),
    changedPaths: List.unmodifiable(changes.map((change) => change.storageKey)),
    documents: Map.unmodifiable(documents),
    createdMapId: actionId == 'map.create' || actionId == 'map.duplicate'
        ? documents.keys
              .where((id) => !before.maps.any((map) => map.id == id))
              .firstOrNull
        : null,
  );
}

ProjectManifest mapCatalogScopedManifest(
  ProjectManifest before,
  ProjectManifest selected,
  ProjectManifest projected,
) => before.copyWith(
  maps: _mergeScoped(before.maps, selected.maps, projected.maps, (e) => e.id),
  groups: _mergeScoped(
    before.groups,
    selected.groups,
    projected.groups,
    (e) => e.id,
  ),
);

List<T> _mergeScoped<T>(
  List<T> before,
  List<T> selected,
  List<T> projected,
  String Function(T) id,
) {
  final selectedById = {for (final entry in selected) id(entry): entry};
  final projectedById = {for (final entry in projected) id(entry): entry};
  final removed = selectedById.keys.toSet().difference(
    projectedById.keys.toSet(),
  );
  final kept = <String>{};
  return [
    for (final entry in before)
      if (kept.add(id(entry)) && !removed.contains(id(entry)))
        switch (projectedById[id(entry)]) {
          final next? when next != selectedById[id(entry)] => next,
          _ => entry,
        },
    for (final entry in projected)
      if (!kept.contains(id(entry))) entry,
  ];
}
