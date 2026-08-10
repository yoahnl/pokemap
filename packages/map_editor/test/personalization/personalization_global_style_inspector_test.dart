import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_global_style_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('exposes exactly four simple global color controls', (
    tester,
  ) async {
    final edited = <String>[];
    await tester.pumpWidget(
      _app(
        PersonalizationGlobalStyleInspector(
          profile: const ProjectPresentationProfile(
            theme: safeProjectSemanticTheme,
          ),
          section: PersonalizationGlobalStyleSection.colors,
          onEditAccent: () => edited.add('accent'),
          onEditThemeToken: edited.add,
          onUseSafeFallback: () {},
          onWindowsChanged: (_) {},
          onImportCommonFont: () {},
          onUseSystemCommonFont: () {},
        ),
      ),
    );

    for (final role in <String>['accent', 'windows', 'text', 'buttons']) {
      expect(
        find.byKey(ValueKey<String>('global-style-color-$role')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('theme-edit-primary')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-color-accent')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-color-windows')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-color-text')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-color-buttons')),
    );

    expect(edited, <String>['accent', 'surface', 'textPrimary', 'primary']);
  });

  testWidgets('applies the three shape presets to every player window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var profile = const ProjectPresentationProfile(
      theme: safeProjectSemanticTheme,
    );
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return Row(
              children: <Widget>[
                SizedBox(
                  width: 380,
                  child: PersonalizationGlobalStyleInspector(
                    profile: profile,
                    section: PersonalizationGlobalStyleSection.forms,
                    onEditAccent: () {},
                    onEditThemeToken: (_) {},
                    onUseSafeFallback: () {},
                    onWindowsChanged: (windows) {
                      setHostState(
                        () => profile = profile.copyWith(windows: windows),
                      );
                    },
                    onImportCommonFont: () {},
                    onUseSystemCommonFont: () {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PersonalizationLivePreview(
                    profile: profile,
                    projectName: 'Pokémon Aurore',
                    projectRootPath: '',
                    scene: PersonalizationStudioScene.globalStyle,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    for (final preset in <String>['square', 'rounded', 'soft']) {
      expect(
        find.byKey(ValueKey<String>('global-shape-$preset')),
        findsOneWidget,
      );
    }
    await tester.tap(find.byKey(const ValueKey<String>('global-shape-soft')));
    await tester.pumpAndSettle();

    expect(
      profile.windows?.styles.map((style) => style.cornerRadius).toSet(),
      <int>{24},
    );
    expect(find.byType(PlayerTitleSurface), findsOneWidget);
    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
    expect(find.byType(RuntimePlayerPauseShell), findsOneWidget);
    expect(find.byType(PlayerBattleSurface), findsOneWidget);
    final dialogueContext = tester.element(find.byType(PlayerDialogueSurface));
    expect(
      dialogueContext.playerWindowTheme
          ?.style(ProjectWindowRole.dialogue)
          .cornerRadius,
      24,
    );
  });

  testWidgets('selects one common font without displaying its asset path', (
    tester,
  ) async {
    var importCalls = 0;
    const role = ProjectTypographyRoleProfile(
      fontPath: 'assets/presentation/fonts/aurore.ttf',
      family: 'Aurore Sans',
      licensePath: 'assets/presentation/fonts/OFL.txt',
      redistributable: true,
      fallbackFamilies: <String>['sans-serif'],
      glyphCoverage: <String>[
        'digits',
        'latin',
        'latinExtended',
        'punctuation',
      ],
    );
    await tester.pumpWidget(
      _app(
        PersonalizationGlobalStyleInspector(
          profile: const ProjectPresentationProfile(
            typography: ProjectTypographyProfile(
              display: role,
              body: role,
              dialogue: role,
              numbers: role,
            ),
            theme: safeProjectSemanticTheme,
          ),
          section: PersonalizationGlobalStyleSection.typography,
          onEditAccent: () {},
          onEditThemeToken: (_) {},
          onUseSafeFallback: () {},
          onWindowsChanged: (_) {},
          onImportCommonFont: () => importCalls += 1,
          onUseSystemCommonFont: () {},
        ),
      ),
    );

    expect(find.text('Aurore Sans'), findsOneWidget);
    expect(find.textContaining('assets/presentation'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('typography-import-common')),
    );
    expect(importCalls, 1);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
