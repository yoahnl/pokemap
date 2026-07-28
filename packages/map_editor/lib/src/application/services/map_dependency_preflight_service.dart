import 'package:map_core/map_core.dart';

import '../../domain/repositories/repositories.dart';
import '../ports/project_workspace.dart';

/// Destructive map lifecycle operations protected by the DS-04 preflight.
enum MapDependencyPreflightOperation {
  rename,
  delete,
}

/// Why one declared map could not participate in the dependency index.
enum MapDependencyIndexIssueKind {
  duplicateManifestId,
  unreadableMap,
  identityMismatch,
  missingTargetDefinition,
  ambiguousTargetDefinition,
}

/// Stable, user-presentable evidence that the dependency index is incomplete.
final class MapDependencyIndexIssue {
  const MapDependencyIndexIssue({
    required this.kind,
    required this.mapId,
    required this.relativePath,
    required this.message,
  });

  final MapDependencyIndexIssueKind kind;
  final String mapId;
  final String relativePath;
  final String message;
}

/// Immutable DS-04 decision returned to both lifecycle code and presentation.
///
/// [inspection] is retained even when loading is incomplete. It lets the UI
/// show already-known usages without ever presenting that partial list as
/// exhaustive or using it to authorize a destructive operation.
final class MapDependencyPreflightResult {
  MapDependencyPreflightResult({
    required this.operation,
    required this.mapId,
    required this.inspection,
    required List<MapDependencyIndexIssue> indexIssues,
  }) : indexIssues = List<MapDependencyIndexIssue>.unmodifiable(indexIssues);

  final MapDependencyPreflightOperation operation;
  final String mapId;
  final NarrativeDependencyInspectionReadModel inspection;
  final List<MapDependencyIndexIssue> indexIssues;

  /// A complete index requires every manifest map and one canonical target.
  bool get isComplete =>
      indexIssues.isEmpty && !inspection.isMissing && !inspection.isAmbiguous;

  bool get hasIncomingReferences => inspection.usages.isNotEmpty;

  /// DS-04 is deliberately fail-closed: partial knowledge never authorizes.
  bool get isAllowed => isComplete && !hasIncomingReferences;

  String get operationLabel => switch (operation) {
        MapDependencyPreflightOperation.rename => 'renommage',
        MapDependencyPreflightOperation.delete => 'suppression',
      };

  String get dialogTitle => switch (operation) {
        MapDependencyPreflightOperation.rename => 'Renommage bloqué',
        MapDependencyPreflightOperation.delete => 'Suppression bloquée',
      };

  String get blockingMessage {
    if (!isComplete) {
      final count = indexIssues.length;
      final diagnosticLabel =
          count == 1 ? '1 diagnostic' : '$count diagnostics';
      return 'Action bloquée ($operationLabel de « $mapId ») : '
          'index incomplet ($diagnosticLabel). Aucune écriture n’a été '
          'effectuée.';
    }
    final count = inspection.usages.length;
    final usageLabel =
        count == 1 ? '1 usage entrant' : '$count usages entrants';
    final requiredAction = count == 1
        ? 'doit être retiré ou redirigé'
        : 'doivent être retirés ou redirigés';
    return 'Action bloquée ($operationLabel de « $mapId ») : '
        '$usageLabel $requiredAction. Aucune écriture n’a '
        'été effectuée.';
  }
}

/// Structured failure used to keep the navigable preflight result intact.
final class MapDependencyPreflightBlockedException implements Exception {
  const MapDependencyPreflightBlockedException(this.result);

  final MapDependencyPreflightResult result;

  @override
  String toString() => result.blockingMessage;
}

/// Builds the canonical project-wide incoming-reference preflight for a map.
///
/// The service intentionally reloads every manifest map from its authoritative
/// path immediately before a lifecycle mutation. A missing, malformed or
/// identity-mismatched document means a hidden incoming reference cannot be
/// ruled out, so the result stays blocked.
final class MapDependencyPreflightService {
  const MapDependencyPreflightService({
    required MapRepository mapRepository,
  }) : _mapRepository = mapRepository;

  final MapRepository _mapRepository;

  Future<MapDependencyPreflightResult> inspect({
    required ProjectWorkspace workspace,
    required ProjectManifest project,
    required String mapId,
    required MapDependencyPreflightOperation operation,
  }) async {
    final normalizedMapId = mapId.trim();
    final loadedMaps = <MapData>[];
    final issues = <MapDependencyIndexIssue>[];
    final seenIds = <String>{};

    for (final entry in project.maps) {
      if (!seenIds.add(entry.id)) {
        issues.add(
          MapDependencyIndexIssue(
            kind: MapDependencyIndexIssueKind.duplicateManifestId,
            mapId: entry.id,
            relativePath: entry.relativePath,
            message:
                'La map « ${entry.id} » apparaît plusieurs fois dans le manifeste.',
          ),
        );
        continue;
      }

      try {
        final path = workspace.resolveMapPath(entry.relativePath);
        final loaded = await _loadMapForIndex(path);
        if (loaded.id != entry.id) {
          issues.add(
            MapDependencyIndexIssue(
              kind: MapDependencyIndexIssueKind.identityMismatch,
              mapId: entry.id,
              relativePath: entry.relativePath,
              message: 'Le fichier « ${entry.relativePath} » déclare '
                  'l’identité « ${loaded.id} » au lieu de « ${entry.id} ».',
            ),
          );
          continue;
        }
        loadedMaps.add(loaded);
      } on Object catch (error) {
        issues.add(
          MapDependencyIndexIssue(
            kind: MapDependencyIndexIssueKind.unreadableMap,
            mapId: entry.id,
            relativePath: entry.relativePath,
            message: 'Impossible d’indexer « ${entry.relativePath} » : $error',
          ),
        );
      }
    }

    // Core owns the exhaustive typed traversal. The editor only owns loading,
    // lifecycle authorization and presentation of its canonical usages.
    final index = buildNarrativeDependencyIndex(
      project: project,
      maps: loadedMaps,
    );
    final inspection = inspectNarrativeDependency(
      index,
      NarrativeDependencyKey.map(normalizedMapId),
    );
    if (inspection.isMissing) {
      issues.add(
        MapDependencyIndexIssue(
          kind: MapDependencyIndexIssueKind.missingTargetDefinition,
          mapId: normalizedMapId,
          relativePath: '',
          message:
              'La cible « $normalizedMapId » est absente du manifeste des maps.',
        ),
      );
    } else if (inspection.isAmbiguous) {
      issues.add(
        MapDependencyIndexIssue(
          kind: MapDependencyIndexIssueKind.ambiguousTargetDefinition,
          mapId: normalizedMapId,
          relativePath: '',
          message:
              'La cible « $normalizedMapId » possède plusieurs définitions.',
        ),
      );
    }

    return MapDependencyPreflightResult(
      operation: operation,
      mapId: normalizedMapId,
      inspection: inspection,
      indexIssues: issues,
    );
  }

  Future<MapDependencyPreflightResult> requireAllowed({
    required ProjectWorkspace workspace,
    required ProjectManifest project,
    required String mapId,
    required MapDependencyPreflightOperation operation,
  }) async {
    final result = await inspect(
      workspace: workspace,
      project: project,
      mapId: mapId,
      operation: operation,
    );
    if (!result.isAllowed) {
      throw MapDependencyPreflightBlockedException(result);
    }
    return result;
  }

  Future<MapData> _loadMapForIndex(String path) async {
    if (_mapRepository case RevisionedMapRepository revisioned) {
      return (await revisioned.loadMapDocument(path)).map;
    }
    return _mapRepository.loadMap(path);
  }
}
