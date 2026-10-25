import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('gift renders only the matching public species sprite', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const Color(0xFF334455), BlendMode.src);
    final picture = recorder.endRecording();
    final image = await tester.runAsync(() => picture.toImage(16, 16));
    picture.dispose();
    addTearDown(image!.dispose);
    final interaction = SceneInteractionRequest.message(
      requestId: 'receipt-image',
      revision: 7,
      prompt: SceneInteractionPrompt(localizationKey: 'pokemonGift.received'),
    );
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.pokedex,
      title: 'Pokédex',
      entries: [
        RuntimePlayerDetailEntrySnapshot(
          id: 'clockbird',
          title: 'Clockbird',
          pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
            knowledge: RuntimePlayerPokedexKnowledge.caught,
            identity: const RuntimePokemonMediaIdentity(speciesId: 'clockbird'),
            media: const RuntimePokemonSummaryMediaSnapshot(
              illustration: RuntimePokemonLocalImageSnapshot(
                absoluteFilePath: 'fixture/gift.png',
                sampling: ProjectMenuImageSampling.pixelArt,
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.light(reducedMotion: true),
        home: PlayerImageScope(
          identity: 'gift-image-test',
          loader: (path, {required isCurrent}) async =>
              PlayerImageLease(image: image, onDispose: () {}),
          child: PlayerPokemonGiftOverlay(
            snapshot: giftSnapshot(
              interaction,
              PokemonGiftInteractionStage.received,
              detail: detail,
            ),
            onCommand: (_) {},
          ),
        ),
      ),
    );
    await tester.runAsync(() async {});
    await tester.pumpAndSettle();
    final visual = find.byKey(const ValueKey('gift-pokemon-image'));
    expect(visual, findsOneWidget);
    final raw = tester.widget<RawImage>(
      find.descendant(of: visual, matching: find.byType(RawImage)),
    );
    expect(identical(raw.image, image), isTrue);
    expect(raw.filterQuality, FilterQuality.none);
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gift does not borrow media from another species', (
    tester,
  ) async {
    final interaction = SceneInteractionRequest.message(
      requestId: 'receipt-other',
      revision: 8,
      prompt: SceneInteractionPrompt(localizationKey: 'pokemonGift.received'),
    );
    final detail = RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.pokedex,
      title: 'Pokédex',
      entries: [
        RuntimePlayerDetailEntrySnapshot(
          id: 'another-species',
          title: 'Another species',
          pokedexEntry: RuntimePlayerPokedexEntrySnapshot(
            knowledge: RuntimePlayerPokedexKnowledge.caught,
            media: const RuntimePokemonSummaryMediaSnapshot(
              illustration: RuntimePokemonLocalImageSnapshot(
                absoluteFilePath: 'fixture/other.png',
                sampling: ProjectMenuImageSampling.pixelArt,
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(reducedMotion: true),
        home: PlayerPokemonGiftOverlay(
          snapshot: giftSnapshot(
            interaction,
            PokemonGiftInteractionStage.received,
            detail: detail,
          ),
          onCommand: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gift-pokemon-image')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one gift receipt groups destination and optional nickname', (
    tester,
  ) async {
    final interaction = SceneChoiceInteractionRequest(
      requestId: 'receipt',
      revision: 4,
      prompt: SceneInteractionPrompt(localizationKey: 'pokemonGift.received'),
      options: [
        for (final id in ['continue', 'nickname'])
          SceneInteractionOption(
            id: id,
            label: SceneInteractionPrompt(localizationKey: 'pokemonGift.$id'),
          ),
      ],
    );
    final commands = <RuntimeWorldServiceCommand>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerPokemonGiftOverlay(
            snapshot: giftSnapshot(
              interaction,
              PokemonGiftInteractionStage.received,
              isNew: true,
            ),
            onCommand: commands.add,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('gift-continue')), findsOneWidget);
    expect(find.byKey(const ValueKey('gift-nickname')), findsOneWidget);
    expect(find.textContaining('Pokédex'), findsOneWidget);
    expect(find.textContaining('PC'), findsOneWidget);
    expect(find.byType(Scrollable), findsNothing);
    await tester.tap(find.byKey(const ValueKey('gift-nickname')));
    expect(commands.single.snapshotRevision, 10);
    expect(
      (commands.single.interactionResult
              as SceneChoiceSelectedInteractionResult)
          .selectedOptionId,
      'nickname',
    );
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
  testWidgets(
    'gift without nickname offers one acknowledgement and no extra dex step',
    (tester) async {
      final interaction = SceneMessageInteractionRequest(
        requestId: 'receipt',
        revision: 2,
        prompt: SceneInteractionPrompt(localizationKey: 'pokemonGift.received'),
      );
      final commands = <RuntimeWorldServiceCommand>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.dark(),
          home: Scaffold(
            body: PlayerPokemonGiftOverlay(
              snapshot: giftSnapshot(
                interaction,
                PokemonGiftInteractionStage.received,
              ),
              onCommand: commands.add,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('gift-nickname')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('gift-continue')));
      expect(
        commands.single.interactionResult,
        isA<SceneAcknowledgedInteractionResult>(),
      );
      expect(commands.single.snapshotRevision, 10);
    },
  );
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
