import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  final root = Platform.environment['AVELUNE_MAP_SAVE_BENCH_ROOT'];
  final mapId =
      Platform.environment['AVELUNE_MAP_SAVE_BENCH_MAP'] ?? 'first-map';
  final profile = Platform.environment['AVELUNE_MAP_SAVE_BENCH_PROFILE'] == '1';
  final repeats = int.parse(
    Platform.environment['AVELUNE_MAP_SAVE_BENCH_REPEATS'] ?? '3',
  );

  test(
    'map save cost on a real working catalog',
    () async {
      final reader = _CountingReader();
      final adapter = LocalMapWorkspaceAdapter(reader: reader);
      final profiler = profile ? await _Profiler.connect() : null;
      final sessionWatch = Stopwatch()..start();
      final session = await LocalProjectSessionAdapter().open(root!);
      stdout.writeln(
        'bench session ms=${sessionWatch.elapsedMilliseconds} storage=${session.storage.name}',
      );
      expect(session.storage, ProjectSessionStorage.workingCatalog);
      final controller = MapWorkspaceController(session, adapter);

      Future<void> measure(String label, Future<void> Function() body) async {
        reader.reset();
        final started = DateTime.now();
        await profiler?.start();
        final watch = Stopwatch()..start();
        await body();
        watch.stop();
        final report = await profiler?.stop();
        final written = await _writtenSince(root, started);
        stdout.writeln(
          'bench $label ms=${watch.elapsedMilliseconds} ${reader.summary()} writes=${written.length} ${_summarizeWrites(written)}',
        );
        if (report != null) stdout.writeln(report);
      }

      await measure('open', () async {
        await controller.initialize();
        expect(controller.error, isNull);
        final entry = controller.project!.maps.singleWhere(
          (map) => map.id == mapId,
        );
        await controller.activate(entry);
        expect(controller.error, isNull);
      });
      final document = controller.documents[mapId]!;
      final npc = document.current.entities.firstWhere(
        (entity) => entity.npc != null,
      );
      final instance = document.current.spatialScene!.instances.first;

      for (var repeat = 0; repeat < repeats; repeat++) {
        await measure('presence#$repeat', () async {
          final previous =
              document.current.entities
                  .firstWhere((entity) => entity.id == npc.id)
                  .npc
                  ?.visibilityRule
                  ?.predicate
                  ?.timeWindow
                  ?.startMinute ??
              0;
          document.commit(
            const EntityActions().setVisibilityRule(
              document.current,
              entityId: npc.id,
              visibilityRule: MapEntityNpcVisibilityRule(
                mode: MapEntityNpcVisibilityMode.visibleWhen,
                predicate: MapEntityRuntimePredicate(
                  kind: MapEntityRuntimePredicateKind.localTimeWindow,
                  timeWindow: LocalTimeWindow(
                    startMinute: (previous + 30) % 600 + 60,
                    endMinute: 60 * 20,
                  ),
                ),
              ),
            ),
          );
          expect(
            await controller.save(document),
            isTrue,
            reason: document.error,
          );
        });
        await measure('camera#$repeat', () async {
          final camera = document.current.spatialScene!.camera;
          document.commit(
            const SpatialMapOperations().configureCamera(
              document.current,
              camera.copyWith(distance: camera.distance + 1),
            ),
          );
          expect(
            await controller.save(document),
            isTrue,
            reason: document.error,
          );
        });
        await measure('move#$repeat', () async {
          final scene = document.current.spatialScene!;
          final current = scene.instances.firstWhere(
            (value) => value.id == instance.id,
          );
          document.commit(
            document.current.copyWith(
              spatialScene: scene.copyWith(
                instances: [
                  for (final value in scene.instances)
                    value.id == current.id
                        ? value.copyWith(
                            position: Model3dVector3(
                              x: current.position.x + (repeat.isEven ? 1 : -1),
                              y: current.position.y,
                              z: current.position.z,
                            ),
                          )
                        : value,
                ],
              ),
            ),
          );
          expect(
            await controller.save(document),
            isTrue,
            reason: document.error,
          );
        });
      }
      final saved = document.saved;
      final cold = LocalMapWorkspaceAdapter();
      await cold.loadCatalog(session);
      final entry = (await cold.loadCatalog(session)).metadata.maps
          .singleWhere((map) => map.id == mapId);
      final reopened = (await cold.loadMapSelection(session, entry)).document;
      expect(reopened.map, saved);
      controller.dispose();
      await profiler?.close();
    },
    skip: root == null
        ? 'Set AVELUNE_MAP_SAVE_BENCH_ROOT to a QA copy.'
        : false,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}

Future<List<String>> _writtenSince(String root, DateTime since) async {
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

String _summarizeWrites(List<String> paths) {
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

final class _CountingReader
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

final class _Profiler {
  _Profiler(this._socket, this._isolateId) {
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

  static Future<_Profiler> connect() async {
    final info = await Service.controlWebServer(enable: true);
    final uri = info.serverWebSocketUri!;
    final socket = await WebSocket.connect(uri.toString());
    return _Profiler(socket, Service.getIsolateId(Isolate.current)!);
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
