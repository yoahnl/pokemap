import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import '../../shell_chrome_test_harness.dart';
import '../../support/narrative_studio_capture_fonts.dart';

const _captureFontFamily = 'PokeMapCharacterStudioCapture';

void main() {
  for (final testCase in <({double width, bool light})>[
    (width: 1672, light: false),
    (width: 1440, light: true),
    (width: 1280, light: false),
  ]) {
    testWidgets(
      'dense Studio fits the real shell at ${testCase.width.toInt()} px '
      'in ${testCase.light ? 'light' : 'dark'} theme',
      (tester) async {
        await pumpEditorShellPage(
          tester,
          initialState: _studioState(_denseProject()),
          surfaceSize: Size(testCase.width, 941),
          useLightTheme: testCase.light,
        );

        expect(
          find.byKey(const ValueKey<String>('character-studio-workspace')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final testCase in <({String name, ProjectManifest project, bool light})>[
    (name: 'zero characters', project: _emptyProject(), light: false),
    (name: 'one character', project: _singleProject(), light: true),
    (name: 'fifty characters', project: _denseProject(), light: false),
  ]) {
    testWidgets('${testCase.name} remain usable at the 720 px minimum', (
      tester,
    ) async {
      await pumpEditorCanvasHostHarness(
        tester,
        initialState: _studioState(testCase.project),
        surfaceSize: const Size(720, 840),
        useLightTheme: testCase.light,
      );

      expect(
        find.byKey(const ValueKey<String>('character-studio-layout-compact')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'twenty portrait states and custom animations fit every compact section',
    (tester) async {
      await pumpEditorCanvasHostHarness(
        tester,
        initialState: _studioState(_denseProject()),
        surfaceSize: const Size(720, 840),
        useLightTheme: true,
      );

      for (final key in const <ValueKey<String>>[
        ValueKey<String>('character-studio-tab-portraits'),
        ValueKey<String>('character-studio-tab-animations'),
        ValueKey<String>('character-studio-tab-identity'),
      ]) {
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: key.value);
      }
    },
  );

  testWidgets('screen-reader regions and controls expose explicit labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final project = _denseProject();
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: _studioState(project),
      surfaceSize: const Size(1672, 840),
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
    expect(
      find.bySemanticsLabel(RegExp(r'^Sélectionner ')),
      findsAtLeastNWidgets(1),
    );
    expect(find.textContaining('points à corriger'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keyboard traversal keeps visible focus across Studio zones', (
    tester,
  ) async {
    await pumpEditorCanvasHostHarness(
      tester,
      initialState: _studioState(_denseProject()),
      surfaceSize: const Size(1672, 840),
    );

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

  test('primary Studio text contrast exceeds WCAG AA in both themes', () {
    for (final colors in const <PokeMapColorTokens>[
      PokeMapColorTokens.light,
      PokeMapColorTokens.dark,
    ]) {
      expect(
        _contrastRatio(colors.textPrimary, colors.contentSurface),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  for (final goldenCase in const <({String name, double width, bool light})>[
    (name: 'dark-wide', width: 1672, light: false),
    (name: 'light-medium', width: 1280, light: true),
  ]) {
    testWidgets('matches the premium ${goldenCase.name} Studio golden', (
      tester,
    ) async {
      await loadNarrativeStudioCaptureFonts(
        textFamilies: const <String>[_captureFontFamily],
      );
      await pumpEditorShellPage(
        tester,
        initialState: _studioState(_denseProject()),
        surfaceSize: Size(goldenCase.width, 941),
        useLightTheme: goldenCase.light,
        fontFamily: _captureFontFamily,
        cupertinoFontFamily: _captureFontFamily,
      );

      await expectLater(
        find.byType(EditorShellPage),
        matchesGoldenFile(
          '../../goldens/character_studio/'
          'character_studio_${goldenCase.name}_${goldenCase.width.toInt()}x941.png',
        ),
      );
    });
  }
}

EditorState _studioState(ProjectManifest project) => EditorState(
  projectRootPath: '/tmp/character-studio-responsive',
  project: project,
  workspaceMode: EditorWorkspaceMode.characterStudio,
  selectedCharacterId: project.characters.firstOrNull?.id,
  statusMessage: 'Sauvegardé à l’instant',
);

ProjectManifest _emptyProject() => buildShellChromeProject(
  name: 'Projet sans personnage',
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'characters_main',
      name: 'Sprites des personnages',
      relativePath: 'tilesets/characters.png',
    ),
  ],
);

ProjectManifest _singleProject() => _emptyProject().copyWith(
  characters: const <ProjectCharacterEntry>[
    ProjectCharacterEntry(
      id: 'elia',
      name:
          'Élia, gardienne des archives septentrionales et des libellés interminables',
      tilesetId: 'characters_main',
      tags: <String>[
        'personnage principal extrêmement déterminé',
        'exploratrice des contrées lointaines',
      ],
    ),
  ],
  settings: const ProjectSettings(defaultPlayerCharacterId: 'elia'),
);

ProjectManifest _denseProject() => _singleProject().copyWith(
  characters: List<ProjectCharacterEntry>.generate(
    50,
    (index) => ProjectCharacterEntry(
      id: 'character_${index.toString().padLeft(2, '0')}',
      name: index == 0
          ? 'Élia, gardienne des archives septentrionales et des libellés interminables'
          : 'Personnage ${index.toString().padLeft(2, '0')} au nom volontairement très détaillé',
      tilesetId: 'characters_main',
      sortOrder: index,
      tags: const <String>[
        'personnage principal extrêmement déterminé',
        'exploratrice des contrées lointaines',
      ],
    ),
  ),
  settings: const ProjectSettings(defaultPlayerCharacterId: 'character_00'),
  characterStudioCatalog: ProjectCharacterStudioCatalog(
    portraitStates: List<CharacterPortraitStateDefinition>.generate(
      20,
      (index) => CharacterPortraitStateDefinition(
        id: 'portrait_state_${index.toString().padLeft(2, '0')}',
        displayName:
            'Expression ${index.toString().padLeft(2, '0')} au libellé français détaillé',
        sortOrder: index,
      ),
    ),
    customAnimationDefinitions: List<CharacterCustomAnimationDefinition>.generate(
      20,
      (index) => CharacterCustomAnimationDefinition(
        id: 'custom_${index.toString().padLeft(2, '0')}',
        displayName:
            'Animation ${index.toString().padLeft(2, '0')} au libellé français détaillé',
        mode: index.isEven
            ? CharacterCustomAnimationMode.directional
            : CharacterCustomAnimationMode.single,
        sortOrder: index,
      ),
    ),
  ),
);

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

Future<bool> _focusByTab(
  WidgetTester tester,
  Key regionKey, {
  int maxTabs = 120,
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
