import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

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
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.light(),
      home: child,
    );
