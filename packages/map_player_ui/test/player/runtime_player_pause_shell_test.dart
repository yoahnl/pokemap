import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('layout classification uses available constraints only', () {
    expect(
      classifyRuntimePlayerLayout(
        const BoxConstraints.tightFor(width: 390, height: 844),
      ),
      RuntimePlayerLayoutClass.compactPortrait,
    );
    expect(
      classifyRuntimePlayerLayout(
        const BoxConstraints.tightFor(width: 390, height: 340),
      ),
      RuntimePlayerLayoutClass.compactPortrait,
      reason: 'A portrait phone must not become two-column above a keyboard.',
    );
    expect(
      classifyRuntimePlayerLayout(
        const BoxConstraints.tightFor(width: 844, height: 390),
      ),
      RuntimePlayerLayoutClass.compactLandscape,
    );
    expect(
      classifyRuntimePlayerLayout(
        const BoxConstraints.tightFor(width: 1280, height: 800),
      ),
      RuntimePlayerLayoutClass.expanded,
    );
  });

  testWidgets('compact portrait shows root then a dedicated detail page',
      (tester) async {
    await _setSurface(tester, const Size(390, 844));
    PlayerPauseAction? selected;
    var backCalls = 0;

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
      actions: _actions(),
      onSelected: (action) => selected = action,
      onBackToRoot: () => backCalls++,
      detail: const Text('DÉTAIL ÉQUIPE'),
    )));

    expect(find.byType(PlayerPauseSurface), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>(
          'runtime-pause-layout-compactPortrait',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('runtime-pause-navigation')),
        findsOneWidget);
    expect(find.text('DÉTAIL ÉQUIPE'), findsNothing);
    expect(find.text('Boutique'), findsNothing);
    expect(find.text('Centre Pokémon'), findsNothing);
    expect(find.text('PC'), findsNothing);

    await tester.tap(find.text('Équipe'));
    expect(selected, PlayerPauseAction.party);

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.party,
      actions: _actions(),
      onSelected: (_) {},
      onBackToRoot: () => backCalls++,
      detail: const Text('DÉTAIL ÉQUIPE'),
    )));

    expect(find.text('DÉTAIL ÉQUIPE'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('runtime-pause-navigation')),
        findsNothing);
    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-pause-back-to-root')),
    );
    expect(backCalls, 1);
  });

  testWidgets('compact landscape uses independently scrollable columns',
      (tester) async {
    await _setSurface(tester, const Size(844, 390));

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.party,
      actions: _actions(),
      onSelected: (_) {},
      onBackToRoot: () {},
      detail: const Text('DÉTAIL ÉQUIPE'),
    )));

    expect(
      find.byKey(
        const ValueKey<String>(
          'runtime-pause-layout-compactLandscape',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-pause-navigation-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('runtime-pause-detail-scroll')),
      findsOneWidget,
    );
    expect(find.text('DÉTAIL ÉQUIPE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded uses a right panel and leaves the world perceptible',
      (tester) async {
    await _setSurface(tester, const Size(1280, 800));

    await tester.pumpWidget(_app(Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const ColoredBox(
          key: ValueKey<String>('world'),
          color: Colors.green,
        ),
        RuntimePlayerPauseShell(
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.party,
          actions: _actions(),
          onSelected: (_) {},
          onBackToRoot: () {},
          detail: const Text('DÉTAIL ÉQUIPE'),
        ),
      ],
    )));

    final panel = find.byKey(
      const ValueKey<String>('runtime-pause-expanded-panel'),
    );
    expect(panel, findsOneWidget);
    expect(tester.getSize(panel).width, lessThan(900));
    expect(find.byKey(const ValueKey<String>('world')), findsOneWidget);
  });

  testWidgets('authored pause layout uses the shared regular breakpoint', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1024, 768));
    final base = suggestedProjectPresentationLayouts('standard');
    final layouts = base.copyWith(
      pauseMenu: base.pauseMenu.copyWith(
        regular: base.pauseMenu.regular.copyWith(
          slot: ProjectPresentationLayoutSlot.right,
        ),
      ),
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell(
          gameTitle: 'Aube',
          pauseSection: RuntimePlayerPauseSection.party,
          actions: _actions(),
          onSelected: (_) {},
          onBackToRoot: () {},
          detail: const Text('DÉTAIL ÉQUIPE'),
        ),
        layouts: layouts,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('runtime-pause-responsive-regular')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 2 keeps every action target at least 48 pixels',
      (tester) async {
    await _setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(_app(
      RuntimePlayerPauseShell(
        gameTitle: 'Aube',
        pauseSection: RuntimePlayerPauseSection.root,
        actions: _actions(),
        onSelected: (_) {},
        onBackToRoot: () {},
        detail: const SizedBox.shrink(),
      ),
      textScaler: const TextScaler.linear(2),
    ));

    final targets =
        find.byKey(const ValueKey<String>('player-action-focus-frame'));
    expect(targets, findsNWidgets(PlayerPauseAction.values.length));
    for (final element in targets.evaluate()) {
      expect(
          tester.getSize(find.byElementPredicate((e) => e == element)).height,
          greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile touch menu stays mounted and dims after controller input',
      (tester) async {
    await _setSurface(tester, const Size(844, 390));
    var resumeCalls = 0;

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.root,
      actions: _actions(),
      onSelected: (_) {},
      onBackToRoot: () {},
      onTouchMenu: () => resumeCalls++,
      activeInputSource: PlayerInputSource.controller,
      detail: const SizedBox.shrink(),
    )));

    final opacity = tester.widget<AnimatedOpacity>(
      find.byKey(const ValueKey<String>('runtime-pause-touch-menu-opacity')),
    );
    expect(opacity.opacity, lessThan(1));

    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-pause-touch-menu')),
    );
    expect(resumeCalls, 1);
  });

  testWidgets('project labels apply to navigation and detail titles',
      (tester) async {
    await _setSurface(tester, const Size(1280, 800));

    await tester.pumpWidget(_app(RuntimePlayerPauseShell(
      gameTitle: 'Aube',
      pauseSection: RuntimePlayerPauseSection.pokedex,
      actions: _actions(),
      labels: const PlayerPauseMenuLabels(
        pauseTitle: 'Interlude',
        pokedex: 'Carnet',
      ),
      onSelected: (_) {},
      onBackToRoot: () {},
      detail: const Text('DÉTAIL CARNET'),
    )));

    expect(find.text('Interlude'), findsOneWidget);
    expect(find.text('Carnet'), findsNWidgets(2));
    expect(find.text('Pokédex'), findsNothing);
  });

  testWidgets('installed runtime shell consumes authored window styling',
      (tester) async {
    await _setSurface(tester, const Size(1280, 800));
    final windows = legacyProjectPresentationWindows.copyWith(
      pauseBackdropOpacity: .82,
    );

    await tester.pumpWidget(_app(
      RuntimePlayerPauseShell(
        gameTitle: 'Aube',
        pauseSection: RuntimePlayerPauseSection.root,
        actions: _actions(),
        onSelected: (_) {},
        onBackToRoot: () {},
        detail: const SizedBox.shrink(),
      ),
      theme: PokeMapPlayerTheme.withWindowProfile(
        PokeMapPlayerTheme.dark(),
        windows,
      ),
    ));

    final backdrop = tester.widget<Material>(
      find.byKey(const ValueKey<String>('runtime-pause-backdrop')),
    );
    expect(backdrop.color?.a, closeTo(.82, .01));
    expect(tester.takeException(), isNull);
  });
}

Map<PlayerPauseAction, PlayerActionAvailability> _actions() =>
    <PlayerPauseAction, PlayerActionAvailability>{
      for (final action in PlayerPauseAction.values)
        action: PlayerActionAvailability.enabled,
    };

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  ThemeData? theme,
  ProjectPresentationLayoutsProfile? layouts,
}) {
  var resolvedTheme = theme ?? PokeMapPlayerTheme.dark();
  if (layouts != null) {
    resolvedTheme = PokeMapPlayerTheme.withLayoutProfile(
      resolvedTheme,
      layouts,
    );
  }
  return MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
    localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
    theme: resolvedTheme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: child,
  );
}
