import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/dialogs/top_toolbar_dialogs.dart';
import 'package:map_editor/src/ui/shared/top_toolbar/widgets/toolbar_capsules.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('TopToolbar', () {
    test('normalizes manual project paths for the macOS picker fallback', () {
      expect(
        resolveProjectManifestPathFromUserSelection(
          '/Users/karim/PokeMapDemo',
        ),
        '/Users/karim/PokeMapDemo/project.json',
      );
      expect(
        resolveProjectManifestPathFromUserSelection(
          '"/Users/karim/PokeMapDemo/project.json"',
        ),
        '/Users/karim/PokeMapDemo/project.json',
      );
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        expect(
          resolveProjectManifestPathFromUserSelection('~/PokeMapDemo'),
          '$home/PokeMapDemo/project.json',
        );
      }
    });

    testWidgets('shows the app brand and project workspace label',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_project',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pokedex,
        ),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('Pokemon Map  •  Catalogues Pokémon'), findsOneWidget);
    });

    testWidgets('falls back to the workspace label when no project is loaded',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: const EditorState(),
      );

      expect(find.text('RPG Map Editor'), findsOneWidget);
      expect(find.text('World Editor'), findsOneWidget);
    });

    testWidgets('shows the toolbar status chip when a status is present',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_status',
          project: buildShellChromeProject(),
          statusMessage: 'Map saved',
        ),
      );

      expect(find.text('Map saved'), findsOneWidget);
    });

    testWidgets('shows the trainer studio label for the trainer workspace',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_trainer',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Pokemon Map  •  Trainer Studio'), findsOneWidget);
    });

    testWidgets('uses the French Narrative Studio overview chrome label',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_narrative_overview',
          project: buildShellChromeProject(name: 'test_project'),
          workspaceMode: EditorWorkspaceMode.narrativeOverview,
        ),
      );

      expect(
        find.text('test_project  •  Narrative Studio / Aperçu'),
        findsOneWidget,
      );
      expect(find.textContaining('Narrative Overview'), findsNothing);

      final overviewButton = tester.widget<ToolbarCapsuleButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton &&
              widget.tooltip == 'Ouvrir Narrative Studio / Aperçu',
        ),
      );
      expect(overviewButton.selected, isTrue);
      expect(overviewButton.onPressed, isNotNull);

      expect(find.text('Carte'), findsNothing);
      expect(find.text('Affichage'), findsNothing);
      expect(find.text('Calques'), findsNothing);

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      expect(
        buttonWithTooltip(
                'Nouvelle storyline à venir — création non branchée en V0')
            .onPressed,
        isNull,
      );
      expect(
        buttonWithTooltip(
                'Validation narrative à venir — aucun validateur global branché en V0')
            .onPressed,
        isNull,
      );
      expect(
        buttonWithTooltip(
                'Recherche narrative à venir — aucune recherche globale branchée en V0')
            .onPressed,
        isNull,
      );
      expect(
        buttonWithTooltip(
                'Notifications indisponibles — aucune source fiable en V0')
            .onPressed,
        isNull,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'New Map',
        ),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton &&
              widget.tooltip == 'Masquer/Afficher le panneau des calques',
        ),
        findsNothing,
      );
    });

    testWidgets('enables project save and disables map history in Path Studio',
        (tester) async {
      final projectDir = Directory('/tmp/top_toolbar_path_studio');
      if (!projectDir.existsSync()) {
        projectDir.createSync(recursive: true);
      }
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_path_studio',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pathStudio,
          activeMap: buildShellChromeMap(),
          isProjectDirty: true,
          canUndoMap: true,
          canRedoMap: true,
        ),
      );

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      final saveButton =
          buttonWithTooltip('Save Project — unsaved project changes');
      expect(saveButton.onPressed, isNotNull);
      expect(saveButton.selected, isTrue);
      expect(buttonWithTooltip('Undo').onPressed, isNull);
      expect(buttonWithTooltip('Redo').onPressed, isNull);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'Save Map',
        ),
        findsNothing,
      );
    });

    testWidgets(
        'shows neutral Save Project when project is clean in Path Studio',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_path_studio_clean',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.pathStudio,
          activeMap: buildShellChromeMap(),
          isProjectDirty: false,
        ),
      );

      final saveButton = tester.widget<ToolbarCapsuleButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton &&
              widget.tooltip == 'Save Project',
        ),
      );
      expect(saveButton.onPressed, isNotNull);
      expect(saveButton.selected, isFalse);
    });

    testWidgets(
        'enables project save and disables map history in Environment Studio',
        (tester) async {
      final projectDir = Directory('/tmp/top_toolbar_environment_studio');
      if (!projectDir.existsSync()) {
        projectDir.createSync(recursive: true);
      }
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_environment_studio',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.environmentStudio,
          activeMap: buildShellChromeMap(),
          isProjectDirty: true,
          canUndoMap: true,
          canRedoMap: true,
        ),
      );

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      final saveButton =
          buttonWithTooltip('Save Project — unsaved project changes');
      expect(saveButton.onPressed, isNotNull);
      expect(saveButton.selected, isTrue);
      expect(buttonWithTooltip('Undo').onPressed, isNull);
      expect(buttonWithTooltip('Redo').onPressed, isNull);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ToolbarCapsuleButton && widget.tooltip == 'Save Map',
        ),
        findsNothing,
      );
    });

    testWidgets('shows Environment Studio in the workspace brand strip',
        (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_env_label',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.environmentStudio,
        ),
      );

      expect(
        find.text('Pokemon Map  •  Environment Studio'),
        findsOneWidget,
      );
    });

    testWidgets('keeps map save action in map workspace', (tester) async {
      await pumpTopToolbarHarness(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/top_toolbar_map',
          project: buildShellChromeProject(name: 'Pokemon Map'),
          workspaceMode: EditorWorkspaceMode.map,
          activeMap: buildShellChromeMap(),
          canUndoMap: true,
          canRedoMap: true,
        ),
      );

      ToolbarCapsuleButton buttonWithTooltip(String tooltip) {
        return tester.widget<ToolbarCapsuleButton>(
          find.byWidgetPredicate(
            (widget) =>
                widget is ToolbarCapsuleButton && widget.tooltip == tooltip,
          ),
        );
      }

      expect(buttonWithTooltip('Save Map').onPressed, isNotNull);
      buttonWithTooltip('Save Map').onPressed?.call();
      await tester.pumpAndSettle();
    });
  });
}
