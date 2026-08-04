import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';

final class SmartTilePatternCanonicalSnapshot {
  const SmartTilePatternCanonicalSnapshot({
    required this.revision,
    required this.manifest,
  });

  final String revision;
  final ProjectManifest manifest;
}

abstract interface class SmartTilePatternAuthoringGateway {
  Future<SmartTilePatternCanonicalSnapshot> load({
    required String projectRootPath,
  });

  Future<String> apply({
    required String projectRootPath,
    required String actionId,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  });
}

final class CanonicalSmartTilePatternAuthoringGateway
    implements SmartTilePatternAuthoringGateway {
  const CanonicalSmartTilePatternAuthoringGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  })  : _mutations = mutations,
        _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;

  @override
  Future<SmartTilePatternCanonicalSnapshot> load({
    required String projectRootPath,
  }) async {
    final session = await _queries.open(projectRootPath);
    return SmartTilePatternCanonicalSnapshot(
      revision: session.snapshotRevision,
      manifest: session.manifest,
    );
  }

  @override
  Future<String> apply({
    required String projectRootPath,
    required String actionId,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: actionId,
      parameters: parameters,
      expectedRevision: expectedRevision,
      idempotencyKey: idempotencyKey,
      requestId: idempotencyKey,
    );
    final result = await _mutations.apply(
      plan,
      operationId: '$idempotencyKey-apply',
    );
    return result.snapshotRevision;
  }
}

final class SmartTilePatternAuthoringResult {
  const SmartTilePatternAuthoringResult({
    required this.manifest,
    required this.pattern,
  });

  final ProjectManifest manifest;
  final ProjectSmartTilePattern pattern;
}

final class SmartTilePatternAuthoringServiceException implements Exception {
  const SmartTilePatternAuthoringServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'SmartTilePatternAuthoringServiceException($code): $message';
}

final class SmartTilePatternAuthoringService {
  const SmartTilePatternAuthoringService({
    required SmartTilePatternAuthoringGateway gateway,
  }) : _gateway = gateway;

  final SmartTilePatternAuthoringGateway _gateway;

  Future<SmartTilePatternAuthoringResult> upsert({
    required String projectRootPath,
    required ProjectSmartTilePattern pattern,
  }) async {
    final initial = await _gateway.load(projectRootPath: projectRootPath);
    final fingerprint = computeAuthoringJsonFingerprint(
      <String, Object?>{
        'revision': initial.revision,
        'pattern': pattern.toJson(),
      },
      logicalName: 'smart-tile-pattern-identity.json',
    );
    // Fingerprints are wire values (`sha256:<hex>`), while durable operation
    // identifiers are filesystem-safe opaque tokens. Keep the digest but not
    // its protocol prefix so the real canonical gateway can persist it.
    final identity = 'smart-tile-pattern-${fingerprint.substring(7)}';
    final appliedRevision = await _gateway.apply(
      projectRootPath: projectRootPath,
      actionId: 'smart_tile.pattern.upsert',
      parameters: <String, Object?>{'pattern': pattern.toJson()},
      expectedRevision: initial.revision,
      idempotencyKey: identity,
    );
    final canonical = await _gateway.load(projectRootPath: projectRootPath);
    if (canonical.revision != appliedRevision) {
      throw const SmartTilePatternAuthoringServiceException(
        'smart_tile.pattern.snapshot_stale',
        'Le snapshot canonique du motif est obsolète.',
      );
    }
    final persisted = canonical.manifest.smartTileCatalog.patterns
        .where((candidate) => candidate.id == pattern.id)
        .firstOrNull;
    if (persisted == null ||
        computeAuthoringJsonFingerprint(
              persisted.toJson(),
              logicalName: 'smart-tile-pattern.json',
            ) !=
            computeAuthoringJsonFingerprint(
              pattern.toJson(),
              logicalName: 'smart-tile-pattern.json',
            )) {
      throw const SmartTilePatternAuthoringServiceException(
        'smart_tile.pattern.snapshot_mismatch',
        'Le motif sauvegardé ne correspond pas à la demande.',
      );
    }
    return SmartTilePatternAuthoringResult(
      manifest: canonical.manifest,
      pattern: persisted,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
