import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/models/narrative_event_authoring_session.dart';
import '../../../application/services/narrative_event_validation_coordinator.dart';
import 'narrative_event_validation_state.dart';

/// Immutable cache key for one attested Event Builder project snapshot.
///
/// The semantic fingerprint deliberately changes whenever the in-memory
/// manifest changes. This prevents a successful registry write from leaving
/// the product route attached to an older disk read model.
final class NarrativeEventBuilderV2SnapshotRequest {
  const NarrativeEventBuilderV2SnapshotRequest({
    required this.projectRootPath,
    required this.expectedManifestFingerprint,
  });

  factory NarrativeEventBuilderV2SnapshotRequest.fromProject({
    required String projectRootPath,
    required ProjectManifest project,
  }) {
    return NarrativeEventBuilderV2SnapshotRequest(
      projectRootPath: p.normalize(projectRootPath),
      expectedManifestFingerprint:
          narrativeEventBuilderV2ManifestFingerprint(project),
    );
  }

  final String projectRootPath;
  final String expectedManifestFingerprint;

  @override
  bool operator ==(Object other) {
    return other is NarrativeEventBuilderV2SnapshotRequest &&
        other.projectRootPath == projectRootPath &&
        other.expectedManifestFingerprint == expectedManifestFingerprint;
  }

  @override
  int get hashCode => Object.hash(
        projectRootPath,
        expectedManifestFingerprint,
      );
}

String narrativeEventBuilderV2ManifestFingerprint(ProjectManifest project) {
  return narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(project.toJson()),
  );
}

/// Typed failure used instead of silently falling back to the legacy writer.
final class NarrativeEventBuilderV2SnapshotMismatch implements Exception {
  const NarrativeEventBuilderV2SnapshotMismatch();

  @override
  String toString() =>
      'Le projet en mémoire et le projet enregistré ne correspondent plus.';
}

typedef LoadNarrativeEventBuilderV2ReadModel
    = Future<NarrativeEventBuilderProjectReadModel> Function(
  NarrativeEventBuilderV2SnapshotRequest request,
);

/// Replaceable I/O seam used by the product route and focused widget tests.
///
/// It composes the existing attested session and canonical map_core read model;
/// it owns no registry mutation and therefore cannot become a second engine.
final narrativeEventBuilderV2ReadModelLoaderProvider =
    Provider<LoadNarrativeEventBuilderV2ReadModel>((ref) {
  return (request) async {
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(request.projectRootPath, 'project.json'),
    );
    if (narrativeEventBuilderV2ManifestFingerprint(session.manifest) !=
        request.expectedManifestFingerprint) {
      throw const NarrativeEventBuilderV2SnapshotMismatch();
    }
    return buildNarrativeEventBuilderProjectReadModel(
      project: session.manifest,
      maps: session.maps,
    );
  };
});

final narrativeEventBuilderV2ReadModelProvider = FutureProvider.autoDispose
    .family<NarrativeEventBuilderProjectReadModel,
        NarrativeEventBuilderV2SnapshotRequest>((ref, request) {
  return ref.watch(narrativeEventBuilderV2ReadModelLoaderProvider)(request);
});

typedef LoadNarrativeEventValidationSnapshot
    = Future<NarrativeEventValidationSnapshot> Function(
  NarrativeEventBuilderV2SnapshotRequest request,
);

final narrativeEventValidationSnapshotLoaderProvider =
    Provider<LoadNarrativeEventValidationSnapshot>((ref) {
  const coordinator = NarrativeEventValidationCoordinator();
  String? cachedProjectPath;
  NarrativeEventIncrementalValidationCache? cache;

  return (request) async {
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(request.projectRootPath, 'project.json'),
    );
    if (narrativeEventBuilderV2ManifestFingerprint(session.manifest) !=
        request.expectedManifestFingerprint) {
      throw const NarrativeEventBuilderV2SnapshotMismatch();
    }
    final registry = session.manifest.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        );
    final catalog = buildNarrativeEventProjectCatalog(
      project: session.manifest,
      maps: session.maps,
    );
    // The provider keeps only the latest project cache. It never owns
    // validation rules: the coordinator delegates scoped rebuilding and final
    // ordering to map_core, and falls back to a full rebuild on record-set
    // changes.
    if (cachedProjectPath != request.projectRootPath) {
      cachedProjectPath = request.projectRootPath;
      cache = null;
    }
    final validation = coordinator.rebuildIncrementally(
      registry: registry,
      catalog: catalog,
      previous: cache,
    );
    cache = validation.cache;
    return NarrativeEventValidationSnapshot(
      registry: registry,
      catalog: catalog,
      report: validation.report,
      state: NarrativeEventValidationState.fromReport(validation.report),
      recalculatedEventIds: validation.recalculatedEventIds,
    );
  };
});

final narrativeEventValidationSnapshotProvider = FutureProvider.autoDispose
    .family<NarrativeEventValidationSnapshot,
        NarrativeEventBuilderV2SnapshotRequest>((ref, request) {
  return ref.watch(narrativeEventValidationSnapshotLoaderProvider)(request);
});
