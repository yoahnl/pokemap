import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/application/personalization_preview_fixtures.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_battle_inspector.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_player_surface_adapter.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('offers three presets, three sizes, colors and combat font', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var profile = const ProjectPresentationProfile();
    var state = PersonalizationBattlePreviewState.commands;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return Row(
              children: <Widget>[
                SizedBox(
                  width: 430,
                  child: SingleChildScrollView(
                    child: PersonalizationBattleInspector(
                      profile: profile,
                      previewState: state,
                      onPreviewStateChanged: (value) =>
                          setHostState(() => state = value),
                      onWindowsChanged: (windows) => setHostState(
                        () => profile = profile.copyWith(windows: windows),
                      ),
                      onLayoutsChanged: (layouts) => setHostState(
                        () => profile = profile.copyWith(layouts: layouts),
                      ),
                      onImportCombatFont: () {},
                      onUseSystemCombatFont: () {},
                    ),
                  ),
                ),
                Expanded(
                  child: PersonalizationLivePreview(
                    profile: profile,
                    projectName: 'Pokémon Aurore',
                    projectRootPath: '',
                    scene: PersonalizationStudioScene.battle,
                    battleState: state,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    for (final preset in <String>['classic', 'compact', 'cinematic']) {
      expect(
        find.byKey(ValueKey<String>('battle-preset-$preset')),
        findsOneWidget,
      );
    }
    for (final size in <String>['narrow', 'comfortable', 'wide']) {
      expect(find.byKey(ValueKey<String>('battle-size-$size')), findsOneWidget);
    }
    for (final previewState in PersonalizationBattlePreviewState.values) {
      expect(
        find.byKey(
          ValueKey<String>('battle-preview-state-${previewState.name}'),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('window-field-fill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('window-field-border-color')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('typography-import-combat')),
      findsOneWidget,
    );

    await _tap(tester, 'battle-preset-cinematic');
    expect(
      profile.layouts?.battle?.compact.slot,
      ProjectPresentationLayoutSlot.bottomCenter,
    );
    expect(
      profile.layouts?.battle?.regular.slot,
      ProjectPresentationLayoutSlot.right,
    );
    expect(
      profile.layouts?.battle?.expanded.slot,
      ProjectPresentationLayoutSlot.right,
    );

    await _tap(tester, 'battle-preset-compact');
    expect(
      profile.layouts?.battle?.regular.spacing,
      ProjectPresentationSpacing.compact,
    );
    expect(
      profile.layouts?.battle?.regular.width,
      ProjectPresentationContentWidth.narrow,
    );

    await _tap(tester, 'battle-preset-classic');
    expect(
      profile.layouts?.battle?.regular.slot,
      ProjectPresentationLayoutSlot.bottomCenter,
    );

    await _tap(tester, 'battle-size-wide');
    expect(
      profile.layouts?.battle?.compact.width,
      ProjectPresentationContentWidth.wide,
    );
    expect(
      profile.layouts?.battle?.regular.width,
      ProjectPresentationContentWidth.wide,
    );
    expect(
      profile.layouts?.battle?.expanded.width,
      ProjectPresentationContentWidth.wide,
    );

    await _tap(tester, 'battle-preview-state-moves');
    expect(find.text('Éco-Sphère'), findsOneWidget);
    expect(find.text('PLANTE · PP 0/10'), findsOneWidget);

    await _tap(tester, 'battle-preview-state-target');
    expect(find.text('ROUCOOL adverse'), findsOneWidget);

    await _tap(tester, 'battle-preview-state-message');
    expect(find.textContaining('Le vent se lève'), findsOneWidget);
    expect(
      tester
          .widget<PlayerBattleSurface>(find.byType(PlayerBattleSurface))
          .data
          .commands,
      isEmpty,
    );
  });

  for (final orientation in <String>['landscape', 'portrait']) {
    for (final state in PersonalizationBattlePreviewState.values) {
      testWidgets(
        '$orientation ${state.name} uses the shared styled battle widget',
        (tester) async {
          tester.view.physicalSize = const Size(1200, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final size = orientation == 'landscape'
              ? const Size(960, 540)
              : const Size(450, 800);
          await tester.pumpWidget(
            _app(
              Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: PersonalizationPlayerSurfaceAdapter(
                    profile: _styledProfile,
                    projectName: 'Pokémon Aurore',
                    projectRootPath: '',
                    scene: PersonalizationStudioScene.battle,
                    aspectRatio: orientation == 'landscape' ? 16 / 9 : 9 / 16,
                    battleState: state,
                  ),
                ),
              ),
            ),
          );

          final surface = tester.widget<PlayerBattleSurface>(
            find.byType(PlayerBattleSurface),
          );
          final title = tester.widget<Text>(find.text(surface.data.title));
          final context = tester.element(find.byType(PlayerBattleSurface));
          final panel = find.byKey(
            const ValueKey<String>('battle-command-panel'),
          );
          final material = tester.widget<Material>(
            find.descendant(of: panel, matching: find.byType(Material)).first,
          );
          expect(title.style?.fontFamily, 'Studio Combat');
          expect(
            context.playerSemanticTheme.battleHudSurface,
            const Color(0xFF224466),
          );
          expect(material.color, const Color(0xFF224466));
          expect(find.text('ROUCOOL'), findsOneWidget);
          expect(find.text('BRINDIBOU'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

final _styledProfile = ProjectPresentationProfile(
  theme: safeProjectSemanticTheme.copyWith(battleHudSurface: '#224466'),
  typography: const ProjectTypographyProfile(
    combat: ProjectTypographyRoleProfile(family: 'Studio Combat'),
  ),
  windows: const ProjectPresentationWindowsProfile(
    styles: <ProjectWindowStyleProfile>[
      ProjectWindowStyleProfile(
        id: 'default',
        fillToken: 'surface',
        borderToken: 'outline',
        borderWidth: 1,
        cornerRadius: 16,
        contentPadding: 24,
        shadowElevation: 8,
      ),
      ProjectWindowStyleProfile(
        id: 'battle',
        fillToken: 'battleHudSurface',
        borderToken: 'primary',
        borderWidth: 2,
        cornerRadius: 12,
        contentPadding: 12,
        shadowElevation: 4,
      ),
    ],
    defaultStyleId: 'default',
    pauseMenuStyleId: 'default',
    dialogueStyleId: 'default',
    battleStyleId: 'battle',
    pauseBackdropOpacity: .7,
  ),
  layouts: suggestedProjectPresentationLayouts('standard'),
);

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
