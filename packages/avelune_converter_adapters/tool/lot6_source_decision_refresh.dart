import 'package:avelune_converter_core/avelune_converter_core.dart';

Map<String, Object?> refreshLot6SourceDecisionsForRootClippings(
    SourceSnapshot snapshot, Map<String, Object?> decisions) {
  if (snapshot.canonicalHash.value == decisions['snapshotHash']) {
    return Map.of(decisions);
  }
  final clippings = snapshot.entries
      .where((entry) =>
          !entry.relativePath.contains('/') &&
          entry.relativePath.endsWith('.textClipping') &&
          entry.kind == SourceNodeKind.file &&
          entry.sha256 != null &&
          entry.byteLength <= 1048576)
      .toList();
  final original = SourceSnapshot(
      logicalProjectNamespace: snapshot.logicalProjectNamespace,
      policyHash: snapshot.policyHash,
      entries: snapshot.entries
          .where((entry) => !clippings.contains(entry))
          .toList(),
      diagnostics: snapshot.diagnostics,
      excludedPaths: snapshot.excludedPaths,
      profileEvidence: snapshot.profileEvidence,
      state: snapshot.state);
  if (snapshot.state != SourceScanState.complete ||
      clippings.isEmpty ||
      original.canonicalHash.value != decisions['snapshotHash']) {
    throw StateError(
        'Source inventory changed beyond root text clippings; regenerate dependency decisions');
  }
  List<Map<String, Object?>> refresh(String key) => [
        for (final row in decisions[key] as List)
          if ((row as Map)['sourceSnapshotHash'] ==
              original.canonicalHash.value)
            {
              ...Map<String, Object?>.from(row),
              'sourceSnapshotHash': snapshot.canonicalHash.value
            }
          else
            throw StateError(
                'Source decision does not belong to the original inventory'),
      ];
  return {
    'snapshotHash': snapshot.canonicalHash.value,
    'decisions': refresh('decisions'),
    'missingItemBindings': refresh('missingItemBindings'),
    'inventoryRefresh': {
      'originalSnapshotHash': original.canonicalHash.value,
      'currentSnapshotHash': snapshot.canonicalHash.value,
      'additionalRootTextClippings':
          clippings.map((entry) => entry.toJson()).toList(),
      'allOtherInventoryEntriesUnchanged': true,
      'sourceFilesModified': 0,
      'sourceClippingsPreserved': true,
      'eventAndItemWitnessValidationRequired': true,
    },
  };
}
