import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../domains/narrative/dialogue_source_store.dart';
import '../support/authoring_fingerprint.dart';
import '../transactions/change_set.dart';
import 'project_snapshot.dart';

/// Projects committed map post-images into a complete immutable snapshot.
///
/// Unsupported changes return `null`, forcing the caller back through the
/// strict loader. This keeps map-only hot paths fast without guessing about
/// manifest, dialogue, asset, creation, or deletion semantics.
final class ProjectSnapshotMapProjector {
  const ProjectSnapshotMapProjector();

  ProjectSnapshot? project(
    ProjectSnapshot snapshot,
    Iterable<AuthoringResourceChange> changes,
  ) {
    if (snapshot.loadDiagnostics.isNotEmpty) return null;
    final replacements = <String, List<int>>{};
    final replacementMaps = <String, MapData>{};
    ProjectManifest? manifest;
    final fingerprints = Map<String, String>.of(
      snapshot.resourceFingerprints,
    );
    for (final change in changes) {
      if ((change.resource.kind != 'map' &&
              change.resource.kind != 'project') ||
          change.beforePayload?.isInline != true ||
          change.afterPayload?.isInline != true) {
        return null;
      }
      final identity = change.resource.kind == 'project'
          ? 'project'
          : 'map:${change.resource.id}';
      if (snapshot.resourceStorageKeys[identity] != change.storageKey ||
          !_bytesEqual(
              snapshot.findResourceBytes(identity), change.beforeBytes)) {
        return null;
      }
      if (replacements.containsKey(identity)) return null;
      if (change.resource.kind == 'project') {
        if (change.resource.id != 'project') return null;
        manifest = _decodeManifestProjection(snapshot, change.afterBytes!);
        if (manifest == null) return null;
      } else {
        final decoded = _decodeMap(change.afterBytes!);
        if (decoded == null || decoded.id != change.resource.id) return null;
        replacementMaps[decoded.id] = decoded;
      }
      replacements[identity] = change.afterBytes!;
      fingerprints[identity] = _resourceFingerprint(
        change.storageKey,
        change.afterBytes!,
      );
    }
    if (replacements.isEmpty) return null;

    final maps = [
      for (final map in snapshot.maps) replacementMaps[map.id] ?? map,
    ];
    final projectedManifest = manifest ?? snapshot.manifest;
    try {
      if (projectedManifest.pokemon.enabled &&
          projectedManifest.pokemon.catalogFiles['items'] != null &&
          snapshot.itemCatalog == null &&
          buildProjectItemReferenceIndex(project: projectedManifest, maps: maps)
              .references
              .isNotEmpty) {
        return null;
      }
      for (final map in maps) {
        if (map.spatialScene != null) {
          MapValidator.validate(map, projectDialogueContext: projectedManifest);
        }
      }
    } on Object {
      return null;
    }
    final resources = snapshot.resourceStorageKeys.entries.toList()
      ..sort((left, right) => left.value.compareTo(right.value));
    // Same rule as ProjectSnapshotLoader: the revision folds the per-resource
    // fingerprints, not the resources themselves. Both paths must agree, so
    // they must fold the same values.
    final revision = computeNarrativeProjectFingerprint([
      for (final resource in resources)
        NarrativeProjectFingerprintEntry(
          relativePath: resource.value,
          bytes: utf8.encode(fingerprints[resource.key]!),
        ),
    ]);
    return snapshot.projectMapResources(
      revision: revision,
      manifest: manifest,
      maps: maps,
      resourceFingerprints: fingerprints,
      replacementBytes: replacements,
    );
  }
}

MapData? _decodeMap(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) return null;
    return MapData.fromJson(Map<String, dynamic>.from(decoded));
  } on Object {
    return null;
  }
}

String _resourceFingerprint(String relativePath, List<int> bytes) =>
    computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: relativePath,
        bytes: bytes,
      ),
    ]);

bool _bytesEqual(List<int>? left, List<int>? right) {
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

ProjectManifest? _decodeManifestProjection(
  ProjectSnapshot snapshot,
  List<int> bytes,
) {
  try {
    final rawBefore = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(snapshot.authoringProjectBytes)) as Map,
    );
    final rawAfter = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(bytes)) as Map,
    );
    final manifest = ProjectManifest.fromJson(rawAfter);
    final modeledBefore = snapshot.manifest.toJson();
    final modeledAfter = manifest.toJson();
    if (manifest.maps.length != snapshot.manifest.maps.length) return null;
    final previousMaps = {
      for (final map in snapshot.manifest.maps) map.id: map
    };
    final seen = <String>{};
    for (final map in manifest.maps) {
      final previous = previousMaps[map.id];
      if (previous == null ||
          !seen.add(map.id) ||
          map.copyWith(
                  name: previous.name,
                  groupId: previous.groupId,
                  sortOrder: previous.sortOrder) !=
              previous) {
        return null;
      }
    }
    if (!_sameDialogueSources(snapshot, manifest)) return null;
    final previousCinematics = {
      for (final entry in snapshot.manifest.cinematics) entry.id: entry
    };
    for (final cinematic in manifest.cinematics) {
      if (cinematic != previousCinematics[cinematic.id] &&
          !preflightCinematicPlayback(
            cinematic: cinematic,
            dialogues: manifest.dialogues,
            mediaAssets: manifest.cinematicMediaAssets,
            availableMapIds: manifest.maps.map((entry) => entry.id),
          ).isReady) {
        return null;
      }
    }
    for (final field in ['facts', 'dialogues', 'cinematics']) {
      if (!_containsOnlyModeledFields(rawBefore[field], modeledBefore[field]) ||
          !_containsOnlyModeledFields(rawAfter[field], modeledAfter[field])) {
        return null;
      }
    }
    final normalizedBefore = _withDefaults(rawBefore, modeledBefore) as Map;
    final normalizedAfter = _withDefaults(rawAfter, modeledAfter) as Map;
    for (final field in [
      'maps',
      'groups',
      'scenes',
      'worldRules',
      'eventRegistry',
      'facts',
      'dialogues',
      'cinematics'
    ]) {
      normalizedBefore.remove(field);
      normalizedAfter.remove(field);
    }
    if (canonicalAuthoringJson(normalizedBefore) !=
        canonicalAuthoringJson(normalizedAfter)) {
      return null;
    }
    ProjectValidator.validate(manifest);
    return manifest;
  } on Object {
    return null;
  }
}

Object? _withDefaults(Object? raw, Object? defaults) {
  if (raw is! Map || defaults is! Map) return raw;
  return <String, Object?>{
    for (final key in {...defaults.keys, ...raw.keys})
      key as String: raw.containsKey(key)
          ? _withDefaults(raw[key], defaults[key])
          : defaults[key],
  };
}

bool _sameDialogueSources(ProjectSnapshot snapshot, ProjectManifest manifest) {
  final previous = snapshot.manifest.dialogues;
  if (manifest.dialogues.length != previous.length) return false;
  final paths = {for (final entry in previous) entry.id: entry.relativePath};
  final seen = <String>{};
  for (final entry in manifest.dialogues) {
    final identity = dialogueSourceResourceIdentity(entry.id);
    if (!seen.add(entry.id) ||
        paths[entry.id] != entry.relativePath ||
        snapshot.resourceStorageKeys[identity] != entry.relativePath ||
        !snapshot.resourceFingerprints.containsKey(identity) ||
        (snapshot.findResourceBytes(identity) == null &&
            !snapshot.storedResources.containsKey(identity))) {
      return false;
    }
  }
  return true;
}

bool _containsOnlyModeledFields(Object? raw, Object? modeled) {
  if (raw is Map && modeled is Map) {
    return raw.keys.every((key) =>
        modeled.containsKey(key) &&
        _containsOnlyModeledFields(raw[key], modeled[key]));
  }
  if (raw is List && modeled is List) {
    if (raw.length != modeled.length) return false;
    for (var index = 0; index < raw.length; index++) {
      if (!_containsOnlyModeledFields(raw[index], modeled[index])) return false;
    }
  }
  return true;
}
