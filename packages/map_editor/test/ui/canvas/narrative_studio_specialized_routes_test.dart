import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_overview_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/narrative_studio_capture_fonts.dart';

const _specializedRoutesCaptureFontFamily =
    'NarrativeStudioSpecializedRoutesArial';

void main() {
  late Directory projectRoot;

  setUp(() async {
    projectRoot = await Directory.systemTemp.createTemp(
      'map_editor_specialized_routes_',
    );
  });

  tearDown(() async {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  });

  final routeCases = <({
    EditorWorkspaceMode mode,
    Type workspaceType,
    String breadcrumb,
  })>[
    (
      mode: EditorWorkspaceMode.narrativeOverview,
      workspaceType: NarrativeOverviewWorkspace,
      breadcrumb: 'Narrative Studio  /  Aperçu',
    ),
    (
      mode: EditorWorkspaceMode.dialogue,
      workspaceType: DialogueStudioWorkspace,
      breadcrumb: 'Narrative Studio  /  Dialogues',
    ),
    (
      mode: EditorWorkspaceMode.facts,
      workspaceType: FactsWorldRulesWorkspace,
      breadcrumb: 'Narrative Studio  /  Facts',
    ),
    (
      mode: EditorWorkspaceMode.worldRules,
      workspaceType: FactsWorldRulesWorkspace,
      breadcrumb: 'Narrative Studio  /  Règles du monde',
    ),
  ];

  for (final routeCase in routeCases) {
    testWidgets(
      '${routeCase.mode.name} full route owns exactly one shared product shell and context',
      (tester) async {
        final project = _project();
        final activeMap = _map();
        final container = await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            projectRootPath: projectRoot.path,
            project: project,
            activeMap: activeMap,
            workspaceMode: routeCase.mode,
            isProjectDirty: true,
          ),
          surfaceSize: const Size(1672, 941),
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(routeCase.workspaceType), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(find.text(routeCase.breadcrumb), findsOneWidget);
        expect(find.text('Modifications non enregistrées'), findsOneWidget);
        expect(container.read(editorNotifierProvider).project, project);
        expect(container.read(editorNotifierProvider).activeMap, activeMap);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'product navigation switches Overview, Dialogues, Facts and World Rules without mutating project or map',
    (tester) async {
      final project = _project();
      final activeMap = _map();
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: projectRoot.path,
          project: project,
          activeMap: activeMap,
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
          isProjectDirty: true,
        ),
        surfaceSize: const Size(1672, 941),
      );

      for (final destination in <({String key, EditorWorkspaceMode mode})>[
        (
          key: 'narrative-studio-product-nav-dialogues',
          mode: EditorWorkspaceMode.dialogue,
        ),
        (
          key: 'narrative-studio-product-nav-facts',
          mode: EditorWorkspaceMode.facts,
        ),
        (
          key: 'narrative-studio-product-nav-worldRules',
          mode: EditorWorkspaceMode.worldRules,
        ),
        (
          key: 'narrative-studio-product-nav-overview',
          mode: EditorWorkspaceMode.narrativeOverview,
        ),
      ]) {
        await tester.tap(find.byKey(ValueKey<String>(destination.key)));
        await tester.pumpAndSettle();

        final state = container.read(editorNotifierProvider);
        expect(state.workspaceMode, destination.mode);
        expect(state.project, project);
        expect(state.activeMap, activeMap);
        expect(state.isProjectDirty, isTrue);
        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final mode in <EditorWorkspaceMode>[
    EditorWorkspaceMode.narrativeOverview,
    EditorWorkspaceMode.dialogue,
    EditorWorkspaceMode.facts,
    EditorWorkspaceMode.worldRules,
  ]) {
    testWidgets(
      '${mode.name} keeps its shared context when no project is loaded',
      (tester) async {
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(workspaceMode: mode),
          surfaceSize: const Size(1280, 768),
        );

        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(find.text('Aucun projet chargé'), findsOneWidget);
        if (mode == EditorWorkspaceMode.narrativeOverview) {
          expect(
            find.byKey(
              const ValueKey('narrative-overview-project-unavailable'),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  const responsiveSizes = <Size>[
    Size(1280, 768),
    Size(1366, 768),
    Size(1440, 900),
    Size(1672, 941),
    Size(1920, 941),
  ];
  const responsiveTextScales = <double>[1, 1.25, 1.5];

  for (final routeCase in routeCases) {
    for (final size in responsiveSizes) {
      for (final textScale in responsiveTextScales) {
        testWidgets(
          '${routeCase.mode.name} is overflow-free at '
          '${size.width}x${size.height} and ${textScale * 100}% text',
          (tester) async {
            tester.platformDispatcher.textScaleFactorTestValue = textScale;
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );

            await pumpEditorShellPage(
              tester,
              initialState: EditorState(
                projectRootPath: projectRoot.path,
                project: _project(),
                activeMap: _map(),
                workspaceMode: routeCase.mode,
              ),
              surfaceSize: size,
            );

            expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
            expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final goldenCase in <({
    EditorWorkspaceMode mode,
    String routeName,
  })>[
    (
      mode: EditorWorkspaceMode.narrativeOverview,
      routeName: 'overview',
    ),
    (
      mode: EditorWorkspaceMode.dialogue,
      routeName: 'dialogues',
    ),
    (
      mode: EditorWorkspaceMode.facts,
      routeName: 'facts',
    ),
    (
      mode: EditorWorkspaceMode.worldRules,
      routeName: 'world_rules',
    ),
  ]) {
    testWidgets(
      'matches the full ${goldenCase.routeName} product route at 1672x941',
      (tester) async {
        await _loadSpecializedRoutesCaptureFonts();
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            projectRootPath: projectRoot.path,
            project: _project(),
            activeMap: _map(),
            workspaceMode: goldenCase.mode,
          ),
          surfaceSize: const Size(1672, 941),
          fontFamily: _specializedRoutesCaptureFontFamily,
          cupertinoFontFamily: _specializedRoutesCaptureFontFamily,
        );
        await tester.pumpAndSettle();

        final output = File(
          'test/goldens/narrative_studio/${goldenCase.routeName}/'
          '${goldenCase.routeName}_full_product_route_1672x941.png',
        );
        output.parent.createSync(recursive: true);
        await expectLater(
          find.byType(EditorShellPage),
          matchesGoldenFile(output.absolute.path),
        );
      },
    );
  }
}

Future<void> _loadSpecializedRoutesCaptureFonts() async {
  await loadNarrativeStudioCaptureFonts(
    textFamilies: const <String>[_specializedRoutesCaptureFontFamily],
  );
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Specialized routes',
    maps: const [
      ProjectMapEntry(
        id: 'map_route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
    ],
    tilesets: const [],
    facts: [
      NarrativeFactDefinition(id: 'fact_started', label: 'A commencé'),
    ],
  );
}

MapData _map() {
  return const MapData(
    id: 'map_route',
    name: 'Route',
    size: GridSize(width: 12, height: 10),
  );
}
