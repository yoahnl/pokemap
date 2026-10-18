import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_scene_interaction_surface.dart';
import 'player_text_input_overlay.dart';
import 'runtime_player_pokedex.dart';

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
    void submit(SceneInteractionResult result) => onCommand(
      RuntimeWorldServiceCommand(
        action: result is SceneCancelledInteractionResult
            ? RuntimeWorldServiceAction.cancel
            : RuntimeWorldServiceAction.confirm,
        snapshotRevision: snapshot.revision,
        interactionResult: result,
      ),
    );
    if (request.stage == PokemonGiftInteractionStage.pokedex) {
      final detail = request.pokedexDetail;
      if (detail == null ||
          detail.entries.length != 1 ||
          detail.entries.single.id != request.pokemon.speciesId) {
        throw StateError(
          'The Pokemon gift Pokedex requires its hydrated native entry.',
        );
      }
      return ColoredBox(
        color: context.playerColors.scrim,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PlayerMenuThemeScope(
                  child: RuntimePlayerPokedex(detail: detail),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(PlayerSpacing.md),
                child: PlayerActionButton(
                  label: Localizations.localeOf(context).languageCode == 'fr'
                      ? 'Continuer'
                      : 'Continue',
                  icon: Icons.check,
                  autofocus: true,
                  onPressed: () => submit(
                    SceneInteractionResult.acknowledged(
                      requestId: interaction.requestId,
                      revision: interaction.revision,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (interaction is SceneTextInteractionRequest) {
      return PlayerTextInputOverlay(snapshot: snapshot, onCommand: onCommand);
    }
    return PlayerSceneInteractionSurface(
      request: interaction,
      allowCancellation: true,
      interactionEnabled: snapshot.isActionEnabled(
        RuntimeWorldServiceAction.confirm,
      ),
      promptResolver: (prompt) {
        final french = Localizations.localeOf(context).languageCode == 'fr';
        final name = request.speciesName ?? request.pokemon.speciesId;
        final nickname = request.pokemon.nickname.isEmpty
            ? name
            : request.pokemon.nickname;
        return switch (request.stage) {
          PokemonGiftInteractionStage.received =>
            french ? 'Vous recevez $name !' : 'You received $name!',
          PokemonGiftInteractionStage.nicknameConfirmation =>
            french ? 'Donner un surnom à $name ?' : 'Give $name a nickname?',
          PokemonGiftInteractionStage.destination =>
            request.projectedState.party.members.any(
                  (p) => p.individualId == request.pokemon.individualId,
                )
                ? (french
                      ? '$nickname rejoint votre équipe.'
                      : '$nickname joined your party.')
                : (french
                      ? '$nickname est envoyé au PC.'
                      : '$nickname was sent to the PC.'),
          _ => prompt.fallbackText,
        };
      },
      onResult: submit,
    );
  }
}
