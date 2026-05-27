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
import 'package:map_editor/src/ui/design_system/pokemap_explorer_module_card.dart';
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
    'EditorShellPage presents coherent Narrative Studio overview chrome',
    (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_10_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize: const Size(1600, 1000),
      );

      expect(find.textContaining('Narrative Studio / Aperçu'), findsWidgets);
      expect(find.textContaining('Vue d’ensemble auteur'), findsWidgets);
      expect(find.textContaining('Narrative Overview'), findsNothing);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ProjectExplorerModuleCard &&
              widget.title == 'Narrative Studio' &&
              widget.selected,
        ),
        findsOneWidget,
      );

      expect(find.text('Aperçu'), findsWidgets);
      expect(find.text('Histoire globale'), findsOneWidget);
      expect(find.text('Étape'), findsOneWidget);
      expect(find.text('Cinématique'), findsOneWidget);
      expect(find.text('Dialogue'), findsWidgets);

      expect(find.text('Locale : FR'), findsNothing);
      expect(find.text('v0.3.0'), findsNothing);
      expect(find.text('Nouvelle storyline'), findsNothing);
      expect(find.text('Valider'), findsNothing);
      expect(find.textContaining('Selbrume'), findsNothing);
      expect(find.text('42'), findsNothing);
      expect(find.text('1 236'), findsNothing);
      expect(find.text('1236'), findsNothing);
      expect(find.text('24'), findsNothing);
      expect(find.text('12'), findsNothing);
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

  testWidgets(
    'NarrativeOverviewWorkspace captures NS-HOME-10 shell chrome screenshots when requested',
    (tester) async {
      const captureDesktop =
          bool.fromEnvironment('NS_HOME_10_CAPTURE_SHELL_DESKTOP');
      const captureFooter =
          bool.fromEnvironment('NS_HOME_10_CAPTURE_SHELL_FOOTER');
      if (!captureDesktop && !captureFooter) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_10_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize:
            captureFooter ? const Size(1600, 1300) : const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      if (captureFooter) {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('narrative-overview-footer')),
          650,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('narrative-overview-scroll')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureFooter ? 'ns_home_10_shell_chrome_footer.png' : 'ns_home_10_shell_chrome_desktop.png'}',
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
