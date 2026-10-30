import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'studio_mcp_process.dart';

enum StudioMcpState { starting, ready, failed, stopping, stopped }

class StudioMcpConnection {
  const StudioMcpConnection(this.url, this._token, this.protocolVersions);
  final Uri url;
  final String _token;
  final List<String> protocolVersions;

  String get clientConfiguration => const JsonEncoder.withIndent('  ').convert({
    'mcpServers': {
      'avelune-studio': {
        'type': 'http',
        'url': url.toString(),
        'headers': {'Authorization': 'Bearer $_token'},
      },
    },
  });
}

class StudioMcpResource {
  const StudioMcpResource({required this.kind, required this.id});
  final String kind;
  final String id;
}

class StudioMcpMutation {
  const StudioMcpMutation({
    required this.projectRoot,
    required this.resources,
    required this.revision,
    this.operationId,
  });
  final String projectRoot;
  final List<StudioMcpResource> resources;
  final String revision;
  final String? operationId;
}

class StudioMcpService extends ChangeNotifier {
  StudioMcpService({
    required this.launch,
    this.startTimeout = const Duration(seconds: 15),
    this.commandTimeout = const Duration(seconds: 5),
    this.stopTimeout = const Duration(seconds: 10),
    this.projectBookmark,
  });

  final Future<StudioMcpProcess> Function() launch;
  final Duration startTimeout;
  final Duration commandTimeout;
  final Duration stopTimeout;
  final Future<String?> Function(String root)? projectBookmark;
  final _owned = <StudioMcpProcess>{};
  final _shutdowns = <StudioMcpProcess, Future<void>>{};
  final _mutations = StreamController<StudioMcpMutation>.broadcast();
  final _requests = <String, Completer<void>>{};
  Stream<StudioMcpMutation> get mutations => _mutations.stream;
  StudioMcpState _state = StudioMcpState.stopped;
  StudioMcpState get state => _state;
  StudioMcpConnection? _connection;
  StudioMcpConnection? get connection => _connection;
  String? _error;
  String? get error => _error;
  String? _diagnosticCode;
  String? get diagnosticCode => _diagnosticCode;
  String? _desiredRoot;
  String? _authorizedRoot;
  bool _rootsSynchronized = false;
  StudioMcpProcess? _process;
  StreamSubscription<Map<String, Object?>>? _events;
  Completer<void>? _ready;
  Future<void>? _starting;
  Future<void>? _stopping;
  Future<void>? _ownedStopping;
  Future<void> _rootChanges = Future.value();
  int _generation = 0;
  int _requestNumber = 0;
  bool _disposed = false;

  Future<void> start() {
    if (_state == StudioMcpState.failed && _owned.isNotEmpty) {
      return Future.value();
    }
    if (_disposed ||
        _state == StudioMcpState.ready ||
        _state == StudioMcpState.stopping) {
      return Future.value();
    }
    if (_state == StudioMcpState.starting) return _starting ?? Future.value();
    _state = StudioMcpState.starting;
    _error = null;
    _diagnosticCode = null;
    _connection = null;
    _rootsSynchronized = false;
    final generation = ++_generation;
    _ready = Completer<void>();
    _publish();
    return _starting = _start(generation);
  }

  Future<void> _start(int generation) async {
    try {
      final spawning = launch();
      unawaited(
        spawning.then<void>((process) {
          _owned.add(process);
          if (_disposed || generation != _generation) {
            unawaited(_shutdown(process).catchError((Object _) {}));
          }
        }, onError: (Object _) {}),
      );
      final process = await spawning.timeout(startTimeout);
      if (_disposed || generation != _generation) return;
      _process = process;
      _events = process.events.listen(
        (event) => _handleEvent(event, generation),
        onError: (Object _) {
          if (generation == _generation) _failReadiness();
        },
        onDone: () {
          if (generation == _generation && !_disposed) _failReadiness();
        },
      );
      unawaited(
        process.exitCode.then((code) {
          if (generation == _generation && !_disposed) {
            _failReadiness('companion.exit_$code');
          }
        }),
      );
      await _ready!.future.timeout(startTimeout);
      if (_disposed || generation != _generation) return;
      await _synchronizeRoots();
      if (_disposed || generation != _generation) return;
      _state = StudioMcpState.ready;
      _publish();
    } on Object catch (failure) {
      if (generation != _generation || _disposed) return;
      _diagnosticCode ??= switch (failure) {
        FormatException(:final message)
            when RegExp(
              r'^(distribution\.[a-z_]+|permission\.bookmark_unavailable)$',
            ).hasMatch(message) =>
          message,
        ProcessException(:final errorCode) => 'launch.process_$errorCode',
        TimeoutException() => 'launch.timeout',
        _ => 'launch.unavailable',
      };
      debugPrint('Studio MCP startup failed ($_diagnosticCode).');
      _generation++;
      final stopped = await _stopOwned().then(
        (_) => true,
        onError: (Object _) => false,
      );
      if (_disposed) return;
      _state = StudioMcpState.failed;
      _connection = null;
      _error = stopped
          ? 'La connexion aux assistants est indisponible. Réessayez.'
          : 'La connexion aux assistants ne peut pas être arrêtée. Réessayez.';
      _publish();
    }
  }

  void _failReadiness([String code = 'companion.unavailable']) {
    _diagnosticCode = code;
    debugPrint('Studio MCP connection failed ($code).');
    _connection = null;
    _authorizedRoot = null;
    final ready = _ready;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(StateError('companion.unavailable'));
    } else if (_state == StudioMcpState.ready) {
      _state = StudioMcpState.failed;
      _error = 'La connexion aux assistants a été interrompue. Réessayez.';
      _publish();
      unawaited(_stopOwned().catchError((Object _) {}));
    }
    _cancelRequests();
  }

  void _handleEvent(Map<String, Object?> event, int generation) {
    if (_disposed || generation != _generation) return;
    if (event['type'] == 'failed') {
      final code = event['code'];
      _failReadiness(
        code is String &&
                RegExp(r'^[a-zA-Z][a-zA-Z0-9_.-]{0,96}$').hasMatch(code)
            ? code
            : 'companion.initialization_failed',
      );
      return;
    }
    if (event['type'] == 'ready') {
      try {
        if (_connection != null || event['controlVersion'] != 1) {
          throw const FormatException();
        }
        final url = Uri.parse(event['url'] as String);
        final token = event['token'] as String;
        final protocols = (event['protocolVersions'] as List).cast<String>();
        if (url.scheme != 'http' ||
            !['127.0.0.1', '::1', '[::1]'].contains(url.host) ||
            !url.hasPort ||
            url.port == 0 ||
            url.userInfo.isNotEmpty ||
            url.hasQuery ||
            url.hasFragment ||
            token.isEmpty ||
            protocols.isEmpty) {
          throw const FormatException();
        }
        _connection = StudioMcpConnection(
          url,
          token,
          List.unmodifiable(protocols),
        );
        if (!_ready!.isCompleted) _ready!.complete();
      } on Object {
        _failReadiness();
      }
    } else if (event['type'] == 'response') {
      final pending = _requests.remove(event['id']);
      if (pending == null || pending.isCompleted) return;
      if (event['ok'] == true) {
        pending.complete();
      } else {
        final code = event['code'];
        if (code is String &&
            RegExp(r'^(control\.[a-z_]+|permission\.transfer_failed_[1-5])$')
                .hasMatch(code)) {
          _diagnosticCode = code;
        }
        pending.completeError(StateError('companion.command_failed'));
      }
    } else if (event['type'] == 'mutation' &&
        _state == StudioMcpState.ready &&
        _authorizedRoot != null &&
        event['projectRoot'] == _desiredRoot &&
        event['projectRoot'] == _authorizedRoot) {
      try {
        final resources = (event['resources'] as List)
            .map((resource) {
              final value = resource as Map;
              return StudioMcpResource(
                kind: value['kind'] as String,
                id: value['id'] as String,
              );
            })
            .toList(growable: false);
        _mutations.add(
          StudioMcpMutation(
            projectRoot: _authorizedRoot!,
            resources: resources,
            revision: event['revision'] as String,
            operationId: event['operationId'] as String?,
          ),
        );
      } on Object {
        _error = 'Une modification externe ne peut pas être synchronisée.';
        _publish();
      }
    }
  }

  Future<void> setProjectRoot(String? root) {
    if (root != null && (!p.isAbsolute(root) || root.contains('\u0000'))) {
      return Future.error(ArgumentError('project.root_invalid'));
    }
    if (_desiredRoot == root) return _rootChanges;
    _desiredRoot = root;
    _authorizedRoot = null;
    _rootsSynchronized = false;
    if (_state != StudioMcpState.ready) return Future.value();
    final update = _rootChanges.then((_) => _synchronizeRoots());
    _rootChanges = update.catchError((Object failure) {
      if (!_disposed) {
        _failReadiness(
          _diagnosticCode ??
              (failure is FormatException &&
                      failure.message == 'permission.bookmark_unavailable'
                  ? failure.message
                  : 'companion.unavailable'),
        );
      }
    });
    return _rootChanges;
  }

  Future<void> _synchronizeRoots() async {
    if (_rootsSynchronized && _authorizedRoot == _desiredRoot) return;
    final process = _process;
    if (process == null) return;
    final generation = _generation;
    while (!_disposed && generation == _generation) {
      final root = _desiredRoot;
      final bookmark = root == null
          ? null
          : await projectBookmark?.call(root).timeout(commandTimeout);
      if (root != null && projectBookmark != null && bookmark == null) {
        throw const FormatException('permission.bookmark_unavailable');
      }
      if (_disposed || generation != _generation) return;
      if (root != _desiredRoot) continue;
      final id = 'studio-${++_requestNumber}';
      final acknowledged = Completer<void>();
      _requests[id] = acknowledged;
      try {
        await Future.wait([
          acknowledged.future.timeout(commandTimeout),
          process.send({
            'id': id,
            'command': 'set_roots',
            'roots': [?root],
            if (bookmark != null)
              'grants': [
                {'root': root, 'bookmark': bookmark},
              ],
          }),
        ], eagerError: true);
      } finally {
        _requests.remove(id);
      }
      if (_disposed || generation != _generation) return;
      if (root == _desiredRoot) {
        _authorizedRoot = root;
        _rootsSynchronized = true;
        return;
      }
    }
  }

  Future<void> retry() async {
    if (_disposed ||
        _state == StudioMcpState.starting ||
        _state == StudioMcpState.stopping ||
        _state == StudioMcpState.ready) {
      return;
    }
    await stop();
    if (_owned.isNotEmpty) return;
    await start();
  }

  Future<void> stop() {
    if (_stopping != null) return _stopping!;
    _generation++;
    _connection = null;
    _authorizedRoot = null;
    _rootsSynchronized = false;
    _state = StudioMcpState.stopping;
    final ready = _ready;
    if (ready != null && !ready.isCompleted) ready.complete();
    _cancelRequests();
    _publish();
    return _stopping = _stop().whenComplete(() => _stopping = null);
  }

  Future<void> _stop() async {
    try {
      await _stopOwned();
      _state = StudioMcpState.stopped;
    } on Object {
      _state = StudioMcpState.failed;
      _error =
          'La connexion aux assistants ne peut pas être arrêtée. Réessayez.';
    }
    _publish();
  }

  Future<void> _stopOwned() => _ownedStopping ??= _performStopOwned()
      .whenComplete(() => _ownedStopping = null);

  Future<void> _performStopOwned() async {
    await _events?.cancel();
    _events = null;
    await Future.wait(_owned.toList().map(_shutdown));
  }

  Future<void> _shutdown(StudioMcpProcess process) =>
      _shutdowns[process] ??= process
          .shutdown()
          .timeout(stopTimeout)
          .then((_) {
            _owned.remove(process);
            if (identical(_process, process)) _process = null;
          })
          .whenComplete(() {
            _shutdowns.remove(process);
          });

  void _cancelRequests() {
    final pending = _requests.values.toList();
    _requests.clear();
    for (final request in pending) {
      if (!request.isCompleted) {
        request.completeError(StateError('companion.stopped'));
      }
    }
  }

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(stop());
    unawaited(_mutations.close());
    super.dispose();
  }
}
