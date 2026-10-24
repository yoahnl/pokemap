import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_text_input_overlay.dart';

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
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final name = request.speciesName ?? request.pokemon.speciesId;
    final nickname = request.pokemon.nickname.isEmpty
        ? name
        : request.pokemon.nickname;
    final party = request.projectedState.party.members.any(
      (pokemon) => pokemon.individualId == request.pokemon.individualId,
    );
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
                    maxWidth: 760,
                    maxHeight: 680,
                  ),
                  child: PlayerMenuPanel(
                    primary: true,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          french ? 'Un nouveau compagnon' : 'A new companion',
                          style: context.playerMenuTheme.title,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: PlayerPagedList(
                            children: [
                              Text(
                                french
                                    ? 'Vous recevez $name !'
                                    : 'You receive $name!',
                                style: context.playerMenuTheme.subtitle,
                              ),
                              Text(
                                '$nickname · ${french ? 'Niv.' : 'Lv.'} ${request.pokemon.level}',
                              ),
                              if (request.isNewPokedexEntry)
                                Text(
                                  french
                                      ? 'Nouvelle entrée Pokédex à ajouter'
                                      : 'New Pokédex entry to add',
                                ),
                              Text(
                                party
                                    ? (french
                                          ? '$nickname rejoindra votre équipe.'
                                          : '$nickname will join your party.')
                                    : (french
                                          ? '$nickname sera envoyé au PC.'
                                          : '$nickname will be sent to the PC.'),
                              ),
                              if (snapshot.safeMessage case final message?
                                  when message.isNotEmpty)
                                Semantics(
                                  liveRegion: true,
                                  child: Text(message),
                                ),
                            ],
                          ),
                        ),
                        if (snapshot.stage == RuntimeWorldServiceStage.applying)
                          const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (choices.any(
                              (choice) => choice.id == 'nickname',
                            )) ...[
                              Expanded(
                                child: PlayerActionButton(
                                  key: const ValueKey('gift-nickname'),
                                  label: french ? 'Surnom' : 'Nickname',
                                  icon: Icons.edit_outlined,
                                  secondary: true,
                                  onPressed: canChoose('nickname')
                                      ? () => choose('nickname')
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: PlayerActionButton(
                                key: const ValueKey('gift-continue'),
                                label: french ? 'Continuer' : 'Continue',
                                icon: Icons.check,
                                autofocus: true,
                                onPressed: canChoose('continue')
                                    ? () => choose('continue')
                                    : null,
                              ),
                            ),
                          ],
                        ),
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
