import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_preview_runner.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

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

  const sampleProject = ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
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

  testWidgets(
      'DialogueStudioWorkspace promotes creation into one shared workspace page',
      (tester) async {
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
            localizationsDelegates: [DefaultMaterialLocalizations.delegate],
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

    expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
    expect(
      find.widgetWithText(PokeMapButton, 'Nouveau dialogue'),
      findsOneWidget,
    );
    expect(find.text('+ Nouveau'), findsNothing);
    expect(find.byType(PokeMapEmptyState), findsOneWidget);

    await tester.tap(
      find.widgetWithText(PokeMapButton, 'Nouveau dialogue'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nouveau dialogue'), findsNWidgets(2));
    expect(find.text('Nom affiché'), findsOneWidget);
  });

  testWidgets('promoted creation keeps the selected target folder', (
    tester,
  ) async {
    final projectRepository = _CapturingProjectRepository();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(projectRepository),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _InMemoryProjectWorkspaceFactory(),
        ),
      ],
    );
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
            localizationsDelegates: [DefaultMaterialLocalizations.delegate],
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

    await tester.tap(find.text('PNJ').first);
    await tester.pump();
    expect(find.text('Import / nouveaux → dossier « PNJ »'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(PokeMapButton, 'Nouveau dialogue'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(MacosTextField), 'Dialogue ciblé');
    expect(find.text('Dialogue ciblé'), findsOneWidget);
    await tester.tap(find.widgetWithText(PushButton, 'Créer'));
    await _pumpUntil(
      tester,
      () => notifier.state.project!.dialogues.length == 2,
    );

    expect(notifier.state.errorMessage, isNull);
    expect(projectRepository.savedProjects, hasLength(1));
    expect(notifier.state.project!.dialogues, hasLength(2));
    final created = projectRepository.savedProjects.single.dialogues.last;
    expect(created.name, 'Dialogue ciblé');
    expect(created.folderId, 'f_npc');
  });

  testWidgets('project-missing state still uses the shared workspace page', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
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

    expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
    expect(find.text('Narrative Studio  /  Dialogues'), findsOneWidget);
    expect(find.byType(PokeMapEmptyState), findsOneWidget);
    expect(
      find.widgetWithText(PokeMapButton, 'Nouveau dialogue'),
      findsNothing,
    );
  });

  testWidgets(
    'project without a workspace exposes no disk-backed dialogue actions',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
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

      expect(
        find.byKey(
          const ValueKey<String>('dialogue-studio-workspace-unavailable'),
        ),
        findsOneWidget,
      );
      expect(find.text('Dossier projet indisponible'), findsOneWidget);
      expect(
        find.widgetWithText(PokeMapButton, 'Nouveau dialogue'),
        findsNothing,
      );
      expect(find.text('+ Dossier'), findsNothing);
      expect(find.text('Importer .yarn / .txt'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('preview displays the stable result selected by the author', (
    tester,
  ) async {
    await tester.pumpWidget(
      MacosTheme(
        data: MacosThemeData.light(),
        child: const CupertinoApp(
          home: CupertinoPageScaffold(
            child: DialoguePreviewEndedView(
              event: DialoguePreviewEnded(outcomeId: 'accepted'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Résultat · accepted'), findsOneWidget);
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

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxFrames = 30,
}) async {
  for (var frame = 0; frame < maxFrames && !condition(); frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(
    condition(),
    isTrue,
    reason: 'La condition attendue n\'a pas été atteinte en $maxFrames frames.',
  );
}

class _CapturingProjectRepository implements ProjectRepository {
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedProjects.add(project);
  }
}

class _InMemoryProjectWorkspaceFactory implements ProjectWorkspaceFactory {
  const _InMemoryProjectWorkspaceFactory();

  @override
  ProjectWorkspace create(String projectRoot) {
    return _InMemoryProjectWorkspace(projectRoot);
  }
}

class _InMemoryProjectWorkspace implements ProjectWorkspace {
  const _InMemoryProjectWorkspace(this.projectRoot);

  @override
  final String projectRoot;

  @override
  String get projectManifestPath => '$projectRoot/project.json';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '$projectRoot/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}
