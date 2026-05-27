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
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

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
    'NarrativeWorkspaceCanvas renders the internal Narrative Studio shell',
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
                  width: 1200,
                  height: 760,
                  child: Column(
                    children: [
                      Expanded(child: NarrativeWorkspaceCanvas()),
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

      final shell = find.byKey(const ValueKey('narrative-studio-shell'));
      final sidebar = find.byKey(const ValueKey('narrative-studio-sidebar'));
      final transientNavigation = find
          .byKey(const ValueKey('narrative-studio-transitional-navigation'));
      final mainContent =
          find.byKey(const ValueKey('narrative-studio-main-content'));

      expect(shell, findsOneWidget);
      expect(sidebar, findsOneWidget);
      expect(transientNavigation, findsNothing);
      expect(mainContent, findsOneWidget);
      expect(
        find.descendant(
          of: shell,
          matching: find.byKey(const ValueKey('narrative-overview-scroll')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: shell, matching: find.byType(ProjectExplorerPanel)),
        findsNothing,
      );

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('narrative-studio-sidebar-overview')),
          matching: find.text('Actif'),
        ),
        findsOneWidget,
      );

      for (final label in <String>['Aperçu', 'Storylines', 'Scènes']) {
        expect(
          find.descendant(of: sidebar, matching: find.text(label)),
          findsOneWidget,
        );
      }
      for (final label in <String>['Cinématiques', 'Dialogues']) {
        expect(
          find.descendant(of: sidebar, matching: find.text(label)),
          findsOneWidget,
        );
      }

      await tester.tap(
        find.descendant(of: sidebar, matching: find.text('Storylines')),
      );
      await tester.pumpAndSettle();
      expect(find.text('workspace:globalStory'), findsOneWidget);

      await tester.tap(
        find.descendant(of: sidebar, matching: find.text('Scènes')),
      );
      await tester.pumpAndSettle();
      expect(find.text('workspace:step'), findsOneWidget);

      await tester.tap(
        find.descendant(of: sidebar, matching: find.text('Cinématiques')),
      );
      await tester.pumpAndSettle();
      expect(find.text('workspace:cutscene'), findsOneWidget);

      await tester.tap(
        find.descendant(of: sidebar, matching: find.text('Dialogues')),
      );
      await tester.pumpAndSettle();
      expect(find.text('workspace:dialogue'), findsOneWidget);

      await tester.tap(
        find.descendant(of: sidebar, matching: find.text('Aperçu')),
      );
      await tester.pumpAndSettle();
      expect(find.text('workspace:narrativeOverview'), findsOneWidget);

      expect(
        find.descendant(of: sidebar, matching: find.text('Maps')),
        findsNothing,
      );
      expect(
        find.descendant(of: sidebar, matching: find.text('À clarifier')),
        findsNothing,
      );

      for (final disabled in <String>[
        'Facts',
        'Règles du monde',
        'Validateur',
      ]) {
        expect(
          find.descendant(of: sidebar, matching: find.text(disabled)),
          findsOneWidget,
        );
      }
      for (final disabledState in <String>[
        'Nécessite un modèle',
        'À venir',
        'Non branché',
      ]) {
        expect(
          find.descendant(of: sidebar, matching: find.text(disabledState)),
          findsOneWidget,
        );
      }

      await tester
          .tap(find.descendant(of: sidebar, matching: find.text('Facts')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: sidebar, matching: find.text('Règles du monde')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: sidebar, matching: find.text('Validateur')),
      );
      await tester.pumpAndSettle();
      expect(find.text('workspace:narrativeOverview'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets(
    'NarrativeWorkspaceCanvas wires overview cards only to real narrative workspaces',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
                  width: 1200,
                  height: 1000,
                  child: Column(
                    children: [
                      Expanded(child: NarrativeWorkspaceCanvas()),
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

      Future<void> returnToOverview() async {
        await tester.tap(find.text('Aperçu').first);
        await tester.pumpAndSettle();
        expect(find.text('workspace:narrativeOverview'), findsOneWidget);
      }

      Future<void> tapOverviewCard(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tapOverviewCard('narrative-overview-kpi-chapters');
      expect(find.text('workspace:globalStory'), findsOneWidget);
      await returnToOverview();

      await tapOverviewCard('narrative-overview-kpi-scenes');
      expect(find.text('workspace:step'), findsOneWidget);
      await returnToOverview();

      await tapOverviewCard('narrative-overview-kpi-cutscenes');
      expect(find.text('workspace:cutscene'), findsOneWidget);
      await returnToOverview();

      await tapOverviewCard('narrative-overview-kpi-dialogues');
      expect(find.text('workspace:dialogue'), findsOneWidget);
      await returnToOverview();

      for (final disabledKpi in <String>[
        'narrative-overview-kpi-quests',
        'narrative-overview-kpi-open_issues',
      ]) {
        await tapOverviewCard(disabledKpi);
        expect(find.text('workspace:narrativeOverview'), findsOneWidget);
      }

      await tapOverviewCard('narrative-overview-module-cutscenes');
      expect(find.text('workspace:cutscene'), findsOneWidget);
      await returnToOverview();

      await tapOverviewCard('narrative-overview-module-dialogues');
      expect(find.text('workspace:dialogue'), findsOneWidget);
      await returnToOverview();

      for (final disabledModule in <String>[
        'narrative-overview-module-quests',
        'narrative-overview-module-conditions',
        'narrative-overview-module-world_rules',
        'narrative-overview-module-facts',
      ]) {
        await tapOverviewCard(disabledModule);
        expect(find.text('workspace:narrativeOverview'), findsOneWidget);
      }

      await tester.ensureVisible(
        find.byKey(const ValueKey('narrative-overview-main-story-card')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('narrative-overview-main-story-card')),
          matching: find.text('Modifier à venir'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('workspace:narrativeOverview'), findsOneWidget);
      expect(find.text('Maps'), findsNothing);

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

      await tester.tap(find.text('Histoire globale'));
      await tester.pumpAndSettle();

      expect(
        find.text('workspace:globalStory'),
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
        find.text(
            'Aperçu, histoire globale, étapes, cinématiques et dialogues'),
        findsOneWidget,
      );
      expect(find.text('World Explorer'), findsNothing);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ProjectExplorerModuleCard &&
              widget.title == 'Narrative Studio' &&
              widget.selected,
        ),
        findsOneWidget,
      );

      final narrativeCard = find.byWidgetPredicate(
        (widget) =>
            widget is ProjectExplorerModuleCard &&
            widget.title == 'Narrative Studio',
      );
      final tilesetCard = find.byWidgetPredicate(
        (widget) =>
            widget is ProjectExplorerModuleCard &&
            widget.title == 'Tileset Library',
      );
      final catalogsCard = find.byWidgetPredicate(
        (widget) =>
            widget is ProjectExplorerModuleCard &&
            widget.title == 'Catalogues Pokémon',
      );

      expect(
        tester.getTopLeft(narrativeCard).dy,
        lessThan(tester.getTopLeft(tilesetCard).dy),
      );
      expect(
        tester.getTopLeft(narrativeCard).dy,
        lessThan(tester.getTopLeft(catalogsCard).dy),
      );

      expect(find.text('Aperçu'), findsWidgets);
      expect(find.text('Histoire globale'), findsWidgets);
      expect(find.text('Étape'), findsWidgets);
      expect(find.text('Cinématique'), findsWidgets);
      expect(find.text('Dialogue'), findsWidgets);
      expect(find.text('World Maps'), findsOneWidget);
      expect(find.text('Tileset Library'), findsOneWidget);
      expect(find.text('Catalogues Pokémon'), findsOneWidget);
      expect(find.text('Trainer Studio'), findsOneWidget);
      expect(find.text('Path Library'), findsOneWidget);
      expect(find.text('Environment Studio'), findsWidgets);
      final projectExplorer = find.byType(ProjectExplorerPanel);
      expect(
        find.descendant(of: projectExplorer, matching: find.text('Facts')),
        findsNothing,
      );
      expect(
        find.descendant(
            of: projectExplorer, matching: find.text('World Rules')),
        findsNothing,
      );
      expect(
        find.descendant(of: projectExplorer, matching: find.text('Validateur')),
        findsNothing,
      );

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
    'ProjectExplorerPanel prioritizes narrative navigation in overview mode',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            editorNotifierProvider.overrideWith(
              () => _SeededEditorNotifier(
                EditorState(
                  projectRootPath: '/tmp/ns_home_11_sidebar_project',
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
                  width: 380,
                  height: 900,
                  child: ProjectExplorerPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(
            'Aperçu, histoire globale, étapes, cinématiques et dialogues'),
        findsOneWidget,
      );
      expect(find.text('World Explorer'), findsNothing);

      final narrativeCard = find.byWidgetPredicate(
        (widget) =>
            widget is ProjectExplorerModuleCard &&
            widget.title == 'Narrative Studio' &&
            widget.selected,
      );
      final tilesetCard = find.byWidgetPredicate(
        (widget) =>
            widget is ProjectExplorerModuleCard &&
            widget.title == 'Tileset Library',
      );

      expect(narrativeCard, findsOneWidget);
      expect(tilesetCard, findsOneWidget);
      expect(
        tester.getTopLeft(narrativeCard).dy,
        lessThan(tester.getTopLeft(tilesetCard).dy),
      );

      expect(find.text('Aperçu'), findsOneWidget);
      expect(find.text('Histoire globale'), findsOneWidget);
      expect(find.text('Étape'), findsOneWidget);
      expect(find.text('Cinématique'), findsOneWidget);
      expect(find.text('Dialogue'), findsOneWidget);
      expect(find.text('World Maps'), findsOneWidget);
      expect(find.text('Tileset Library'), findsOneWidget);
      expect(find.text('Catalogues Pokémon'), findsOneWidget);
      expect(find.text('Facts'), findsNothing);
      expect(find.text('World Rules'), findsNothing);
      expect(find.text('Validateur'), findsNothing);

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

  testWidgets(
    'NarrativeOverviewWorkspace captures NS-HOME-11 sidebar navigation screenshots when requested',
    (tester) async {
      const captureDesktop =
          bool.fromEnvironment('NS_HOME_11_CAPTURE_SIDEBAR_DESKTOP');
      const captureFocus =
          bool.fromEnvironment('NS_HOME_11_CAPTURE_SIDEBAR_FOCUS');
      if (!captureDesktop && !captureFocus) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_11_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize:
            captureFocus ? const Size(1180, 1000) : const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureFocus ? 'ns_home_11_sidebar_navigation_focus.png' : 'ns_home_11_sidebar_navigation_desktop.png'}',
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
    'NarrativeOverviewWorkspace captures NS-HOME-12 top bar screenshots when requested',
    (tester) async {
      const captureDesktop =
          bool.fromEnvironment('NS_HOME_12_CAPTURE_TOP_BAR_DESKTOP');
      const captureFocus =
          bool.fromEnvironment('NS_HOME_12_CAPTURE_TOP_BAR_FOCUS');
      if (!captureDesktop && !captureFocus) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_12_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize:
            captureFocus ? const Size(1600, 700) : const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureFocus ? 'ns_home_12_top_bar_action_focus.png' : 'ns_home_12_top_bar_desktop.png'}',
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
    'NarrativeOverviewWorkspace captures NS-HOME-13 breadcrumb header screenshots when requested',
    (tester) async {
      const captureDesktop =
          bool.fromEnvironment('NS_HOME_13_CAPTURE_BREADCRUMB_HEADER_DESKTOP');
      const captureFocus =
          bool.fromEnvironment('NS_HOME_13_CAPTURE_BREADCRUMB_HEADER_FOCUS');
      if (!captureDesktop && !captureFocus) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_13_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize:
            captureFocus ? const Size(1600, 700) : const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureFocus ? 'ns_home_13_breadcrumb_header_focus.png' : 'ns_home_13_breadcrumb_header_desktop.png'}',
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
    'NarrativeOverviewWorkspace captures NS-HOME-14 header density screenshots when requested',
    (tester) async {
      const captureDesktop =
          bool.fromEnvironment('NS_HOME_14_CAPTURE_HEADER_DENSITY_DESKTOP');
      const captureFocus =
          bool.fromEnvironment('NS_HOME_14_CAPTURE_HEADER_DENSITY_FOCUS');
      const captureMedium =
          bool.fromEnvironment('NS_HOME_14_CAPTURE_HEADER_DENSITY_MEDIUM');
      if (!captureDesktop && !captureFocus && !captureMedium) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_14_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize: captureMedium
            ? const Size(1180, 1000)
            : captureFocus
                ? const Size(1600, 700)
                : const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureMedium ? 'ns_home_14_header_density_medium.png' : captureFocus ? 'ns_home_14_header_density_focus.png' : 'ns_home_14_header_density_desktop.png'}',
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
    'NarrativeOverviewWorkspace captures NS-HOME-16 internal shell screenshots when requested',
    (tester) async {
      const captureDesktop =
          bool.fromEnvironment('NS_HOME_16_CAPTURE_STUDIO_SHELL_DESKTOP');
      const captureFocus =
          bool.fromEnvironment('NS_HOME_16_CAPTURE_STUDIO_SHELL_FOCUS');
      const captureMedium =
          bool.fromEnvironment('NS_HOME_16_CAPTURE_STUDIO_SHELL_MEDIUM');
      if (!captureDesktop && !captureFocus && !captureMedium) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_16_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize: captureMedium
            ? const Size(1180, 1000)
            : captureFocus
                ? const Size(1600, 700)
                : const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureMedium ? 'ns_home_16_narrative_studio_shell_medium.png' : captureFocus ? 'ns_home_16_narrative_studio_shell_focus.png' : 'ns_home_16_narrative_studio_shell_desktop.png'}',
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
    'NarrativeOverviewWorkspace captures NS-HOME-17 internal sidebar screenshots when requested',
    (tester) async {
      const captureDesktop =
          bool.fromEnvironment('NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_DESKTOP');
      const captureFocus =
          bool.fromEnvironment('NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_FOCUS');
      const captureMedium =
          bool.fromEnvironment('NS_HOME_17_CAPTURE_INTERNAL_SIDEBAR_MEDIUM');
      if (!captureDesktop && !captureFocus && !captureMedium) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_17_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize: captureMedium
            ? const Size(1180, 1000)
            : captureFocus
                ? const Size(1600, 700)
                : const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureMedium ? 'ns_home_17_internal_sidebar_medium.png' : captureFocus ? 'ns_home_17_internal_sidebar_focus.png' : 'ns_home_17_internal_sidebar_desktop.png'}',
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
    'NarrativeOverviewWorkspace captures NS-HOME-18 interaction wiring screenshots when requested',
    (tester) async {
      const captureDesktop =
          bool.fromEnvironment('NS_HOME_18_CAPTURE_INTERACTION_DESKTOP');
      const captureFocus =
          bool.fromEnvironment('NS_HOME_18_CAPTURE_INTERACTION_FOCUS');
      const captureDisabledStates = bool.fromEnvironment(
        'NS_HOME_18_CAPTURE_INTERACTION_DISABLED_STATES',
      );
      if (!captureDesktop && !captureFocus && !captureDisabledStates) {
        return;
      }

      await _loadShellScreenshotFonts();
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/ns_home_18_test_project',
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          project: _minimalProject('test_project'),
        ),
        surfaceSize:
            captureFocus ? const Size(1600, 700) : const Size(1600, 1000),
      );
      await tester.pump(const Duration(milliseconds: 100));

      if (captureDisabledStates) {
        await tester.drag(
          find.byKey(const ValueKey('narrative-overview-scroll')),
          const Offset(0, -520),
        );
        await tester.pumpAndSettle();
      }

      final screenshotFile = File(
        '../../reports/narrativeStudio/ui/screenshots/'
        '${captureDisabledStates ? 'ns_home_18_interaction_disabled_states.png' : captureFocus ? 'ns_home_18_interaction_wiring_focus.png' : 'ns_home_18_interaction_wiring_desktop.png'}',
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
