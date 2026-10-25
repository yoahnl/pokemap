import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_diff.dart';
import '../../contracts/map_authoring_exception.dart';
import '../../contracts/resource_ref.dart';
import '../../ports/project_file_reader.dart';
import '../../ports/transaction_file_gateway.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';

const mapAtmosphereGuardsKey = 'mapAtmosphereGuards';
const mapAtmosphereLifecycleActions = {
  'map.create',
  'map.duplicate',
  'map.rename',
  'map.delete_apply',
};

typedef MapAtmosphereResourceProbe = Future<ProjectResourceProbe> Function(
  String path,
);

Future<AuthoringMutationDraft> includeMapLifecycleAtmosphere(
  AuthoringPlanningContext context,
  AuthoringMutationDraft draft, {
  required Future<List<int>?> Function(String) readResource,
  required MapAtmosphereResourceProbe probeResource,
}) async {
  for (final document in _LifecycleDocument.values) {
    draft = await _includeMapLifecycleDocument(
      context,
      draft,
      document: document,
      readResource: readResource,
      probeResource: probeResource,
    );
  }
  return draft;
}

Future<AuthoringMutationDraft> _includeMapLifecycleDocument(
  AuthoringPlanningContext context,
  AuthoringMutationDraft draft, {
  required Future<List<int>?> Function(String) readResource,
  required MapAtmosphereResourceProbe probeResource,
  required _LifecycleDocument document,
}) async {
  final action = context.request.actionId;
  if (!mapAtmosphereLifecycleActions.contains(action)) return draft;
  final parameters = context.request.parameters;
  final sourceId = switch (action) {
    'map.duplicate' => parameters['sourceMapId'] as String,
    'map.rename' || 'map.delete_apply' => parameters['mapId'] as String,
    _ => null,
  };
  final targetId = switch (action) {
    'map.create' || 'map.duplicate' => draft.preview['mapId'] as String,
    'map.rename' => parameters['newMapId'] as String,
    _ => null,
  };
  final guards = <Map<String, Object?>>[];
  final changes = <AuthoringResourceChange>[];
  final diff = <AuthoringDiffEntry>[];
  Map<String, dynamic>? source;
  List<int>? sourceBytes;
  if (sourceId != null) {
    final path = document.path(sourceId);
    final probe = await probeResource(path);
    _requireSafeProbe(probe, document);
    if (probe.status == ProjectResourceProbeStatus.exists) {
      sourceBytes = await readResource(path);
      if (sourceBytes == null || sourceBytes.length > document.maximumBytes) {
        throw _failure(
          'map.${document.name}_changed',
          'The map ${document.name} changed while preparing its lifecycle operation.',
        );
      }
      try {
        source = document.decode(sourceBytes);
        if (source['mapId'] != sourceId) {
          throw const FormatException('Map sidecar identity mismatch.');
        }
      } on Object {
        throw _failure(
          'map.${document.name}_invalid',
          'The map ${document.name} must be repaired before this lifecycle operation.',
        );
      }
    }
    if (source == null || action == 'map.duplicate') {
      guards.add({
        'mapId': sourceId,
        'revision': sourceBytes == null
            ? null
            : computeAuthoringBytesFingerprint(sourceBytes, logicalName: path),
      });
    }
    if (source != null && action != 'map.duplicate') {
      final resource = AuthoringResourceRef(
        kind: document.resourceKind,
        id: sourceId,
      );
      changes.add(
        AuthoringResourceChange(
          resource: resource,
          storageKey: path,
          beforeBytes: sourceBytes,
          afterBytes: null,
        ),
      );
      diff.add(
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.remove,
          resource: resource,
          path: '/',
          before: source,
        ),
      );
    }
  }
  if (targetId != null) {
    final path = document.path(targetId);
    final probe = await probeResource(path);
    _requireSafeProbe(probe, document);
    if (probe.status != ProjectResourceProbeStatus.missing) {
      throw _failure(
        'map.${document.name}_orphan_conflict',
        'An ${document.name} document already owns this destination map identity. Preserve or move it before creating this map.',
      );
    }
    if (source == null) {
      guards.add({'mapId': targetId, 'revision': null});
    } else {
      final target = {...source, 'mapId': targetId};
      final bytes = utf8.encode(jsonEncode(target));
      if (bytes.length > document.maximumBytes) {
        throw _failure(
          'map.${document.name}_invalid',
          'The destination ${document.name} exceeds its document limit.',
        );
      }
      final resource = AuthoringResourceRef(
        kind: document.resourceKind,
        id: targetId,
      );
      changes.add(
        AuthoringResourceChange(
          resource: resource,
          storageKey: path,
          beforeBytes: null,
          afterBytes: bytes,
        ),
      );
      diff.add(
        AuthoringDiffEntry(
          operation: AuthoringDiffOperation.add,
          resource: resource,
          path: '/',
          after: target,
        ),
      );
    }
  }
  final entries = draft.changeSet.diff.entries.toList();
  if (guards.isNotEmpty) {
    final first = entries.first;
    entries[0] = AuthoringDiffEntry.fromJson({
      ...first.toJson(),
      'extensions': {...first.extensions, document.guardKey: guards},
    });
  }
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [...draft.changeSet.changes, ...changes],
      diff: AuthoringDiff([...entries, ...diff]),
    ),
    projectedProject: draft.projectedProject,
    preview: {
      ...draft.preview,
      '${document.name}ChangedDocuments': changes.length,
    },
    referenceImpact: draft.referenceImpact,
    artifacts: draft.artifacts,
  );
}

Future<void> requireMapLifecycleAtmosphereGuards(
  AuthoringDiff diff, {
  required TransactionFileGateway gateway,
  required MapAtmosphereResourceProbe probeResource,
}) async {
  for (final document in _LifecycleDocument.values) {
    await _requireMapLifecycleDocumentGuards(
      diff,
      document: document,
      gateway: gateway,
      probeResource: probeResource,
    );
  }
}

Future<void> _requireMapLifecycleDocumentGuards(
  AuthoringDiff diff, {
  required TransactionFileGateway gateway,
  required MapAtmosphereResourceProbe probeResource,
  required _LifecycleDocument document,
}) async {
  var count = 0;
  for (final entry in diff.entries) {
    final raw = entry.extensions[document.guardKey];
    if (raw == null) continue;
    if (raw is! List || (count += raw.length) > 2) {
      throw _failure(
        'map.${document.name}_guard_invalid',
        'Invalid lifecycle ${document.name} guards.',
      );
    }
    for (final item in raw) {
      if (item is! Map ||
          item.length != 2 ||
          item['mapId'] is! String ||
          !item.containsKey('revision')) {
        throw _failure(
          'map.${document.name}_guard_invalid',
          'Invalid lifecycle ${document.name} guard.',
        );
      }
      final expected = item['revision'];
      if (expected != null &&
          (expected is! String ||
              !RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(expected))) {
        throw _failure(
          'map.${document.name}_guard_invalid',
          'Invalid lifecycle ${document.name} revision.',
        );
      }
      final path = document.path(item['mapId'] as String);
      final probe = await probeResource(path);
      _requireSafeProbe(probe, document);
      final actual = probe.status == ProjectResourceProbeStatus.missing
          ? null
          : await gateway.readResourceRevision(path);
      if (actual != expected) {
        throw _failure(
          'map.${document.name}_changed',
          'The map ${document.name} changed after lifecycle preparation. Preserve the current document and prepare the operation again.',
        );
      }
    }
  }
}

void _requireSafeProbe(
  ProjectResourceProbe probe,
  _LifecycleDocument document,
) {
  if (probe.status != ProjectResourceProbeStatus.missing &&
      (probe.status != ProjectResourceProbeStatus.exists ||
          probe.identity!.byteLength > document.maximumBytes)) {
    throw _failure(
      'map.${document.name}_invalid',
      'The map ${document.name} is unsafe or exceeds its document limit.',
    );
  }
}

MapAuthoringException _failure(String code, String message) =>
    MapAuthoringException(code: code, message: message);

enum _LifecycleDocument {
  atmosphere,
  editor;

  String get resourceKind => switch (this) {
    atmosphere => 'mapAtmosphere',
    editor => 'mapEditor',
  };

  String get guardKey => switch (this) {
    atmosphere => mapAtmosphereGuardsKey,
    editor => 'mapEditorGuards',
  };

  int get maximumBytes => switch (this) {
    atmosphere => SpatialAtmosphereDocument.maxBytes,
    editor => MapEditorDocument.maxBytes,
  };

  String path(String mapId) => switch (this) {
    atmosphere => SpatialAtmosphereDocument.relativePathForMap(mapId),
    editor => MapEditorDocument.relativePathForMap(mapId),
  };

  Map<String, dynamic> decode(List<int> bytes) {
    final json = Map<String, dynamic>.from(
      decodeNarrativeEventJsonStrict(utf8.decode(bytes)) as Map,
    );
    return switch (this) {
      atmosphere => SpatialAtmosphereDocument.fromJson(json).toJson(),
      editor => MapEditorDocument.fromJson(json).toJson(),
    };
  }
}
