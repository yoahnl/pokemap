import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart';

Future<List<String>> writtenSince(String root, DateTime since) async {
  final marker = File('$root/.bench-marker');
  await marker.writeAsString('');
  await marker.setLastModified(since);
  final result = await Process.run('find', [
    root,
    '-type',
    'f',
    '-newer',
    marker.path,
    '-not',
    '-name',
    '.bench-marker',
  ]);
  await marker.delete();
  return [
    for (final line in LineSplitter.split(result.stdout as String))
      if (line.isNotEmpty) line.substring(root.length + 1),
  ];
}

String summarizeWrites(List<String> paths) {
  final counts = <String, int>{};
  for (final path in paths) {
    final key = path.startsWith('catalog/objects/')
        ? 'catalog/objects'
        : path.startsWith('.pokemap/authoring/transactions/')
        ? 'transactions'
        : path;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts.entries.map((entry) => '${entry.key}:${entry.value}').join(' ');
}

final class SaveCostCountingReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  final paths = <String>[];
  var bytes = 0;
  final delegate = const LocalProjectFileReader();

  void reset() {
    paths.clear();
    bytes = 0;
  }

  String summary() {
    final counts = <String, int>{};
    for (final path in paths) {
      final key = path.startsWith('catalog/objects/')
          ? 'objects'
          : path.startsWith('maps/')
          ? 'maps'
          : path.startsWith('assets/')
          ? 'assets'
          : path;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final maps = {
      for (final path in paths)
        if (path.startsWith('maps/')) path,
    };
    return 'reads=${paths.length} readMB=${(bytes / 1e6).toStringAsFixed(1)} '
        '${counts.entries.map((entry) => '${entry.key}:${entry.value}').join(' ')} '
        'distinctMaps=${maps.length}';
  }

  @override
  bool get supportsStreamingResources => true;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.probeResource(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    paths.add(relativePath);
    final value = await delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    bytes += value.length;
    return value;
  }

  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

final class SaveCostProfiler {
  SaveCostProfiler(this._socket, this._isolateId) {
    _socket.listen((message) {
      final decoded = jsonDecode(message as String) as Map<String, dynamic>;
      final id = decoded['id'];
      final completer = _pending.remove(id);
      completer?.complete(decoded);
    });
  }

  final WebSocket _socket;
  final String _isolateId;
  final _pending = <Object?, Completer<Map<String, dynamic>>>{};
  var _next = 0;
  var _origin = 0;

  static Future<SaveCostProfiler> connect() async {
    final info = await Service.controlWebServer(enable: true);
    final uri = info.serverWebSocketUri!;
    final socket = await WebSocket.connect(uri.toString());
    return SaveCostProfiler(socket, Service.getIsolateId(Isolate.current)!);
  }

  Future<Map<String, dynamic>> _call(
    String method,
    Map<String, Object?> params,
  ) {
    final id = '${_next++}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
    return completer.future;
  }

  Future<void> start() async {
    await _call('clearCpuSamples', {'isolateId': _isolateId});
    final now = await _call('getVMTimelineMicros', {});
    _origin = (now['result'] as Map)['timestamp'] as int;
  }

  Future<String> stop() async {
    final now = await _call('getVMTimelineMicros', {});
    final end = (now['result'] as Map)['timestamp'] as int;
    final response = await _call('getCpuSamples', {
      'isolateId': _isolateId,
      'timeOriginMicros': _origin,
      'timeExtentMicros': end - _origin,
    });
    final result = response['result'] as Map<String, dynamic>?;
    if (result == null) return 'profile error ${response['error']}';
    final functions = [
      for (final entry in result['functions'] as List)
        _name((entry as Map)['function'] as Map),
    ];
    final samples = result['samples'] as List;
    final exclusive = <String, int>{};
    final inclusive = <String, int>{};
    for (final sample in samples) {
      final stack = ((sample as Map)['stack'] as List).cast<int>();
      if (stack.isEmpty) continue;
      final top = functions[stack.first];
      exclusive[top] = (exclusive[top] ?? 0) + 1;
      for (final name in {for (final index in stack) functions[index]}) {
        inclusive[name] = (inclusive[name] ?? 0) + 1;
      }
    }
    String top(Map<String, int> values, int count) {
      final sorted = values.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted
          .take(count)
          .map((entry) => '  ${entry.value}\t${entry.key}')
          .join('\n');
    }

    return 'profile samples=${samples.length}\n-- inclusive\n${top(inclusive, 70)}\n-- exclusive\n${top(exclusive, 25)}';
  }

  static String _name(Map function) {
    final owner = function['owner'];
    final ownerName = owner is Map ? owner['name'] : null;
    final name = function['name'];
    return ownerName == null ? '$name' : '$ownerName.$name';
  }

  Future<void> close() => _socket.close();
}
