import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_control_profile.dart';
import 'runtime_player_actions.dart';
import 'player_service_layout.dart';

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
    final memberWidth =
        math.min(
          500,
          MediaQuery.sizeOf(context).width -
              MediaQuery.paddingOf(context).horizontal -
              24,
        ) -
        24;
    final memberColumns =
        memberWidth >= 420 && MediaQuery.textScalerOf(context).scale(1) < 1.5
        ? 2
        : 1;
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
        child: Focus(
          autofocus: true,
          child: PlayerMenuThemeScope(
            role: ProjectPresentationSurfaceRole.confirmation,
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
                          maxHeight: 760,
                        ),
                        child: PlayerMenuPanel(
                          key: const ValueKey('party-trade-service-panel'),
                          primary: true,
                          padding: const EdgeInsets.all(12),
                          child: PlayerServiceContent(
                            contentIdentity: (
                              snapshot.revision,
                              phase,
                              snapshot.stage,
                            ),
                            title: Text(
                              text('Échange de l’équipe', 'Party trade'),
                              style: context.playerMenuTheme.title,
                            ),
                            actions: applying
                                ? null
                                : PlayerServiceActions(
                                    children: [
                                      if (phase ==
                                              RuntimePartyTradePhase.review &&
                                          !failed &&
                                          !completed)
                                        PlayerActionButton(
                                          key: const ValueKey(
                                            'party-trade-confirm',
                                          ),
                                          label: text('Confirmer', 'Confirm'),
                                          labelMaxLines: 8,
                                          icon: Icons.check,
                                          autofocus: true,
                                          onPressed:
                                              snapshot.isActionEnabled(
                                                RuntimeWorldServiceAction
                                                    .confirm,
                                              )
                                              ? () => _emit(
                                                  RuntimeWorldServiceAction
                                                      .confirm,
                                                )
                                              : null,
                                        ),
                                      PlayerActionButton(
                                        key: ValueKey(
                                          completed || failed
                                              ? 'party-trade-close'
                                              : 'party-trade-cancel',
                                        ),
                                        label: completed || failed
                                            ? context.playerL10n.close
                                            : text('Annuler', 'Cancel'),
                                        labelMaxLines: 8,
                                        icon: Icons.close,
                                        secondary: true,
                                        onPressed:
                                            snapshot.isActionEnabled(
                                              RuntimeWorldServiceAction.cancel,
                                            )
                                            ? () => _emit(
                                                RuntimeWorldServiceAction
                                                    .cancel,
                                              )
                                            : snapshot.isActionEnabled(
                                                RuntimeWorldServiceAction.close,
                                              )
                                            ? () => _emit(
                                                RuntimeWorldServiceAction.close,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                            children: [
                              Text(message),
                              if (applying) const LinearProgressIndicator(),
                              if (!failed && !completed && content != null) ...[
                                if (phase ==
                                        RuntimePartyTradePhase.selectFirst ||
                                    phase ==
                                        RuntimePartyTradePhase.selectPartner)
                                  for (
                                    var start = 0;
                                    start < content.members.length;
                                    start += memberColumns
                                  )
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (
                                          var index = start;
                                          index <
                                              math.min(
                                                start + memberColumns,
                                                content.members.length,
                                              );
                                          index++
                                        ) ...[
                                          if (index > start)
                                            const SizedBox(width: 8),
                                          Expanded(
                                            child: _memberButton(
                                              context,
                                              content,
                                              content.members[index],
                                              phase!,
                                            ),
                                          ),
                                        ],
                                        if (memberColumns == 2 &&
                                            start + 1 ==
                                                content.members.length) ...[
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: SizedBox.shrink(),
                                          ),
                                        ],
                                      ],
                                    ),
                                if (phase ==
                                    RuntimePartyTradePhase.choosePartner) ...[
                                  PlayerActionButton(
                                    key: const ValueKey(
                                      'party-trade-other-partner',
                                    ),
                                    label: text(
                                      'Choisir un partenaire',
                                      'Choose a partner',
                                    ),
                                    icon: Icons.people_outline,
                                    autofocus: true,
                                    onPressed:
                                        snapshot.isActionEnabled(
                                          RuntimeWorldServiceAction.select,
                                        )
                                        ? () => _emit(
                                            RuntimeWorldServiceAction.select,
                                            targetId:
                                                RuntimePartyTradeServiceContent
                                                    .otherPartnerTarget,
                                          )
                                        : null,
                                  ),
                                  PlayerActionButton(
                                    key: const ValueKey(
                                      'party-trade-same-partner',
                                    ),
                                    label: text('Avec lui-même', 'With itself'),
                                    icon: Icons.person_outline,
                                    secondary: true,
                                    onPressed:
                                        snapshot.isActionEnabled(
                                          RuntimeWorldServiceAction.select,
                                        )
                                        ? () => _emit(
                                            RuntimeWorldServiceAction.select,
                                            targetId:
                                                RuntimePartyTradeServiceContent
                                                    .samePartnerTarget,
                                          )
                                        : null,
                                  ),
                                ],
                                if (phase == RuntimePartyTradePhase.review) ...[
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      Widget identity(
                                        String prefix,
                                        String? id,
                                      ) {
                                        final member = content.members
                                            .where(
                                              (member) =>
                                                  member.individualId == id,
                                            )
                                            .firstOrNull;
                                        return PlayerMenuPanel(
                                          key: ValueKey(
                                            'party-trade-identity-$prefix',
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$prefix ${label(id)}',
                                                style: context
                                                    .playerMenuTheme
                                                    .label,
                                              ),
                                              if (member != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${text('Niv.', 'Lv.')} ${member.level}',
                                                  style: context
                                                      .playerMenuTheme
                                                      .meta,
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }

                                      final first = identity(
                                        text('Pokémon :', 'Pokémon:'),
                                        content.firstIndividualId,
                                      );
                                      final partner = identity(
                                        text('Partenaire :', 'Partner:'),
                                        content.partnerIndividualId,
                                      );
                                      return SizedBox(
                                        key: const ValueKey('party-trade-pair'),
                                        child:
                                            constraints.maxWidth >= 400 &&
                                                MediaQuery.textScalerOf(context)
                                                        .scale(1) <
                                                    1.5
                                            ? Row(
                                                children: [
                                                  Expanded(child: first),
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    child: Icon(
                                                      Icons.swap_horiz,
                                                    ),
                                                  ),
                                                  Expanded(child: partner),
                                                ],
                                              )
                                            : Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  first,
                                                  const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    child: Icon(
                                                      Icons.swap_vert,
                                                    ),
                                                  ),
                                                  partner,
                                                ],
                                              ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                              if (snapshot.safeMessage case final safe?
                                  when safe.isNotEmpty)
                                Semantics(liveRegion: true, child: Text(safe)),
                            ],
                          ),
                        ),
                      ),
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

  Widget _memberButton(
    BuildContext context,
    RuntimePartyTradeServiceContent content,
    RuntimePartyTradePokemonSnapshot member,
    RuntimePartyTradePhase phase,
  ) {
    final levelLabel = Localizations.localeOf(context).languageCode == 'fr'
        ? 'Niv.'
        : 'Lv.';
    return PlayerActionButton(
      key: ValueKey('party-trade-pokemon-${member.individualId}'),
      label: '${member.label} · $levelLabel ${member.level}',
      labelMaxLines: 2,
      icon: Icons.catching_pokemon,
      secondary: true,
      selected:
          member.individualId ==
          (phase == RuntimePartyTradePhase.selectPartner
              ? content.partnerIndividualId
              : content.firstIndividualId),
      autofocus: member == content.members.first,
      onPressed: snapshot.isActionEnabled(RuntimeWorldServiceAction.select)
          ? () => _emit(
              RuntimeWorldServiceAction.select,
              targetId: member.individualId,
            )
          : null,
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
