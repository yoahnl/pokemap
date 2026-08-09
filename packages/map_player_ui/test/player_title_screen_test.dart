import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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

    expect(find.text('Aube'), findsOneWidget);
    expect(find.text('Studio Brume'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Nouvelle partie'), findsOneWidget);
    expect(find.text('Charger'), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
    expect(find.text('Crédits / À propos'), findsOneWidget);
    expect(find.text('Retour au Hub'), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Nouvelle partie',
      reason: 'Focus starts on the first enabled action.',
    );

    await tester.tap(find.text('Nouvelle partie'));
    expect(selected, <PlayerTitleMenuAction>[
      PlayerTitleMenuAction.newGame,
    ]);

    await tester.tap(find.text('Continuer'));
    expect(selected, hasLength(1), reason: 'Disabled actions cannot dispatch.');
  });

  testWidgets('title fits a narrow portrait viewport with text scaling',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: _app(
          PlayerTitleScreen(
            data: PlayerTitleViewData(
              gameTitle: 'Une très longue aventure',
              author: 'Studio',
              actions: <PlayerTitleMenuAction, PlayerActionAvailability>{
                for (final action in PlayerTitleMenuAction.values)
                  action: PlayerActionAvailability.enabled,
              },
            ),
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey<String>('player-title-scroll')),
        findsOneWidget);
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
      tester.widget<Text>(find.text('Nouvelle partie')).style?.fontFamily,
      'Aube Body',
    );
  });

  testWidgets('cinematic startup menu matches desktop and mobile geometry',
      (tester) async {
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
      },
    );

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(PlayerTitleScreen(data: data, onSelected: (_) {})),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('player-cinematic-stage')),
      ),
      const Size(1440, 810),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('player-title-startup-menu')),
          )
          .width,
      619.2,
    );
    expect(find.text('01:46 · Vallée d’Hisui'), findsOneWidget);

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(
      _app(PlayerTitleScreen(data: data, onSelected: (_) {})),
    );

    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('player-title-startup-visual')),
          )
          .height,
      closeTo(489.52, .01),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('player-title-startup-menu')),
          )
          .height,
      closeTo(379.8, .01),
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme ?? PokeMapPlayerTheme.light(),
      home: child,
    );
