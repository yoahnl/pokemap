import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../localization/player_localizations.dart';
import '../foundation/player_components.dart';
import '../foundation/player_image.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_text_input_overlay.dart';
import 'player_service_layout.dart';

class PlayerPokemonGiftOverlay extends StatelessWidget {
  const PlayerPokemonGiftOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;

  @override
  Widget build(BuildContext context) {
    final request = snapshot.request;
    if (request is! OpenPokemonGiftInteractionService) {
      throw StateError('The Pokemon gift overlay requires its typed request.');
    }
    final interaction = request.interaction;
    if (interaction is SceneTextInteractionRequest) {
      return PlayerTextInputOverlay(snapshot: snapshot, onCommand: onCommand);
    }
    final strings = context.playerL10n;
    final name = request.pokemon.isEgg
        ? (context.playerL10n.giftEgg)
        : request.speciesName ?? request.pokemon.speciesId;
    final nickname = request.pokemon.nickname.isEmpty
        ? name
        : request.pokemon.nickname;
    final party = request.projectedState.party.members.any(
      (pokemon) => pokemon.individualId == request.pokemon.individualId,
    );
    final dexEntry = request.pokedexDetail?.entries
        .where(
          (entry) =>
              entry.id == request.pokemon.speciesId ||
              entry.pokedexEntry?.identity?.speciesId ==
                  request.pokemon.speciesId,
        )
        .firstOrNull
        ?.pokedexEntry;
    final media = dexEntry?.knowledge == RuntimePlayerPokedexKnowledge.unknown
        ? null
        : dexEntry?.media.illustration ?? dexEntry?.media.thumbnail;
    final enabled = snapshot.isActionEnabled(RuntimeWorldServiceAction.confirm);
    final choices = interaction is SceneChoiceInteractionRequest
        ? interaction.options
        : const <SceneInteractionOption>[];
    bool canChoose(String id) =>
        enabled &&
        (interaction is SceneChoiceInteractionRequest
            ? choices.any((choice) => choice.id == id && choice.enabled)
            : interaction is SceneMessageInteractionRequest &&
                  id == 'continue');
    void choose(String id) {
      if (!canChoose(id)) return;
      final result = interaction is SceneChoiceInteractionRequest
          ? SceneInteractionResult.choiceSelected(
              requestId: interaction.requestId,
              revision: interaction.revision,
              selectedOptionId: id,
            )
          : SceneInteractionResult.acknowledged(
              requestId: interaction.requestId,
              revision: interaction.revision,
            );
      onCommand(
        RuntimeWorldServiceCommand(
          action: RuntimeWorldServiceAction.confirm,
          snapshotRevision: snapshot.revision,
          interactionResult: result,
        ),
      );
    }

    return PlayerMenuThemeScope(
      role: ProjectPresentationSurfaceRole.captureResult,
      child: Builder(
        builder: (context) => ColoredBox(
          color: context.playerColors.scrim,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 500,
                    maxHeight: 680,
                  ),
                  child: PlayerMenuPanel(
                    key: const ValueKey('gift-service-panel'),
                    primary: true,
                    padding: const EdgeInsets.all(16),
                    child: PlayerServiceContent(
                      contentIdentity: (snapshot.revision, snapshot.stage),
                      title: Text(
                        context.playerL10n.giftTitle,
                        style: context.playerMenuTheme.title,
                      ),
                      actions: PlayerServiceActions(
                        children: [
                          if (choices.any((choice) => choice.id == 'nickname'))
                            PlayerActionButton(
                              key: const ValueKey('gift-nickname'),
                              label: context.playerL10n.pcNickname,
                              labelMaxLines: 8,
                              icon: Icons.edit_outlined,
                              secondary: true,
                              onPressed: canChoose('nickname')
                                  ? () => choose('nickname')
                                  : null,
                            ),
                          PlayerActionButton(
                            key: const ValueKey('gift-continue'),
                            label: context.playerL10n.continueGame,
                            labelMaxLines: 8,
                            icon: Icons.check,
                            autofocus: true,
                            onPressed: canChoose('continue')
                                ? () => choose('continue')
                                : null,
                          ),
                        ],
                      ),
                      children: [
                        if (request.isNewPokedexEntry)
                          Text(context.playerL10n.giftNewPokedexEntry),
                        Text(
                          party
                              ? (context.playerL10n.giftJoinsParty(
                                  nickname: nickname,
                                ))
                              : (context.playerL10n.giftSentToPc(
                                  nickname: nickname,
                                )),
                        ),
                        if (media != null)
                          Semantics(
                            image: true,
                            label: nickname,
                            child: SizedBox(
                              height: 72,
                              child: PlayerFileImage(
                                key: const ValueKey('gift-pokemon-image'),
                                path: media.absoluteFilePath,
                                fit: BoxFit.contain,
                                filterQuality:
                                    media.sampling ==
                                        ProjectMenuImageSampling.pixelArt
                                    ? FilterQuality.none
                                    : FilterQuality.medium,
                                excludeFromSemantics: true,
                                fallback: const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        Text(
                          strings.pokemonNameAndLevel(
                            name: nickname == name
                                ? name
                                : strings.pokemonNameAndNickname(
                                    nickname: nickname,
                                    name: name,
                                  ),
                            level: request.pokemon.level,
                          ),
                          key: const ValueKey('gift-pokemon-identity'),
                          textAlign: TextAlign.center,
                          style: context.playerMenuTheme.label,
                        ),
                        if (snapshot.safeMessage case final message?
                            when message.isNotEmpty)
                          Semantics(liveRegion: true, child: Text(message)),
                        if (snapshot.stage == RuntimeWorldServiceStage.applying)
                          const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
