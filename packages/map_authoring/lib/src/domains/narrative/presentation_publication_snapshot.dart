import 'dart:convert';
import '../assets/asset_store.dart';
import 'package:map_core/map_core.dart';
import '../../contracts/resource_ref.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';

ProjectSnapshot projectPresentationPublicationSnapshot(
  ProjectSnapshot source, {
  required ProjectManifest manifest,
  required Iterable<AuthoringResourceChange> changes,
}) {
  final bytes = <String, List<int>>{
    ...source.inlineResourceBytes,
  };
  final stored = Map<String, ProjectStoredResource>.of(source.storedResources);
  final payloads = Map.of(source.payloadResources);
  final paths = Map<String, String>.of(source.resourceStorageKeys);
  final fingerprints = Map<String, String>.of(source.resourceFingerprints);
  for (final change in changes) {
    final id = paths.entries
            .where((e) => e.value == change.storageKey)
            .firstOrNull
            ?.key ??
        switch (change.resource.kind) {
          'project' => 'project',
          'presentationMediaCatalog' => 'projectMediaCatalog',
          'assetCatalog' => 'assetCatalog',
          'assetBlob' => 'assetBlob:${change.resource.id}',
          _ =>
            throw StateError('Unsupported Presentation publication resource.'),
        };
    final after = change.afterPayload;
    if (after == null) {
      bytes.remove(id);
      stored.remove(id);
      payloads.remove(id);
      paths.remove(id);
      fingerprints.remove(id);
    } else {
      stored.remove(id);
      if (after.isInline) {
        bytes[id] = after.inlineBytes;
        payloads.remove(id);
      } else {
        bytes.remove(id);
        payloads[id] = after;
      }
      paths[id] = change.storageKey;
      fingerprints[id] = change.afterRevision!;
    }
  }
  return ProjectSnapshot(
    projectHandle: source.projectHandle,
    revision: computeAuthoringJsonFingerprint(fingerprints,
        logicalName: 'presentation-publication'),
    manifest: manifest,
    maps: source.maps,
    resourceFingerprints: fingerprints,
    resourceBytes: bytes,
    resourceStorageKeys: paths,
    storedResources: stored,
    payloadResources: payloads,
    resourcePayloadReader: source.resourcePayloadReader,
    payloadOwner: source.payloadOwner,
  );
}

List<AuthoringResourceChange> mergePresentationPublicationChanges(
  Iterable<AuthoringResourceChange> changes,
) {
  final merged = <String, AuthoringResourceChange>{};
  for (final change in changes) {
    final before = merged[change.storageKey];
    merged[change.storageKey] = before == null
        ? change
        : AuthoringResourceChange.withPayloads(
            resource: AuthoringResourceRef(
                kind: change.resource.kind,
                id: change.resource.id,
                revision: before.beforeRevision),
            storageKey: change.storageKey,
            beforePayload: before.beforePayload,
            afterPayload: change.afterPayload,
          );
  }
  return merged.values.toList();
}

List<ProjectMediaSourceAssetDefinition> presentationSourceAssets(
    ProjectSnapshot snapshot) {
  final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
  if (bytes == null) return const [];
  final catalog = AssetCatalog.fromJson(
      Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map));
  return [
    for (final asset in catalog.records)
      ProjectMediaSourceAssetDefinition(id: asset.id, label: asset.logicalPath)
  ];
}
