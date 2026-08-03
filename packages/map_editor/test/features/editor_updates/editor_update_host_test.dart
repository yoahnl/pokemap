import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor_updates/application/editor_update_providers.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_exit_readiness.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_native_updater.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_catalog.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_models.dart';
import 'package:map_editor/src/features/editor_updates/presentation/editor_update_host.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('controller creation does not eagerly initialize exit readiness', () {
    var readinessReads = 0;
    final nativeUpdater = _FakeNativeUpdater();
    final container = ProviderContainer(
      overrides: [
        editorNativeUpdaterProvider.overrideWithValue(nativeUpdater),
        editorExitReadinessProvider.overrideWith((ref) {
          readinessReads += 1;
          return EditorExitReadiness.clean;
        }),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorUpdateControllerProvider);

    expect(readinessReads, 0);
  });

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
    expect(nativeUpdater.restartReadyCalls, [true]);
    expect(delay.durations, [const Duration(seconds: 12)]);
    expect(catalog.calls, 0);

    await tester.pump();
    expect(delay.durations, hasLength(1));

    delay.completeNext();
    await tester.pump();
    await tester.pump();
    expect(catalog.calls, 1);
  });

  testWidgets('shows an available update without replacing the editor',
      (tester) async {
    final catalog = _FakeCatalog()..nextRelease = _release();
    final nativeUpdater = _FakeNativeUpdater();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorUpdateCatalogProvider.overrideWithValue(catalog),
          editorInstalledVersionReaderProvider.overrideWithValue(
            _FakeVersionReader(),
          ),
          editorNativeUpdaterProvider.overrideWithValue(nativeUpdater),
          editorExitReadinessProvider.overrideWithValue(
            EditorExitReadiness.clean,
          ),
        ],
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: const EditorUpdateHost(child: Text('Editor shell')),
        ),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.text('Editor shell')),
    );

    await container.read(editorUpdateControllerProvider).checkManually();
    await tester.pump();

    expect(find.text('Editor shell'), findsOneWidget);
    expect(find.text('Une nouvelle aventure t’attend ✨'), findsOneWidget);
    expect(find.text('Mettre à jour'), findsOneWidget);
  });

  testWidgets('lists every blocker and returns to the available banner',
      (tester) async {
    final catalog = _FakeCatalog()..nextRelease = _release();
    final nativeUpdater = _FakeNativeUpdater();
    final readiness = EditorExitReadiness.fromBlockers([
      const EditorExitBlocker(
        id: 'active-map',
        kind: EditorExitBlockerKind.map,
      ),
      const EditorExitBlocker(
        id: 'dialogue-draft',
        kind: EditorExitBlockerKind.dialogueStudio,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorUpdateCatalogProvider.overrideWithValue(catalog),
          editorInstalledVersionReaderProvider.overrideWithValue(
            _FakeVersionReader(),
          ),
          editorNativeUpdaterProvider.overrideWithValue(nativeUpdater),
          editorExitReadinessProvider.overrideWithValue(readiness),
        ],
        child: MaterialApp(
          theme: PokeMapTheme.light(),
          home: const EditorUpdateHost(child: Text('Editor shell')),
        ),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.text('Editor shell')),
    );
    final controller = container.read(editorUpdateControllerProvider);
    await controller.checkManually();
    await tester.pump();
    await tester.tap(find.text('Mettre à jour'));
    await tester.pump();

    expect(find.text('Des créations restent à sauvegarder'), findsOneWidget);
    expect(find.text('Carte active'), findsOneWidget);
    expect(find.text('Dialogue Studio'), findsOneWidget);
    expect(find.text('Sauvegarder et redémarrer'), findsNothing);
    expect(find.text('Revenir à l’éditeur'), findsOneWidget);
    expect(find.text('Réessayer le redémarrage'), findsOneWidget);

    await tester.tap(find.text('Revenir à l’éditeur'));
    await tester.pump();
    expect(find.text('Une nouvelle aventure t’attend ✨'), findsOneWidget);
    expect(nativeUpdater.openCalls, 0);
  });
}

final class _FakeCatalog implements EditorUpdateCatalog {
  int calls = 0;
  EditorUpdateRelease? nextRelease;

  @override
  Future<EditorUpdateRelease?> latestStable(Version currentVersion) async {
    calls += 1;
    return nextRelease;
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
  Stream<void> get manualCheckRequests => const Stream<void>.empty();

  int openCalls = 0;
  final restartReadyCalls = <bool>[];

  @override
  Future<void> openUpdateFlow({
    required String operationId,
    required EditorUpdateRelease release,
  }) async {
    openCalls += 1;
  }

  @override
  Future<void> setRestartReady({required bool canRestart}) async {
    restartReadyCalls.add(canRestart);
  }

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
