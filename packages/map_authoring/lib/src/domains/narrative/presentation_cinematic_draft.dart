import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/authoring_request.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../workspace/project_snapshot.dart';
import '../assets/project_media_store.dart';
import '../maps/map_lifecycle_adapter.dart';
import 'presentation_cinematic_actions.dart';
import 'scene_actions.dart';

final class PresentationCinematicDraftException implements Exception {
  const PresentationCinematicDraftException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'PresentationCinematicDraftException($code): $message';
}

/// Scene actions the Presentation Studio may run on its own draft.
///
/// Deliberately a short, explicit list: widening it is an architectural
/// decision, not a convenience (BETA-CIN-079).
const _sceneActionIds = <String>{'scene.presentation.cue.routes.set'};

final class PresentationCinematicDraft {
  PresentationCinematicDraft._(this._snapshot);

  factory PresentationCinematicDraft.fromSnapshot(
    ProjectSnapshot snapshot, {
    required ProjectManifest expectedProject,
    bool allowProjectedProject = false,
  }) {
    if (snapshot.manifest != expectedProject && !allowProjectedProject) {
      throw const PresentationCinematicDraftException(
        'presentation_draft.stale',
        'The visible project does not match the authoring snapshot.',
      );
    }
    final projectBytes = snapshot.manifest == expectedProject
        ? snapshot.resourceBytes('project')
        : encodeProjectAuthoringDocument(snapshot, expectedProject);
    return PresentationCinematicDraft._(
      _compactSnapshot(
        snapshot,
        manifest: expectedProject,
        projectBytes: projectBytes,
      ),
    );
  }

  ProjectSnapshot _snapshot;

  ProjectManifest get manifest => _snapshot.manifest;

  ProjectManifest adopt(ProjectManifest manifest) {
    final projectBytes = encodeProjectAuthoringDocument(_snapshot, manifest);
    _snapshot = _snapshotWithProject(
      _snapshot,
      manifest: manifest,
      projectBytes: projectBytes,
    );
    return manifest;
  }

  ProjectManifest apply({
    required String actionId,
    required Map<String, Object?> parameters,
    required String operationId,
  }) {
    final normalizedOperationId = operationId.trim();
    if (normalizedOperationId.isEmpty || normalizedOperationId != operationId) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'must be nonblank and trimmed',
      );
    }
    final context = AuthoringPlanningContext(
      snapshot: _snapshot,
      request: AuthoringRequest(
        requestId: normalizedOperationId,
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'workspace-presentation-draft',
        parameters: parameters,
        expectedRevision: _snapshot.revision,
        idempotencyKey: normalizedOperationId,
      ),
      planId: 'plan-$normalizedOperationId',
      seed: 0,
    );
    // The Studio authors two things: the Presentation document, and the cue
    // branches that hang off its markers — which live on the Scene side of
    // the BETA-CIN-068 boundary. Scene actions are admitted for that reason
    // only; the single-project.json invariant below still fences them in.
    final draft = _sceneActionIds.contains(actionId)
        ? const SceneActions().build(context)
        : const PresentationCinematicActions().build(context);
    final changes = draft.changeSet.changes;
    if (changes.length != 1 ||
        changes.single.storageKey != 'project.json' ||
        changes.single.afterBytes == null) {
      throw const PresentationCinematicDraftException(
        'presentation_draft.change_set_invalid',
        'A Presentation draft action must only project project.json.',
      );
    }
    final projectBytes = changes.single.afterBytes!;
    // The action already built the projected manifest. Re-parsing the bytes it
    // just serialised costs a full utf8 + JSON + fromJson pass over the whole
    // project — hundreds of milliseconds of frozen UI per edit on a real
    // project. Decoding stays the fallback for an action that only projects
    // bytes.
    final projected =
        draft.projectedProject ?? _decodeProject(projectBytes);
    _snapshot = _snapshotWithProject(
      _snapshot,
      manifest: projected,
      projectBytes: projectBytes,
    );
    return projected;
  }
}

ProjectSnapshot _compactSnapshot(
  ProjectSnapshot source, {
  required ProjectManifest manifest,
  required List<int> projectBytes,
}) {
  return _draftSnapshot(
    source,
    manifest: manifest,
    projectBytes: projectBytes,
    mediaBytes: source.findResourceBytes(projectMediaCatalogResourceIdentity),
  );
}

ProjectSnapshot _snapshotWithProject(
  ProjectSnapshot source, {
  required ProjectManifest manifest,
  required List<int> projectBytes,
}) =>
    _draftSnapshot(
      source,
      manifest: manifest,
      projectBytes: projectBytes,
      mediaBytes: source.findResourceBytes(projectMediaCatalogResourceIdentity),
    );

ProjectSnapshot _draftSnapshot(
  ProjectSnapshot source, {
  required ProjectManifest manifest,
  required List<int> projectBytes,
  required List<int>? mediaBytes,
}) {
  final bytesByIdentity = <String, List<int>>{'project': projectBytes};
  final storageKeys = <String, String>{
    'project': source.resourceStorageKeys['project'] ?? 'project.json',
  };
  if (mediaBytes != null) {
    bytesByIdentity[projectMediaCatalogResourceIdentity] = mediaBytes;
    storageKeys[projectMediaCatalogResourceIdentity] =
        source.resourceStorageKeys[projectMediaCatalogResourceIdentity] ??
            projectMediaCatalogStorageKey;
  }
  final orderedIdentities = storageKeys.keys.toList()
    ..sort(
      (left, right) => storageKeys[left]!.compareTo(storageKeys[right]!),
    );
  return ProjectSnapshot(
    projectHandle: source.projectHandle,
    revision:
        computeNarrativeProjectFingerprint(<NarrativeProjectFingerprintEntry>[
      for (final identity in orderedIdentities)
        NarrativeProjectFingerprintEntry(
          relativePath: storageKeys[identity]!,
          bytes: bytesByIdentity[identity]!,
        ),
    ]),
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{
      for (final identity in orderedIdentities)
        identity: computeAuthoringBytesFingerprint(
          bytesByIdentity[identity]!,
          logicalName: storageKeys[identity]!,
        ),
    },
    resourceBytes: bytesByIdentity,
    resourceStorageKeys: storageKeys,
  );
}

ProjectManifest _decodeProject(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    return ProjectManifest.fromJson(Map<String, dynamic>.from(decoded));
  } on Object catch (error) {
    throw PresentationCinematicDraftException(
      'presentation_draft.project_invalid',
      'The projected project manifest is invalid: $error',
    );
  }
}
