import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

void main() {
  group('UI smoke/non-regression panels', () {
    late Directory tempProjectRoot;

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('map_editor_ui_smoke_');

      // Le Dialogue Studio lit réellement le fichier référencé quand un
      // dialogue est sélectionné. Ce fixture garde le test honnête sans
      // introduire un bootstrap projet plus lourd que nécessaire.
      final yarn = File(
        '${tempProjectRoot.path}/dialogues/pnj/dlg_hi.yarn',
      );
      await yarn.parent.create(recursive: true);
      await yarn.writeAsString('title: Salut\n---\n<<jump End>>\n===\n');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    Future<void> pumpEditorSurface(
      WidgetTester tester,
      ProviderContainer container, {
      required Widget child,
      Size surfaceSize = const Size(1600, 1200),
    }) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              theme: ThemeData(splashFactory: NoSplash.splashFactory),
              home: CupertinoPageScaffold(
                child: Center(
                  child: SizedBox(
                    width: surfaceSize.width,
                    height: surfaceSize.height,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    ProjectManifest buildSampleProject() {
      return const ProjectManifest(
        name: 'ui_smoke_project',
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'route_1',
            name: 'Route 1',
            relativePath: 'maps/route_1.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tileset_world',
            name: 'World Tileset',
            relativePath: 'tilesets/world.png',
            isWorldTileset: true,
          ),
        ],
        dialogueFolders: <ProjectDialogueFolder>[
          ProjectDialogueFolder(id: 'f_npc', name: 'PNJ'),
        ],
        dialogues: <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dlg_hi',
            name: 'Salut',
            relativePath: 'dialogues/pnj/dlg_hi.yarn',
            folderId: 'f_npc',
          ),
        ],
      );
    }

    testWidgets('ProjectExplorerPanel renders world and tileset sections',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = buildSampleProject();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempProjectRoot.path,
        project: project,
      );

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 420,
          height: 980,
          child: ProjectExplorerPanel(),
        ),
        surfaceSize: const Size(900, 1200),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('World Explorer'), findsOneWidget);

      await tester.tap(find.text('World Maps'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Route 1'), findsOneWidget);
      expect(find.text('Tileset Library'), findsOneWidget);
      expect(find.text('Smart Tiles Studio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TilesetPalettePanel renders selected tileset wiring without crashing',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = buildSampleProject();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempProjectRoot.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.tileset,
        selectedTilesetEditorId: 'tileset_world',
      );

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 720,
          height: 980,
          child: TilesetPalettePanel(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Chargement de l’image du tileset'), findsOneWidget);
      expect(find.text('Tileset image unavailable'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'DialogueStudioWorkspace renders library and selected dialogue without crashing',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = buildSampleProject();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempProjectRoot.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.dialogue,
        selectedProjectDialogueId: 'dlg_hi',
      );

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 1280,
          height: 900,
          child: DialogueStudioWorkspace(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Importer .yarn / .txt'), findsOneWidget);
      expect(find.text('PNJ'), findsWidgets);
      expect(find.text('Salut'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

  });
}
