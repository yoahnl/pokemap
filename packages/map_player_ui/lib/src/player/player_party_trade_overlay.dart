import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_control_profile.dart';
import 'runtime_player_actions.dart';

class PlayerPartyTradeOverlay extends StatelessWidget {
  const PlayerPartyTradeOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.controlProfile,
    this.hardwareGamepadEnabled = true,
  });

  final RuntimeWorldServiceSnapshot snapshot;
  final ValueChanged<RuntimeWorldServiceCommand> onCommand;
  final PlayerControlProfile? controlProfile;
  final bool hardwareGamepadEnabled;

  @override
  Widget build(BuildContext context) {
    final value = snapshot.content;
    final content = value is RuntimePartyTradeServiceContent ? value : null;
    final french = Localizations.localeOf(context).languageCode == 'fr';
    String text(String fr, String en) => french ? fr : en;
    final applying = snapshot.stage == RuntimeWorldServiceStage.applying;
    final completed = snapshot.stage == RuntimeWorldServiceStage.completed;
    final failed = snapshot.stage == RuntimeWorldServiceStage.failed;
    String label(String? id) =>
        content?.members
            .where((member) => member.individualId == id)
            .firstOrNull
            ?.label ??
        '';
    final phase = content?.phase;
    final message = completed
        ? content?.completionMessage ??
              text('Échange terminé.', 'Trade completed.')
        : failed || content == null
        ? text('L’échange est indisponible.', 'Trade is unavailable.')
        : switch (phase!) {
            RuntimePartyTradePhase.selectFirst => text(
              'Choisissez le Pokémon à échanger.',
              'Choose the Pokémon to trade.',
            ),
            RuntimePartyTradePhase.choosePartner => text(
              'Choisir un autre Pokémon comme partenaire ?',
              'Choose another Pokémon as partner?',
            ),
            RuntimePartyTradePhase.selectPartner => text(
              'Choisissez son partenaire dans l’équipe.',
              'Choose its partner from your party.',
            ),
            RuntimePartyTradePhase.review => text(
              'Confirmer cet échange ?',
              'Confirm this trade?',
            ),
            RuntimePartyTradePhase.completed => text(
              'Échange terminé.',
              'Trade completed.',
            ),
          };
    return RuntimePlayerActions(
      includeDefaultKeyboardShortcuts: false,
      onBack: () => _emit(
        snapshot.isActionEnabled(RuntimeWorldServiceAction.cancel)
            ? RuntimeWorldServiceAction.cancel
            : RuntimeWorldServiceAction.close,
      ),
      onMenu: () {},
      onInputSourceChanged: (_) {},
      child: RuntimePlayerInputBindings(
        controlProfile: controlProfile,
        hardwareGamepadEnabled: hardwareGamepadEnabled,
        child: ColoredBox(
          color: context.playerColors.scrim,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(PlayerSpacing.md),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: PlayerPanel(
                    surfaceRole: ProjectPresentationSurfaceRole.confirmation,
                    elevated: true,
                    padding: const EdgeInsets.all(PlayerSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          text('Échange de l’équipe', 'Party trade'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: PlayerSpacing.sm),
                        Text(message),
                        const SizedBox(height: PlayerSpacing.md),
                        if (applying)
                          const LinearProgressIndicator()
                        else if (!failed && !completed && content != null) ...[
                          if (phase == RuntimePartyTradePhase.selectFirst ||
                              phase == RuntimePartyTradePhase.selectPartner)
                            for (final member in content.members)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: PlayerSpacing.xs,
                                ),
                                child: PlayerActionButton(
                                  key: ValueKey(
                                    'party-trade-pokemon-${member.individualId}',
                                  ),
                                  label:
                                      '${member.label} · ${text('Niv.', 'Lv.')} ${member.level}',
                                  icon: Icons.catching_pokemon,
                                  autofocus: member == content.members.first,
                                  onPressed:
                                      snapshot.isActionEnabled(
                                        RuntimeWorldServiceAction.select,
                                      )
                                      ? () => _emit(
                                          RuntimeWorldServiceAction.select,
                                          targetId: member.individualId,
                                        )
                                      : null,
                                ),
                              ),
                          if (phase ==
                              RuntimePartyTradePhase.choosePartner) ...[
                            PlayerActionButton(
                              key: const ValueKey('party-trade-other-partner'),
                              label: text(
                                'Choisir un partenaire',
                                'Choose a partner',
                              ),
                              icon: Icons.people_outline,
                              autofocus: true,
                              onPressed: () => _emit(
                                RuntimeWorldServiceAction.select,
                                targetId: RuntimePartyTradeServiceContent
                                    .otherPartnerTarget,
                              ),
                            ),
                            const SizedBox(height: PlayerSpacing.xs),
                            PlayerActionButton(
                              key: const ValueKey('party-trade-same-partner'),
                              label: text('Avec lui-même', 'With itself'),
                              icon: Icons.person_outline,
                              secondary: true,
                              onPressed: () => _emit(
                                RuntimeWorldServiceAction.select,
                                targetId: RuntimePartyTradeServiceContent
                                    .samePartnerTarget,
                              ),
                            ),
                          ],
                          if (phase == RuntimePartyTradePhase.review) ...[
                            Text(
                              '${text('Pokémon :', 'Pokémon:')} ${label(content.firstIndividualId)}',
                            ),
                            Text(
                              '${text('Partenaire :', 'Partner:')} ${label(content.partnerIndividualId)}',
                            ),
                            const SizedBox(height: PlayerSpacing.sm),
                            PlayerActionButton(
                              key: const ValueKey('party-trade-confirm'),
                              label: text(
                                'Confirmer l’échange',
                                'Confirm trade',
                              ),
                              icon: Icons.check,
                              autofocus: true,
                              onPressed:
                                  snapshot.isActionEnabled(
                                    RuntimeWorldServiceAction.confirm,
                                  )
                                  ? () =>
                                        _emit(RuntimeWorldServiceAction.confirm)
                                  : null,
                            ),
                          ],
                        ],
                        if (snapshot.safeMessage case final safe?
                            when safe.isNotEmpty) ...[
                          const SizedBox(height: PlayerSpacing.sm),
                          Text(safe),
                        ],
                        if (!applying) ...[
                          const SizedBox(height: PlayerSpacing.sm),
                          PlayerActionButton(
                            key: ValueKey(
                              completed || failed
                                  ? 'party-trade-close'
                                  : 'party-trade-cancel',
                            ),
                            label: completed || failed
                                ? context.playerL10n.close
                                : text('Annuler', 'Cancel'),
                            icon: Icons.close,
                            secondary: true,
                            onPressed: () => _emit(
                              snapshot.isActionEnabled(
                                    RuntimeWorldServiceAction.cancel,
                                  )
                                  ? RuntimeWorldServiceAction.cancel
                                  : RuntimeWorldServiceAction.close,
                            ),
                          ),
                        ],
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

  void _emit(RuntimeWorldServiceAction action, {String? targetId}) {
    if (!snapshot.isActionEnabled(action)) return;
    onCommand(
      RuntimeWorldServiceCommand(
        action: action,
        snapshotRevision: snapshot.revision,
        targetId: targetId,
      ),
    );
  }
}
