import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';
import 'package:map_editor/src/features/personalization/presentation/inspectors/personalization_pause_inspector.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('offers focused pause placement size colors and typography', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
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
              child: PersonalizationPauseInspector(
                profile: profile,
                onPauseChanged: (pause) => setHostState(
                  () => profile = profile.copyWith(pause: pause),
                ),
                onWindowsChanged: (windows) => setHostState(
                  () => profile = profile.copyWith(windows: windows),
                ),
                onLayoutsChanged: (layouts) => setHostState(
                  () => profile = profile.copyWith(layouts: layouts),
                ),
                onImportBodyFont: () {},
                onUseSystemBodyFont: () {},
              ),
            );
          },
        ),
      ),
    );

    for (final placement in <String>['left', 'center', 'right']) {
      expect(
        find.byKey(ValueKey<String>('pause-layout-$placement')),
        findsOneWidget,
      );
    }
    for (final size in <String>['compact', 'normal', 'large']) {
      expect(find.byKey(ValueKey<String>('pause-size-$size')), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey<String>('window-target-dialogue')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('window-field-fill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('typography-import-body')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('pause-presentation-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('pause-presentation-hint')),
      findsOneWidget,
    );
    for (final action in <String>[
      'resume',
      'party',
      'bag',
      'pokedex',
      'map',
      'save',
      'options',
      'returnToTitle',
    ]) {
      expect(
        find.byKey(ValueKey<String>('pause-action-label-$action')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey<String>('pause-action-icon-$action')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey<String>('pause-action-visible-resume')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('pause-action-visible-pokedex')),
      findsOneWidget,
    );
    for (final layout in <String>[
      'compactPortrait',
      'compactLandscape',
      'expanded',
    ]) {
      expect(
        find.byKey(ValueKey<String>('pause-composition-$layout-entry-size')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey<String>('pause-composition-$layout-entry-spacing')),
        findsOneWidget,
      );
    }

    final left = find.byKey(const ValueKey<String>('pause-layout-left'));
    await tester.ensureVisible(left);
    await tester.pumpAndSettle();
    expect(left.hitTestable(), findsOneWidget);
    await tester.tap(left);
    await tester.pumpAndSettle();
    expect(
      profile.layouts?.pauseMenu.regular.slot,
      ProjectPresentationLayoutSlot.left,
    );
    expect(
      profile.layouts?.pauseMenu.expanded.slot,
      ProjectPresentationLayoutSlot.left,
    );

    final large = find.byKey(const ValueKey<String>('pause-size-large'));
    await tester.ensureVisible(large);
    await tester.pumpAndSettle();
    expect(large.hitTestable(), findsOneWidget);
    await tester.tap(large);
    await tester.pumpAndSettle();
    expect(
      profile.layouts?.pauseMenu.regular.width,
      ProjectPresentationContentWidth.wide,
    );

    final compactStyle = find.byKey(
      const ValueKey<String>('window-preset-compact'),
    );
    await tester.ensureVisible(compactStyle);
    await tester.pumpAndSettle();
    expect(compactStyle.hitTestable(), findsOneWidget);
    await tester.tap(compactStyle);
    await tester.pumpAndSettle();
    expect(
      profile.windows?.resolve(ProjectWindowRole.pauseMenu).cornerRadius,
      8,
    );
    expect(
      profile.windows?.resolve(ProjectWindowRole.dialogue).cornerRadius,
      16,
    );

    final showExpandedTitle = find.byKey(
      const ValueKey<String>('pause-composition-expanded-show-title'),
    );
    await tester.ensureVisible(showExpandedTitle);
    await tester.pumpAndSettle();
    expect(showExpandedTitle.hitTestable(), findsOneWidget);
    await tester.tap(showExpandedTitle);
    await tester.pumpAndSettle();
    expect(profile.pause?.composition?.expanded.showTitle, isFalse);
  });

  testWidgets('Pokedex becomes Bestiaire in the runtime pause surface', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
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
            return Row(
              children: <Widget>[
                SizedBox(
                  width: 380,
                  child: SingleChildScrollView(
                    child: PersonalizationPauseInspector(
                      profile: profile,
                      onPauseChanged: (pause) => setHostState(
                        () => profile = profile.copyWith(pause: pause),
                      ),
                      onWindowsChanged: (windows) => setHostState(
                        () => profile = profile.copyWith(windows: windows),
                      ),
                      onLayoutsChanged: (layouts) => setHostState(
                        () => profile = profile.copyWith(layouts: layouts),
                      ),
                      onImportBodyFont: () {},
                      onUseSystemBodyFont: () {},
                    ),
                  ),
                ),
                Expanded(
                  child: PersonalizationLivePreview(
                    profile: profile,
                    projectName: 'Pokémon Aurore',
                    projectRootPath: '',
                    scene: PersonalizationStudioScene.pause,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final pokedex = find.byKey(
      const ValueKey<String>('pause-action-label-pokedex'),
    );
    await tester.ensureVisible(pokedex);
    await tester.pumpAndSettle();
    expect(pokedex.hitTestable(), findsOneWidget);
    await tester.enterText(pokedex, 'Bestiaire');
    await tester.pumpAndSettle();

    expect(find.byType(RuntimePlayerPauseShell), findsOneWidget);
    expect(find.byType(PlayerPauseSurface), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(RuntimePlayerPauseShell),
        matching: find.text('Bestiaire'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(PlayerPauseSurface),
        matching: find.text('Bestiaire'),
      ),
      findsOneWidget,
    );
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: PokeMapTheme.light(),
  home: Scaffold(body: child),
);
