import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/character_studio/application/character_studio_media_resolver.dart';
import 'package:map_editor/src/features/character_studio/presentation/character_studio_workspace.dart';
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

  testWidgets('renders real sprite pixels in the library matrix and player', (
    tester,
  ) async {
    await loadNarrativeStudioCaptureFonts(
      textFamilies: const <String>[_captureFontFamily],
    );
    final mediaResolver = _MemorySpriteResolver(_spritePreviewAtlasBytes());
    final project = _spritePreviewProject();
    await pumpEditorShellPage(
      tester,
      initialState: _studioState(
        project,
        projectRootPath: '/character-studio-real-sprites',
      ),
      surfaceSize: const Size(1920, 1080),
      fontFamily: _captureFontFamily,
      cupertinoFontFamily: _captureFontFamily,
      overrides: [
        characterStudioMediaResolverProvider.overrideWithValue(mediaResolver),
      ],
    );
    final shellContext = tester.element(find.byType(EditorShellPage));
    await tester.runAsync(
      () => precacheImage(MemoryImage(mediaResolver.bytes), shellContext),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('character-studio-tab-animations')),
    );
    await tester.pump();
    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }

    expect(
      find.byKey(
        const ValueKey<String>('character-header-sprite-thumbnail-elia'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('character-studio-sprite-thumbnail-content'),
      ),
      findsAtLeastNWidgets(6),
    );
    expect(
      find.byKey(const ValueKey<String>('animation-preview-frame-0')),
      findsOneWidget,
    );
    await expectLater(
      find.byType(EditorShellPage),
      matchesGoldenFile(
        '../../goldens/character_studio/'
        'character_studio_real-sprite-previews_1920x1080.png',
      ),
    );
  });
}

EditorState _studioState(
  ProjectManifest project, {
  String projectRootPath = '/tmp/character-studio-responsive',
}) => EditorState(
  projectRootPath: projectRootPath,
  project: project,
  workspaceMode: EditorWorkspaceMode.characterStudio,
  selectedCharacterId: project.characters.firstOrNull?.id,
  statusMessage: 'Sauvegardé à l’instant',
);

ProjectManifest _spritePreviewProject() =>
    buildShellChromeProject(
      name: 'Projet previews sprites',
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'characters_main',
          name: 'Sprites de prévisualisation',
          relativePath: 'tilesets/characters.png',
        ),
      ],
    ).copyWith(
      characters: <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'elia',
          name: 'Élia — Sprite QA',
          tilesetId: 'characters_main',
          frameWidth: 1,
          frameHeight: 1,
          tags: const <String>['jouable', 'preview'],
          animations: <CharacterAnimation>[
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: CharacterAnimationState.idle,
                direction: direction,
                sourceAssetId: 'qa-sprite-atlas',
                frames: <CharacterAnimationFrame>[
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(
                      x: 0,
                      y: direction.index * 16,
                      width: 16,
                      height: 16,
                    ),
                  ),
                ],
              ),
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: CharacterAnimationState.walk,
                direction: direction,
                sourceAssetId: 'qa-sprite-atlas',
                frames: <CharacterAnimationFrame>[
                  for (var frame = 1; frame <= 3; frame++)
                    CharacterAnimationFrame(
                      source: TilesetSourceRect(
                        x: frame * 16,
                        y: direction.index * 16,
                        width: 16,
                        height: 16,
                      ),
                      durationMs: 125,
                    ),
                ],
              ),
          ],
        ),
      ],
      settings: const ProjectSettings(defaultPlayerCharacterId: 'elia'),
    );

Uint8List _spritePreviewAtlasBytes() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAABsUlEQVR4nO3YsUoDQRSF4TOHdD6AD6BgbyNYWaSItYWNxXaphK1k2SdYUy3pLAIptDCQ2hQWMYVgYy9oZeUDWCsICjsMc11GDOHkq8KFPwkJXGbWIWBza/8jNH97uXeh+V+/x39+PiHOhYbvD9fBX29j7/hX/8Aq9YQ4QhwhjhDn/EE3fw4ukG+39XZ0EXUroy+Mfmz0mdHPjL7X7AlxhDhCHCGOENfxB6+L05/XT483XxtzZ/cwulkb/SSxHyb2ZbueEEeIc6Hh+nmAELfq9/nUnhBHiCPEEeKcP+jn8+ip66I+iC6ifmX0hdGPjT4z+pnR95o9IY4QR4gjxBHiOv5gvjhPuo/PJ4n9MLEv2/WEOEKcCw3XzwOEuFW/z6f2hDhCHCGOEOf8wSC/jJ66zuqT6CIaVEZfGP3Y6DOjnxl9r9kT4ghxhDhCHCGu4w9Gi6uk+/hoktgPE/uyXU+II8S50HD9PECIW/X7fGpPiCPEEeIIcc4fTPMqeuo6qovoIppWRl8Y/djoM6OfGX2v2RPiCHGEOEIcIa7jD8rFXdJ9vJwk9sPEvmzXE+K47C+wbJ8xmR7ESBnctwAAAABJRU5ErkJggg==',
);

final class _MemorySpriteResolver
    implements CharacterStudioMediaResolverContract {
  const _MemorySpriteResolver(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) async => bytes;
}

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
