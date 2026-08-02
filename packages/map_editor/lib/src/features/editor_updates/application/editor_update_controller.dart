import 'dart:async';

import 'package:pub_semver/pub_semver.dart';

import '../domain/editor_exit_readiness.dart';
import '../domain/editor_native_updater.dart';
import '../domain/editor_update_catalog.dart';
import '../domain/editor_update_models.dart';

typedef EditorUpdateTimerFactory = Timer Function(
  Duration duration,
  void Function() callback,
);
typedef EditorExitReadinessReader = EditorExitReadiness Function();

final class EditorUpdateController {
  EditorUpdateController({
    required EditorUpdateCatalog catalog,
    required EditorInstalledVersionReader installedVersionReader,
    required EditorNativeUpdater nativeUpdater,
    required EditorExitReadinessReader readExitReadiness,
    EditorUpdateTimerFactory scheduleTimer = Timer.new,
    void Function(EditorUpdateFailure)? onBackgroundFailure,
    this.automaticCheckDelay = const Duration(seconds: 12),
    this.manualFeedbackDuration = const Duration(seconds: 4),
  })  : _catalog = catalog,
        _installedVersionReader = installedVersionReader,
        _nativeUpdater = nativeUpdater,
        _readExitReadiness = readExitReadiness,
        _scheduleTimer = scheduleTimer,
        _onBackgroundFailure = onBackgroundFailure {
    _nativeEventsSubscription = _nativeUpdater.events.listen(
      (event) => unawaited(_handleNativeEvent(event)),
    );
  }

  final EditorUpdateCatalog _catalog;
  final EditorInstalledVersionReader _installedVersionReader;
  final EditorNativeUpdater _nativeUpdater;
  final EditorExitReadinessReader _readExitReadiness;
  final EditorUpdateTimerFactory _scheduleTimer;
  final void Function(EditorUpdateFailure)? _onBackgroundFailure;
  final Duration automaticCheckDelay;
  final Duration manualFeedbackDuration;
  final StreamController<EditorUpdateState> _stateChanges =
      StreamController<EditorUpdateState>.broadcast(sync: true);

  late final StreamSubscription<EditorNativeUpdateEvent>
      _nativeEventsSubscription;
  EditorUpdateState _state = EditorUpdateState.idle();
  Future<void>? _automaticCheck;
  Completer<void>? _automaticCheckCompleter;
  Timer? _automaticCheckTimer;
  Timer? _manualFeedbackTimer;
  Future<void>? _activeCheck;
  Future<Version>? _installedVersion;
  EditorUpdateRelease? _availableRelease;
  String? _activeNativeOperationId;
  int _nextOperationId = 0;
  bool _disposed = false;

  EditorUpdateState get state => _state;
  Stream<EditorUpdateState> get stateChanges => _stateChanges.stream;

  Future<void> scheduleAutomaticCheck() {
    final existing = _automaticCheck;
    if (existing != null) {
      return existing;
    }
    final completer = Completer<void>();
    _automaticCheckCompleter = completer;
    _automaticCheck = completer.future;
    _automaticCheckTimer = _scheduleTimer(automaticCheckDelay, () {
      _automaticCheckTimer = null;
      if (_disposed) {
        _completeAutomaticCheck();
        return;
      }
      unawaited(
        _startCheck(userInitiated: false).whenComplete(
          _completeAutomaticCheck,
        ),
      );
    });
    return completer.future;
  }

  Future<void> checkManually() => _startCheck(userInitiated: true);

  Future<void> openNativeUpdateFlow() async {
    if (_disposed || !_nativeUpdater.isSupported) {
      return;
    }
    final release = _availableRelease;
    final currentVersion = _state.currentVersion;
    if (release == null || currentVersion == null) {
      return;
    }
    if (!_readExitReadiness().canExit) {
      _emit(
        EditorUpdateState.blockedByUnsavedWork(
          currentVersion: currentVersion,
          release: release,
        ),
      );
      return;
    }

    final operationId = 'editor-update-${++_nextOperationId}';
    _activeNativeOperationId = operationId;
    _emit(
      EditorUpdateState.handingOff(
        currentVersion: currentVersion,
        release: release,
      ),
    );
    try {
      await _nativeUpdater.openUpdateFlow(
        operationId: operationId,
        release: release,
      );
    } catch (error) {
      if (_disposed || _activeNativeOperationId != operationId) {
        return;
      }
      _emit(
        EditorUpdateState.failed(
          currentVersion: currentVersion,
          failure: _failureFrom(error, fallbackCode: 'native_update_failed'),
          userInitiated: true,
        ),
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _activeNativeOperationId = null;
    _automaticCheckTimer?.cancel();
    _automaticCheckTimer = null;
    _manualFeedbackTimer?.cancel();
    _manualFeedbackTimer = null;
    _completeAutomaticCheck();
    await _nativeEventsSubscription.cancel();
    await _nativeUpdater.dispose();
    await _stateChanges.close();
  }

  Future<void> _startCheck({required bool userInitiated}) {
    if (_disposed) {
      return Future.value();
    }
    final active = _activeCheck;
    if (active != null) {
      return active;
    }
    final operation = _performCheck(userInitiated: userInitiated);
    _activeCheck = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_activeCheck, operation)) {
          _activeCheck = null;
        }
      }),
    );
    return operation;
  }

  Future<void> _performCheck({required bool userInitiated}) async {
    if (!_nativeUpdater.isSupported) {
      _emit(EditorUpdateState.unsupported());
      return;
    }

    final previousRelease = _availableRelease;
    _emit(
      EditorUpdateState.checking(
        currentVersion: _state.currentVersion,
        userInitiated: userInitiated,
      ),
    );
    var currentVersion = _state.currentVersion;
    try {
      currentVersion =
          await (_installedVersion ??= _installedVersionReader.read());
      if (_disposed) {
        return;
      }
      final release = await _catalog.latestStable(currentVersion);
      if (_disposed) {
        return;
      }
      if (release != null) {
        _availableRelease = release;
        _emit(
          EditorUpdateState.available(
            currentVersion: currentVersion,
            release: release,
            userInitiated: userInitiated,
          ),
        );
        return;
      }
      if (previousRelease != null &&
          previousRelease.version.compareTo(currentVersion) > 0) {
        _availableRelease = previousRelease;
        _emit(
          EditorUpdateState.available(
            currentVersion: currentVersion,
            release: previousRelease,
            userInitiated: userInitiated,
          ),
        );
        return;
      }
      if (userInitiated) {
        final feedback = EditorUpdateState.upToDate(
          currentVersion: currentVersion,
        );
        _emit(feedback);
        _manualFeedbackTimer?.cancel();
        _manualFeedbackTimer = _scheduleTimer(manualFeedbackDuration, () {
          _manualFeedbackTimer = null;
          if (!_disposed && identical(_state, feedback)) {
            _emit(
              EditorUpdateState.idle(
                currentVersion: feedback.currentVersion,
              ),
            );
          }
        });
      } else {
        _emit(EditorUpdateState.idle(currentVersion: currentVersion));
      }
    } catch (error) {
      if (_disposed) {
        return;
      }
      final failure = _failureFrom(error);
      if (userInitiated) {
        _emit(
          EditorUpdateState.failed(
            currentVersion: currentVersion,
            failure: failure,
            userInitiated: true,
          ),
        );
      } else {
        _onBackgroundFailure?.call(failure);
        if (previousRelease != null && currentVersion != null) {
          _emit(
            EditorUpdateState.available(
              currentVersion: currentVersion,
              release: previousRelease,
              userInitiated: false,
            ),
          );
        } else {
          _emit(EditorUpdateState.idle(currentVersion: currentVersion));
        }
      }
    }
  }

  Future<void> _handleNativeEvent(EditorNativeUpdateEvent event) async {
    if (_disposed || event.operationId != _activeNativeOperationId) {
      return;
    }
    final release = _availableRelease;
    final currentVersion = _state.currentVersion;
    if (release == null || currentVersion == null) {
      return;
    }
    switch (event.kind) {
      case EditorNativeUpdateEventKind.cancelled:
      case EditorNativeUpdateEventKind.noUpdate:
        _activeNativeOperationId = null;
        _emit(
          EditorUpdateState.available(
            currentVersion: currentVersion,
            release: release,
            userInitiated: true,
          ),
        );
      case EditorNativeUpdateEventKind.installing:
        _emit(
          EditorUpdateState.installing(
            currentVersion: currentVersion,
            release: release,
          ),
        );
      case EditorNativeUpdateEventKind.restartRequested:
        final canRestart = _readExitReadiness().canExit;
        await _nativeUpdater.respondToRestart(
          operationId: event.operationId,
          canRestart: canRestart,
        );
        if (_disposed || event.operationId != _activeNativeOperationId) {
          return;
        }
        _emit(
          canRestart
              ? EditorUpdateState.restarting(
                  currentVersion: currentVersion,
                  release: release,
                )
              : EditorUpdateState.blockedByUnsavedWork(
                  currentVersion: currentVersion,
                  release: release,
                ),
        );
      case EditorNativeUpdateEventKind.failed:
        _activeNativeOperationId = null;
        _emit(
          EditorUpdateState.failed(
            currentVersion: currentVersion,
            failure: event.failure ??
                const EditorUpdateFailure(
                  code: 'native_update_failed',
                  message: 'The native update flow failed.',
                ),
            userInitiated: true,
          ),
        );
    }
  }

  EditorUpdateFailure _failureFrom(
    Object error, {
    String fallbackCode = 'update_check_failed',
  }) {
    if (error is EditorUpdateCatalogException) {
      return EditorUpdateFailure(
        code: error.code.name,
        message: error.message,
      );
    }
    return EditorUpdateFailure(
      code: fallbackCode,
      message: 'The update operation failed.',
    );
  }

  void _emit(EditorUpdateState state) {
    if (_disposed) {
      return;
    }
    _state = state;
    _stateChanges.add(state);
  }

  void _completeAutomaticCheck() {
    final completer = _automaticCheckCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
