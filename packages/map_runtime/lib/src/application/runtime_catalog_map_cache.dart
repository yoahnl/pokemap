import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class RuntimeCatalogMapCache {
  RuntimeCatalogMapCache({
    required this.projectFilePath,
    required this.maximumMaps,
    required this.maximumSourceBytes,
  });

  final String projectFilePath;
  final int maximumMaps;
  final int maximumSourceBytes;
  final Map<String, _CachedRuntimeMap> _values = {};
  final Map<String, Future<MapData>> _pending = {};
  int _sourceBytes = 0;
  bool _disposed = false;

  Future<MapData> load(ProjectMapEntry entry) {
    _ensureOpen();
    final pending = _pending[entry.id];
    if (pending != null) return pending;
    final future = _load(entry);
    _pending[entry.id] = future;
    return future.whenComplete(() {
      if (identical(_pending[entry.id], future)) _pending.remove(entry.id);
    });
  }

  Future<MapData> _load(ProjectMapEntry entry) async {
    final cached = _values[entry.id];
    final read = await _readRuntimeMapInIsolate(
      projectFilePath,
      entry,
      cached?.fingerprint,
    );
    _ensureOpen();
    final value = read.map == null && cached != null
        ? cached
        : _CachedRuntimeMap(
            map: read.map!,
            fingerprint: read.fingerprint,
            sourceBytes: read.sourceBytes,
          );
    _retain(entry.id, value);
    return value.map;
  }

  void _retain(String id, _CachedRuntimeMap value) {
    final previous = _values.remove(id);
    if (previous != null) _sourceBytes -= previous.sourceBytes;
    if (maximumMaps == 0 || value.sourceBytes > maximumSourceBytes) return;
    while (_values.isNotEmpty &&
        (_values.length >= maximumMaps ||
            _sourceBytes + value.sourceBytes > maximumSourceBytes)) {
      _sourceBytes -= _values.remove(_values.keys.first)!.sourceBytes;
    }
    _values[id] = value;
    _sourceBytes += value.sourceBytes;
  }

  Future<List<MapData>> loadNarrativeMaps(
    List<ProjectMapEntry> entries,
    PixelSize tileSize, {
    Map<String, String>? expectedSha256ByMapId,
  }) async {
    _ensureOpen();
    final maps = await _readNarrativeMapsInIsolate(
      projectFilePath,
      entries,
      tileSize,
      expectedSha256ByMapId,
    );
    _ensureOpen();
    return maps;
  }

  void dispose() {
    _disposed = true;
    _values.clear();
    _pending.clear();
    _sourceBytes = 0;
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Runtime map cache is disposed.');
  }
}

final class _CachedRuntimeMap {
  const _CachedRuntimeMap({
    required this.map,
    required this.fingerprint,
    required this.sourceBytes,
  });

  final MapData map;
  final String fingerprint;
  final int sourceBytes;
}

Future<({MapData? map, String fingerprint, int sourceBytes})>
_readRuntimeMapInIsolate(
  String projectPath,
  ProjectMapEntry entry,
  String? previousFingerprint,
) =>
    Isolate.run(() => _readRuntimeMap(projectPath, entry, previousFingerprint));

Future<List<MapData>> _readNarrativeMapsInIsolate(
  String projectPath,
  List<ProjectMapEntry> entries,
  PixelSize tileSize,
  Map<String, String>? expectedSha256ByMapId,
) => Isolate.run(() async {
  final result = <MapData>[];
  for (final entry in entries) {
    try {
      final read = await _readRuntimeMap(
        projectPath,
        entry,
        null,
        expectedSourceSha256: expectedSha256ByMapId?[entry.id],
      );
      final map = read.map!;
      MapValidator.validate(map, projectTileSize: tileSize);
      if (!buildMapVisualCompositionPlan(map).canCompose) {
        throw MapLoadException(
          'Map ${map.id} cannot be composed by this runtime.',
        );
      }
      result.add(map);
    } on MapLoadException {
      rethrow;
    } on Object catch (error) {
      throw MapLoadException('Failed to load map: $error');
    }
  }
  return List<MapData>.unmodifiable(result);
});

Future<({MapData? map, String fingerprint, int sourceBytes})> _readRuntimeMap(
  String projectFilePath,
  ProjectMapEntry entry,
  String? previousFingerprint, {
  String? expectedSourceSha256,
}) async {
  final root = p.dirname(projectFilePath);
  final path = p.normalize(p.join(root, entry.relativePath));
  if (!p.isWithin(root, path) ||
      !p.isWithin(root, await File(path).resolveSymbolicLinks())) {
    throw const MapLoadException('Map entry escapes the project directory');
  }
  final file = File(path);
  const maximumBytes = 128 * 1024 * 1024;
  if (await file.length() > maximumBytes) {
    throw const MapLoadException('Map document exceeds its byte limit');
  }
  final builder = BytesBuilder(copy: false);
  var length = 0;
  await for (final chunk in file.openRead()) {
    length += chunk.length;
    if (length > maximumBytes) {
      throw const MapLoadException('Map document exceeds its byte limit');
    }
    builder.add(chunk);
  }
  final bytes = builder.takeBytes();
  final hash = narrativeEventBytesFingerprint(bytes);
  if (expectedSourceSha256 != null && hash != 'sha256:$expectedSourceSha256') {
    throw const MapLoadException(
      'Map source fingerprint does not match the admitted bytes',
    );
  }
  if (hash == previousFingerprint) {
    return (map: null, fingerprint: hash, sourceBytes: length);
  }
  final raw = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
  if (raw is! Map<String, dynamic>) {
    throw const FormatException('Expected a map JSON object.');
  }
  final map = MapData.fromJson(raw);
  if (map.id != entry.id) throw const MapLoadException('Map identity mismatch');
  return (map: map, fingerprint: hash, sourceBytes: length);
}
