import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

import 'native_project_writer.dart';

final class SourceConnectionArrival {
  const SourceConnectionArrival._(
      {required this.sourceMapId,
      required this.nativeSourceMapId,
      required this.sourcePosition,
      required this.direction,
      required this.targetSourceMapId,
      required this.nativeTargetMapId,
      required this.targetPosition,
      required this.passage});
  final int sourceMapId, targetSourceMapId;
  final String nativeSourceMapId, nativeTargetMapId;
  final GridPos sourcePosition, targetPosition;
  final MapConnectionDirection direction;
  final SourceConnectionEntryTilePassage passage;
  Map<String, Object?> toJson() => {
        'sourceMapId': sourceMapId,
        'nativeSourceMapId': nativeSourceMapId,
        'sourcePosition': sourcePosition.toJson(),
        'direction': direction.name,
        'targetSourceMapId': targetSourceMapId,
        'nativeTargetMapId': nativeTargetMapId,
        'targetPosition': targetPosition.toJson(),
        'status': passage.status.name,
        'reason': passage.reason.name,
        'trace': passage.trace.map((step) => step.toJson()).toList(),
      };
}

List<SourceConnectionArrival> sourceConnectionArrivals({
  required NormalizedSourceProject source,
  required NormalizedMapConnection connection,
  required Map<int, MapData> nativeMaps,
  ScanCancellation? cancellation,
}) {
  final resolver = SourceSemanticResolver.forProject(source);
  final result = <SourceConnectionArrival>[];
  void direction(int fromId, int toId,
      SourceConnectionDirection sourceDirection, int offset) {
    final from = nativeMaps[fromId]!, to = nativeMaps[toId]!;
    final direction = MapConnectionDirection.values
        .singleWhere((value) => value.name == sourceDirection.name);
    final sourceLength =
        direction.usesHorizontalOffset ? from.size.width : from.size.height;
    final targetLength =
        direction.usesHorizontalOffset ? to.size.width : to.size.height;
    final start = offset > 0 ? offset : 0;
    final end = sourceLength < offset + targetLength
        ? sourceLength
        : offset + targetLength;
    for (var axis = start; axis < end; axis++) {
      cancellation?.check();
      final sourcePos = _edgePosition(from, direction, axis);
      final targetPos = _edgePosition(to, direction.opposite, axis - offset);
      result.add(SourceConnectionArrival._(
          sourceMapId: fromId,
          nativeSourceMapId: from.id,
          sourcePosition: sourcePos,
          direction: direction,
          targetSourceMapId: toId,
          nativeTargetMapId: to.id,
          targetPosition: targetPos,
          passage: resolver.resolveConnectionEntryTile(
              resolver.cellAt(toId, targetPos.x, targetPos.y))));
    }
  }

  direction(connection.sourceMapId, connection.targetSourceMapId,
      connection.sourceDirection, connection.nativeOffset);
  direction(connection.targetSourceMapId, connection.sourceMapId,
      connection.targetDirection, -connection.nativeOffset);
  return List.unmodifiable(result);
}

GridPos _edgePosition(
        MapData map, MapConnectionDirection direction, int axis) =>
    switch (direction) {
      MapConnectionDirection.north => GridPos(x: axis, y: 0),
      MapConnectionDirection.east => GridPos(x: map.size.width - 1, y: axis),
      MapConnectionDirection.south => GridPos(x: axis, y: map.size.height - 1),
      MapConnectionDirection.west => GridPos(x: 0, y: axis),
    };

bool sourceConnectionHasBorderEvents(
    {required NormalizedSourceProject source,
    required NormalizedMapConnection connection,
    required Map<int, MapData> nativeMaps,
    ScanCancellation? cancellation}) {
  bool intersects(
      int id, SourceConnectionDirection sourceDirection, int offset, int toId) {
    final map = nativeMaps[id]!, to = nativeMaps[toId]!;
    final direction = MapConnectionDirection.values
        .singleWhere((value) => value.name == sourceDirection.name);
    final length =
        direction.usesHorizontalOffset ? map.size.width : map.size.height;
    final targetLength =
        direction.usesHorizontalOffset ? to.size.width : to.size.height;
    final start = offset > 0 ? offset : 0;
    final end = length < offset + targetLength ? length : offset + targetLength;
    final position = _edgePosition(map, direction, start);
    final original =
        source.maps.singleWhere((value) => value.map.sourceMapId == id).map;
    for (final event in original.events) {
      cancellation?.check();
      final size = RegExp(r'size\((\d+),(\d+)\)', caseSensitive: false)
          .firstMatch(event.name);
      final width = size == null ? 1 : int.tryParse(size.group(1)!);
      final height = size == null ? 1 : int.tryParse(size.group(2)!);
      if (width == null || height == null || width < 1 || height < 1) {
        return true;
      }
      if (direction.usesHorizontalOffset) {
        if (position.y > event.y - height &&
            position.y <= event.y &&
            event.x < end &&
            event.x + width > start) {
          return true;
        }
      } else if (position.x >= event.x &&
          position.x < event.x + width &&
          event.y - height + 1 < end &&
          event.y + 1 > start) {
        return true;
      }
    }
    return false;
  }

  return intersects(connection.sourceMapId, connection.sourceDirection,
          connection.nativeOffset, connection.targetSourceMapId) ||
      intersects(connection.targetSourceMapId, connection.targetDirection,
          -connection.nativeOffset, connection.sourceMapId);
}

final class SourceConnectionStudyComposition {
  SourceConnectionStudyComposition({
    required List<NativeMutation> mutations,
    required Map<int, MapData> nativeMaps,
    required Map<String, Object?> evidence,
  })  : mutations = List.unmodifiable(mutations),
        nativeMaps = Map.unmodifiable(nativeMaps),
        evidence = _freeze(evidence) as Map<String, Object?>;

  final List<NativeMutation> mutations;
  final Map<int, MapData> nativeMaps;
  final Map<String, Object?> evidence;
}

final class SourceConnectionStudyComposer {
  const SourceConnectionStudyComposer();

  Future<SourceConnectionStudyComposition> compose({
    required NormalizedSourceProject source,
    required Map<int, MapData> nativeMaps,
    required SourceFilePort files,
    NativeWriteLimits limits = const NativeWriteLimits(),
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    limits.validate();
    final maps = Map<int, MapData>.from(nativeMaps);
    final rows = <Map<String, Object?>>[];
    final diagnostics = <Map<String, Object?>>[];
    final mutations = <NativeMutation>[];
    final fileId = source.connectionsFileId;
    final file = fileId == null ? null : source.archive.files[fileId];
    final evidence = <String, Object?>{
      'kind': 'sourceConnectionStudy',
      'version': 1,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizedSourceHash': source.canonicalHash.value,
      'connectionsState': source.connectionsState.name,
      'sourceFileId': fileId?.value,
      'sourceFileHash': file?.entry.sha256?.value,
      'rows': rows,
      'diagnostics': diagnostics,
      'operationIds': <String>[],
      'wholeSourceConnectivityQualified': false,
      'sourceCrossingParityQualified': false,
      'sourceDirection': 0,
      'directionBit': 0,
      'sourceEntryScope': 'destinationStaticTilesWithoutBorderEvents',
      'sourceEntryProfile':
          SourceSemanticResolver.forProject(source).profile.toJson(),
      'sourceEntryContext': const SourceSemanticContext().toJson(),
      'sourceEntryContextAssumptions': {
        'surfing': false,
        'bicycle': false,
        'debugThrough': false,
        'eventFootprints': 'noSourceEventIntersectsOverlap',
        'runtimeState': 'initialStaticStudy'
      },
      'nativeArrivalAdmission': 'requiredBeforeStaging',
      'aiCalls': 0,
      'sourceScriptsExecuted': false,
    };
    if (source.connectionsState == SourceConnectionsState.notRequested) {
      diagnostics.add({
        'code': 'connections.not_requested',
        'message':
            'Source connectivity was not extracted; regional connectivity is not certified',
        'locator': SourceLocator.fromJson({
          'file': 'Data/map_connections.dat',
          'mapId': null,
          'eventId': null,
          'pageIndex': null,
          'commandIndex': null,
          'tileId': null,
          'line': null
        }).toJson(),
      });
      return SourceConnectionStudyComposition(
          mutations: mutations, nativeMaps: maps, evidence: evidence);
    }
    if (!source.connectionsExtracted || file == null || fileId == null) {
      throw const NativeWriteException('connections.source_unavailable',
          'A present compiled source graph must be fully and validly extracted');
    }
    if (file.entry.byteLength > limits.maxTotalArtifactBytes) {
      throw const NativeWriteException('connections.source_quota',
          'The compiled graph exceeds the admitted source witness budget');
    }
    final bytes = await files.read(fileId);
    cancellation?.check();
    if (bytes.length != file.entry.byteLength ||
        sha256.convert(bytes).toString() != file.entry.sha256?.value) {
      throw const NativeWriteException('connections.source_changed',
          'The compiled graph differs from its sealed normalized source');
    }
    for (final entry in maps.entries) {
      final sourceMap = source.maps
          .where((map) => map.map.sourceMapId == entry.key)
          .firstOrNull;
      if (sourceMap == null ||
          entry.value.size.width != sourceMap.map.width ||
          entry.value.size.height != sourceMap.map.height) {
        throw const NativeWriteException('connections.map_binding',
            'Every native connection map requires its exact source geometry');
      }
    }
    final edgeCounts = <String, int>{};
    String edge(int mapId, SourceConnectionDirection direction) =>
        '$mapId:${direction.sourceCode}';
    for (final row in source.connections) {
      for (final key in [
        edge(row.sourceMapId, row.sourceDirection),
        edge(row.targetSourceMapId, row.targetDirection)
      ]) {
        edgeCounts[key] = (edgeCounts[key] ?? 0) + 1;
      }
    }
    for (final row in source.connections) {
      cancellation?.check();
      final record = {...row.toJson(), 'status': 'preservedOnly'};
      rows.add(record);
      void preserve(String code, String message) {
        diagnostics.add({
          'code': code,
          'message': message,
          'locator': row.locator.toJson(),
          'connectionIdentity': row.identity.value
        });
        record['gap'] = code;
      }

      if (edgeCounts[edge(row.sourceMapId, row.sourceDirection)] != 1 ||
          edgeCounts[edge(row.targetSourceMapId, row.targetDirection)] != 1) {
        preserve('connections.edge_multiplicity',
            'A source edge has multiple neighbors; the native one-connection-per-edge contract cannot represent this row');
        continue;
      }
      final from = maps[row.sourceMapId], to = maps[row.targetSourceMapId];
      if (from == null || to == null) {
        preserve('connections.map_excluded',
            'A source connection endpoint is outside the admitted native map selection');
        continue;
      }
      final direction = MapConnectionDirection.values
          .singleWhere((value) => value.name == row.sourceDirection.name);
      if (row.targetDirection != row.sourceDirection.opposite ||
          from.id == to.id) {
        preserve('connections.direction_unsupported',
            'Native bidirectional connections require distinct maps and opposing source edges');
        continue;
      }
      if (!hasMapConnectionOverlap(
          sourceSize: from.size,
          targetSize: to.size,
          direction: direction,
          offset: row.nativeOffset)) {
        preserve('connections.no_overlap',
            'The source offset has no representable native edge overlap');
        continue;
      }
      if (findMapConnection(from, direction) != null ||
          findMapConnection(to, direction.opposite) != null) {
        throw const NativeWriteException('connections.native_occupied',
            'A source connection cannot overwrite an occupied native edge');
      }
      if (sourceConnectionHasBorderEvents(
          source: source,
          connection: row,
          nativeMaps: maps,
          cancellation: cancellation)) {
        preserve('connections.border_events_unqualified',
            'Source tile or sprite event pages and footprints can affect the overlap; the entire connection remains inactive');
        continue;
      }
      final arrivals = sourceConnectionArrivals(
          source: source,
          connection: row,
          nativeMaps: maps,
          cancellation: cancellation);
      record['arrivals'] = arrivals.map((entry) => entry.toJson()).toList();
      if (arrivals.any(
          (entry) => entry.passage.status == SourcePassageStatus.unqualified)) {
        preserve('connections.source_entry_unqualified',
            'One destination d0 passage is unqualified; the entire connection remains inactive');
        continue;
      }
      if (mutations.length >= limits.maxMutations) {
        throw const NativeWriteException(
            'native.quota.mutations', 'Connection mutation budget exceeded');
      }
      final mutation = NativeMutation(
          operationId: ConverterId('ac15_connection_${canonicalHashOf({
                'connectionIdentity': row.identity.value
              }).value.substring(0, 40)}'),
          actionId: 'connection.create_bidirectional_apply',
          sourceEntityIds: [
            row.identity,
            fileId,
            source.mapIdentity(row.sourceMapId),
            source.mapIdentity(row.targetSourceMapId)
          ],
          targetEntityIds: [ConverterId(from.id), ConverterId(to.id)],
          parameters: {
            'mapId': from.id,
            'direction': direction.name,
            'targetMapId': to.id,
            'offset': row.nativeOffset
          },
          limits: limits);
      mutations.add(mutation);
      maps[row.sourceMapId] = upsertMapConnectionOnMap(from,
          connection: MapConnection(
              direction: direction,
              targetMapId: to.id,
              offset: row.nativeOffset));
      maps[row.targetSourceMapId] = upsertMapConnectionOnMap(to,
          connection: MapConnection(
              direction: direction.opposite,
              targetMapId: from.id,
              offset: -row.nativeOffset));
      record['status'] = 'imported';
      record['operationId'] = mutation.operationId.value;
    }
    evidence['operationIds'] =
        mutations.map((row) => row.operationId.value).toList();
    canonicalJsonOf(evidence, limits: limits.jsonLimits);
    return SourceConnectionStudyComposition(
        mutations: mutations, nativeMaps: maps, evidence: evidence);
  }
}

Object? _freeze(Object? value) => switch (value) {
      Map<String, Object?>() => Map<String, Object?>.unmodifiable(
          value.map((key, child) => MapEntry(key, _freeze(child)))),
      List() => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };
