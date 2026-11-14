import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'studio_mcp_models.dart';
import 'studio_mcp_process.dart';

export 'studio_mcp_models.dart';

part 'studio_mcp_events.dart';
part 'studio_mcp_roots.dart';

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
  String? get readyClientConfiguration =>
      _state == StudioMcpState.ready ? _connection?.clientConfiguration : null;
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
