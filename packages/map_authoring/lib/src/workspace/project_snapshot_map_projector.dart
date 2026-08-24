import 'dart:convert';

import 'package:map_core/map_core.dart';

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
    final replacements = <String, List<int>>{};
    final replacementMaps = <String, MapData>{};
    final fingerprints = Map<String, String>.of(
      snapshot.resourceFingerprints,
    );
    for (final change in changes) {
      if (change.resource.kind != 'map' ||
          change.beforeBytes == null ||
          change.afterBytes == null) {
        return null;
      }
      final identity = 'map:${change.resource.id}';
      if (snapshot.resourceStorageKeys[identity] != change.storageKey ||
          !_bytesEqual(
              snapshot.findResourceBytes(identity), change.beforeBytes)) {
        return null;
      }
      final decoded = _decodeMap(change.afterBytes!);
      if (decoded == null || decoded.id != change.resource.id) return null;
      if (replacements.containsKey(identity)) return null;
      replacements[identity] = change.afterBytes!;
      replacementMaps[decoded.id] = decoded;
      fingerprints[identity] = _resourceFingerprint(
        change.storageKey,
        change.afterBytes!,
      );
    }
    if (replacements.isEmpty) return null;

    final maps = [
      for (final map in snapshot.maps) replacementMaps[map.id] ?? map,
    ];
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
