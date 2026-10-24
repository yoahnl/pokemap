import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('one gift receipt groups destination and optional nickname',
      (tester) async {
    final interaction = SceneChoiceInteractionRequest(
      requestId: 'receipt', revision: 4,
      prompt: SceneInteractionPrompt(localizationKey: 'pokemonGift.received'),
      options: [for (final id in ['continue', 'nickname']) SceneInteractionOption(
        id: id, label: SceneInteractionPrompt(localizationKey: 'pokemonGift.$id'),
      )],
    );
    final commands = <RuntimeWorldServiceCommand>[];
    await tester.pumpWidget(MaterialApp(theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(body: PlayerPokemonGiftOverlay(
        snapshot: giftSnapshot(interaction, PokemonGiftInteractionStage.received,
          isNew: true), onCommand: commands.add,
      )),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('gift-continue')), findsOneWidget);
    expect(find.byKey(const ValueKey('gift-nickname')), findsOneWidget);
    expect(find.textContaining('Pokédex'), findsOneWidget);
    expect(find.textContaining('PC'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    await tester.tap(find.byKey(const ValueKey('gift-nickname')));
    expect(commands.single.snapshotRevision, 10);
    expect((commands.single.interactionResult as SceneChoiceSelectedInteractionResult).selectedOptionId, 'nickname');
  });
  testWidgets(
    'gift nickname uses text overlay and sends typed bounded response',
    (tester) async {
      final interaction = SceneTextInteractionRequest(
        requestId: 'nickname',
        revision: 3,
        prompt: SceneInteractionPrompt(
          localizationKey: 'nickname',
          fallbackText: 'Surnom',
        ),
        constraints: SceneTextInputConstraints(maxGraphemes: 10),
        initialValue: 'Horloge',
      );
      final commands = <RuntimeWorldServiceCommand>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.dark(),
          home: Scaffold(
            body: PlayerPokemonGiftOverlay(
              snapshot: giftSnapshot(
                interaction,
                PokemonGiftInteractionStage.nickname,
              ),
              onCommand: commands.add,
            ),
          ),
        ),
      );
      expect(find.byType(PlayerTextInputOverlay), findsOneWidget);
      expect(find.text('Horloge'), findsOneWidget);
      final surface = tester.widget<PlayerSceneInteractionSurface>(
        find.byType(PlayerSceneInteractionSurface),
      );
      surface.onResult(
        SceneInteractionResult.textSubmitted(
          requestId: 'nickname',
          revision: 3,
          value: 'Horloge',
        ),
      );
      expect(commands.single.snapshotRevision, 10);
      expect(
        commands.single.interactionResult,
        isA<SceneTextSubmittedInteractionResult>(),
      );
    },
  );
  testWidgets('gift without nickname offers one acknowledgement and no extra dex step', (tester) async {
    final interaction = SceneMessageInteractionRequest(requestId: 'receipt', revision: 2,
      prompt: SceneInteractionPrompt(localizationKey: 'pokemonGift.received'));
    final commands = <RuntimeWorldServiceCommand>[];
    await tester.pumpWidget(MaterialApp(theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(body: PlayerPokemonGiftOverlay(
        snapshot: giftSnapshot(interaction, PokemonGiftInteractionStage.received),
        onCommand: commands.add,
      )),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('gift-nickname')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('gift-continue')));
    expect(commands.single.interactionResult, isA<SceneAcknowledgedInteractionResult>());
    expect(commands.single.snapshotRevision, 10);
  });
}

RuntimeWorldServiceSnapshot giftSnapshot(
  SceneInteractionRequest interaction,
  PokemonGiftInteractionStage stage, {
  RuntimePlayerPauseDetailSnapshot? detail,
  bool isNew = false,
}) => RuntimeWorldServiceSnapshot(
  revision: 10,
  stage: RuntimeWorldServiceStage.active,
  request: OpenPokemonGiftInteractionService(
    interactionId: interaction.requestId,
    interaction: interaction,
    stage: stage,
    pokemon: const PlayerPokemon(
      speciesId: 'clockbird',
      natureId: 'hardy',
      abilityId: 'clockwork',
      currentHp: 10,
    ),
    projectedState: const GameState(saveId: 'gift'),
    pokedexDetail: detail,
    isNewPokedexEntry: isNew,
  ),
  content: interaction,
  actions: const [
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.confirm,
    ),
    RuntimeWorldServiceActionAvailability.enabled(
      RuntimeWorldServiceAction.cancel,
    ),
  ],
);
