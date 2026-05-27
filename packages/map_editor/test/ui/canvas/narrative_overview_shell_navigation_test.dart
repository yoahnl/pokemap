import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/narrative_library_panel.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'NarrativeWorkspaceCanvas routes overview mode to the overview shell',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorNotifierProvider.overrideWith(
              () => _SeededEditorNotifier(
                EditorState(
                  workspaceMode: EditorWorkspaceMode.narrativeOverview,
                  project: _minimalProject('test_project'),
                ),
              ),
            ),
          ],
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 1000,
                  height: 720,
                  child: NarrativeWorkspaceCanvas(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Aperçu'), findsWidgets);
      expect(find.textContaining('test_project'), findsWidgets);
      expect(find.textContaining('Non évalué'), findsWidgets);
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.text('42'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'NarrativeLibraryPanel exposes overview without removing existing studios',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorNotifierProvider.overrideWith(
              () => _SeededEditorNotifier(
                EditorState(
                  workspaceMode: EditorWorkspaceMode.globalStory,
                  project: _minimalProject('test_project'),
                ),
              ),
            ),
          ],
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: const MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 360,
                  height: 640,
                  child: Column(
                    children: [
                      Expanded(child: NarrativeLibraryPanel(embedded: true)),
                      _WorkspaceModeProbe(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Aperçu'), findsOneWidget);
      expect(find.text('Histoire globale'), findsOneWidget);
      expect(find.text('Étape'), findsOneWidget);
      expect(find.text('Cinématique'), findsOneWidget);
      expect(find.text('Dialogue'), findsOneWidget);

      await tester.tap(find.text('Aperçu'));
      await tester.pumpAndSettle();

      expect(
        find.text('workspace:narrativeOverview'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'NarrativeOverviewWorkspace captures a full editor shell screenshot when requested',
    (tester) async {
      if (!const bool.fromEnvironment('NS_HOME_09_CAPTURE_FULL_SHELL')) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_09_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize: const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        'ns_home_09_overview_full_shell.png',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byType(EditorShellPage),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
    },
  );
}

Future<void> _loadShellScreenshotFonts() async {
  final fontBytes =
      File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync();
  for (final family in <String>[
    'Roboto',
    'Arial',
    '.SF Pro Text',
    'SF Pro Text',
  ]) {
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(fontBytes)));
    await loader.load();
  }
}

ProjectManifest _minimalProject(String name) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
  );
}

class _WorkspaceModeProbe extends ConsumerWidget {
  const _WorkspaceModeProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(editorNotifierProvider).workspaceMode;
    return Text('workspace:${mode.name}');
  }
}

class _SeededEditorNotifier extends EditorNotifier {
  _SeededEditorNotifier(this.initialState);

  final EditorState initialState;

  @override
  EditorState build() {
    return initialState;
  }
}
