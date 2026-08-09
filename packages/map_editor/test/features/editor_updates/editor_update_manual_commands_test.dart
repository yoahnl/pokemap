import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor_updates/application/editor_update_providers.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_exit_readiness.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_native_updater.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_catalog.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_models.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/shared/top_toolbar.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';
import 'package:pub_semver/pub_semver.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'classic shell exposes the Help command and disables it in flight',
    (tester) async {
      final response = Completer<EditorUpdateRelease?>();
      final catalog = _FakeCatalog(response: response.future);
      final updater = _FakeNativeUpdater();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: buildShellChromeProject(),
          projectRootPath: '/tmp/editor-update-classic',
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
        overrides: _overrides(catalog, updater),
      );

      final action = find.byKey(editorUpdateCheckToolbarActionKey);
      expect(action, findsOneWidget);
      await tester.tap(action);
      await tester.pump();

      expect(catalog.calls, 1);
      final checkingAction = tester.widget<ToolbarCapsuleButton>(action);
      expect(checkingAction.onPressed, isNull);

      response.complete(null);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets('World Map exposes the same command in its Plus menu', (
    tester,
  ) async {
    final catalog = _FakeCatalog();
    final updater = _FakeNativeUpdater();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        project: buildShellChromeProject(),
        projectRootPath: '/tmp/editor-update-world-map',
        workspaceMode: EditorWorkspaceMode.map,
        activeMap: buildShellChromeMap(
          layers: const [MapLayer.tile(id: 'ground', name: 'Ground')],
        ),
        activeLayerId: 'ground',
      ),
      overrides: _overrides(catalog, updater),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-command-plus')),
    );
    await tester.pump();
    expect(find.text('Aide · Vérifier les mises à jour'), findsOneWidget);

    await tester.tap(find.text('Aide · Vérifier les mises à jour'));
    await tester.pump();
    expect(catalog.calls, 1);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('Narrative Studio exposes the shared update command', (
    tester,
  ) async {
    final catalog = _FakeCatalog();
    final updater = _FakeNativeUpdater();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        project: buildShellChromeProject(),
        projectRootPath: '/tmp/editor-update-narrative',
        workspaceMode: EditorWorkspaceMode.narrativeOverview,
      ),
      overrides: _overrides(catalog, updater),
    );

    expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
    final action = find.byKey(narrativeStudioCheckForUpdatesKey);
    expect(action, findsOneWidget);
    await tester.tap(action);
    await tester.pump();
    expect(catalog.calls, 1);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('native Help menu requests use the same guarded callback', (
    tester,
  ) async {
    final catalog = _FakeCatalog();
    final updater = _FakeNativeUpdater();
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        project: buildShellChromeProject(),
        projectRootPath: '/tmp/editor-update-native-menu',
        workspaceMode: EditorWorkspaceMode.narrativeOverview,
      ),
      overrides: _overrides(catalog, updater),
    );

    updater.requestManualCheck();
    await tester.pump();
    await tester.pump();
    expect(catalog.calls, 1);
    await tester.pump(const Duration(seconds: 4));
  });
}

List<Override> _overrides(_FakeCatalog catalog, _FakeNativeUpdater updater) {
  return [
    editorUpdateCatalogProvider.overrideWithValue(catalog),
    editorInstalledVersionReaderProvider.overrideWithValue(
      _FakeVersionReader(),
    ),
    editorNativeUpdaterProvider.overrideWithValue(updater),
    editorExitReadinessProvider.overrideWithValue(EditorExitReadiness.clean),
  ];
}

final class _FakeCatalog implements EditorUpdateCatalog {
  _FakeCatalog({this.response});

  final Future<EditorUpdateRelease?>? response;
  int calls = 0;

  @override
  Future<EditorUpdateRelease?> latestStable(Version currentVersion) {
    calls += 1;
    return response ?? Future.value();
  }
}

final class _FakeVersionReader implements EditorInstalledVersionReader {
  @override
  Future<Version> read() async => Version.parse('0.3.0');
}

final class _FakeNativeUpdater implements EditorNativeUpdater {
  final _events = StreamController<EditorNativeUpdateEvent>.broadcast();
  final _manualChecks = StreamController<void>.broadcast(sync: true);

  @override
  bool get isSupported => true;

  @override
  EditorNativeUpdaterCapabilities get capabilities =>
      EditorNativeUpdaterCapabilities.macosV1;

  @override
  Stream<EditorNativeUpdateEvent> get events => _events.stream;

  @override
  Stream<void> get manualCheckRequests => _manualChecks.stream;

  void requestManualCheck() => _manualChecks.add(null);

  @override
  Future<void> openUpdateFlow({
    required String operationId,
    required EditorUpdateRelease release,
  }) async {}

  @override
  Future<void> setRestartReady({required bool canRestart}) async {}

  @override
  Future<void> respondToRestart({
    required String operationId,
    required bool canRestart,
  }) async {}

  @override
  Future<void> dispose() async {
    await _events.close();
    await _manualChecks.close();
  }
}
