import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_battle_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  testWidgets('shows one focused V10 battle section at a time', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var profile = const ProjectPresentationProfile();
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SingleChildScrollView(
              child: PersonalizationBattleInspector(
                profile: profile,
                previewState: PersonalizationBattlePreviewState.commands,
                onPreviewStateChanged: (_) {},
                onBattleChanged: (battle) => setHostState(
                  () => profile = profile.copyWith(battle: battle),
                ),
                onWindowsChanged: (_) {},
                onLayoutsChanged: (_) {},
                onImportCombatFont: () {},
                onUseSystemCombatFont: () {},
              ),
            );
          },
        ),
      ),
    );

    for (final section in <String>[
      'commands',
      'hud',
      'moves',
      'target',
      'message',
    ]) {
      expect(
        find.byKey(ValueKey<String>('battle-section-$section')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('battle-commands-editor')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-hud-editor')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('battle-section-hud')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('battle-commands-editor')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-hud-editor')),
      findsOneWidget,
    );
  });

  testWidgets('switches the runtime preview with each authored battle panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var preview = PersonalizationBattlePreviewState.commands;
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SingleChildScrollView(
              child: PersonalizationBattleInspector(
                profile: const ProjectPresentationProfile(),
                previewState: preview,
                onPreviewStateChanged: (value) =>
                    setHostState(() => preview = value),
                onBattleChanged: (_) {},
                onWindowsChanged: (_) {},
                onLayoutsChanged: (_) {},
                onImportCombatFont: () {},
                onUseSystemCombatFont: () {},
              ),
            );
          },
        ),
      ),
    );

    for (final entry in <(String, PersonalizationBattlePreviewState)>[
      ('moves', PersonalizationBattlePreviewState.moves),
      ('target', PersonalizationBattlePreviewState.target),
      ('message', PersonalizationBattlePreviewState.message),
      ('commands', PersonalizationBattlePreviewState.commands),
    ]) {
      await tester.tap(
        find.byKey(ValueKey<String>('battle-section-${entry.$1}')),
      );
      await tester.pumpAndSettle();
      expect(preview, entry.$2);
    }
  });

  testWidgets('edits command layout and HUD visibility immediately', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ProjectBattlePresentationProfile battle =
        const ProjectBattlePresentationProfile();
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SingleChildScrollView(
              child: PersonalizationBattleInspector(
                profile: ProjectPresentationProfile(battle: battle),
                previewState: PersonalizationBattlePreviewState.commands,
                onPreviewStateChanged: (_) {},
                onBattleChanged: (value) => setHostState(() => battle = value),
                onWindowsChanged: (_) {},
                onLayoutsChanged: (_) {},
                onImportCombatFont: () {},
                onUseSystemCombatFont: () {},
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('battle-command-layout-list')),
    );
    await tester.pumpAndSettle();
    expect(battle.commandLayout, ProjectBattleCommandLayout.list);

    await tester.tap(find.byKey(const ValueKey<String>('battle-section-hud')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('battle-hud-show-level')),
    );
    await tester.pumpAndSettle();
    expect(battle.showLevel, isFalse);
  });

  testWidgets('reveals dense command and HUD decisions progressively', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: PersonalizationBattleInspector(
            profile: const ProjectPresentationProfile(),
            previewState: PersonalizationBattlePreviewState.commands,
            onPreviewStateChanged: (_) {},
            onBattleChanged: (_) {},
            onWindowsChanged: (_) {},
            onLayoutsChanged: (_) {},
            onImportCombatFont: () {},
            onUseSystemCombatFont: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('battle-command-layout-grid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-command-color-surface')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-command-label-fight')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('battle-command-group-appearance')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('battle-command-color-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-command-layout-grid')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey<String>('battle-section-hud')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('battle-hud-show-level')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-hud-color-healthy')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('battle-hud-group-health')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('battle-hud-color-healthy')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('battle-hud-show-level')),
      findsNothing,
    );
  });

  testWidgets('opens the preview-targeted section and resets only that state', (
    tester,
  ) async {
    var battle = const ProjectBattlePresentationProfile(
      moves: ProjectBattlePanelPresentationProfile(
        shape: ProjectWindowShape.cutCorner,
      ),
      target: ProjectBattlePanelPresentationProfile(
        shape: ProjectWindowShape.rectangle,
      ),
    );
    late StateSetter setHostState;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SingleChildScrollView(
              child: PersonalizationBattleInspector(
                profile: ProjectPresentationProfile(battle: battle),
                previewState: PersonalizationBattlePreviewState.moves,
                initialSection: PersonalizationBattleInspectorSection.moves,
                onPreviewStateChanged: (_) {},
                onBattleChanged: (value) => setHostState(() => battle = value),
                onWindowsChanged: (_) {},
                onLayoutsChanged: (_) {},
                onImportCombatFont: () {},
                onUseSystemCombatFont: () {},
              ),
            );
          },
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('battle-moves-editor')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey<String>('battle-reset-moves')));
    await tester.pumpAndSettle();

    expect(battle.moves, const ProjectBattlePanelPresentationProfile());
    expect(battle.target.shape, ProjectWindowShape.rectangle);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.dark(),
  home: Scaffold(body: child),
);
