import 'dart:ui' show Tristate, SemanticsAction;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('keyboard moves, confirms, returns and resumes', (tester) async {
    await _setSurface(tester, const Size(390, 844));
    PlayerPauseAction? selected;
    var backCalls = 0;
    var menuCalls = 0;

    await tester.pumpWidget(
      _app(
        _shell(
          onSelected: (action) => selected = action,
          onBack: () => backCalls++,
          onMenu: () => menuCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Pokédex',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, PlayerPauseAction.pokedex);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(backCalls, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    expect(menuCalls, 1);
  });

  testWidgets('mouse hover does not activate and hides synthetic focus', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 800));
    PlayerPauseAction? selected;

    await tester.pumpWidget(
      _app(_shell(onSelected: (action) => selected = action)),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.text('Pokémon')));
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(
      find.byKey(const ValueKey('pause.party-focus-marker')),
      findsNothing,
    );
  });

  testWidgets('touch selects once without forcing focus highlight', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    final selected = <PlayerPauseAction>[];
    final focusController = RuntimePlayerFocusController();
    addTearDown(focusController.dispose);

    await tester.pumpWidget(
      _app(_shell(onSelected: selected.add, focusController: focusController)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pokémon'));
    await tester.pumpAndSettle();

    expect(selected, <PlayerPauseAction>[PlayerPauseAction.party]);
    expect(focusController.showFocusHighlight, isFalse);
  });

  testWidgets('logical controller intents follow the same navigation', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    PlayerPauseAction? selected;

    await tester.pumpWidget(
      _app(_shell(onSelected: (action) => selected = action)),
    );
    await tester.pumpAndSettle();
    final context = tester.element(
      find.byKey(const ValueKey<String>('runtime-player-actions-context')),
    );

    Actions.invoke(
      context,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.down,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Pokédex',
    );

    Actions.invoke(
      context,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.confirm,
        source: PlayerInputSource.controller,
      ),
    );
    expect(selected, PlayerPauseAction.pokedex);
  });

  testWidgets(
    'orientation preserves logical selection and selected semantics',
    (tester) async {
      final focusController = RuntimePlayerFocusController(
        logicalSelectionId: 'pause.party',
      );
      addTearDown(focusController.dispose);
      await _setSurface(tester, const Size(390, 844));

      await tester.pumpWidget(
        _app(
          _shell(
            focusController: focusController,
            logicalSelectionId: 'pause.party',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(focusController.logicalSelectionId, 'pause.party');

      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(focusController.logicalSelectionId, 'pause.party');
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'Player action: Pokémon',
      );

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(focusController.logicalSelectionId, 'pause.party');

      final semantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('pause.party')),
      );
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
      expect(
        semantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
    },
  );

  testWidgets('rapid restore requests focus only the latest logical item', (
    tester,
  ) async {
    await _setSurface(tester, const Size(844, 390));
    final focusController = RuntimePlayerFocusController();
    addTearDown(focusController.dispose);

    await tester.pumpWidget(_app(_shell(focusController: focusController)));
    focusController.restoreSelection('pause.party');
    focusController.restoreSelection('pause.bag');
    focusController.restoreSelection('pause.options');
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(focusController.logicalSelectionId, 'pause.options');
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Options',
    );
  });

  testWidgets('compact gameplay exposes a touch menu opener', (tester) async {
    await _setSurface(tester, const Size(390, 844));
    final actions = <RuntimePlayerAction>[];
    final snapshot = RuntimePlayerSnapshot(
      revision: 21,
      phase: RuntimePlayerPhase.playing,
      gameTitle: 'Aube',
      actions: const <RuntimePlayerActionAvailability>[
        RuntimePlayerActionAvailability.enabled(RuntimePlayerAction.openMenu),
      ],
      activeInputSource: PlayerInputSource.touch,
    );

    await tester.pumpWidget(
      _app(
        RuntimePlayerSurfaceRouter(
          snapshot: snapshot,
          titlePresentation: const RuntimePlayerTitlePresentation(
            author: 'Studio Test',
          ),
          gameSceneBuilder: (_) => const SizedBox.expand(),
          onAction: (action) async {
            actions.add(action);
            return const RuntimePlayerCommandResult(
              status: RuntimePlayerCommandStatus.accepted,
            );
          },
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('runtime-player-touch-menu-open')),
    );
    expect(actions, <RuntimePlayerAction>[RuntimePlayerAction.openMenu]);
  });

  testWidgets('reduced motion and text scale two remain usable', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(
      _app(
        _shell(activeInputSource: PlayerInputSource.controller),
        textScaler: const TextScaler.linear(2),
        reducedMotion: true,
      ),
    );

    await tester.pumpAndSettle();
    final opening = tester.widget<Transform>(
      find.byKey(const ValueKey('player-menu-opening-transform')),
    );
    expect(opening.transform.getTranslation().y, 0);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

RuntimePlayerPauseShell _shell({
  ValueChanged<PlayerPauseAction>? onSelected,
  VoidCallback? onBack,
  VoidCallback? onMenu,
  String? logicalSelectionId,
  RuntimePlayerFocusController? focusController,
  PlayerInputSource? activeInputSource,
}) {
  return RuntimePlayerPauseShell(
    gameTitle: 'Aube',
    pauseSection: RuntimePlayerPauseSection.root,
    actions: <PlayerPauseAction, PlayerActionAvailability>{
      for (final action in PlayerPauseAction.values)
        action: PlayerActionAvailability.enabled,
    },
    onSelected: onSelected ?? (_) {},
    onBackToRoot: onBack ?? () {},
    onTouchMenu: onMenu ?? () {},
    logicalSelectionId: logicalSelectionId,
    focusController: focusController,
    activeInputSource: activeInputSource,
    detail: const SizedBox.shrink(),
  );
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(
  Widget child, {
  TextScaler textScaler = TextScaler.noScaling,
  bool reducedMotion = false,
}) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: PokeMapPlayerTheme.dark(reducedMotion: reducedMotion),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: textScaler),
    child: child!,
  ),
  home: child,
);
