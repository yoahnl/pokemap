import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_builder_workspace.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematics_library_workspace.dart';
import 'package:map_editor/src/ui/canvas/cutscene_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_workspace_page.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  testWidgets(
    'Cinematics keeps one product shell and page through Library, Builder and legacy',
    (tester) async {
      final project = _cinematicsProject();
      final before = project.toJson();

      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: project,
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: const Size(1672, 941),
      );

      void expectSharedRoute() {
        expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
        expect(find.byType(NarrativeStudioProductNavigation), findsOneWidget);
        expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
        expect(find.byType(ProjectExplorerPanel), findsNothing);
        expect(
          find.byKey(
            const ValueKey<String>(
              'narrative-studio-product-nav-cinematics',
            ),
          ),
          findsOneWidget,
        );
      }

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematics-library-workspace')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cinematic-builder-workspace')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Narrative Studio  /  Cinématiques  /  Intro cinématique',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-back-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey('cinematics-library-open-legacy-button'),
        ),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CutsceneStudioWorkspace), findsOneWidget);
      expect(find.text('Narrative Studio  ›  Step  ›  Cutscene'), findsNothing);
      for (final action in <String>[
        'Sauvegarder',
        'Réinitialiser',
        'Nouvelle cutscene',
      ]) {
        expect(find.text(action), findsOneWidget);
      }
      expect(find.text('Tester'), findsNothing);
      expect(find.text('Simuler'), findsNothing);
      expect(
        find.text('Narrative Studio  /  Cinématiques  /  Ancien studio'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('cinematics-library-back-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-back-button')),
      );
      await tester.pumpAndSettle();

      expectSharedRoute();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
      expect(project.toJson(), before);
    },
  );

  testWidgets('Cinematics project-absent state still owns one shared page', (
    tester,
  ) async {
    await pumpEditorShellPage(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1280, 768),
    );

    expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
    expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
    expect(find.byType(ProjectExplorerPanel), findsNothing);
    expect(find.text('Aucun projet chargé'), findsOneWidget);
    expect(
      find.text(
        'Chargez un projet pour ouvrir la bibliothèque et les outils cinématiques.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Cinematics shared route is responsive at supported widths', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.25;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final size in <Size>[
      const Size(1280, 768),
      const Size(1366, 768),
      const Size(1440, 900),
      const Size(1672, 941),
      const Size(1920, 941),
    ]) {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          project: _cinematicsProject(),
          workspaceMode: EditorWorkspaceMode.cutscene,
        ),
        surfaceSize: size,
      );

      expect(find.byType(NarrativeStudioProductShell), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Library viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-open-builder-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CinematicBuilderWorkspace), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Builder viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematic-builder-back-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('cinematics-library-open-legacy-button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CutsceneStudioWorkspace), findsOneWidget);
      expect(find.byType(NarrativeStudioWorkspacePage), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Legacy viewport: $size');

      await tester.tap(
        find.byKey(const ValueKey('cinematics-library-back-button')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CinematicsLibraryWorkspace), findsOneWidget);
    }
  });

  for (final goldenState in <String>['library', 'builder', 'legacy']) {
    testWidgets(
      'matches the full Cinematics $goldenState route at 1672x941',
      (tester) async {
        await loadEventBuilderV2PhaseKCaptureFonts();
        await pumpEditorShellPage(
          tester,
          initialState: EditorState(
            project: _cinematicsProject(),
            workspaceMode: EditorWorkspaceMode.cutscene,
          ),
          surfaceSize: const Size(1672, 941),
          fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
          cupertinoFontFamily: eventBuilderV2PhaseKCaptureFontFamily,
        );

        if (goldenState == 'builder') {
          await tester.tap(
            find.byKey(const ValueKey('cinematic-entry-cinematic_intro')),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              const ValueKey('cinematics-library-open-builder-button'),
            ),
          );
        } else if (goldenState == 'legacy') {
          await tester.tap(
            find.byKey(
              const ValueKey('cinematics-library-open-legacy-button'),
            ),
          );
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        final golden = File(
          'test/goldens/narrative_studio/cinematics/'
          'cinematics_${goldenState}_full_product_route_1672x941.png',
        );
        golden.parent.createSync(recursive: true);
        await expectLater(
          find.byType(EditorShellPage),
          matchesGoldenFile(golden.absolute.path),
        );
      },
    );
  }
}

ProjectManifest _cinematicsProject() {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: 'Cinématiques route fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: const <ScenarioAsset>[
      ScenarioAsset(
        id: 'scenario_legacy',
        name: 'Ancienne cinématique',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'start',
        metadata: <String, String>{
          'authoring.cutsceneSchema': 'cutscene-studio-v0',
        },
      ),
    ],
    cinematics: <CinematicAsset>[
      CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro cinématique',
        timeline: CinematicTimeline(),
      ),
    ],
  );
}
