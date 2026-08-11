import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_global_style_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('navigates through the three global style tabs', (tester) async {
    var section = PersonalizationGlobalStyleSection.colors;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return PersonalizationGlobalStyleInspector(
              profile: const ProjectPresentationProfile(
                theme: safeProjectSemanticTheme,
              ),
              section: section,
              onSectionChanged: (value) {
                setHostState(() => section = value);
              },
              onEditAccent: () {},
              onEditThemeToken: (_) {},
              onUseSafeFallback: () {},
              onWindowsChanged: (_) {},
              onImportCommonFont: () {},
              onUseSystemCommonFont: () {},
              onResetColors: () {},
              onResetWindows: () {},
              onResetTypography: () {},
            );
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('global-style-tab-colors')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('global-style-tab-windows')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('global-style-tab-typography')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('global-style-color-accent')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-tab-windows')),
    );
    await tester.pumpAndSettle();
    expect(section, PersonalizationGlobalStyleSection.forms);
    expect(
      find.byKey(const ValueKey<String>('global-shape-rounded')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-tab-typography')),
    );
    await tester.pumpAndSettle();
    expect(section, PersonalizationGlobalStyleSection.typography);
    expect(
      find.byKey(const ValueKey<String>('typography-import-common')),
      findsOneWidget,
    );
  });

  testWidgets('keeps advanced controls behind Plus de réglages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var section = PersonalizationGlobalStyleSection.colors;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SingleChildScrollView(
              child: PersonalizationGlobalStyleInspector(
                profile: const ProjectPresentationProfile(
                  theme: safeProjectSemanticTheme,
                ),
                section: section,
                onSectionChanged: (value) {
                  setHostState(() => section = value);
                },
                onEditAccent: () {},
                onEditThemeToken: (_) {},
                onUseSafeFallback: () {},
                onWindowsChanged: (_) {},
                onImportCommonFont: () {},
                onUseSystemCommonFont: () {},
                onResetColors: () {},
                onResetWindows: () {},
                onResetTypography: () {},
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Plus de réglages'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('theme-edit-primary')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-more-settings')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('theme-edit-primary')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-tab-windows')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('window-target-standard')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-more-settings')),
    );
    await tester.pump();
    for (final role in <String>['standard', 'pause', 'dialogue', 'battle']) {
      expect(
        find.byKey(ValueKey<String>('window-target-$role')),
        findsOneWidget,
      );
    }

    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-tab-typography')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('typography-import-common')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('global-style-more-settings')),
    );
    await tester.pump();
    for (final role in ProjectTypographyRole.values) {
      expect(
        find.byKey(ValueKey<String>('typography-import-${role.name}')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('typography-import-common')),
      findsNothing,
    );
  });

  testWidgets('offers an explicit reset for every global section', (
    tester,
  ) async {
    final resets = <PersonalizationGlobalStyleSection>[];
    var section = PersonalizationGlobalStyleSection.colors;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return PersonalizationGlobalStyleInspector(
              profile: const ProjectPresentationProfile(
                theme: safeProjectSemanticTheme,
              ),
              section: section,
              onSectionChanged: (value) {
                setHostState(() => section = value);
              },
              onEditAccent: () {},
              onEditThemeToken: (_) {},
              onUseSafeFallback: () {},
              onWindowsChanged: (_) {},
              onImportCommonFont: () {},
              onUseSystemCommonFont: () {},
              onResetColors: () =>
                  resets.add(PersonalizationGlobalStyleSection.colors),
              onResetWindows: () =>
                  resets.add(PersonalizationGlobalStyleSection.forms),
              onResetTypography: () =>
                  resets.add(PersonalizationGlobalStyleSection.typography),
            );
          },
        ),
      ),
    );

    for (final entry in <(String, PersonalizationGlobalStyleSection)>[
      ('colors', PersonalizationGlobalStyleSection.colors),
      ('windows', PersonalizationGlobalStyleSection.forms),
      ('typography', PersonalizationGlobalStyleSection.typography),
    ]) {
      await tester.tap(
        find.byKey(ValueKey<String>('global-style-tab-${entry.$1}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey<String>('global-style-reset-${entry.$1}')),
      );
      await tester.pump();
    }

    expect(resets, <PersonalizationGlobalStyleSection>[
      PersonalizationGlobalStyleSection.colors,
      PersonalizationGlobalStyleSection.forms,
      PersonalizationGlobalStyleSection.typography,
    ]);
  });

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
          onSectionChanged: (_) {},
          onEditAccent: () => edited.add('accent'),
          onEditThemeToken: edited.add,
          onUseSafeFallback: () {},
          onWindowsChanged: (_) {},
          onImportCommonFont: () {},
          onUseSystemCommonFont: () {},
          onResetColors: () {},
          onResetWindows: () {},
          onResetTypography: () {},
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
                    onSectionChanged: (_) {},
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
                    onResetColors: () {},
                    onResetWindows: () {},
                    onResetTypography: () {},
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
          onSectionChanged: (_) {},
          onEditAccent: () {},
          onEditThemeToken: (_) {},
          onUseSafeFallback: () {},
          onWindowsChanged: (_) {},
          onImportCommonFont: () => importCalls += 1,
          onUseSystemCommonFont: () {},
          onResetColors: () {},
          onResetWindows: () {},
          onResetTypography: () {},
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

  testWidgets('keeps contrast errors visible in the colors tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: PersonalizationGlobalStyleInspector(
            profile: ProjectPresentationProfile(
              theme: safeProjectSemanticTheme.copyWith(
                primary: '#111111',
                onPrimary: '#111111',
              ),
            ),
            section: PersonalizationGlobalStyleSection.colors,
            onSectionChanged: (_) {},
            onEditAccent: () {},
            onEditThemeToken: (_) {},
            onUseSafeFallback: () {},
            onWindowsChanged: (_) {},
            onImportCommonFont: () {},
            onUseSystemCommonFont: () {},
            onResetColors: () {},
            onResetWindows: () {},
            onResetTypography: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('global-style-contrast-gate')),
      findsOneWidget,
    );
    expect(
      find.text('Corrigez les contrastes avant de pouvoir enregistrer.'),
      findsOneWidget,
    );
  });

  testWidgets('remains usable at narrow width and 200 percent text scale', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SingleChildScrollView(
            child: PersonalizationGlobalStyleInspector(
              profile: const ProjectPresentationProfile(
                theme: safeProjectSemanticTheme,
              ),
              section: PersonalizationGlobalStyleSection.colors,
              onSectionChanged: (_) {},
              onEditAccent: () {},
              onEditThemeToken: (_) {},
              onUseSafeFallback: () {},
              onWindowsChanged: (_) {},
              onImportCommonFont: () {},
              onUseSystemCommonFont: () {},
              onResetColors: () {},
              onResetWindows: () {},
              onResetTypography: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final tabSemantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('global-style-tab-colors')),
            matching: find.byType(Semantics),
          ),
        )
        .map((widget) => widget.properties.label);
    final resetSemantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('global-style-reset-colors')),
            matching: find.byType(Semantics),
          ),
        )
        .map((widget) => widget.properties.label);
    expect(tabSemantics, contains('Onglet Couleurs'));
    expect(resetSemantics, contains('Réinitialiser les couleurs'));
    semantics.dispose();
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
