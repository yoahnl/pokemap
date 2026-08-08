import 'package:map_core/map_core.dart';

import '../../../application/ports/project_workspace.dart';
import '../../../domain/repositories/repositories.dart';
import 'world_map_connection_context.dart';

final class WorldMapConnectionContextLoader {
  const WorldMapConnectionContextLoader({
    required this.mapRepository,
    this.projector = const WorldMapConnectionContextProjector(),
  });

  final MapRepository mapRepository;
  final WorldMapConnectionContextProjector projector;

  Future<WorldMapConnectionContext> load({
    required ProjectWorkspace workspace,
    required ProjectManifest project,
    required MapData sourceMap,
  }) async {
    final entriesById = {for (final entry in project.maps) entry.id: entry};
    final connectionsByDirection = <MapConnectionDirection, MapConnection>{};
    for (final connection in sourceMap.connections) {
      connectionsByDirection.putIfAbsent(
        connection.direction,
        () => connection,
      );
    }
    final results = await Future.wait([
      for (final direction in MapConnectionDirection.values)
        if (connectionsByDirection[direction] case final connection?)
          _loadOne(
            workspace: workspace,
            sourceMap: sourceMap,
            connection: connection,
            entry: entriesById[connection.targetMapId],
          ),
    ]);
    final neighbors = <MapConnectionDirection, WorldMapConnectionNeighbor>{};
    final issues = <MapConnectionDirection, WorldMapConnectionContextIssue>{};
    for (final result in results) {
      switch (result) {
        case _NeighborResult(:final neighbor):
          neighbors[neighbor.direction] = neighbor;
        case _IssueResult(:final issue):
          issues[issue.direction] = issue;
      }
    }
    return WorldMapConnectionContext(
      sourceMap: sourceMap,
      neighbors: neighbors,
      issues: issues,
    );
  }

  Future<_LoadResult> _loadOne({
    required ProjectWorkspace workspace,
    required MapData sourceMap,
    required MapConnection connection,
    required ProjectMapEntry? entry,
  }) async {
    if (entry == null) {
      return _IssueResult(
        WorldMapConnectionContextIssue(
          direction: connection.direction,
          targetMapId: connection.targetMapId,
          code: 'target_not_in_manifest',
          message: 'La map cible n’existe pas dans le manifeste du projet.',
        ),
      );
    }
    try {
      final targetMap = await mapRepository.loadMap(
        workspace.resolveMapPath(entry.relativePath),
      );
      return _NeighborResult(
        projector.projectNeighbor(
          sourceMap: sourceMap,
          connection: connection,
          entry: entry,
          targetMap: targetMap,
        ),
      );
    } on WorldMapConnectionProjectionException catch (error) {
      return _IssueResult(
        WorldMapConnectionContextIssue(
          direction: connection.direction,
          targetMapId: connection.targetMapId,
          code: 'no_overlap',
          message: error.message,
        ),
      );
    } on Object catch (error) {
      final message = error.toString();
      final normalized = message.toLowerCase();
      final missing = normalized.contains('does not exist') ||
          normalized.contains('not found') ||
          normalized.contains('no such file');
      return _IssueResult(
        WorldMapConnectionContextIssue(
          direction: connection.direction,
          targetMapId: connection.targetMapId,
          code: missing ? 'target_file_missing' : 'target_unreadable',
          message: message,
        ),
      );
    }
  }
}

sealed class _LoadResult {
  const _LoadResult();
}

final class _NeighborResult extends _LoadResult {
  const _NeighborResult(this.neighbor);

  final WorldMapConnectionNeighbor neighbor;
}

final class _IssueResult extends _LoadResult {
  const _IssueResult(this.issue);

  final WorldMapConnectionContextIssue issue;
}
