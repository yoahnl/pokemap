import 'package:map_core/map_core.dart';

import '../../workspace/project_snapshot.dart';
import 'map_lifecycle_adapter.dart';

enum WorldGraphEdgeKind {
  connection,
  warp,
}

final class WorldGraphEdge {
  const WorldGraphEdge({
    required this.sourceMapId,
    required this.targetMapId,
    required this.kind,
    required this.sourceId,
  });

  final String sourceMapId;
  final String targetMapId;
  final WorldGraphEdgeKind kind;
  final String sourceId;

  Map<String, Object?> toJson() => {
        'sourceMapId': sourceMapId,
        'targetMapId': targetMapId,
        'kind': kind.name,
        'sourceId': sourceId,
      };
}

final class WorldGraphIssue {
  WorldGraphIssue({
    required this.code,
    required this.message,
    required this.mapId,
    this.targetMapId,
    this.sourceId,
  });

  final String code;
  final String message;
  final String mapId;
  final String? targetMapId;
  final String? sourceId;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'mapId': mapId,
        if (targetMapId != null) 'targetMapId': targetMapId,
        if (sourceId != null) 'sourceId': sourceId,
      };
}

final class WorldGraphInspection {
  WorldGraphInspection({
    required Iterable<String> nodes,
    required Iterable<WorldGraphEdge> edges,
    required Iterable<WorldGraphIssue> issues,
  })  : nodes = List.unmodifiable(nodes),
        edges = List.unmodifiable(edges),
        issues = List.unmodifiable(issues);

  final List<String> nodes;
  final List<WorldGraphEdge> edges;
  final List<WorldGraphIssue> issues;

  bool get isConsistent => issues.isEmpty;

  Map<String, Object?> toJson() => {
        'nodes': nodes,
        'edges': [for (final edge in edges) edge.toJson()],
        'issues': [for (final issue in issues) issue.toJson()],
        'isConsistent': isConsistent,
      };
}

/// Logical rendering model only. PokeMap currently persists no map coordinates.
final class WorldGraphRenderModel {
  WorldGraphRenderModel({
    required Iterable<String> nodes,
    required Iterable<WorldGraphEdge> edges,
  })  : nodes = List.unmodifiable(nodes),
        edges = List.unmodifiable(edges);

  final List<String> nodes;
  final List<WorldGraphEdge> edges;

  bool get hasPersistentLayout => false;

  Map<String, Object?> toJson() => {
        'nodes': nodes,
        'edges': [for (final edge in edges) edge.toJson()],
        'hasPersistentLayout': hasPersistentLayout,
        'layoutPolicy': 'logical_graph_only',
      };
}

/// Deterministic directed graph queries over authored warps and connections.
final class WorldGraphQueries {
  const WorldGraphQueries();

  WorldGraphInspection inspect(ProjectSnapshot snapshot) {
    final nodes = <String>{
      for (final entry in snapshot.manifest.maps) entry.id,
      for (final map in snapshot.maps) map.id,
    }.toList()
      ..sort();
    final knownMapIds = {for (final map in snapshot.maps) map.id};
    final manifestMapIds = {
      for (final entry in snapshot.manifest.maps) entry.id,
    };
    final edges = <WorldGraphEdge>[];
    final issues = <WorldGraphIssue>[];

    for (final mapId in manifestMapIds.difference(knownMapIds).toList()
      ..sort()) {
      issues.add(WorldGraphIssue(
        code: 'world_graph.map_document_missing',
        message: 'A declared map has no loaded document.',
        mapId: mapId,
      ));
    }
    for (final mapId in knownMapIds.difference(manifestMapIds).toList()
      ..sort()) {
      issues.add(WorldGraphIssue(
        code: 'world_graph.manifest_entry_missing',
        message: 'A loaded map has no project manifest entry.',
        mapId: mapId,
      ));
    }

    for (final map in snapshot.maps) {
      for (final connection in map.connections) {
        edges.add(WorldGraphEdge(
          sourceMapId: map.id,
          targetMapId: connection.targetMapId,
          kind: WorldGraphEdgeKind.connection,
          sourceId: connection.direction.name,
        ));
        final target = snapshot.mapById(connection.targetMapId);
        if (target == null) {
          issues.add(_missingTarget(
            mapId: map.id,
            targetMapId: connection.targetMapId,
            sourceId: connection.direction.name,
            kind: 'connection',
          ));
          continue;
        }
        final reciprocal = findMapConnection(
          target,
          connection.direction.opposite,
        );
        if (reciprocal == null ||
            reciprocal.targetMapId != map.id ||
            reciprocal.offset != -connection.offset) {
          issues.add(WorldGraphIssue(
            code: 'world_graph.connection_reciprocal_mismatch',
            message: 'A connection has no exact reciprocal connection.',
            mapId: map.id,
            targetMapId: target.id,
            sourceId: connection.direction.name,
          ));
        }
        if (!hasMapConnectionOverlap(
          sourceSize: map.size,
          targetSize: target.size,
          direction: connection.direction,
          offset: connection.offset,
        )) {
          issues.add(WorldGraphIssue(
            code: 'world_graph.connection_no_overlap',
            message: 'A connection has no overlapping border cells.',
            mapId: map.id,
            targetMapId: target.id,
            sourceId: connection.direction.name,
          ));
        }
      }
      for (final warp in map.warps) {
        edges.add(WorldGraphEdge(
          sourceMapId: map.id,
          targetMapId: warp.targetMapId,
          kind: WorldGraphEdgeKind.warp,
          sourceId: warp.id,
        ));
        final target = snapshot.mapById(warp.targetMapId);
        if (target == null) {
          issues.add(_missingTarget(
            mapId: map.id,
            targetMapId: warp.targetMapId,
            sourceId: warp.id,
            kind: 'warp',
          ));
        } else if (!_inBounds(warp.targetPos, target.size)) {
          issues.add(WorldGraphIssue(
            code: 'world_graph.warp_target_out_of_bounds',
            message: 'A warp targets a position outside its target map.',
            mapId: map.id,
            targetMapId: target.id,
            sourceId: warp.id,
          ));
        }
      }
    }

    edges.sort(_compareEdges);
    issues.sort(_compareIssues);
    return WorldGraphInspection(
      nodes: nodes,
      edges: edges,
      issues: issues,
    );
  }

  List<String> listConnected(
    ProjectSnapshot snapshot, {
    required String fromMapId,
  }) {
    final inspection = inspect(snapshot);
    _requireNode(inspection, fromMapId);
    final adjacency = _adjacency(inspection);
    final visited = <String>{fromMapId};
    final queue = <String>[fromMapId];
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      for (final target in adjacency[current] ?? const <String>[]) {
        if (visited.add(target)) queue.add(target);
      }
    }
    return List.unmodifiable(visited.toList()..sort());
  }

  List<String> listDisconnected(
    ProjectSnapshot snapshot, {
    required String fromMapId,
  }) {
    final inspection = inspect(snapshot);
    final connected = listConnected(snapshot, fromMapId: fromMapId).toSet();
    return List.unmodifiable([
      for (final node in inspection.nodes)
        if (!connected.contains(node)) node,
    ]);
  }

  List<String>? findPath(
    ProjectSnapshot snapshot, {
    required String sourceMapId,
    required String targetMapId,
  }) {
    final inspection = inspect(snapshot);
    _requireNode(inspection, sourceMapId);
    _requireNode(inspection, targetMapId);
    final adjacency = _adjacency(inspection);
    final previous = <String, String?>{sourceMapId: null};
    final queue = <String>[sourceMapId];
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      if (current == targetMapId) break;
      for (final target in adjacency[current] ?? const <String>[]) {
        if (!previous.containsKey(target)) {
          previous[target] = current;
          queue.add(target);
        }
      }
    }
    if (!previous.containsKey(targetMapId)) return null;
    final reverse = <String>[];
    String? current = targetMapId;
    while (current != null) {
      reverse.add(current);
      current = previous[current];
    }
    return List.unmodifiable(reverse.reversed);
  }

  List<WorldGraphIssue> validateConsistency(ProjectSnapshot snapshot) =>
      inspect(snapshot).issues;

  WorldGraphRenderModel render(ProjectSnapshot snapshot) {
    final inspection = inspect(snapshot);
    return WorldGraphRenderModel(
      nodes: inspection.nodes,
      edges: inspection.edges,
    );
  }
}

WorldGraphIssue _missingTarget({
  required String mapId,
  required String targetMapId,
  required String sourceId,
  required String kind,
}) =>
    WorldGraphIssue(
      code: 'world_graph.${kind}_target_missing',
      message: 'A $kind references a map that is not loaded.',
      mapId: mapId,
      targetMapId: targetMapId,
      sourceId: sourceId,
    );

Map<String, List<String>> _adjacency(WorldGraphInspection inspection) {
  final known = inspection.nodes.toSet();
  final values = <String, Set<String>>{
    for (final node in inspection.nodes) node: <String>{},
  };
  for (final edge in inspection.edges) {
    if (known.contains(edge.targetMapId)) {
      values[edge.sourceMapId]?.add(edge.targetMapId);
    }
  }
  return {
    for (final entry in values.entries)
      entry.key: List.unmodifiable(entry.value.toList()..sort()),
  };
}

void _requireNode(WorldGraphInspection inspection, String mapId) {
  if (!inspection.nodes.contains(mapId)) {
    throw MapAuthoringException(
      code: 'world_graph.map_missing',
      message: 'The requested map is absent from the world graph.',
      details: {'mapId': mapId},
    );
  }
}

bool _inBounds(GridPos pos, GridSize size) =>
    pos.x >= 0 && pos.y >= 0 && pos.x < size.width && pos.y < size.height;

int _compareEdges(WorldGraphEdge left, WorldGraphEdge right) {
  for (final comparison in <int>[
    left.sourceMapId.compareTo(right.sourceMapId),
    left.targetMapId.compareTo(right.targetMapId),
    left.kind.name.compareTo(right.kind.name),
    left.sourceId.compareTo(right.sourceId),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

int _compareIssues(WorldGraphIssue left, WorldGraphIssue right) {
  for (final comparison in <int>[
    left.mapId.compareTo(right.mapId),
    (left.targetMapId ?? '').compareTo(right.targetMapId ?? ''),
    left.code.compareTo(right.code),
    (left.sourceId ?? '').compareTo(right.sourceId ?? ''),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}
