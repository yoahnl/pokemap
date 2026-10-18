import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/runtime_player_pokedex.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
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
  testWidgets('gift Pokedex renders the native one-entry surface', (
    tester,
  ) async {
    final interaction = SceneMessageInteractionRequest(
      requestId: 'dex',
      revision: 2,
      prompt: SceneInteractionPrompt(
        localizationKey: 'dex',
        fallbackText: 'Pokédex',
      ),
    );
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.pokedex,
      title: 'Pokédex',
      entries: [
        RuntimePlayerDetailEntrySnapshot(
          id: 'clockbird',
          title: 'Clockbird',
          subtitle: 'Capturé',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerPokemonGiftOverlay(
            snapshot: giftSnapshot(
              interaction,
              PokemonGiftInteractionStage.pokedex,
              detail: detail,
            ),
            onCommand: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(RuntimePlayerPokedex), findsOneWidget);
    expect(
      tester
          .widget<RuntimePlayerPokedex>(find.byType(RuntimePlayerPokedex))
          .detail
          .entries
          .single
          .id,
      'clockbird',
    );
  });
}

RuntimeWorldServiceSnapshot giftSnapshot(
  SceneInteractionRequest interaction,
  PokemonGiftInteractionStage stage, {
  RuntimePlayerPauseDetailSnapshot? detail,
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
