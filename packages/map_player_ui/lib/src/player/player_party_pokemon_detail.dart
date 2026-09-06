import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_menu_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'player_pokemon_image.dart';
import 'player_pokemon_summary_strings.dart';

class PlayerPartyPokemonDetail extends StatelessWidget {
  const PlayerPartyPokemonDetail({super.key, required this.summary});

  final RuntimePokemonSummarySnapshot summary;

  @override
  Widget build(BuildContext context) {
    final strings = PlayerPokemonSummaryStrings.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 700 ||
          MediaQuery.textScalerOf(context).scale(18) > 25.2;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _overview(context, strings, stacked: stacked),
          const SizedBox(height: 16),
          _informationBand(
              context,
              strings.ability,
              summary.abilityLabel.trim().isEmpty
                  ? strings.none
                  : summary.abilityLabel),
          const SizedBox(height: 8),
          _informationBand(
              context, strings.heldItem, summary.heldItemLabel ?? strings.none),
          const SizedBox(height: 16),
          for (var index = 0; index < 4; index++) ...[
            if (index > 0) const SizedBox(height: 8),
            _move(context, strings, index),
          ],
        ],
      );
    });
  }

  Widget _overview(BuildContext context, PlayerPokemonSummaryStrings strings,
      {required bool stacked}) {
    final illustration = PlayerPokemonImage(
      key: ValueKey('party-detail-image-${summary.targetId}'),
      summary: summary,
      thumbnail: false,
      width: 320,
      height: 272,
    );
    final information = _identityAndStats(context, strings);
    return PlayerMenuPanel(
      primary: true,
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 272),
        child: stacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(child: illustration),
                  const SizedBox(height: 16),
                  information,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  illustration,
                  const SizedBox(width: 24),
                  Expanded(child: information),
                ],
              ),
      ),
    );
  }

  Widget _identityAndStats(
      BuildContext context, PlayerPokemonSummaryStrings strings) {
    final theme = context.playerMenuTheme;
    final stats = summary.stats;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(summary.displayLabel, style: theme.title),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (summary.nickname.isNotEmpty)
              Text(summary.speciesLabel,
                  style: theme.meta.copyWith(color: theme.secondary)),
            if (summary.formLabel case final form?)
              Text(form, style: theme.meta.copyWith(color: theme.secondary)),
            Text(strings.levelValue(summary.level), style: theme.meta),
            if (summary.genderLabel case final gender?)
              Text(gender, style: theme.meta),
          ],
        ),
        if (summary.typeIds.isNotEmpty ||
            summary.isShiny ||
            summary.isFainted ||
            summary.statusLabel != null) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final type in summary.typeIds)
                PlayerMenuBadge(
                  label: context.playerL10n.battleMoveType(type),
                  kind: PlayerMenuBadgeKind.type,
                ),
              if (summary.isShiny) PlayerMenuBadge(label: strings.shiny),
              if (summary.isFainted)
                const PlayerMenuBadge(
                    label: 'KO', kind: PlayerMenuBadgeKind.status)
              else if (summary.statusLabel case final status?)
                PlayerMenuBadge(
                    label: status, kind: PlayerMenuBadgeKind.status),
            ],
          ),
        ],
        const SizedBox(height: 8),
        _stat(context, strings.hp,
            strings.hpValue(summary.currentHp, summary.maxHp)),
        _stat(context, strings.attack, stats?.attack.toString() ?? '—'),
        _stat(context, strings.defense, stats?.defense.toString() ?? '—'),
        _stat(context, strings.specialAttack,
            stats?.specialAttack.toString() ?? '—'),
        _stat(context, strings.specialDefense,
            stats?.specialDefense.toString() ?? '—'),
        _stat(context, strings.speed, stats?.speed.toString() ?? '—'),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    final theme = context.playerMenuTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Text(label,
                style: theme.body.copyWith(color: theme.secondary))),
        const SizedBox(width: 12),
        Text(value, style: theme.numbers, textAlign: TextAlign.right),
      ],
    );
  }

  Widget _informationBand(BuildContext context, String label, String value) {
    final theme = context.playerMenuTheme;
    return PlayerMenuPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 28),
        child: LayoutBuilder(builder: (context, constraints) {
          final labelWidget =
              Text(label, style: theme.meta.copyWith(color: theme.secondary));
          final valueWidget = Text(value, style: theme.label);
          if (constraints.maxWidth < 450 ||
              MediaQuery.textScalerOf(context).scale(18) > 25.2) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, valueWidget],
            );
          }
          return Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: 132, maxWidth: constraints.maxWidth * .4),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: labelWidget,
                ),
              ),
              Expanded(child: valueWidget),
            ],
          );
        }),
      ),
    );
  }

  Widget _move(
      BuildContext context, PlayerPokemonSummaryStrings strings, int index) {
    final theme = context.playerMenuTheme;
    final move = index < summary.moves.length ? summary.moves[index] : null;
    return PlayerMenuPanel(
      key: ValueKey('party-detail-move-slot-$index'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: move == null
            ? ExcludeSemantics(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('—',
                      style: theme.label.copyWith(color: theme.disabled)),
                ),
              )
            : LayoutBuilder(builder: (context, constraints) {
                final typeLabel = move.typeId == null
                    ? move.typeLabel
                    : context.playerL10n.battleMoveType(move.typeId!);
                final name = Text(move.label, style: theme.label);
                final pp = ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 80),
                  child: PlayerMenuBadge(
                    label: move.hasPpTracking
                        ? strings.ppValue(move.currentPp!, move.maxPp!)
                        : strings.ppUnavailable,
                  ),
                );
                final type = typeLabel == null || typeLabel.trim().isEmpty
                    ? null
                    : PlayerMenuBadge(
                        label: typeLabel, kind: PlayerMenuBadgeKind.type);
                if (constraints.maxWidth < 560 ||
                    MediaQuery.textScalerOf(context).scale(18) > 25.2) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      name,
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [if (type != null) type, pp],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    if (type != null) ...[type, const SizedBox(width: 12)],
                    Expanded(child: name),
                    const SizedBox(width: 12),
                    pp,
                  ],
                );
              }),
      ),
    );
  }
}
