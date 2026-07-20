import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets('chrome controls drive undo, redo, save and navigation guard',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(() => tester.runAsync(fixture.dispose));
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: fixture.root.path,
        project: fixture.before,
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1672, 941),
      settleInitialFrame: false,
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    await tester.runAsync(() async {
      await notifier.initializeNarrativeDocumentSession();
      await notifier.applyNarrativeDocumentEdit(
        fixture.local,
        operationId: 'ui-cinematic-edit',
        label: 'Renommer depuis le test UI',
      );
    });
    await _pumpUi(tester);

    expect(find.text('Modifié'), findsOneWidget);
    for (final key in [
      narrativeDocumentUndoActionKey,
      narrativeDocumentRedoActionKey,
      narrativeDocumentSaveActionKey,
      narrativeDocumentAutosaveActionKey,
      narrativeDocumentDiscardActionKey,
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }

    await _invokeIconAction(
      tester,
      narrativeDocumentUndoActionKey,
      waitUntil: () =>
          notifier.state.project!.cinematics.single.title == 'Introduction',
    );
    await _pumpUi(tester);
    expect(notifier.state.project!.cinematics.single.title, 'Introduction');
    await _invokeIconAction(
      tester,
      narrativeDocumentRedoActionKey,
      waitUntil: () =>
          notifier.state.project!.cinematics.single.title == 'Version locale',
    );
    await _pumpUi(tester);
    expect(notifier.state.project!.cinematics.single.title, 'Version locale');

    await _invokeIconAction(
      tester,
      narrativeDocumentSaveActionKey,
      waitUntil: () => !notifier.narrativeDocumentBlocksNavigation,
    );
    final durableTitle = await tester.runAsync(
      () => _readCinematicTitle(fixture.root),
    );
    expect(durableTitle, 'Version locale');
    await tester.runAsync(() async {
      final current = notifier.state.project!;
      await notifier.applyNarrativeDocumentEdit(
        current.copyWith(cinematics: fixture.before.cinematics),
        operationId: 'ui-cinematic-second-edit',
        label: 'Préparer le garde de navigation',
      );
    });
    await _pumpUi(tester);

    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-overview')),
    );
    await _pumpUi(tester);
    expect(find.text('Modifications Cinématiques en attente'), findsOneWidget);
    await tester.tap(find.text('Rester ici'));
    await _pumpUi(tester);
    expect(notifier.state.workspaceMode, EditorWorkspaceMode.cutscene);

    await _invokeIconAction(
      tester,
      narrativeDocumentDiscardActionKey,
      waitUntil: () =>
          notifier.state.project!.cinematics.single.title == 'Version locale' &&
          !notifier.narrativeDocumentBlocksNavigation,
    );
    await _pumpUi(tester);
    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-overview')),
    );
    await _pumpUi(tester);
    expect(notifier.state.workspaceMode, EditorWorkspaceMode.narrativeOverview);
    expect(notifier.state.project!.cinematics.single.title, 'Version locale');
    expect(find.byKey(narrativeDocumentUndoActionKey), findsNothing);
    expect(find.byKey(narrativeDocumentSaveActionKey), findsNothing);
  });

  testWidgets('conflict controls compare and reload the external version',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(() => tester.runAsync(fixture.dispose));
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: fixture.root.path,
        project: fixture.before,
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1672, 941),
      settleInitialFrame: false,
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    final saved = await tester.runAsync(() async {
      await notifier.initializeNarrativeDocumentSession();
      await notifier.applyNarrativeDocumentEdit(
        fixture.local,
        operationId: 'ui-conflict-edit',
        label: 'Préparer un conflit',
      );
      await _writeProject(fixture.root, fixture.external);
      return notifier.saveNarrativeDocument();
    });

    expect(saved, isFalse);
    await _pumpUi(tester);

    expect(find.text('Conflit'), findsOneWidget);
    expect(find.byKey(narrativeDocumentCompareActionKey), findsOneWidget);
    expect(find.byKey(narrativeDocumentReloadActionKey), findsOneWidget);
    expect(find.byKey(narrativeDocumentKeepLocalActionKey), findsOneWidget);

    await tester.tap(find.byKey(narrativeDocumentCompareActionKey));
    await _pumpUi(tester);
    expect(find.text('Comparer les versions Cinématiques'), findsOneWidget);
    expect(find.text('Base de la session'), findsOneWidget);
    expect(find.text('Version locale récupérable'), findsOneWidget);
    expect(find.text('Version externe sur disque'), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer'));
    await _pumpUi(tester);

    await _invokeIconAction(
      tester,
      narrativeDocumentReloadActionKey,
      waitUntil: () =>
          notifier.state.project!.cinematics.single.title == 'Version externe',
    );
    await _pumpUi(tester);
    expect(notifier.state.project!.cinematics.single.title, 'Version externe');
    expect(find.text('Enregistré'), findsOneWidget);
  });
}

final class _Fixture {
  const _Fixture({
    required this.root,
    required this.before,
    required this.local,
    required this.external,
  });

  final Directory root;
  final ProjectManifest before;
  final ProjectManifest local;
  final ProjectManifest external;

  Future<void> dispose() => root.delete(recursive: true);
}

Future<_Fixture> _fixture() async {
  final root = await Directory.systemTemp.createTemp('narrative-ui-session-');
  final before = _project('Introduction');
  final local = _project('Version locale');
  final external = _project('Version externe');
  await _writeProject(root, before);
  return _Fixture(
    root: root,
    before: before,
    local: local,
    external: external,
  );
}

ProjectManifest _project(String title) {
  return ProjectManifest(
    name: 'Narrative UI session',
    maps: const [],
    tilesets: const [],
    cinematics: [
      CinematicAsset(
        id: 'cinematic_intro',
        title: title,
        timeline: CinematicTimeline(),
      ),
    ],
  );
}

Future<void> _writeProject(Directory root, ProjectManifest project) {
  return File('${root.path}/project.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
    flush: true,
  );
}

Future<String> _readCinematicTitle(Directory root) async {
  final json =
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>;
  return ProjectManifest.fromJson(json).cinematics.single.title;
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 220));
}

Future<void> _invokeIconAction(
  WidgetTester tester,
  Key key, {
  required bool Function() waitUntil,
}) async {
  final button = tester.widget<PokeMapIconButton>(find.byKey(key));
  await tester.runAsync(() async {
    button.onPressed!.call();
    await _waitUntil(waitUntil);
  });
}

Future<void> _waitUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('The asynchronous UI action did not complete.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
