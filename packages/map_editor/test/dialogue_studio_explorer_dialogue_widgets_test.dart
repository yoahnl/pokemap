import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  late Directory tempProjectRoot;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('map_editor_dlg_widget_');
    final yarn = File(
      '${tempProjectRoot.path}/dialogues/pnj/dlg_hi.yarn',
    );
    await yarn.parent.create(recursive: true);
    await yarn.writeAsString('title: Salut\n---\n===\n');
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  const sampleProject = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
    name: 'widget_test_proj',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
    dialogueFolders: [
      ProjectDialogueFolder(id: 'f_npc', name: 'PNJ'),
    ],
    dialogues: [
      ProjectDialogueEntry(
        id: 'dlg_hi',
        name: 'Salut',
        relativePath: 'dialogues/pnj/dlg_hi.yarn',
        folderId: 'f_npc',
      ),
    ],
  );

  testWidgets('DialogueStudioWorkspace shows import control and tree rows', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: tempProjectRoot.path,
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.dialogue,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1100,
                height: 720,
                child: DialogueStudioWorkspace(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Importer .yarn / .txt'), findsOneWidget);
    expect(find.text('PNJ'), findsWidgets);
    expect(find.text('Salut'), findsOneWidget);
  });

  testWidgets('selecting a dialogue updates selectedProjectDialogueId', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: tempProjectRoot.path,
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.dialogue,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1100,
                height: 720,
                child: DialogueStudioWorkspace(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salut'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(notifier.state.selectedProjectDialogueId, 'dlg_hi');
  });

  testWidgets('ProjectExplorerPanel has no embedded project dialogues card', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: tempProjectRoot.path,
      project: sampleProject,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 420,
                height: 900,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dialogues (projet)'), findsNothing);
    expect(find.text('Dialogue Library'), findsNothing);
    expect(find.text('Tileset Library'), findsOneWidget);
  });
}
