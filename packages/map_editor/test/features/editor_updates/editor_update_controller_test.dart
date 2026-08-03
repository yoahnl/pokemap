import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor_updates/application/editor_update_controller.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_exit_readiness.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_native_updater.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_catalog.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_link_opener.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_models.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('automatic check is delayed and runs only once per session', () async {
    final delay = _ControlledTimerFactory();
    final catalog = _FakeCatalog()..nextRelease = _release();
    final controller = _controller(
      catalog: catalog,
      scheduleTimer: delay.call,
    );

    final first = controller.scheduleAutomaticCheck();
    final second = controller.scheduleAutomaticCheck();

    expect(identical(first, second), isTrue);
    expect(delay.durations, [const Duration(seconds: 12)]);
    expect(catalog.calls, 0);

    delay.completeNext();
    await first;

    expect(catalog.calls, 1);
    expect(controller.state.phase, EditorUpdatePhase.available);

    await controller.dispose();
  });

  test('unsupported platform never reads version or catalog', () async {
    final catalog = _FakeCatalog();
    final reader = _FakeVersionReader();
    final updater = _FakeNativeUpdater(isSupported: false);
    final controller = _controller(
      catalog: catalog,
      versionReader: reader,
      updater: updater,
    );

    await controller.checkManually();

    expect(controller.state.phase, EditorUpdatePhase.unsupported);
    expect(reader.calls, 0);
    expect(catalog.calls, 0);

    await controller.dispose();
  });

  test('manual no-update feedback is visible then returns to idle', () async {
    final delay = _ControlledTimerFactory();
    final controller = _controller(
      catalog: _FakeCatalog(),
      scheduleTimer: delay.call,
    );

    await controller.checkManually();

    expect(controller.state.phase, EditorUpdatePhase.upToDate);
    expect(controller.state.userInitiated, isTrue);
    expect(delay.durations, [const Duration(seconds: 4)]);

    delay.completeNext();
    await pumpEventQueue();
    expect(controller.state.phase, EditorUpdatePhase.idle);

    await controller.dispose();
  });

  test('concurrent checks share the active operation', () async {
    final response = Completer<EditorUpdateRelease?>();
    final catalog = _FakeCatalog()..pendingResponse = response.future;
    final controller = _controller(catalog: catalog);

    final first = controller.checkManually();
    final second = controller.checkManually();

    expect(identical(first, second), isTrue);
    await pumpEventQueue();
    expect(catalog.calls, 1);

    response.complete(_release());
    await first;
    expect(controller.state.phase, EditorUpdatePhase.available);

    await controller.dispose();
  });

  test('automatic failures stay silent and are logged once', () async {
    final failures = <EditorUpdateFailure>[];
    final catalog = _FakeCatalog()
      ..error = const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.timeout,
        'timeout',
      );
    final timerFactory = _ControlledTimerFactory();
    final controller = _controller(
      catalog: catalog,
      scheduleTimer: timerFactory.call,
      onBackgroundFailure: failures.add,
    );

    final automaticCheck = controller.scheduleAutomaticCheck();
    timerFactory.completeNext();
    await automaticCheck;

    expect(controller.state.phase, EditorUpdatePhase.idle);
    expect(controller.state.currentVersion, Version.parse('0.3.0'));
    expect(failures.single.code, 'timeout');

    await controller.dispose();
  });

  test('native handoff is blocked while unsaved work exists', () async {
    var readiness = EditorExitReadiness.fromBlockers([
      const EditorExitBlocker(
        id: 'active-map',
        kind: EditorExitBlockerKind.map,
      ),
    ]);
    final updater = _FakeNativeUpdater();
    final controller = _controller(
      catalog: _FakeCatalog()..nextRelease = _release(),
      updater: updater,
      readExitReadiness: () => readiness,
    );
    await controller.checkManually();

    await controller.openNativeUpdateFlow();
    expect(controller.state.phase, EditorUpdatePhase.blockedByUnsavedWork);
    expect(
      controller.state.exitBlockers,
      [
        const EditorExitBlocker(
          id: 'active-map',
          kind: EditorExitBlockerKind.map,
        ),
      ],
    );
    expect(updater.openCalls, 0);

    controller.returnToEditor();
    expect(controller.state.phase, EditorUpdatePhase.available);

    readiness = EditorExitReadiness.clean;
    await controller.openNativeUpdateFlow();
    expect(controller.state.phase, EditorUpdatePhase.handingOff);
    expect(updater.openCalls, 1);

    updater.emit(EditorNativeUpdateEvent.cancelled(updater.lastOperationId!));
    await pumpEventQueue();
    expect(controller.state.phase, EditorUpdatePhase.available);

    await controller.dispose();
  });

  test('release notes open externally and dismissing hides the banner',
      () async {
    final linkOpener = _FakeLinkOpener();
    final controller = _controller(
      catalog: _FakeCatalog()..nextRelease = _release(),
      linkOpener: linkOpener,
    );
    await controller.checkManually();

    await controller.openReleaseNotes();
    expect(linkOpener.openedUris, [_release().releaseNotesUri]);
    expect(controller.state.phase, EditorUpdatePhase.available);

    controller.dismissAvailableBanner();
    expect(controller.state.phase, EditorUpdatePhase.idle);
    expect(controller.state.currentVersion, Version.parse('0.3.0'));

    await controller.dispose();
  });

  test('restart request rechecks readiness after the native handoff', () async {
    var readiness = EditorExitReadiness.clean;
    final updater = _FakeNativeUpdater();
    final controller = _controller(
      catalog: _FakeCatalog()..nextRelease = _release(),
      updater: updater,
      readExitReadiness: () => readiness,
    );
    await controller.checkManually();
    await controller.openNativeUpdateFlow();

    readiness = EditorExitReadiness.fromBlockers([
      const EditorExitBlocker(
        id: 'dialogue',
        kind: EditorExitBlockerKind.dialogueStudio,
      ),
    ]);
    updater.emit(
      EditorNativeUpdateEvent.restartRequested(updater.lastOperationId!),
    );
    await pumpEventQueue();

    expect(updater.restartDecisions, [false]);
    expect(controller.state.phase, EditorUpdatePhase.blockedByUnsavedWork);

    await controller.dispose();
  });

  test('dispose prevents a delayed automatic check from starting', () async {
    final delay = _ControlledTimerFactory();
    final catalog = _FakeCatalog();
    final updater = _FakeNativeUpdater();
    final controller = _controller(
      catalog: catalog,
      updater: updater,
      scheduleTimer: delay.call,
    );

    final pending = controller.scheduleAutomaticCheck();
    await controller.dispose();
    expect(delay.hasActiveTimer, isFalse);
    expect(updater.isDisposed, isTrue);
    delay.completeNext();
    await pending;

    expect(catalog.calls, 0);
  });
}

EditorUpdateController _controller({
  required _FakeCatalog catalog,
  _FakeVersionReader? versionReader,
  _FakeNativeUpdater? updater,
  EditorUpdateTimerFactory? scheduleTimer,
  EditorExitReadiness Function()? readExitReadiness,
  void Function(EditorUpdateFailure)? onBackgroundFailure,
  EditorUpdateLinkOpener? linkOpener,
}) {
  return EditorUpdateController(
    catalog: catalog,
    installedVersionReader: versionReader ?? _FakeVersionReader(),
    nativeUpdater: updater ?? _FakeNativeUpdater(),
    scheduleTimer: scheduleTimer ?? Timer.new,
    readExitReadiness: readExitReadiness ?? () => EditorExitReadiness.clean,
    linkOpener: linkOpener ?? _FakeLinkOpener(),
    onBackgroundFailure: onBackgroundFailure,
  );
}

final class _FakeLinkOpener implements EditorUpdateLinkOpener {
  final openedUris = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    openedUris.add(uri);
    return true;
  }
}

EditorUpdateRelease _release() {
  return EditorUpdateRelease(
    version: Version.parse('0.3.1'),
    tag: 'pokemap-v0.3.1',
    publishedAt: DateTime.utc(2026, 8, 3),
    releaseNotesUri: Uri.parse(
      'https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.1',
    ),
  );
}

final class _FakeCatalog implements EditorUpdateCatalog {
  int calls = 0;
  EditorUpdateRelease? nextRelease;
  Future<EditorUpdateRelease?>? pendingResponse;
  Object? error;

  @override
  Future<EditorUpdateRelease?> latestStable(Version currentVersion) {
    calls += 1;
    if (error case final thrown?) {
      return Future.error(thrown);
    }
    return pendingResponse ?? Future.value(nextRelease);
  }
}

final class _FakeVersionReader implements EditorInstalledVersionReader {
  int calls = 0;

  @override
  Future<Version> read() async {
    calls += 1;
    return Version.parse('0.3.0');
  }
}

final class _FakeNativeUpdater implements EditorNativeUpdater {
  _FakeNativeUpdater({this.isSupported = true});

  final _events = StreamController<EditorNativeUpdateEvent>.broadcast();
  @override
  final bool isSupported;
  int openCalls = 0;
  String? lastOperationId;
  final restartDecisions = <bool>[];
  bool isDisposed = false;

  @override
  EditorNativeUpdaterCapabilities get capabilities =>
      EditorNativeUpdaterCapabilities.macosV1;

  @override
  Stream<EditorNativeUpdateEvent> get events => _events.stream;

  @override
  Stream<void> get manualCheckRequests => const Stream<void>.empty();

  @override
  Future<void> openUpdateFlow({
    required String operationId,
    required EditorUpdateRelease release,
  }) async {
    openCalls += 1;
    lastOperationId = operationId;
  }

  @override
  Future<void> respondToRestart({
    required String operationId,
    required bool canRestart,
  }) async {
    restartDecisions.add(canRestart);
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await _events.close();
  }

  void emit(EditorNativeUpdateEvent event) => _events.add(event);
}

final class _ControlledTimerFactory {
  final durations = <Duration>[];
  final _pending = <_ControlledTimer>[];

  Timer call(Duration duration, void Function() callback) {
    durations.add(duration);
    final timer = _ControlledTimer(callback);
    _pending.add(timer);
    return timer;
  }

  bool get hasActiveTimer => _pending.any((timer) => timer.isActive);

  void completeNext() => _pending.removeAt(0).fire();
}

final class _ControlledTimer implements Timer {
  _ControlledTimer(this._callback);

  final void Function() _callback;
  bool _isActive = true;

  void fire() {
    if (!_isActive) {
      return;
    }
    _isActive = false;
    _callback();
  }

  @override
  void cancel() => _isActive = false;

  @override
  bool get isActive => _isActive;

  @override
  int get tick => _isActive ? 0 : 1;
}
