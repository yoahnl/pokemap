import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  for (final width in <double>[1672, 1440, 1280, 960, 720]) {
    testWidgets('Character Studio has no overflow at ${width.toInt()} px', (
      tester,
    ) async {
      await _pumpWorkspace(tester, width);

      expect(
        find.byKey(const ValueKey<String>('character-studio-canvas-region')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('wide layout exposes the three semantic regions', (tester) async {
    await _pumpWorkspace(tester, 1672);

    expect(
      find.byKey(const ValueKey<String>('character-studio-layout-wide')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Bibliothèque des personnages'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Espace d’édition du personnage'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Inspecteur Character Studio'),
      findsOneWidget,
    );
    expect(find.text('Prêt pour le runtime'), findsNothing);
  });

  testWidgets('selected character sprite appears in the canvas header', (
    tester,
  ) async {
    await _pumpWorkspace(tester, 1672);

    expect(
      find.byKey(
        const ValueKey<String>('character-header-sprite-thumbnail-elia'),
      ),
      findsOneWidget,
    );
  });

  for (final width in <double>[1080, 960]) {
    testWidgets('medium layout alternates library and inspector at $width px', (
      tester,
    ) async {
      await _pumpWorkspace(tester, width);

      expect(
        find.byKey(const ValueKey<String>('character-studio-layout-medium')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('character-studio-library-region')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('character-studio-inspector-region')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('character-studio-inspector-toggle')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('character-studio-library-region')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('character-studio-inspector-region')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('compact layout opens each region in an accessible side sheet', (
    tester,
  ) async {
    await _pumpWorkspace(tester, 720);

    expect(
      find.byKey(const ValueKey<String>('character-studio-layout-compact')),
      findsOneWidget,
    );
    expect(find.byType(PokeMapDesktopSideSheet), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey<String>('character-studio-library-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
    expect(
      find.bySemanticsLabel('Bibliothèque des personnages'),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('character-studio-inspector-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
    expect(
      find.bySemanticsLabel('Inspecteur Character Studio'),
      findsOneWidget,
    );
  });

  testWidgets('keyboard traversal reaches library and editor zones', (
    tester,
  ) async {
    await _pumpWorkspace(tester, 1672);

    expect(
      await _focusByTab(
        tester,
        const ValueKey<String>('character-library-search'),
      ),
      isTrue,
    );
    expect(
      await _focusByTab(
        tester,
        const ValueKey<String>('character-studio-tab-identity'),
      ),
      isTrue,
    );
  });

  testWidgets('real editor shell keeps the complete wide workspace', (
    tester,
  ) async {
    await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: '/tmp/character-studio-layout',
        project: _characterStudioProject(),
        workspaceMode: EditorWorkspaceMode.characterStudio,
        selectedCharacterId: 'elia',
        statusMessage: 'Sauvegardé à l’instant',
      ),
      surfaceSize: const Size(1672, 1000),
    );

    expect(
      find.byKey(const ValueKey<String>('character-studio-layout-wide')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('right-inspector-region')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('character-studio-library-region')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('character-studio-inspector-region')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing character never discards an identity draft silently', (
    tester,
  ) async {
    await _pumpWorkspace(tester, 1672);

    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-name')),
      'Élia modifiée',
    );
    await tester.pump();
    expect(find.text('Modifications non enregistrées'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-name')),
      'Élia',
    );
    await tester.pump();
    expect(find.text('Modifications non enregistrées'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-name')),
      'Élia modifiée',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey<String>('character-card-nox')));
    await tester.pumpAndSettle();
    expect(find.byKey(pokeMapConfirmationDialogKey), findsOneWidget);
    expect(find.text('Élia modifiée'), findsOneWidget);

    await tester.tap(find.text('Rester ici'));
    await tester.pumpAndSettle();
    expect(find.text('Élia modifiée'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('character-card-nox')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ignorer les modifications'));
    await tester.pumpAndSettle();
    final nameField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('character-identity-name')),
    );
    expect(nameField.controller?.text, 'Nox');
    expect(find.text('Modifications non enregistrées'), findsNothing);
  });

  testWidgets('identity draft survives leaving the whole workspace', (
    tester,
  ) async {
    final state = EditorState(
      projectRootPath: '/tmp/character-studio-layout',
      project: _characterStudioProject(),
      workspaceMode: EditorWorkspaceMode.characterStudio,
      selectedCharacterId: 'elia',
    );
    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: state,
      surfaceSize: const Size(1672, 840),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('character-identity-name')),
      'Élia persistante',
    );
    await tester.pump();
    container.read(editorNotifierProvider.notifier).state = state.copyWith(
      workspaceMode: EditorWorkspaceMode.map,
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('character-studio-workspace')),
      findsNothing,
    );

    container.read(editorNotifierProvider.notifier).state = state;
    await tester.pumpAndSettle();
    final nameField = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('character-identity-name')),
    );
    expect(nameField.controller?.text, 'Élia persistante');
    expect(find.text('Modifications non enregistrées'), findsOneWidget);
  });

  testWidgets('saving state disables character mutations', (tester) async {
    final state = EditorState(
      projectRootPath: '/tmp/character-studio-layout',
      project: _characterStudioProject(),
      workspaceMode: EditorWorkspaceMode.characterStudio,
      selectedCharacterId: 'elia',
    );
    final container = await pumpEditorCanvasHostHarness(
      tester,
      initialState: state,
      surfaceSize: const Size(1672, 840),
    );
    container.read(editorNotifierProvider.notifier).state = state.copyWith(
      isSaving: true,
    );
    await tester.pump();

    expect(
      tester
          .widget<PokeMapCard>(
            find.byKey(const ValueKey<String>('character-card-nox')),
          )
          .onTap,
      isNull,
    );
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey<String>('character-create-button')),
          )
          .onPressed,
      isNull,
    );
  });
}

Future<void> _pumpWorkspace(WidgetTester tester, double width) async {
  await pumpEditorCanvasHostHarness(
    tester,
    initialState: EditorState(
      projectRootPath: '/tmp/character-studio-layout',
      project: _characterStudioProject(),
      workspaceMode: EditorWorkspaceMode.characterStudio,
      selectedCharacterId: 'elia',
      statusMessage: 'Sauvegardé à l’instant',
    ),
    surfaceSize: Size(width, 840),
  );
}

Future<bool> _focusByTab(
  WidgetTester tester,
  Key regionKey, {
  int maxTabs = 40,
}) async {
  for (var index = 0; index < maxTabs; index++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focusContext = tester.binding.focusManager.primaryFocus?.context;
    final region = find.byKey(regionKey);
    if (focusContext == null || region.evaluate().isEmpty) continue;
    final regionElement = region.evaluate().single;
    var containsFocus = focusContext == regionElement;
    if (!containsFocus && focusContext is Element) {
      focusContext.visitAncestorElements((ancestor) {
        if (ancestor == regionElement) {
          containsFocus = true;
          return false;
        }
        return true;
      });
    }
    if (containsFocus) return true;
  }
  return false;
}

ProjectManifest _characterStudioProject() {
  return buildShellChromeProject(
    name: 'Character Studio certification',
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'characters_main',
        name: 'Sprites des héros',
        relativePath: 'tilesets/characters.png',
      ),
    ],
  ).copyWith(
    characters: const <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'characters_main',
        tags: <String>['héroïne'],
        animations: <CharacterAnimation>[
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            sourceAssetId: 'elia-idle-south',
            frames: <CharacterAnimationFrame>[
              CharacterAnimationFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
      ),
      ProjectCharacterEntry(
        id: 'nox',
        name: 'Nox',
        tilesetId: 'characters_main',
        tags: <String>['rival'],
      ),
    ],
    settings: const ProjectSettings(defaultPlayerCharacterId: 'elia'),
  );
}
