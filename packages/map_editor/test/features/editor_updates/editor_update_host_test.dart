import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor_updates/application/editor_update_providers.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_native_updater.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_catalog.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_models.dart';
import 'package:map_editor/src/features/editor_updates/presentation/editor_update_host.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  testWidgets('starts one delayed check without rebuilding the shell',
      (tester) async {
    final delay = _ControlledTimerFactory();
    final catalog = _FakeCatalog();
    final nativeUpdater = _FakeNativeUpdater();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorUpdateCatalogProvider.overrideWithValue(catalog),
          editorInstalledVersionReaderProvider.overrideWithValue(
            _FakeVersionReader(),
          ),
          editorNativeUpdaterProvider.overrideWithValue(nativeUpdater),
          editorUpdateTimerFactoryProvider.overrideWithValue(delay.call),
        ],
        child: const MaterialApp(
          home: EditorUpdateHost(
            child: Text('Editor shell'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Editor shell'), findsOneWidget);
    expect(delay.durations, [const Duration(seconds: 12)]);
    expect(catalog.calls, 0);

    await tester.pump();
    expect(delay.durations, hasLength(1));

    delay.completeNext();
    await tester.pump();
    await tester.pump();
    expect(catalog.calls, 1);
  });
}

final class _FakeCatalog implements EditorUpdateCatalog {
  int calls = 0;

  @override
  Future<EditorUpdateRelease?> latestStable(Version currentVersion) async {
    calls += 1;
    return null;
  }
}

final class _FakeVersionReader implements EditorInstalledVersionReader {
  @override
  Future<Version> read() async => Version.parse('0.3.0');
}

final class _FakeNativeUpdater implements EditorNativeUpdater {
  final _events = StreamController<EditorNativeUpdateEvent>.broadcast();

  @override
  bool get isSupported => true;

  @override
  EditorNativeUpdaterCapabilities get capabilities =>
      EditorNativeUpdaterCapabilities.macosV1;

  @override
  Stream<EditorNativeUpdateEvent> get events => _events.stream;

  @override
  Future<void> openUpdateFlow({
    required String operationId,
    required EditorUpdateRelease release,
  }) async {}

  @override
  Future<void> respondToRestart({
    required String operationId,
    required bool canRestart,
  }) async {}

  @override
  Future<void> dispose() async {
    await _events.close();
  }
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
