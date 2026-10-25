import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  test('phone appears only when the runtime provides its capability', () {
    final unavailable = const PlayerPausePresentation().resolveVisibility(
      PlayerPauseMenuState(),
      contactsAvailable: false,
    );
    expect(
      unavailable.visibleActions,
      isNot(contains(PlayerPauseAction.contacts)),
    );
    final available = const PlayerPausePresentation().resolveVisibility(
      PlayerPauseMenuState(),
    );
    expect(
      available.label(
        PlayerPauseAction.contacts,
        PokeMapPlayerLocalizations.lookup(const Locale('fr')),
      ),
      'Contacts',
    );
    expect(available.icon(PlayerPauseAction.contacts), Icons.call_outlined);
    final authored = const PlayerPausePresentation(
      actionLabels: {PlayerPauseAction.contacts: 'Pokématos'},
    );
    expect(
      authored.label(
        PlayerPauseAction.contacts,
        PokeMapPlayerLocalizations.lookup(const Locale('fr')),
      ),
      'Pokématos',
    );
  });

  test(
    'save visibility overrides project defaults and keeps Resume visible',
    () {
      final presentation =
          const PlayerPausePresentation(
            hiddenActions: <PlayerPauseAction>{PlayerPauseAction.pokedex},
          ).resolveVisibility(
            PlayerPauseMenuState(
              visibilityOverrides: const <ProjectPauseActionId, bool>{
                ProjectPauseActionId.bag: false,
                ProjectPauseActionId.pokedex: true,
              },
            ),
          );

      expect(presentation.visibleActions, contains(PlayerPauseAction.resume));
      expect(
        presentation.visibleActions,
        isNot(contains(PlayerPauseAction.bag)),
      );
      expect(presentation.visibleActions, contains(PlayerPauseAction.pokedex));
    },
  );

  testWidgets('pause uses a grid on wide surfaces and dispatches selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    PlayerPauseAction? selected;

    await tester.pumpWidget(
      _app(
        PlayerPauseMenu(
          gameTitle: 'Aube',
          actions: _actions(),
          onSelected: (action) => selected = action,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(Scrollable), findsNothing);
    expect(find.byType(PlayerPauseSurface), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('player-pause-grid')),
      findsOneWidget,
    );
    expect(find.text('Boutique'), findsNothing);
    expect(find.text('Centre Pokémon'), findsNothing);
    expect(find.text('PC'), findsNothing);

    await tester.tap(find.text('Reprendre'));
    expect(selected, PlayerPauseAction.resume);
  });

  testWidgets('pause pages compact actions without content scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 680);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        PlayerPauseMenu(
          gameTitle: 'Aube',
          actions: _actions(),
          onSelected: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(Scrollable), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('player-pause-list')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable pause action exposes its reason', (tester) async {
    final actions = _actions();
    actions[PlayerPauseAction.resume] = const PlayerActionAvailability.disabled(
      'Reprise différée',
    );
    actions[PlayerPauseAction.pokedex] =
        const PlayerActionAvailability.disabled('Pokédex non obtenu');

    await tester.pumpWidget(
      _app(
        PlayerPauseMenu(
          gameTitle: 'Aube',
          actions: actions,
          onSelected: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey<String>('player-action-semantics-Pokédex')),
    );
    expect(semantics.hint, contains('Pokédex non obtenu'));
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Équipe',
      reason: 'Focus skips unavailable actions.',
    );
  });

  testWidgets('project menu labels replace localized defaults', (tester) async {
    await tester.pumpWidget(
      _app(
        PlayerPauseMenu(
          gameTitle: 'Aube',
          actions: _actions(),
          labels: const PlayerPauseMenuLabels(
            pauseTitle: 'Interlude',
            pokedex: 'Carnet',
          ),
          onSelected: (_) {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Interlude'), findsOneWidget);
    expect(find.text('Carnet'), findsOneWidget);
    expect(find.text('Pokédex'), findsNothing);
    expect(find.text('Équipe'), findsOneWidget);
  });

  testWidgets('project window profile controls the Pause backdrop', (
    tester,
  ) async {
    final windows = legacyProjectPresentationWindows.copyWith(
      pauseBackdropOpacity: .85,
    );
    await tester.pumpWidget(
      _app(
        PlayerPauseMenu(
          gameTitle: 'Aube',
          actions: _actions(),
          onSelected: (_) {},
        ),
        theme: PokeMapPlayerTheme.withWindowProfile(
          PokeMapPlayerTheme.dark(),
          windows,
        ),
      ),
    );

    final backdrop = tester.widget<Material>(
      find.byKey(const ValueKey<String>('player-pause-backdrop')),
    );
    expect(backdrop.color?.a, closeTo(.85, .01));
  });
}

Map<PlayerPauseAction, PlayerActionAvailability> _actions() =>
    <PlayerPauseAction, PlayerActionAvailability>{
      for (final action in PlayerPauseAction.values)
        action: PlayerActionAvailability.enabled,
    };

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  locale: const Locale('fr'),
  supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
  localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
  theme: theme ?? PokeMapPlayerTheme.dark(),
  home: child,
);
