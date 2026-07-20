import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';
import '../read_models/narrative_dependency_index.dart';

enum NarrativeAssetCloneMode { shallow, deep }

enum NarrativeAssetCloneReferenceDisposition { preserved, rewritten }

@immutable
final class NarrativeAssetCloneReferencePreview {
  const NarrativeAssetCloneReferencePreview({
    required this.before,
    required this.after,
    required this.owner,
    required this.path,
    required this.disposition,
  });

  final NarrativeDependencyKey before;
  final NarrativeDependencyKey after;
  final NarrativeDependencyKey owner;
  final String path;
  final NarrativeAssetCloneReferenceDisposition disposition;
}

@immutable
final class NarrativeAssetClonePlan {
  NarrativeAssetClonePlan({
    required this.sourceProjectIdentity,
    required this.destinationProjectIdentity,
    required this.mode,
    required this.root,
    required Iterable<NarrativeDependencyKey> cloneKeys,
    required Map<NarrativeDependencyKey, String> idRewrites,
    required Map<NarrativeDependencyKey, NarrativeDependencyKey> rewrittenKeys,
    required Iterable<NarrativeAssetCloneReferencePreview> references,
    required Iterable<NarrativeDependencyKey> collisions,
    required Iterable<NarrativeDependencyKey> unresolvedDependencies,
    required Iterable<String> diagnostics,
  })  : cloneKeys = List.unmodifiable(cloneKeys),
        idRewrites = Map.unmodifiable(idRewrites),
        rewrittenKeys = Map.unmodifiable(rewrittenKeys),
        references = List.unmodifiable(references),
        collisions = List.unmodifiable(collisions),
        unresolvedDependencies = List.unmodifiable(unresolvedDependencies),
        diagnostics = List.unmodifiable(diagnostics);

  final String sourceProjectIdentity;
  final String destinationProjectIdentity;
  final NarrativeAssetCloneMode mode;
  final NarrativeDependencyKey root;
  final List<NarrativeDependencyKey> cloneKeys;
  final Map<NarrativeDependencyKey, String> idRewrites;
  final Map<NarrativeDependencyKey, NarrativeDependencyKey> rewrittenKeys;
  final List<NarrativeAssetCloneReferencePreview> references;
  final List<NarrativeDependencyKey> collisions;
  final List<NarrativeDependencyKey> unresolvedDependencies;
  final List<String> diagnostics;

  bool get isCrossProject =>
      sourceProjectIdentity != destinationProjectIdentity;

  bool get canApply =>
      collisions.isEmpty &&
      unresolvedDependencies.isEmpty &&
      diagnostics.isEmpty;
}

NarrativeAssetClonePlan previewNarrativeAssetClone({
  required String sourceProjectIdentity,
  required String destinationProjectIdentity,
  required NarrativeDependencyIndex sourceIndex,
  required NarrativeDependencyIndex destinationIndex,
  required NarrativeDependencyKey root,
  required NarrativeAssetCloneMode mode,
  required String requestedRootId,
  Set<NarrativeDependencyKey> deepCloneDependencies = const {},
  Map<NarrativeDependencyKey, String> requestedDependencyIds = const {},
}) {
  final sourceIdentity = _requiredIdentity(
    sourceProjectIdentity,
    'sourceProjectIdentity',
  );
  final destinationIdentity = _requiredIdentity(
    destinationProjectIdentity,
    'destinationProjectIdentity',
  );
  final diagnostics = <String>[];
  final rootDefinitions = sourceIndex.definitionsFor(root);
  if (rootDefinitions.length != 1) {
    diagnostics.add(
      rootDefinitions.isEmpty
          ? 'The clone root is missing from the source project.'
          : 'The clone root is ambiguous in the source project.',
    );
  }

  final cloneSet = <NarrativeDependencyKey>{root};
  if (mode == NarrativeAssetCloneMode.deep) {
    cloneSet.addAll(deepCloneDependencies);
    var changed = true;
    while (changed) {
      changed = false;
      for (final definition in sourceIndex.definitions) {
        if (definition.owner != null &&
            cloneSet.contains(definition.owner) &&
            cloneSet.add(definition.key)) {
          changed = true;
        }
      }
    }
  } else if (deepCloneDependencies.isNotEmpty ||
      requestedDependencyIds.isNotEmpty) {
    diagnostics.add('A shallow clone cannot rewrite dependency assets.');
  }

  for (final key in cloneSet) {
    final definitions = sourceIndex.definitionsFor(key);
    if (definitions.length != 1 && key != root) {
      diagnostics.add(
        definitions.isEmpty
            ? 'A selected deep dependency is missing: ${_keyLabel(key)}.'
            : 'A selected deep dependency is ambiguous: ${_keyLabel(key)}.',
      );
    }
  }
  for (final key in requestedDependencyIds.keys) {
    if (!cloneSet.contains(key)) {
      diagnostics.add(
        'An id rewrite targets an asset outside the deep clone: '
        '${_keyLabel(key)}.',
      );
    }
  }

  final orderedCloneKeys = cloneSet.toList()..sort(_compareKeys);
  orderedCloneKeys.remove(root);
  orderedCloneKeys.insert(0, root);
  final idRewrites = <NarrativeDependencyKey, String>{};
  final reservedByKind = <NarrativeDependencyTargetKind, Set<String>>{};
  for (final definition in destinationIndex.definitions) {
    reservedByKind
        .putIfAbsent(definition.key.kind, () => <String>{})
        .add(definition.key.id);
  }
  for (final key in orderedCloneKeys) {
    final requested = key == root
        ? requestedRootId.trim()
        : requestedDependencyIds[key]?.trim();
    if (requested != null && requested.isEmpty) {
      diagnostics.add(
        'A cloned asset requires a non-blank id: ${_keyLabel(key)}.',
      );
      continue;
    }
    idRewrites[key] = requested ??
        _freshCloneId(
          key.id,
          reservedByKind.putIfAbsent(key.kind, () => <String>{}),
        );
  }

  final rewrittenKeys = <NarrativeDependencyKey, NarrativeDependencyKey>{};
  for (final key in orderedCloneKeys) {
    final id = idRewrites[key];
    if (id == null) continue;
    rewrittenKeys[key] = _rewriteKey(
      key,
      id: id,
      cloneKeys: orderedCloneKeys,
      idRewrites: idRewrites,
    );
  }

  final collisions = <NarrativeDependencyKey>[];
  final plannedTargets = <NarrativeDependencyKey>{};
  for (final key in rewrittenKeys.values) {
    if (!plannedTargets.add(key) ||
        destinationIndex.definitionsFor(key).isNotEmpty) {
      if (!collisions.contains(key)) collisions.add(key);
    }
  }

  final references = <NarrativeAssetCloneReferencePreview>[];
  final unresolved = <NarrativeDependencyKey>{};
  final referenceIdentities = <String>{};
  for (final owner in orderedCloneKeys) {
    for (final usage in sourceIndex.usagesOwnedBy(owner)) {
      final rewrittenTarget = rewrittenKeys[usage.target];
      final disposition = rewrittenTarget == null
          ? NarrativeAssetCloneReferenceDisposition.preserved
          : NarrativeAssetCloneReferenceDisposition.rewritten;
      final target = rewrittenTarget ?? usage.target;
      final identity = '${_keyLabel(owner)}|${usage.path}|${_keyLabel(target)}';
      if (!referenceIdentities.add(identity)) continue;
      references.add(
        NarrativeAssetCloneReferencePreview(
          before: usage.target,
          after: target,
          owner: rewrittenKeys[owner] ?? owner,
          path: usage.path,
          disposition: disposition,
        ),
      );
      if (disposition == NarrativeAssetCloneReferenceDisposition.preserved &&
          destinationIndex.definitionsFor(usage.target).length != 1) {
        unresolved.add(usage.target);
      }
    }
  }
  references.sort((a, b) {
    final owner = _compareKeys(a.owner, b.owner);
    if (owner != 0) return owner;
    final path = a.path.compareTo(b.path);
    if (path != 0) return path;
    return _compareKeys(a.after, b.after);
  });
  collisions.sort(_compareKeys);
  final unresolvedList = unresolved.toList()..sort(_compareKeys);

  return NarrativeAssetClonePlan(
    sourceProjectIdentity: sourceIdentity,
    destinationProjectIdentity: destinationIdentity,
    mode: mode,
    root: root,
    cloneKeys: orderedCloneKeys,
    idRewrites: idRewrites,
    rewrittenKeys: rewrittenKeys,
    references: references,
    collisions: collisions,
    unresolvedDependencies: unresolvedList,
    diagnostics: diagnostics,
  );
}

@immutable
final class NarrativeAssetClipboardEntry {
  NarrativeAssetClipboardEntry({
    required this.sourceKey,
    required this.destinationKey,
    required Map<String, Object?> payload,
  }) : payload = Map.unmodifiable(payload);

  final NarrativeDependencyKey sourceKey;
  final NarrativeDependencyKey destinationKey;
  final Map<String, Object?> payload;
}

@immutable
final class NarrativeAssetClipboard {
  NarrativeAssetClipboard({
    required this.sourceProjectIdentity,
    required this.root,
    required this.mode,
    required Iterable<NarrativeAssetClipboardEntry> entries,
    required Iterable<NarrativeDependencyKey> preservedDependencies,
    this.schemaVersion = 1,
  })  : entries = List.unmodifiable(entries),
        preservedDependencies = List.unmodifiable(preservedDependencies) {
    if (schemaVersion != 1) {
      throw ArgumentError.value(
        schemaVersion,
        'schemaVersion',
        'Unsupported Narrative clipboard schema.',
      );
    }
    if (entries.isEmpty) {
      throw ArgumentError.value(entries, 'entries', 'Clipboard is empty.');
    }
  }

  factory NarrativeAssetClipboard.fromPlan(
    NarrativeAssetClonePlan plan, {
    required Map<NarrativeDependencyKey, Map<String, Object?>> payloads,
  }) {
    final entries = <NarrativeAssetClipboardEntry>[];
    for (final key in plan.cloneKeys) {
      final payload = payloads[key];
      final destinationKey = plan.rewrittenKeys[key];
      if (payload == null || destinationKey == null) {
        throw ArgumentError.value(
          _keyLabel(key),
          'payloads',
          'Every planned clone requires a typed payload and destination id.',
        );
      }
      entries.add(
        NarrativeAssetClipboardEntry(
          sourceKey: key,
          destinationKey: destinationKey,
          payload: payload,
        ),
      );
    }
    final preserved = <NarrativeDependencyKey>{
      for (final reference in plan.references)
        if (reference.disposition ==
            NarrativeAssetCloneReferenceDisposition.preserved)
          reference.before,
    }.toList()
      ..sort(_compareKeys);
    return NarrativeAssetClipboard(
      sourceProjectIdentity: plan.sourceProjectIdentity,
      root: plan.root,
      mode: plan.mode,
      entries: entries,
      preservedDependencies: preserved,
    );
  }

  final int schemaVersion;
  final String sourceProjectIdentity;
  final NarrativeDependencyKey root;
  final NarrativeAssetCloneMode mode;
  final List<NarrativeAssetClipboardEntry> entries;
  final List<NarrativeDependencyKey> preservedDependencies;
}

@immutable
final class NarrativeAssetClipboardValidation {
  NarrativeAssetClipboardValidation({
    required this.crossProject,
    required Iterable<NarrativeDependencyKey> collisions,
    required Iterable<NarrativeDependencyKey> unresolvedDependencies,
    required Iterable<String> diagnostics,
  })  : collisions = List.unmodifiable(collisions),
        unresolvedDependencies = List.unmodifiable(unresolvedDependencies),
        diagnostics = List.unmodifiable(diagnostics);

  final bool crossProject;
  final List<NarrativeDependencyKey> collisions;
  final List<NarrativeDependencyKey> unresolvedDependencies;
  final List<String> diagnostics;

  bool get canPaste =>
      collisions.isEmpty &&
      unresolvedDependencies.isEmpty &&
      diagnostics.isEmpty;
}

NarrativeAssetClipboardValidation validateNarrativeAssetClipboardPaste(
  NarrativeAssetClipboard clipboard, {
  required String destinationProjectIdentity,
  required NarrativeDependencyIndex destinationIndex,
}) {
  final destinationIdentity = _requiredIdentity(
    destinationProjectIdentity,
    'destinationProjectIdentity',
  );
  final collisions = <NarrativeDependencyKey>[];
  for (final entry in clipboard.entries) {
    if (destinationIndex.definitionsFor(entry.destinationKey).isNotEmpty) {
      collisions.add(entry.destinationKey);
    }
  }
  final unresolved = <NarrativeDependencyKey>[];
  for (final dependency in clipboard.preservedDependencies) {
    if (destinationIndex.definitionsFor(dependency).length != 1) {
      unresolved.add(dependency);
    }
  }
  collisions.sort(_compareKeys);
  unresolved.sort(_compareKeys);
  return NarrativeAssetClipboardValidation(
    crossProject: clipboard.sourceProjectIdentity != destinationIdentity,
    collisions: collisions,
    unresolvedDependencies: unresolved,
    diagnostics: const [],
  );
}

enum NarrativeBulkMutationKind { tag, move, archive }

@immutable
final class NarrativeBulkProjectMutation {
  NarrativeBulkProjectMutation({
    required String operationId,
    required this.kind,
    required this.before,
    required this.after,
    required Iterable<NarrativeDependencyKey> assetKeys,
  })  : operationId = _requiredIdentity(operationId, 'operationId'),
        assetKeys = List.unmodifiable(assetKeys) {
    if (this.assetKeys.isEmpty) {
      throw ArgumentError.value(
        this.assetKeys,
        'assetKeys',
        'A bulk mutation requires at least one asset.',
      );
    }
    if (this.assetKeys.toSet().length != this.assetKeys.length) {
      throw ArgumentError.value(
        this.assetKeys,
        'assetKeys',
        'A bulk mutation cannot contain duplicate assets.',
      );
    }
    if (before == after) {
      throw ArgumentError('A bulk mutation must change the project.');
    }
  }

  final String operationId;
  final NarrativeBulkMutationKind kind;
  final ProjectManifest before;
  final ProjectManifest after;
  final List<NarrativeDependencyKey> assetKeys;

  ProjectManifest apply(ProjectManifest current) {
    if (current != before) {
      throw StateError('Bulk mutation refused because the project changed.');
    }
    return after;
  }

  ProjectManifest undo(ProjectManifest current) {
    if (current != after) {
      throw StateError('Bulk undo refused because the project changed.');
    }
    return before;
  }
}

NarrativeDependencyKey _rewriteKey(
  NarrativeDependencyKey key, {
  required String id,
  required List<NarrativeDependencyKey> cloneKeys,
  required Map<NarrativeDependencyKey, String> idRewrites,
}) {
  var parentId = key.parentId;
  if (parentId != null) {
    for (final parent in cloneKeys) {
      if (parent.id == parentId && idRewrites[parent] != null) {
        parentId = idRewrites[parent];
        break;
      }
    }
  }
  return NarrativeDependencyKey(
    key.kind,
    id,
    scope: key.scope,
    parentId: parentId,
    sourceKind: key.sourceKind,
  );
}

String _freshCloneId(String sourceId, Set<String> reserved) {
  final root = '${sourceId}_copy';
  var candidate = root;
  var suffix = 2;
  while (reserved.contains(candidate)) {
    candidate = '${root}_${suffix++}';
  }
  reserved.add(candidate);
  return candidate;
}

String _requiredIdentity(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be blank.');
  }
  return normalized;
}

int _compareKeys(NarrativeDependencyKey a, NarrativeDependencyKey b) =>
    _keyLabel(a).compareTo(_keyLabel(b));

String _keyLabel(NarrativeDependencyKey key) => [
      key.kind.name,
      key.scope ?? '',
      key.parentId ?? '',
      key.sourceKind ?? '',
      key.id,
    ].join(':');
