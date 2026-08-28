import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('keeps authored title action order, copy and runtime identity', (
    tester,
  ) async {
    final selected = <PlayerTitleMenuAction>[];
    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: 'Aube',
            author: 'Studio Brume',
            actions: const <PlayerTitleMenuAction, PlayerActionAvailability>{
              PlayerTitleMenuAction.newGame: PlayerActionAvailability.enabled,
              PlayerTitleMenuAction.continueGame:
                  PlayerActionAvailability.disabled('Aucune sauvegarde'),
            },
            actionLabels: const <PlayerTitleMenuAction, String>{
              PlayerTitleMenuAction.newGame: 'Commencer',
              PlayerTitleMenuAction.continueGame: 'Reprendre',
            },
            actionIcons: const <PlayerTitleMenuAction, ProjectTitleActionIcon>{
              PlayerTitleMenuAction.newGame: ProjectTitleActionIcon.sparkles,
              PlayerTitleMenuAction.continueGame: ProjectTitleActionIcon.play,
            },
          ),
          onSelected: selected.add,
        ),
      ),
    );

    final buttons = tester
        .widgetList<PlayerActionButton>(find.byType(PlayerActionButton))
        .toList(growable: false);
    expect(buttons.map((button) => button.label), <String>[
      'Commencer',
      'Reprendre',
    ]);
    expect(buttons.first.icon, Icons.auto_awesome_rounded);
    expect(find.text('Options'), findsNothing);

    await tester.tap(find.text('Commencer'));
    expect(selected, <PlayerTitleMenuAction>[PlayerTitleMenuAction.newGame]);
    await tester.tap(find.text('Reprendre'));
    expect(selected, hasLength(1));
  });

  testWidgets('title exposes the product actions and availability',
      (tester) async {
    var selected = <PlayerTitleMenuAction>[];
    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: 'Aube',
            author: 'Studio Brume',
            description: 'Une aventure au bord de mer.',
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: PlayerActionAvailability.enabled,
              PlayerTitleMenuAction.continueGame:
                  const PlayerActionAvailability.disabled(
                'Aucune sauvegarde disponible',
              ),
            },
          ),
          onSelected: selected.add,
        ),
      ),
    );

    expect(find.byType(PlayerTitleSurface), findsOneWidget);
    expect(find.text('Aube'), findsOneWidget);
    expect(find.text('Studio Brume'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Nouveau jeu'), findsOneWidget);
    expect(find.text('Charger'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Crédits / À propos'), findsOneWidget);
    expect(find.text('Retour au Hub'), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Nouveau jeu',
      reason: 'Focus starts on the first enabled action.',
    );

    await tester.tap(find.text('Nouveau jeu'));
    expect(selected, <PlayerTitleMenuAction>[
      PlayerTitleMenuAction.newGame,
    ]);

    await tester.tap(find.text('Continuer'));
    expect(selected, hasLength(1), reason: 'Disabled actions cannot dispatch.');
  });

  testWidgets('title keeps every long action reachable at 200 percent text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: 'Une très longue aventure',
            author: 'Studio',
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: PlayerActionAvailability.enabled,
            },
            actionLabels: const <PlayerTitleMenuAction, String>{
              PlayerTitleMenuAction.continueGame:
                  'Continuer depuis la dernière sauvegarde disponible',
              PlayerTitleMenuAction.newGame:
                  'Commencer une nouvelle aventure extraordinaire',
              PlayerTitleMenuAction.load:
                  'Charger une sauvegarde parmi toutes les aventures',
              PlayerTitleMenuAction.options:
                  'Configurer toutes les options du jeu',
              PlayerTitleMenuAction.creditsAbout:
                  'Crédits, licences et informations sur le studio',
              PlayerTitleMenuAction.returnToHub:
                  'Quitter cette aventure et retourner au Hub',
            },
          ),
          onSelected: (_) {},
        ),
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('player-title-scrollbar')),
      findsOneWidget,
    );
    final scroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey<String>('player-title-scroll')),
    );
    expect(scroll.controller, isNotNull);
    expect(scroll.controller!.position.maxScrollExtent, greaterThan(0));

    for (var index = 1; index < PlayerTitleMenuAction.values.length; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      contains('Quitter cette aventure'),
    );
    final lastAction = tester.getRect(
      find.text('Quitter cette aventure et retourner au Hub'),
    );
    expect(lastAction.top, greaterThanOrEqualTo(0));
    expect(lastAction.bottom, lessThanOrEqualTo(640));
  });

  testWidgets('cinematic branding selects the authored title layout',
      (tester) async {
    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: 'Aube',
            author: 'Studio Brume',
            layoutVariant: PlayerTitleLayoutVariant.cinematic,
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: PlayerActionAvailability.enabled,
            },
          ),
          onSelected: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('player-title-layout-cinematic'),
      ),
      findsOneWidget,
    );
    final alignment = tester.widget<Align>(
      find.byKey(const ValueKey<String>('player-title-content-alignment')),
    );
    expect(alignment.alignment, Alignment.bottomLeft);
  });

  testWidgets('authored responsive title layout uses the shared regular slot', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final layouts = suggestedProjectPresentationLayouts('standard').copyWith(
      title: suggestedProjectPresentationLayouts('standard').title.copyWith(
            regular: suggestedProjectPresentationLayouts(
              'standard',
            ).title.regular.copyWith(
                  slot: ProjectPresentationLayoutSlot.leftPane,
                ),
          ),
    );
    final theme = PokeMapPlayerTheme.withLayoutProfile(
      PokeMapPlayerTheme.light(),
      layouts,
    );

    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: 'Aube',
            author: 'Studio',
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: PlayerActionAvailability.enabled,
            },
          ),
          onSelected: (_) {},
        ),
        theme: theme,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('player-title-responsive-regular')),
      findsOneWidget,
    );
    final alignment = tester.widget<Align>(
      find.byKey(const ValueKey<String>('player-title-content-alignment')),
    );
    expect(alignment.alignment, Alignment.centerLeft);
  });

  testWidgets('title and menu consume their semantic typography roles',
      (tester) async {
    final theme = PokeMapPlayerTheme.withTypography(
      PokeMapPlayerTheme.light(),
      const PokeMapPlayerTypography(
        displayFamily: 'Aube Display',
        bodyFamily: 'Aube Body',
      ),
    );
    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: 'Aube',
            author: 'Studio',
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: PlayerActionAvailability.enabled,
            },
          ),
          onSelected: (_) {},
        ),
        theme: theme,
      ),
    );

    expect(tester.widget<Text>(find.text('Aube')).style?.fontFamily,
        'Aube Display');
    expect(
      tester.widget<Text>(find.text('Nouveau jeu')).style?.fontFamily,
      'Aube Body',
    );
  });

  testWidgets('premium startup menu matches the authored compact composition',
      (tester) async {
    final focusController = RuntimePlayerFocusController(
      logicalSelectionId: 'title.newGame',
    );
    addTearDown(focusController.dispose);
    final data = PlayerTitleViewData(
      gameTitle: 'Le Train de 17h42',
      author: 'PokeMap',
      layoutVariant: PlayerTitleLayoutVariant.runtimeStartupCinematic,
      continueSave: PlayerSaveSummary(
        address: SaveSlotAddress(
          gameId: 'com.pokemap.train1742',
          profileId: 'default',
          slotId: 'slot-1',
        ),
        updatedAt: DateTime(2026, 8, 9),
        playTimeSeconds: 6386,
        status: SaveStatus.active,
        canContinue: true,
        locationLabel: 'Vallée d’Hisui',
      ),
      actions: const <PlayerTitleMenuAction, PlayerActionAvailability>{
        PlayerTitleMenuAction.continueGame: PlayerActionAvailability.enabled,
        PlayerTitleMenuAction.newGame: PlayerActionAvailability.enabled,
        PlayerTitleMenuAction.options: PlayerActionAvailability.enabled,
        PlayerTitleMenuAction.returnToHub: PlayerActionAvailability.enabled,
      },
    );

    tester.view.physicalSize = const Size(392, 996);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: data,
          focusController: focusController,
          onSelected: (_) {},
        ),
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('player-title-startup-menu')),
      ),
      const Size(392, 996),
    );
    expect(find.byKey(const ValueKey<String>('player-cinematic-stage')),
        findsNothing);
    expect(find.byKey(const ValueKey<String>('player-title-startup-visual')),
        findsNothing);
    expect(find.text('PokeMap'), findsNothing);
    expect(find.text('Le Train\nde 17h42'), findsOneWidget);
    expect(find.text('01:46 · Vallée d’Hisui'), findsOneWidget);
    expect(find.text('Nouveau jeu'), findsOneWidget);
    expect(find.text('Retour au Hub'), findsOneWidget);
    expect(find.text('Choisir'), findsOneWidget);
    expect(find.text('ENTER'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);

    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey<String>('player-title-premium-title')),
      ),
      const Offset(46, 74),
    );
    expect(
      tester.getRect(
        find.byKey(
          const ValueKey<String>('player-title-premium-action-newGame'),
        ),
      ),
      const Rect.fromLTWH(46, 243, 302, 58),
    );
    expect(
      tester.getTopLeft(
        find.byKey(const ValueKey<String>('player-title-premium-controls')),
      ),
      const Offset(46, 930),
    );

    final actionCenters = <PlayerTitleMenuAction, Offset>{
      for (final action in const <PlayerTitleMenuAction>[
        PlayerTitleMenuAction.continueGame,
        PlayerTitleMenuAction.newGame,
        PlayerTitleMenuAction.options,
        PlayerTitleMenuAction.returnToHub,
      ])
        action: tester.getCenter(
          find.byKey(
            ValueKey<String>('player-title-premium-action-${action.name}'),
          ),
        ),
    };
    focusController.select('title.continueGame');
    await tester.pump();
    for (final entry in actionCenters.entries) {
      expect(
        tester.getCenter(
          find.byKey(
            ValueKey<String>(
              'player-title-premium-action-${entry.key.name}',
            ),
          ),
        ),
        entry.value,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium startup menu activates Continue with Enter',
      (tester) async {
    final selected = <PlayerTitleMenuAction>[];
    final focusController = RuntimePlayerFocusController(
      logicalSelectionId: 'title.continueGame',
    );
    addTearDown(focusController.dispose);

    await tester.pumpWidget(
      _app(
        RuntimePlayerActions(
          onBack: () {},
          onMenu: () {},
          onInputSourceChanged: (_) {},
          child: PlayerTitleScreen(
            data: PlayerTitleViewData(
              gameTitle: 'Le Train de 17h42',
              author: 'PokeMap',
              layoutVariant: PlayerTitleLayoutVariant.runtimeStartupCinematic,
              actions: const <PlayerTitleMenuAction, PlayerActionAvailability>{
                PlayerTitleMenuAction.continueGame:
                    PlayerActionAvailability.enabled,
                PlayerTitleMenuAction.newGame: PlayerActionAvailability.enabled,
              },
            ),
            focusController: focusController,
            onSelected: selected.add,
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, <PlayerTitleMenuAction>[
      PlayerTitleMenuAction.continueGame,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium startup menu keeps a 392 pixel rail on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(995, 690);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: 'Le Train de 17h42',
            author: 'PokeMap',
            layoutVariant: PlayerTitleLayoutVariant.runtimeStartupCinematic,
            actions: const <PlayerTitleMenuAction, PlayerActionAvailability>{
              PlayerTitleMenuAction.continueGame:
                  PlayerActionAvailability.enabled,
              PlayerTitleMenuAction.newGame: PlayerActionAvailability.enabled,
              PlayerTitleMenuAction.options: PlayerActionAvailability.enabled,
            },
          ),
          onSelected: (_) {},
        ),
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('player-title-startup-menu')),
      ),
      const Size(392, 690),
    );
    expect(find.byKey(const ValueKey<String>('player-title-startup-visual')),
        findsOneWidget);
    expect(find.text('PokeMap'), findsNothing);
  });

  testWidgets('premium startup menu scrolls every authored title action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(995, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        PlayerTitleScreen(
          data: PlayerTitleViewData(
            gameTitle: 'Le Train de 17h42',
            author: 'PokeMap',
            layoutVariant: PlayerTitleLayoutVariant.runtimeStartupCinematic,
            actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
              for (final action in PlayerTitleMenuAction.values)
                action: PlayerActionAvailability.enabled,
            },
          ),
          onSelected: (_) {},
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('player-title-premium-actions-scroll'),
      ),
      findsOneWidget,
    );
    expect(find.text('Crédits / À propos'), findsOneWidget);
    expect(find.text('Retour au Hub'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(
  Widget child, {
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
}) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme ?? PokeMapPlayerTheme.light(),
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: appChild!,
      ),
      home: child,
    );
