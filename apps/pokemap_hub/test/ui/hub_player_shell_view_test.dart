import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_player_ui/map_player_ui.dart' hide PlayerTitleMenuAction;
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  test('global preferences project into runtime accessibility and audio', () {
    final projection = projectHubPlayerSettings(
      const PlayerPreferences().copyWith(
        reducedMotion: true,
        textScale: 1.3,
        hapticsEnabled: false,
        masterVolume: 0.7,
        musicVolume: 0.5,
        effectsVolume: 0.6,
      ),
    );

    expect(projection.accessibility.reducedMotion, isTrue);
    expect(projection.accessibility.textScale, 1.3);
    expect(projection.accessibility.hapticsEnabled, isFalse);
    expect(projection.masterVolume, 0.7);
    expect(projection.musicVolume, 0.5);
    expect(projection.effectsVolume, 0.6);
  });

  testWidgets('Phase 4 title snapshot drives the player title actions',
      (tester) async {
    PlayerTitleAction? selected;
    await tester.pumpWidget(
      _app(
        HubPlayerShellSurface(
          snapshot: _snapshot(
            state: PlayerShellState.title,
            enabledActions: const <PlayerTitleAction>{
              PlayerTitleAction.newGame,
              PlayerTitleAction.options,
              PlayerTitleAction.creditsAbout,
              PlayerTitleAction.returnToHub,
            },
          ),
          gameView: const SizedBox(),
          onTitleAction: (action) => selected = action,
          onPauseAction: (_) {},
          onCancelLoading: () {},
          onShowCredits: () {},
          onFinishCredits: (_) {},
          onReturnToHub: () {},
        ),
      ),
    );

    await tester.tap(find.text('Nouvelle partie'));
    expect(selected, PlayerTitleAction.newGame);
    final semantics = tester.getSemantics(
      find.byKey(
        const ValueKey<String>('player-action-semantics-Continuer'),
      ),
    );
    expect(semantics.hint, contains('Aucune sauvegarde'));
  });

  testWidgets(
      'paused session overlays the game and never grants world services',
      (tester) async {
    PlayerPauseAction? selected;
    await tester.pumpWidget(
      _app(
        HubPlayerShellSurface(
          snapshot: _snapshot(state: PlayerShellState.paused),
          gameView: const ColoredBox(
            key: ValueKey<String>('mounted-game'),
            color: Colors.blue,
          ),
          pauseActions: <PlayerPauseAction, PlayerActionAvailability>{
            for (final action in PlayerPauseAction.values)
              action: PlayerActionAvailability.enabled,
          },
          onTitleAction: (_) {},
          onPauseAction: (action) => selected = action,
          onCancelLoading: () {},
          onShowCredits: () {},
          onFinishCredits: (_) {},
          onReturnToHub: () {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('mounted-game')), findsOneWidget);
    expect(find.text('Boutique'), findsNothing);
    expect(find.text('Centre Pokémon'), findsNothing);
    expect(find.text('PC'), findsNothing);
    await tester.tap(find.text('Sauvegarder'));
    expect(selected, PlayerPauseAction.save);
  });

  testWidgets('loading reports a stage and cancellable progress',
      (tester) async {
    var cancelled = false;
    await tester.pumpWidget(
      _app(
        HubPlayerShellSurface(
          snapshot: _snapshot(
            state: PlayerShellState.loadingSession,
            loading: const GameSessionLoadingProgress(
              stage: 'catalogues',
              current: 2,
              total: 4,
            ),
          ),
          gameView: const SizedBox(),
          onTitleAction: (_) {},
          onPauseAction: (_) {},
          onCancelLoading: () => cancelled = true,
          onShowCredits: () {},
          onFinishCredits: (_) {},
          onReturnToHub: () {},
        ),
      ),
    );

    expect(find.text('catalogues'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    expect(cancelled, isTrue);
  });

  testWidgets('credits enforce the completion destination', (tester) async {
    GameCompletionDestination? destination;
    await tester.pumpWidget(
      _app(
        HubPlayerShellSurface(
          snapshot: PlayerShellSnapshot(
            state: PlayerShellState.credits,
            title: _title(const <PlayerTitleAction>{}),
            credits: const GameCreditsSnapshot(
              title: 'Aube',
              author: 'Studio',
              endingLabel: 'Fin principale',
            ),
            completionDestination: GameCompletionDestination.hub,
          ),
          gameView: const SizedBox(),
          onTitleAction: (_) {},
          onPauseAction: (_) {},
          onCancelLoading: () {},
          onShowCredits: () {},
          onFinishCredits: (value) => destination = value,
          onReturnToHub: () {},
        ),
      ),
    );

    final titleSemantics = tester.getSemantics(
      find.byKey(
        const ValueKey<String>(
          'player-action-semantics-Retour au titre',
        ),
      ),
    );
    expect(titleSemantics.hint, contains('retourne directement au Hub'));
    await tester.tap(find.text('Retour au Hub'));
    expect(destination, GameCompletionDestination.hub);
  });
}

PlayerShellSnapshot _snapshot({
  required PlayerShellState state,
  Set<PlayerTitleAction> enabledActions = const <PlayerTitleAction>{},
  GameSessionLoadingProgress? loading,
}) =>
    PlayerShellSnapshot(
      state: state,
      title: _title(enabledActions),
      loadingProgress: loading,
    );

PlayerTitleSnapshot _title(Set<PlayerTitleAction> enabledActions) =>
    PlayerTitleSnapshot(
      state: PlayerTitleState.titleIdle,
      gameTitle: 'Aube',
      author: 'Studio',
      description: 'Une aventure.',
      enabledActions: enabledActions,
    );

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );
