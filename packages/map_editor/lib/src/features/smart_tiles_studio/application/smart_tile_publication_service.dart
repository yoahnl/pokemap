import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/authoring_mutation_adapter.dart';
import '../../../application/authoring_api/authoring_query_adapter.dart';

enum SmartTilePublicationTargetKind { library, map }

sealed class SmartTilePublicationTarget {
  const SmartTilePublicationTarget();

  const factory SmartTilePublicationTarget.library() =
      SmartTileLibraryPublicationTarget;

  const factory SmartTilePublicationTarget.map({
    required String mapId,
    required String layerId,
    required String layerName,
  }) = SmartTileMapPublicationTarget;

  SmartTilePublicationTargetKind get kind => switch (this) {
        SmartTileLibraryPublicationTarget() =>
          SmartTilePublicationTargetKind.library,
        SmartTileMapPublicationTarget() => SmartTilePublicationTargetKind.map,
      };
}

final class SmartTileLibraryPublicationTarget
    extends SmartTilePublicationTarget {
  const SmartTileLibraryPublicationTarget();
}

final class SmartTileMapPublicationTarget extends SmartTilePublicationTarget {
  const SmartTileMapPublicationTarget({
    required this.mapId,
    required this.layerId,
    required this.layerName,
  });

  final String mapId;
  final String layerId;
  final String layerName;
}

final class SmartTilePublicationCanonicalPlan {
  const SmartTilePublicationCanonicalPlan({
    required this.token,
    required this.planId,
    required this.snapshotRevision,
    required this.receipt,
  });

  final Object token;
  final String planId;
  final String snapshotRevision;
  final AuthoringReceipt receipt;
}

final class SmartTilePublicationCanonicalSnapshot {
  const SmartTilePublicationCanonicalSnapshot({
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

abstract interface class SmartTilePublicationGateway {
  Future<SmartTilePublicationCanonicalSnapshot> load({
    required String projectRootPath,
  });

  Future<SmartTilePublicationCanonicalPlan> plan({
    required String projectRootPath,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  });

  Future<String> apply({
    required SmartTilePublicationCanonicalPlan plan,
    required String operationId,
  });
}

final class CanonicalSmartTilePublicationGateway
    implements SmartTilePublicationGateway {
  const CanonicalSmartTilePublicationGateway({
    required AuthoringMutationAdapter mutations,
    required AuthoringQueryAdapter queries,
  })  : _mutations = mutations,
        _queries = queries;

  final AuthoringMutationAdapter _mutations;
  final AuthoringQueryAdapter _queries;

  @override
  Future<SmartTilePublicationCanonicalSnapshot> load({
    required String projectRootPath,
  }) async {
    final session = await _queries.open(projectRootPath);
    return SmartTilePublicationCanonicalSnapshot(
      snapshotRevision: session.snapshotRevision,
      manifest: session.manifest,
      maps: session.maps,
      mapRevisions: <String, String>{
        for (final map in session.maps)
          map.id: ?session.resourceRevision('map:${map.id}'),
      },
    );
  }

  @override
  Future<SmartTilePublicationCanonicalPlan> plan({
    required String projectRootPath,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    final plan = await _mutations.plan(
      projectRootPath,
      actionId: 'smart_tile.preset.publish',
      parameters: parameters,
      expectedRevision: expectedRevision,
      idempotencyKey: idempotencyKey,
      requestId: idempotencyKey,
    );
    return SmartTilePublicationCanonicalPlan(
      token: plan,
      planId: plan.planId,
      snapshotRevision: plan.snapshotRevision,
      receipt: plan.receipt,
    );
  }

  @override
  Future<String> apply({
    required SmartTilePublicationCanonicalPlan plan,
    required String operationId,
  }) async {
    final token = plan.token;
    if (token is! EditorAuthoringMutationPlan) {
      throw StateError('The canonical publication plan token is invalid.');
    }
    final result = await _mutations.apply(
      token,
      operationId: operationId,
    );
    return result.snapshotRevision;
  }
}

final class SmartTilePublicationPlan {
  SmartTilePublicationPlan({
    required this.canonical,
    required this.target,
    required this.draftId,
    required this.presetId,
    required Iterable<SmartTileDiagnostic> warnings,
  }) : warnings = List.unmodifiable(warnings);

  final SmartTilePublicationCanonicalPlan canonical;
  final SmartTilePublicationTarget target;
  final String draftId;
  final String presetId;
  final List<SmartTileDiagnostic> warnings;

  String get planId => canonical.planId;

  String? get layerId => switch (target) {
        SmartTileMapPublicationTarget(:final layerId) => layerId,
        SmartTileLibraryPublicationTarget() => null,
      };

  Map<String, Object?> get preview {
    final value = canonical.receipt.extensions['preview'];
    return value is Map
        ? Map<String, Object?>.unmodifiable(Map<String, Object?>.from(value))
        : const <String, Object?>{};
  }

  List<AuthoringResourceRef> get affectedResources =>
      canonical.receipt.affectedResources;
}

final class SmartTilePublicationResult {
  const SmartTilePublicationResult({
    required this.plan,
    required this.snapshot,
    required this.map,
    required this.mapRevision,
  });

  final SmartTilePublicationPlan plan;
  final SmartTilePublicationCanonicalSnapshot snapshot;
  final MapData? map;
  final String? mapRevision;

  ProjectManifest get manifest => snapshot.manifest;
  String? get layerId => plan.layerId;
}

final class SmartTilePresetDuplicationResult {
  const SmartTilePresetDuplicationResult({
    required this.preset,
    required this.snapshot,
  });

  final ProjectSmartTilePreset preset;
  final SmartTilePublicationCanonicalSnapshot snapshot;
}

final class SmartTilePublicationException implements Exception {
  const SmartTilePublicationException(
    this.code,
    this.message, {
    this.diagnostics = const <SmartTileDiagnostic>[],
  });

  final String code;
  final String message;
  final List<SmartTileDiagnostic> diagnostics;

  @override
  String toString() => 'SmartTilePublicationException($code): $message';
}

/// Guided plan/apply publication over the canonical map_authoring action.
///
/// The service never edits a manifest or map locally. It flushes the durable
/// draft, plans against one revision, applies that exact plan, then reloads the
/// authoritative snapshot for editor adoption.
final class SmartTilePublicationService {
  const SmartTilePublicationService(
      {required SmartTilePublicationGateway gateway})
      : _gateway = gateway;

  final SmartTilePublicationGateway _gateway;

  Future<SmartTilePublicationPlan> plan({
    required String projectRootPath,
    required String draftId,
    required String presetId,
    required SmartTilePublicationTarget target,
    required Future<void> Function() flushDraft,
    Iterable<SmartTileDiagnostic> diagnostics = const <SmartTileDiagnostic>[],
  }) async {
    final diagnosticList = List<SmartTileDiagnostic>.unmodifiable(diagnostics);
    final blocking = diagnosticList.where((diagnostic) => diagnostic.isError);
    if (blocking.isNotEmpty) {
      throw SmartTilePublicationException(
        'smart_tile.publish.incomplete',
        'Le Smart Tile contient des erreurs bloquantes.',
        diagnostics: List.unmodifiable(blocking),
      );
    }
    await flushDraft();
    final snapshot = await _gateway.load(projectRootPath: projectRootPath);
    final canonicalDraft = snapshot.manifest.smartTileCatalog.drafts
        .where((draft) => draft.id == draftId)
        .firstOrNull;
    if (canonicalDraft == null) {
      throw const SmartTilePublicationException(
        'smart_tile.draft.unknown',
        'Le brouillon Smart Tile sauvegardé est introuvable.',
      );
    }
    if (canonicalDraft.targetPresetId != presetId) {
      throw const SmartTilePublicationException(
        'smart_tile.draft.target_conflict',
        'La cible du brouillon a changé depuis son ouverture.',
      );
    }
    final parameters = <String, Object?>{'draftId': draftId};
    if (target
        case SmartTileMapPublicationTarget(
          :final mapId,
          :final layerId,
          :final layerName,
        )) {
      parameters['layer'] = <String, Object?>{
        'mapId': mapId,
        'layerId': _nonBlank(layerId, 'layerId'),
        'name': _nonBlank(layerName, 'layerName'),
      };
    }
    final identity = _publicationIdentity(
      draftId: draftId,
      revision: snapshot.snapshotRevision,
      target: target,
    );
    final canonical = await _gateway.plan(
      projectRootPath: projectRootPath,
      parameters: parameters,
      expectedRevision: snapshot.snapshotRevision,
      idempotencyKey: identity,
    );
    return SmartTilePublicationPlan(
      canonical: canonical,
      target: target,
      draftId: draftId,
      presetId: presetId,
      warnings: diagnosticList.where((diagnostic) => !diagnostic.isError),
    );
  }

  Future<SmartTilePublicationResult> apply(
    SmartTilePublicationPlan plan, {
    required String projectRootPath,
  }) async {
    final appliedRevision = await _gateway.apply(
      plan: plan.canonical,
      operationId: '${plan.canonical.planId}-apply',
    );
    final snapshot = await _gateway.load(projectRootPath: projectRootPath);
    if (snapshot.snapshotRevision != appliedRevision) {
      throw const SmartTilePublicationException(
        'smart_tile.publish.snapshot_stale',
        'Le snapshot canonique chargé après publication est obsolète.',
      );
    }
    MapData? map;
    String? mapRevision;
    if (plan.target
        case SmartTileMapPublicationTarget(
          :final mapId,
          :final layerId,
        )) {
      map = snapshot.mapById(mapId);
      if (map == null || !map.layers.any((layer) => layer.id == layerId)) {
        throw const SmartTilePublicationException(
          'smart_tile.publish.layer_missing_after_apply',
          'La couche publiée est absente du snapshot canonique.',
        );
      }
      mapRevision = snapshot.mapRevisions[mapId];
      if (mapRevision == null) {
        throw const SmartTilePublicationException(
          'smart_tile.publish.map_revision_missing',
          'La révision canonique de la map publiée est indisponible.',
        );
      }
    }
    return SmartTilePublicationResult(
      plan: plan,
      snapshot: snapshot,
      map: map,
      mapRevision: mapRevision,
    );
  }

  /// Publie un preset déjà existant en remplaçant son contenu.
  ///
  /// C'est la seconde forme de `smart_tile.preset.publish` : elle prend le
  /// preset complet au lieu d'un brouillon, et sert à modifier un preset
  /// publié sans repasser par l'assistant — par exemple pour réécrire les
  /// poids de ses variantes. Renvoie le snapshot canonique rechargé après
  /// l'application afin que les transports éditeur adoptent exactement l'état
  /// publié.
  Future<SmartTilePublicationCanonicalSnapshot> publishPreset({
    required String projectRootPath,
    required ProjectSmartTilePreset preset,
  }) async {
    final snapshot = await _gateway.load(projectRootPath: projectRootPath);
    return _publishPresetFromSnapshot(
      projectRootPath: projectRootPath,
      preset: preset,
      snapshot: snapshot,
    );
  }

  Future<SmartTilePresetDuplicationResult> duplicatePreset({
    required String projectRootPath,
    required ProjectSmartTilePreset preset,
  }) async {
    final snapshot = await _gateway.load(projectRootPath: projectRootPath);
    final presets = snapshot.manifest.smartTileCatalog.presets;
    final duplicate = preset.copyWith(
      id: suggestPresetId(
        sourceId: preset.id,
        existingPresetIds: presets.map((candidate) => candidate.id),
      ),
      name: suggestPresetCopyName(
        sourceName: preset.name,
        existingPresetNames: presets.map((candidate) => candidate.name),
      ),
      status: SmartTilePresetStatus.published,
    );
    final canonical = await _publishPresetFromSnapshot(
      projectRootPath: projectRootPath,
      preset: duplicate,
      snapshot: snapshot,
    );
    if (!canonical.manifest.smartTileCatalog.presets
        .any((candidate) => candidate.id == duplicate.id)) {
      throw const SmartTilePublicationException(
        'smart_tile.publish.duplicate_missing_after_apply',
        'La copie est absente du snapshot canonique après publication.',
      );
    }
    return SmartTilePresetDuplicationResult(
      preset: duplicate,
      snapshot: canonical,
    );
  }

  Future<SmartTilePublicationCanonicalSnapshot> _publishPresetFromSnapshot({
    required String projectRootPath,
    required ProjectSmartTilePreset preset,
    required SmartTilePublicationCanonicalSnapshot snapshot,
  }) async {
    final payload = preset.toJson();
    // La révision fait partie de l'identité de la requête : sans elle, revenir
    // à une table déjà appliquée rejoue la même clé sur une charge différente
    // et le journal d'idempotence la refuse.
    final fingerprint = sha256
        .convert(
          utf8.encode('${snapshot.snapshotRevision}|${jsonEncode(payload)}'),
        )
        .toString()
        .substring(0, 20);
    final plan = await _gateway.plan(
      projectRootPath: projectRootPath,
      parameters: <String, Object?>{'preset': payload},
      expectedRevision: snapshot.snapshotRevision,
      idempotencyKey: 'smart-tile-preset-publish-$fingerprint',
    );
    final appliedRevision = await _gateway.apply(
      plan: plan,
      operationId: 'smart-tile-preset-publish-$fingerprint',
    );
    final canonical = await _gateway.load(projectRootPath: projectRootPath);
    if (canonical.snapshotRevision != appliedRevision) {
      throw const SmartTilePublicationException(
        'smart_tile.publish.snapshot_stale',
        'Le snapshot canonique chargé après publication est obsolète.',
      );
    }
    return canonical;
  }

  static String suggestPresetId({
    required String sourceId,
    required Iterable<String> existingPresetIds,
  }) {
    final stem = _identifier('${sourceId}_copy', fallback: 'smart_tile_copy');
    return _suggestUniqueValue(stem: stem, existingValues: existingPresetIds);
  }

  static String suggestPresetCopyName({
    required String sourceName,
    required Iterable<String> existingPresetNames,
  }) {
    final stem = '${sourceName.trim()} — copie';
    return _suggestUniqueValue(stem: stem, existingValues: existingPresetNames);
  }

  static String suggestLayerId({
    required String presetId,
    required Iterable<String> existingLayerIds,
  }) {
    final stem = _identifier('${presetId}_layer', fallback: 'smart_tile_layer');
    final existing = existingLayerIds.toSet();
    if (!existing.contains(stem)) return stem;
    var suffix = 2;
    while (existing.contains('${stem}_$suffix')) {
      suffix++;
    }
    return '${stem}_$suffix';
  }
}

String _publicationIdentity({
  required String draftId,
  required String revision,
  required SmartTilePublicationTarget target,
}) {
  final digest = computeAuthoringJsonFingerprint(
    <String, Object?>{
      'draftId': draftId,
      'revision': revision,
      'target': switch (target) {
        SmartTileLibraryPublicationTarget() => const <String, Object?>{
            'kind': 'library'
          },
        SmartTileMapPublicationTarget(:final mapId, :final layerId) =>
          <String, Object?>{
            'kind': 'map',
            'mapId': mapId,
            'layerId': layerId,
          },
      },
    },
    logicalName: 'smart-tile-publication-identity.json',
  );
  return 'smart-tile-publish-${digest.substring('sha256:'.length, 39)}';
}

String _identifier(String value, {required String fallback}) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[_-]+|[_-]+$'), '');
  return normalized.isEmpty ? fallback : normalized;
}

String _suggestUniqueValue({
  required String stem,
  required Iterable<String> existingValues,
}) {
  final existing = existingValues.toSet();
  if (!existing.contains(stem)) return stem;
  var suffix = 2;
  while (existing.contains('$stem $suffix') ||
      existing.contains('${stem}_$suffix')) {
    suffix++;
  }
  final separator = stem.contains(' — ') ? ' ' : '_';
  return '$stem$separator$suffix';
}

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw SmartTilePublicationException(
      'smart_tile.publish.identity_invalid',
      '$field ne peut pas être vide.',
    );
  }
  return normalized;
}
