import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets(
    'EditorShellPage reduces and restores the global Project Explorer in Narrative Studio',
    (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_19_narrative_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _project(),
        ),
        surfaceSize: const Size(1600, 1000),
      );

      expect(find.byKey(const ValueKey('project-explorer-region')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('project-explorer-toggle')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-studio-sidebar')),
          findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('narrative-studio-shell')),
          matching: find.byType(ProjectExplorerPanel),
        ),
        findsNothing,
      );
      expect(_opacity(tester, 'project-explorer-expanded-state'), 1);
      expect(_opacity(tester, 'project-explorer-reduced-state'), 0);

      await tester.tap(find.byKey(const ValueKey('project-explorer-toggle')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('project-explorer-reduced')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('narrative-studio-sidebar')),
          findsOneWidget);
      expect(find.text('Facts'), findsWidgets);
      expect(find.text('Règles du monde'), findsWidgets);
      expect(find.text('Validateur'), findsWidgets);
      expect(find.text('Maps'), findsNothing);
      expect(_opacity(tester, 'project-explorer-expanded-state'), 0);
      expect(_opacity(tester, 'project-explorer-reduced-state'), 1);

      await tester
          .tap(find.byKey(const ValueKey('project-explorer-reopen-toggle')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(_opacity(tester, 'project-explorer-expanded-state'), 1);
      expect(_opacity(tester, 'project-explorer-reduced-state'), 0);
      expect(find.text('World Maps'), findsOneWidget);
    },
  );

  testWidgets(
    'EditorShellPage keeps non narrative Project Explorer behavior expanded by default',
    (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_19_map_project',
          workspaceMode: EditorWorkspaceMode.map,
          project: _project(),
          activeMap: _map(),
        ),
        surfaceSize: const Size(1600, 1000),
      );

      expect(find.byKey(const ValueKey('project-explorer-region')),
          findsOneWidget);
      expect(find.byType(ProjectExplorerPanel), findsOneWidget);
      expect(
          find.byKey(const ValueKey('narrative-studio-sidebar')), findsNothing);
      expect(find.text('World Explorer'), findsOneWidget);
      expect(find.text('World Maps'), findsOneWidget);
      expect(_opacity(tester, 'project-explorer-expanded-state'), 1);
      expect(_opacity(tester, 'project-explorer-reduced-state'), 0);
    },
  );

  testWidgets(
    'EditorShellPage captures NS-HOME-19 Project Explorer handoff screenshots when requested',
    (tester) async {
      const captureReducedDesktop =
          bool.fromEnvironment('NS_HOME_19_CAPTURE_REDUCED_DESKTOP');
      const captureReducedFocus =
          bool.fromEnvironment('NS_HOME_19_CAPTURE_REDUCED_FOCUS');
      const captureNonNarrative =
          bool.fromEnvironment('NS_HOME_19_CAPTURE_NON_NARRATIVE');
      if (!captureReducedDesktop &&
          !captureReducedFocus &&
          !captureNonNarrative) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: captureNonNarrative
              ? '/tmp/ns_home_19_map_project'
              : '/tmp/ns_home_19_narrative_project',
          workspaceMode: captureNonNarrative
              ? EditorWorkspaceMode.map
              : EditorWorkspaceMode.narrativeOverview,
          project: _project(),
          activeMap: captureNonNarrative ? _map() : null,
        ),
        surfaceSize: captureReducedFocus
            ? const Size(1600, 700)
            : const Size(1600, 1000),
      );

      if (!captureNonNarrative) {
        await tester.tap(find.byKey(const ValueKey('project-explorer-toggle')));
        await tester.pump(const Duration(milliseconds: 350));
      }

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureNonNarrative ? 'ns_home_19_project_explorer_non_narrative_regression.png' : captureReducedFocus ? 'ns_home_19_project_explorer_handoff_reduced_focus.png' : 'ns_home_19_project_explorer_handoff_reduced_desktop.png'}',
      );
      screenshotFile.parent.createSync(recursive: true);
      await expectLater(
        find.byType(EditorShellPage),
        matchesGoldenFile(screenshotFile.absolute.path),
      );

      expect(screenshotFile.existsSync(), isTrue);
      if (!captureNonNarrative) {
        await tester
            .tap(find.byKey(const ValueKey('project-explorer-reopen-toggle')));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
      }
    },
  );
}

double _opacity(WidgetTester tester, String key) {
  return tester.widget<AnimatedOpacity>(find.byKey(ValueKey(key))).opacity;
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

ProjectManifest _project() {
  return const ProjectManifest(
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
    name: 'test_project',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'test_map',
        name: 'Test Map',
        relativePath: 'maps/test_map.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
  );
}

MapData _map() {
  return const MapData(
    id: 'test_map',
    name: 'Test Map',
    size: GridSize(width: 20, height: 15),
    layers: <MapLayer>[],
  );
}
