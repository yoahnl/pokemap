import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_pause_illustrated_root.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets('unconfigured mobile pause uses the illustrated menu $size', (
      tester,
    ) async {
      await _surface(tester, size);
      final selected = <PlayerPauseAction>[];
      await tester.pumpWidget(
        _app(
          RuntimePlayerPauseShell.root(
            gameTitle: 'Voyage',
            actions: _actions(),
            onSelected: selected.add,
            detail: const SizedBox.shrink(),
            activeInputSource: PlayerInputSource.touch,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('runtime-night-illustrated-frame')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('pause-root-rail')), findsNothing);
      await _reveal(tester, find.byKey(const ValueKey('pause.options')));
      await tester.tap(find.byKey(const ValueKey('pause.options')));
      await tester.tap(
        find.byKey(const ValueKey('pause-frame-return-surface')),
      );
      expect(selected, [PlayerPauseAction.options, PlayerPauseAction.resume]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'expanded root keeps eight entries in its rail and Save in the footer',
    (tester) async {
      await _surface(tester, const Size(1440, 900));
      final selected = <PlayerPauseAction>[];
      await tester.pumpWidget(_app(_root(onSelected: selected.add)));
      await tester.pumpAndSettle();

      final frame = tester.getRect(find.byType(PlayerPauseIllustratedRoot));
      final rail = tester.getRect(
        find.byKey(const ValueKey('pause-root-rail')),
      );
      expect(frame, const Rect.fromLTWH(0, 0, 1440, 900));
      expect(rail.left, frame.left);
      expect(rail.top, frame.top);
      expect(rail.width, 432);
      final railClip = tester.widget<ClipPath>(
        find.descendant(
          of: find.byKey(const ValueKey('pause-root-rail')),
          matching: find.byType(ClipPath),
        ),
      );
      final railPath = railClip.clipper!.getClip(rail.size);
      expect(railPath.contains(const Offset(407, 1)), isTrue);
      expect(railPath.contains(const Offset(409, 1)), isFalse);
      expect(railPath.contains(Offset(430, rail.height - 1)), isTrue);
      final footer = tester.getRect(find.byType(PlayerMenuFooter));
      expect(footer.left, frame.left);
      expect(footer.right, frame.right);
      expect(footer.bottom, frame.bottom);
      expect(footer.height, greaterThanOrEqualTo(64));
      expect(rail.bottom, footer.top);

      const defaults = [
        PlayerPauseAction.party,
        PlayerPauseAction.bag,
        PlayerPauseAction.pokedex,
        PlayerPauseAction.quests,
        PlayerPauseAction.contacts,
        PlayerPauseAction.map,
        PlayerPauseAction.profile,
        PlayerPauseAction.options,
      ];
      final rows = tester
          .widgetList<PlayerMenuSelectableRow>(
            find.descendant(
              of: find.byType(PlayerPauseNavigation),
              matching: find.byType(
                PlayerMenuSelectableRow,
                skipOffstage: false,
              ),
              skipOffstage: false,
            ),
          )
          .where((row) => row.id.startsWith('pause.'))
          .toList();
      expect(
        rows.map((row) => row.id),
        defaults.map((action) => 'pause.${action.name}'),
      );
      for (var index = 0; index < defaults.length; index++) {
        final action = defaults[index];
        final finder = find.byKey(ValueKey('pause.${action.name}'));
        await _reveal(tester, finder);
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(rail.left + 16));
        expect(rect.right, lessThanOrEqualTo(rail.right - 16));
        expect(rect.top, greaterThanOrEqualTo(rail.top));
        expect(rect.bottom, lessThanOrEqualTo(rail.bottom));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      final save = find.byKey(const ValueKey('pause.save'));
      expect(save.hitTestable(), findsOneWidget);
      final saveBounds = tester.getRect(save);
      expect(saveBounds.top, greaterThanOrEqualTo(footer.top));
      expect(saveBounds.bottom, lessThanOrEqualTo(footer.bottom));
      expect(saveBounds.height, greaterThanOrEqualTo(48));
      await tester.tap(save);
      await tester.tap(
        find.byKey(const ValueKey('pause-frame-return-surface')),
      );
      final exit = find.byKey(const ValueKey('pause.returnToTitle'));
      expect(exit.hitTestable(), findsOneWidget);
      final exitBounds = tester.getRect(exit);
      expect(exitBounds.top, greaterThanOrEqualTo(footer.top));
      expect(exitBounds.bottom, lessThanOrEqualTo(footer.bottom));
      expect(exitBounds.size, const Size(48, 48));
      expect(exitBounds.left - saveBounds.right, greaterThanOrEqualTo(8));
      await tester.tap(exit);
      expect(selected, [
        PlayerPauseAction.save,
        PlayerPauseAction.resume,
        PlayerPauseAction.returnToTitle,
      ]);
      expect(find.byKey(const ValueKey('pause.resume')), findsNothing);
      expect(find.text('Reprendre'), findsOneWidget);
      expect(find.byType(PlayerEmptyState), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('actions only root keeps the full party detail surface', (
    tester,
  ) async {
    await _surface(tester, const Size(538, 468));
    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell(
          gameTitle: 'Voyage',
          pauseSection: RuntimePlayerPauseSection.party,
          actions: _actions(),
          onSelected: (_) {},
          onBackToRoot: () {},
          rootActionsOnly: true,
          detailTitle: 'Compagnons',
          detail: const SizedBox(
            key: ValueKey('actual-party-detail'),
            width: double.infinity,
            child: Text('Contenu réel de l’équipe'),
          ),
          presentation: _presentation,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('runtime-pause-action-grid')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('actual-party-detail')), findsOneWidget);
    expect(find.text('Compagnons'), findsOneWidget);
    expect(find.byKey(const ValueKey('pause.party')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final optionsHidden in [true, false]) {
    testWidgets(
      'return to title stays reachable when Options is ${optionsHidden ? 'hidden' : 'disabled'}',
      (tester) async {
        await _surface(tester, const Size(1440, 900));
        final selected = <PlayerPauseAction>[];
        final focus = RuntimePlayerFocusController(
          logicalSelectionId: 'pause.returnToTitle',
        );
        addTearDown(focus.dispose);
        await tester.pumpWidget(
          _app(
            _root(
              focusController: focus,
              onSelected: selected.add,
              actions: {
                ..._actions(),
                if (!optionsHidden)
                  PlayerPauseAction.options:
                      const PlayerActionAvailability.disabled(
                        'Options verrouillées',
                      ),
              },
              presentation: PlayerPausePresentation(
                style: ProjectPauseMenuStyle.nightIllustrated,
                hiddenActions: {if (optionsHidden) PlayerPauseAction.options},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('pause.returnToTitle'));
        expect(action, findsOneWidget);
        expect(focus.logicalSelectionId, 'pause.returnToTitle');
        await tester.ensureVisible(action);
        await tester.tap(action);
        expect(selected, [PlayerPauseAction.returnToTitle]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('expanded root summary presents the supplied player snapshot', (
    tester,
  ) async {
    await _surface(tester, const Size(1440, 900));
    await tester.pumpWidget(_app(_root(profile: _profile())));
    await tester.pumpAndSettle();

    expect(find.text('Port des brumes'), findsOneWidget);
    expect(find.text('Camille'), findsOneWidget);
    expect(find.text('Badges : 2 / 8'), findsOneWidget);
    expect(find.text('Temps de jeu : 12:05'), findsOneWidget);
    expect(find.text('Pokédex : 42 / 151'), findsOneWidget);
    expect(find.textContaining('map.internal.004'), findsNothing);
    final summary = tester.getRect(
      find.byKey(const ValueKey('player-pause-summary-panel')),
    );
    final rail = tester.getRect(find.byKey(const ValueKey('pause-root-rail')));
    final frame = tester.getRect(find.byType(PlayerPauseIllustratedRoot));
    expect(summary.left, greaterThan(rail.right));
    expect(summary.width, inInclusiveRange(520, 640));
    expect(summary.height, closeTo(208, 1));
    expect(summary.bottom, lessThan(frame.bottom));
    expect(summary.right, lessThan(frame.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail uses the frame width and replaces the root rail', (
    tester,
  ) async {
    await _surface(tester, const Size(1440, 900));
    var returns = 0;
    await tester.pumpWidget(
      _app(
        RuntimePlayerPauseShell(
          gameTitle: 'Voyage',
          pauseSection: RuntimePlayerPauseSection.party,
          actions: _actions(),
          onSelected: (_) {},
          onBackToRoot: () => returns++,
          detailTitle: 'Compagnons',
          detail: const SizedBox(
            key: ValueKey('actual-party-detail'),
            width: double.infinity,
            child: Text('Contenu réel de l’équipe'),
          ),
          playerProfile: _profile(),
          presentation: _presentation,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pause-root-rail')), findsNothing);
    expect(
      find.byKey(const ValueKey('player-pause-summary-panel')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('pause.party')), findsNothing);
    expect(find.text('Compagnons'), findsOneWidget);
    final detail = tester.getRect(
      find.byKey(const ValueKey('actual-party-detail')),
    );
    final frame = tester.getRect(
      find.byKey(const ValueKey('player-menu-frame-panel')),
    );
    expect(detail.width, greaterThan(frame.width * .85));
    expect(detail.left, greaterThan(frame.left));
    expect(detail.right, lessThan(frame.right));
    await tester.tap(find.byKey(const ValueKey('pause-frame-return-surface')));
    expect(returns, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'portrait with doubled text keeps context and profile access reachable',
    (tester) async {
      await _surface(tester, const Size(390, 844));
      final selected = <PlayerPauseAction>[];
      await tester.pumpWidget(
        _app(
          _root(
            profile: _profile(),
            onSelected: selected.add,
            activeInputSource: PlayerInputSource.touch,
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pause-root-rail')), findsNothing);
      expect(find.byType(Scrollable), findsNothing);
      expect(find.text('Port des brumes'), findsOneWidget);
      final profile = find.byKey(const ValueKey('pause.profile'));
      await _reveal(tester, profile);
      expect(tester.getSize(profile).height, greaterThanOrEqualTo(48));
      await tester.tap(profile);
      expect(selected, [PlayerPauseAction.profile]);
      final options = find.byKey(const ValueKey('pause.options'));
      await _reveal(tester, options);
      await tester.tap(options);
      await tester.pumpAndSettle();
      expect(selected, [PlayerPauseAction.profile, PlayerPauseAction.options]);
      await tester.tap(
        find.byKey(const ValueKey('pause-frame-return-surface')),
      );
      expect(selected, [
        PlayerPauseAction.profile,
        PlayerPauseAction.options,
        PlayerPauseAction.resume,
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'touch root does not request keyboard focus on opening or selection',
    (tester) async {
      await _surface(tester, const Size(1440, 900));
      final focus = RuntimePlayerFocusController(
        activeInputSource: PlayerInputSource.touch,
      );
      addTearDown(focus.dispose);
      final selected = <PlayerPauseAction>[];
      await tester.pumpWidget(
        _app(
          _root(
            focusController: focus,
            activeInputSource: PlayerInputSource.touch,
            onSelected: selected.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rows = tester.widgetList<PlayerMenuSelectableRow>(
        find.byType(PlayerMenuSelectableRow),
      );
      expect(focus.logicalSelectionId, isNull);
      expect(rows.every((row) => !row.showFocusHighlight), isTrue);
      expect(rows.every((row) => row.focusNode?.hasFocus != true), isTrue);
      await tester.tap(find.byKey(const ValueKey('pause.bag')));
      await tester.pumpAndSettle();
      expect(selected, [PlayerPauseAction.bag]);
      expect(focus.activeInputSource, PlayerInputSource.touch);
      expect(focus.logicalSelectionId, 'pause.bag');
      final bag = tester.widget<PlayerMenuSelectableRow>(
        find.byKey(const ValueKey('pause.bag')),
      );
      expect(bag.showFocusHighlight, isFalse);
      expect(bag.focusNode?.hasFocus, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all authored entries hidden still leave a working Resume', (
    tester,
  ) async {
    await _surface(tester, const Size(390, 844));
    final selected = <PlayerPauseAction>[];
    await tester.pumpWidget(
      _app(
        _root(
          onSelected: selected.add,
          presentation: PlayerPausePresentation(
            style: ProjectPauseMenuStyle.nightIllustrated,
            hiddenActions: PlayerPauseAction.values.toSet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final rows = tester.widgetList<PlayerMenuSelectableRow>(
      find.byType(PlayerMenuSelectableRow),
    );
    expect(rows.map((row) => row.id), ['pause-frame-return']);
    expect(find.text('Reprendre'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pause-frame-return-surface')));
    expect(selected, [PlayerPauseAction.resume]);
    expect(tester.takeException(), isNull);
  });
}

const _presentation = PlayerPausePresentation(
  style: ProjectPauseMenuStyle.nightIllustrated,
);

Widget _root({
  RuntimePlayerProfileSnapshot? profile,
  ValueChanged<PlayerPauseAction>? onSelected,
  RuntimePlayerFocusController? focusController,
  PlayerInputSource? activeInputSource,
  PlayerPausePresentation presentation = _presentation,
  Map<PlayerPauseAction, PlayerActionAvailability>? actions,
}) => RuntimePlayerPauseShell.root(
  gameTitle: 'Voyage',
  actions: actions ?? _actions(),
  onSelected: onSelected ?? (_) {},
  detail: const SizedBox.shrink(),
  playerProfile: profile,
  focusController: focusController,
  activeInputSource: activeInputSource,
  presentation: presentation,
);

Map<PlayerPauseAction, PlayerActionAvailability> _actions() => {
  for (final action in PlayerPauseAction.values)
    action: PlayerActionAvailability.enabled,
};

RuntimePlayerProfileSnapshot _profile() => RuntimePlayerProfileSnapshot(
  playerName: 'Camille',
  currentMapId: 'map.internal.004',
  locationName: 'Port des brumes',
  money: 350,
  badgeIds: ['badge.tide', 'badge.mist'],
  badgeTotal: 8,
  playtimeSeconds: 12 * 3600 + 5 * 60 + 49,
  pokedex: const RuntimePlayerPokedexProgressSnapshot(
    seen: 60,
    caught: 42,
    total: 151,
  ),
);

Future<void> _surface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _app(Widget child, {TextScaler textScaler = TextScaler.noScaling}) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: child,
    );

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  final scope = find.byType(PlayerPauseNavigation);
  if (finder.hitTestable().evaluate().isNotEmpty) return;
  final previous = find.descendant(
    of: scope,
    matching: find.byKey(const ValueKey('player-page-previous')),
  );
  for (
    var page = 0;
    page < 30 &&
        previous.evaluate().isNotEmpty &&
        tester.widget<IconButton>(previous).onPressed != null;
    page++
  ) {
    await tester.tap(previous);
    await tester.pumpAndSettle();
  }
  for (var page = 0; page < 30 && finder.evaluate().isEmpty; page++) {
    final next = find.descendant(
      of: scope,
      matching: find.byKey(const ValueKey('player-page-next')),
    );
    expect(next, findsOneWidget);
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
  expect(finder.hitTestable(), findsOneWidget);
}
