import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'native_project_writer.dart';

final class SourceRoutedDoorLoadingEngine {
  SourceRoutedDoorLoadingEngine._(this._evidence);

  static const _viewportTilesX = 16, _viewportTilesY = 12;
  static const _margin = 6, _transitionFringe = 1;
  final Map<String, Object?> _evidence;
  final _cameraScopes = <String, bool>{};

  bool hasBoundedCamera({
    required NormalizedSourceProject source,
    required NormalizedSourceProject? retainedSource,
    required Set<int> attestedMapIds,
    ScanCancellation? cancellation,
  }) {
    final key =
        '${source.canonicalHash.value}/${retainedSource?.canonicalHash.value}/${(attestedMapIds.toList()..sort()).join(',')}';
    return _cameraScopes.putIfAbsent(key, () {
      final files = <String, SourceSemanticFile>{};
      for (final project in [
        source,
        if (retainedSource != null) retainedSource
      ]) {
        for (final file in project.sourceFiles.values) {
          final path = file.entry.relativePath;
          if (path == 'Data/CommonEvents.rxdata' ||
              attestedMapIds.any((id) =>
                  path == 'Data/Map${id.toString().padLeft(3, '0')}.rxdata')) {
            files[path] = file;
          }
        }
      }
      for (final file in files.values) {
        final document = file.document;
        for (final node in document.nodes) {
          cancellation?.check();
          if (node.className != 'RPG::EventCommand') continue;
          final codes = node.instanceVariables
              .where((pair) => document.node(pair.key).name == '@code')
              .toList();
          if (codes.length != 1) return false;
          final code = document.node(codes.single.value).integerValue?.toInt();
          if (code == null ||
              code == 203 ||
              (code == 209 && _playerRouteMayJump(document, node))) {
            return false;
          }
        }
      }
      return true;
    });
  }

  static Future<SourceRoutedDoorLoadingEngine?> read({
    required NormalizedSourceProject source,
    required SourceFilePort files,
    required NativeWriteLimits limits,
    ScanCancellation? cancellation,
  }) async {
    cancellation?.check();
    final profile = source.interpretationProfile;
    if (profile == null ||
        profile.customPluginPolicy !=
            SourceCustomPluginPolicy.excludeCustomBehavior) {
      return null;
    }
    final entries =
        source.snapshot.entriesMatchingPath(profile.scriptsRelativePath);
    final cap =
        limits.maxArtifactBytes < 8388608 ? limits.maxArtifactBytes : 8388608;
    if (entries.length != 1 ||
        entries.single.relativePath != profile.scriptsRelativePath ||
        entries.single.kind != SourceNodeKind.file ||
        entries.single.byteLength > cap ||
        entries.single.sha256 != profile.scriptsArchiveHash) {
      return null;
    }
    final entry = entries.single;
    final input = await files.read(entry.fileId);
    cancellation?.check();
    if (input.length != entry.byteLength ||
        input.any((value) => value < 0 || value > 255)) {
      throw const NativeWriteException('events.execution.witness.changed',
          'Camera loading witnesses differ from the sealed source snapshot');
    }
    final bytes = Uint8List.fromList(input);
    if (crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw const NativeWriteException('events.execution.witness.changed',
          'Camera loading witnesses differ from the sealed source snapshot');
    }
    final document = const MarshalDecoder().decode(bytes,
        sourcePath: entry.relativePath,
        limits: MarshalDecodeLimits(
            maxInputBytes: cap,
            maxNodes: 100000,
            maxObjects: 100000,
            maxSymbols: 4096,
            maxContainerEntries: 65536,
            maxTotalEntries: 100000,
            maxStringBytes: cap,
            maxTotalStringBytes: cap));
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.array) return null;
    final sections = <Map<String, Object?>>[];
    var expandedBytes = 0;
    for (final spec in const [
      (
        0,
        'Settings',
        'cc412c0b86e5ebbc121a91ca5efc2d7d6c7b398469cb0c7cd5be1b770531b06f',
        [684, 688]
      ),
      (
        32,
        'Scene_Map',
        '2ddbb7198dd0445142cf76c44b32ae8f983c11ec1230c6179d46808854356fe1',
        [72, 90, 136, 140]
      ),
      (
        42,
        'Game_Map',
        '2e31060a4dc0ac036fecc510735f8a70f8cb8c7f33291b572e489e89c4f5b7f9',
        [323, 340, 460, 465]
      ),
      (
        43,
        'Game_MapFactory',
        'bba3deeae94afff918edfcde6d251748498f44f59655fc9ce32aa42f304d98c6',
        [17, 25, 114, 139, 361, 375, 475, 493]
      ),
      (
        45,
        'Game_Event',
        '8c11fb7f170df5ca2aff17725e1dbed031c94deebabdbbae69dd926e24acafa7',
        [244, 274]
      ),
      (
        46,
        'Game_Player',
        '7159cc172004da46b72a51b7d009df24de7a297bdb09599de31a4b5116dab373',
        [12, 13, 254, 265]
      ),
    ]) {
      cancellation?.check();
      if (spec.$1 >= root.elements.length) return null;
      final row = document.node(root.elements[spec.$1]);
      if (row.kind != MarshalKind.array || row.elements.length != 3) {
        return null;
      }
      final name = document.node(row.elements[1]);
      final data = document.node(row.elements[2]);
      if (name.kind != MarshalKind.string ||
          name.text().text != spec.$2 ||
          data.kind != MarshalKind.string ||
          data.bytes == null) {
        return null;
      }
      final remaining = limits.maxTotalArtifactBytes - expandedBytes;
      final outputCap = remaining < 1048576 ? remaining : 1048576;
      if (outputCap <= 0) {
        throw const NativeWriteException('events.execution.witness.quota',
            'Camera loading witnesses exceed their aggregate byte budget');
      }
      final expanded = const BoundedZlibDecoder().decode(data.bytes!,
          sourcePath: entry.relativePath,
          limits:
              ZlibDecodeLimits(maxInputBytes: cap, maxOutputBytes: outputCap));
      expandedBytes += expanded.length;
      if (crypto.sha256.convert(expanded).toString() != spec.$3) return null;
      sections.add(Map.unmodifiable({
        'index': spec.$1,
        'name': spec.$2,
        'sha256': spec.$3,
        'oracleLinePairs': spec.$4
      }));
    }
    cancellation?.check();
    return SourceRoutedDoorLoadingEngine._(Map.unmodifiable({
      'scriptsArchive': entry.toJson(),
      'sections': List.unmodifiable(sections),
      'viewportPixels': const [512, 384],
      'tilePixels': 32,
      'loadingMarginTiles': 6,
      'transitionFringeTiles': 1,
      'camera': 'nativePlayerFollowingIncludingSetupDisplayZero',
      'customCameraOverrides': 'excludedByExplicitStaticConversionPolicy',
      'sourceOverrideParityQualified': false,
      'sourceScriptsExecuted': 0,
    }));
  }

  ({Set<int> executionMapIds, Map<String, Object?> evidence}) scope({
    required NormalizedSourceProject source,
    required NormalizedSourceProject? retainedSource,
    required Set<int> activeMapIds,
    required Set<int> retainedMapIds,
  }) {
    final maps = <int, SourceMapIr>{};
    final duplicateIds = <int>{};
    for (final map in [...source.maps, ...?retainedSource?.maps]) {
      final id = map.map.sourceMapId;
      if (maps.containsKey(id)) duplicateIds.add(id);
      maps[id] = map;
    }
    final excluded = <int>{};
    final exclusions = <Map<String, Object?>>[];
    for (final target in retainedMapIds) {
      final neighbor = maps[target]?.map;
      if (neighbor == null || duplicateIds.contains(target)) continue;
      final connections = source.connections
          .where((connection) =>
              (activeMapIds.contains(connection.sourceMapId) &&
                  connection.targetSourceMapId == target) ||
              (activeMapIds.contains(connection.targetSourceMapId) &&
                  connection.sourceMapId == target))
          .toList();
      if (connections.isEmpty) continue;
      final seen = <int>{};
      final rectangles = <Map<String, Object?>>[];
      var outsideEveryActiveMap = true;
      for (final connection in connections) {
        final forward = connection.targetSourceMapId == target;
        final activeId =
            forward ? connection.sourceMapId : connection.targetSourceMapId;
        final active = maps[activeId]?.map;
        if (active == null ||
            duplicateIds.contains(activeId) ||
            !seen.add(activeId)) {
          outsideEveryActiveMap = false;
          break;
        }
        final activePoint = _anchor(
            forward ? connection.sourceDirection : connection.targetDirection,
            forward ? connection.sourceOffset : connection.targetOffset,
            active.width,
            active.height);
        final neighborPoint = _anchor(
            forward ? connection.targetDirection : connection.sourceDirection,
            forward ? connection.targetOffset : connection.sourceOffset,
            neighbor.width,
            neighbor.height);
        final originX = activePoint.$1 - neighborPoint.$1;
        final originY = activePoint.$2 - neighborPoint.$2;
        final outside = active.width + _transitionFringe - originX <
                -_viewportTilesX - _margin ||
            -_viewportTilesX - _transitionFringe - originX >
                neighbor.width + _margin ||
            active.height + _transitionFringe - originY <
                -_viewportTilesY - _margin ||
            -_viewportTilesY - _transitionFringe - originY >
                neighbor.height + _margin;
        if (!outside) outsideEveryActiveMap = false;
        rectangles.add({
          'activeSourceMapId': activeId,
          'activeDimensions': [active.width, active.height],
          'neighborOrigin': [originX, originY],
          'neighborDimensions': [neighbor.width, neighbor.height],
          'connection': connection.toJson(),
          'outsideWholeActiveCameraEnvelope': outside
        });
      }
      if (outsideEveryActiveMap) {
        excluded.add(target);
        exclusions.add({'sourceMapId': target, 'connections': rectangles});
      }
    }
    return (
      executionMapIds: Set.unmodifiable(
          {...activeMapIds, ...retainedMapIds.difference(excluded)}),
      evidence: Map.unmodifiable({
        'kind': 'boundedSourceDoorNeighborLoading',
        'version': 1,
        ..._evidence,
        'scope': 'allActiveMapTilesAndOneTileConnectionTransition',
        'excludedSourceMapIds': excluded.toList()..sort(),
        'exclusions': exclusions,
        'retainedGeometryAndSourceWitnessesPreserved': true
      })
    );
  }
}

bool _playerRouteMayJump(MarshalDocument document, MarshalNode command) {
  MarshalNode? field(MarshalNode node, String name) {
    final matches = node.instanceVariables
        .where((pair) => document.node(pair.key).name == name)
        .toList();
    return matches.length == 1 ? document.node(matches.single.value) : null;
  }

  final parameters = field(command, '@parameters');
  if (parameters?.kind != MarshalKind.array ||
      parameters!.elements.length != 2) {
    return true;
  }
  final actor = document.node(parameters.elements.first).integerValue?.toInt();
  if (actor == null) return true;
  if (actor != -1) return false;
  final route = document.node(parameters.elements.last);
  if (route.className != 'RPG::MoveRoute') return true;
  final list = field(route, '@list');
  if (list?.kind != MarshalKind.array) return true;
  return list!.elements.any((id) {
    final step = document.node(id);
    final code = field(step, '@code')?.integerValue?.toInt();
    return step.className != 'RPG::MoveCommand' || code == null || code == 14;
  });
}

(int, int) _anchor(SourceConnectionDirection direction, int offset, int width,
        int height) =>
    switch (direction) {
      SourceConnectionDirection.north => (offset, 0),
      SourceConnectionDirection.south => (offset, height),
      SourceConnectionDirection.west => (0, offset),
      SourceConnectionDirection.east => (width, offset),
    };
