import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';

final class SmartTileReconstructionRequest {
  const SmartTileReconstructionRequest({
    required this.mapId,
    required this.sourceLayerId,
    required this.presetId,
    required this.targetLayerId,
    required this.targetLayerName,
  });

  final String mapId;
  final String sourceLayerId;
  final String presetId;
  final String targetLayerId;
  final String targetLayerName;

  Map<String, Object?> toActionParameters() => <String, Object?>{
        'mapId': mapId,
        'sourceLayerId': sourceLayerId,
        'presetId': presetId,
        'targetLayerId': targetLayerId,
        'name': targetLayerName,
      };
}

final class SmartTileReconstructionCanonicalSnapshot {
  const SmartTileReconstructionCanonicalSnapshot({
    required this.snapshotRevision,
    required this.manifest,
    required this.maps,
    required this.mapRevisions,
  });

  final String snapshotRevision;
  final ProjectManifest manifest;
  final List<MapData> maps;
  final Map<String, String> mapRevisions;

  MapData? mapById(String mapId) {
    for (final map in maps) {
      if (map.id == mapId) return map;
    }
    return null;
  }
}

final class SmartTileReconstructionCanonicalPlan {
  SmartTileReconstructionCanonicalPlan({
    required this.token,
    required this.planId,
    required this.snapshotRevision,
    required Map<String, Object?> preview,
  }) : preview = Map<String, Object?>.unmodifiable(preview);

  final Object token;
  final String planId;
  final String snapshotRevision;
  final Map<String, Object?> preview;
}

abstract interface class SmartTileReconstructionGateway {
  Future<SmartTileReconstructionCanonicalSnapshot> load({
    required String projectRootPath,
  });

  Future<SmartTileReconstructionCanonicalPlan> plan({
    required String projectRootPath,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  });

  Future<String> confirmAndApply({
    required SmartTileReconstructionCanonicalPlan plan,
    required String operationId,
  });
}

final class CanonicalSmartTileReconstructionGateway
    implements SmartTileReconstructionGateway {
  const CanonicalSmartTileReconstructionGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  })  : _mutations = mutations,
        _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;

  @override
  Future<SmartTileReconstructionCanonicalSnapshot> load({
    required String projectRootPath,
  }) async {
    final session = await _queries.open(projectRootPath);
    return SmartTileReconstructionCanonicalSnapshot(
      snapshotRevision: session.snapshotRevision,
      manifest: session.manifest,
      maps: session.maps,
      mapRevisions: <String, String>{
        for (final map in session.maps)
          if (session.resourceRevision('map:${map.id}') case final revision?)
            map.id: revision,
      },
    );
  }

  @override
  Future<SmartTileReconstructionCanonicalPlan> plan({
    required String projectRootPath,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: 'smart_tile.layer.reconstruct',
      parameters: parameters,
      expectedRevision: expectedRevision,
      idempotencyKey: idempotencyKey,
      requestId: idempotencyKey,
    );
    return SmartTileReconstructionCanonicalPlan(
      token: plan,
      planId: plan.planId,
      snapshotRevision: plan.snapshotRevision,
      preview: plan.preview,
    );
  }

  @override
  Future<String> confirmAndApply({
    required SmartTileReconstructionCanonicalPlan plan,
    required String operationId,
  }) async {
    final token = plan.token;
    if (token is! EditorAuthoringMutationPlan) {
      throw StateError('The canonical reconstruction plan token is invalid.');
    }
    final confirmationToken = await _mutations.confirm(token);
    final result = await _mutations.apply(
      token,
      operationId: operationId,
      confirmationToken: confirmationToken,
    );
    return result.snapshotRevision;
  }
}

final class SmartTileReconstructionPlan {
  SmartTileReconstructionPlan({
    required this.canonical,
    required this.request,
    required this.sourceLayer,
  });

  final SmartTileReconstructionCanonicalPlan canonical;
  final SmartTileReconstructionRequest request;
  final TileLayer sourceLayer;

  Map<String, Object?> get preview => canonical.preview;
  double get coverage => _number('coverage').toDouble();
  int get sourceCellCount => _integer('sourceCellCount');
  int get reconstructedCellCount => _integer('reconstructedCellCount');
  int get unresolvedCellCount => _integer('unresolvedCellCount');
  int get ambiguousCellCount => _integer('ambiguousCellCount');
  int get conflictCount => _integer('conflictCount');
  int get exactVisualMatchCount => _integer('exactVisualMatchCount');
  int get visualMismatchCellCount => _integer('visualMismatchCellCount');
  bool get sourcePreserved => _boolean('sourcePreserved');
  bool get confirmationRequired => _boolean('confirmationRequired');
  String get assessmentChecksum => _string('assessmentChecksum');

  num _number(String key) {
    final value = preview[key];
    if (value is num) return value;
    throw FormatException('Reconstruction preview field "$key" is invalid.');
  }

  int _integer(String key) {
    final value = preview[key];
    if (value is int) return value;
    throw FormatException('Reconstruction preview field "$key" is invalid.');
  }

  bool _boolean(String key) {
    final value = preview[key];
    if (value is bool) return value;
    throw FormatException('Reconstruction preview field "$key" is invalid.');
  }

  String _string(String key) {
    final value = preview[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Reconstruction preview field "$key" is invalid.');
  }
}

final class SmartTileReconstructionResult {
  const SmartTileReconstructionResult({
    required this.plan,
    required this.snapshot,
    required this.map,
    required this.mapRevision,
  });

  final SmartTileReconstructionPlan plan;
  final SmartTileReconstructionCanonicalSnapshot snapshot;
  final MapData map;
  final String mapRevision;

  ProjectManifest get manifest => snapshot.manifest;
  String get layerId => plan.request.targetLayerId;
}

final class SmartTileReconstructionServiceException implements Exception {
  const SmartTileReconstructionServiceException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SmartTileReconstructionServiceException($code): '
      '$message';
}

/// Two-step no-code assistant over the canonical reconstruction action.
///
/// Planning is read-only. Applying always requests the high-risk confirmation
/// token for that exact revision-bound plan, reloads canonical state, and
/// verifies that the literal source remained byte-for-byte semantic-equal.
final class SmartTileReconstructionService {
  const SmartTileReconstructionService({
    required SmartTileReconstructionGateway gateway,
  }) : _gateway = gateway;

  final SmartTileReconstructionGateway _gateway;

  Future<SmartTileReconstructionPlan> plan({
    required String projectRootPath,
    required SmartTileReconstructionRequest request,
  }) async {
    final snapshot = await _gateway.load(projectRootPath: projectRootPath);
    final map = snapshot.mapById(request.mapId);
    if (map == null) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.map_missing',
        'La map à reconstruire est introuvable.',
      );
    }
    final source = map.layers
        .where((layer) => layer.id == request.sourceLayerId)
        .firstOrNull;
    if (source is! TileLayer || source.purpose != MapLayerPurpose.visual) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.source_invalid',
        'La source doit être une couche de tuiles littérales.',
      );
    }
    if (map.layers.any((layer) => layer.id == request.targetLayerId)) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.target_duplicate',
        'L’identifiant de la couche cible est déjà utilisé.',
      );
    }
    final preset = snapshot.manifest.smartTileCatalog.presets
        .where((candidate) => candidate.id == request.presetId)
        .firstOrNull;
    if (preset == null || preset.status != SmartTilePresetStatus.published) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.preset_unavailable',
        'Choisissez un preset Smart Tile publié.',
      );
    }
    final identityDigest = narrativeEventCanonicalSha256(
      <String, Object?>{
        'revision': snapshot.snapshotRevision,
        'parameters': request.toActionParameters(),
      },
    );
    final identity =
        'smart-tile-reconstruct-${identityDigest.substring(0, 32)}';
    final canonical = await _gateway.plan(
      projectRootPath: projectRootPath,
      parameters: request.toActionParameters(),
      expectedRevision: snapshot.snapshotRevision,
      idempotencyKey: identity,
    );
    final plan = SmartTileReconstructionPlan(
      canonical: canonical,
      request: request,
      sourceLayer: source,
    );
    // Eagerly validate the complete preview contract before it reaches UI.
    plan
      ..coverage
      ..sourceCellCount
      ..reconstructedCellCount
      ..unresolvedCellCount
      ..ambiguousCellCount
      ..conflictCount
      ..exactVisualMatchCount
      ..visualMismatchCellCount
      ..sourcePreserved
      ..confirmationRequired
      ..assessmentChecksum;
    return plan;
  }

  Future<SmartTileReconstructionResult> apply(
    SmartTileReconstructionPlan plan, {
    required String projectRootPath,
  }) async {
    final appliedRevision = await _gateway.confirmAndApply(
      plan: plan.canonical,
      operationId: '${plan.canonical.planId}-apply',
    );
    final snapshot = await _gateway.load(projectRootPath: projectRootPath);
    if (snapshot.snapshotRevision != appliedRevision) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.snapshot_stale',
        'Le snapshot canonique rechargé est obsolète.',
      );
    }
    final map = snapshot.mapById(plan.request.mapId);
    if (map == null) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.map_missing_after_apply',
        'La map reconstruite est absente du snapshot canonique.',
      );
    }
    final source = map.layers
        .where((layer) => layer.id == plan.request.sourceLayerId)
        .firstOrNull;
    if (source != plan.sourceLayer) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.source_changed',
        'La transaction n’a pas conservé la couche littérale à l’identique.',
      );
    }
    final target = map.layers
        .where((layer) => layer.id == plan.request.targetLayerId)
        .firstOrNull;
    if (target is! SmartTileLayer || target.isVisible) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.target_missing_after_apply',
        'La couche Smart Tile reconstruite et masquée est introuvable.',
      );
    }
    final mapRevision = snapshot.mapRevisions[map.id];
    if (mapRevision == null) {
      throw const SmartTileReconstructionServiceException(
        'smart_tile.reconstruction.map_revision_missing',
        'La révision canonique de la map est indisponible.',
      );
    }
    return SmartTileReconstructionResult(
      plan: plan,
      snapshot: snapshot,
      map: map,
      mapRevision: mapRevision,
    );
  }
}
