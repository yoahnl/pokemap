import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_pokemon_summary_strings.dart';

/// Fiche Pokémon unique de l'Équipe et du PC.
///
/// Les deux surfaces rendaient leur propre projection, avec des libellés
/// divergents pour le même individu. Le seul rendu vit ici et consomme le
/// snapshot canonique produit par le runtime.
class PlayerPokemonSummarySheet extends StatelessWidget {
  const PlayerPokemonSummarySheet({
    super.key,
    required this.summary,
    this.surfaceRole = ProjectPresentationSurfaceRole.party,
  });

  final RuntimePokemonSummarySnapshot summary;
  final ProjectPresentationSurfaceRole surfaceRole;

  @override
  Widget build(BuildContext context) {
    final strings = PlayerPokemonSummaryStrings.of(context);
    return PlayerPanel(
      surfaceRole: surfaceRole,
      child: Semantics(
        container: true,
        label: summary.displayLabel,
        value: strings.hpValue(summary.currentHp, summary.maxHp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _header(context, strings),
            const SizedBox(height: PlayerSpacing.sm),
            _hpBar(context, strings),
            const SizedBox(height: PlayerSpacing.md),
            _identity(context, strings),
            if (summary.stats case final stats?) ...<Widget>[
              const SizedBox(height: PlayerSpacing.md),
              _sectionTitle(context, strings.stats),
              _statsGrid(context, strings, stats),
            ],
            const SizedBox(height: PlayerSpacing.md),
            _sectionTitle(context, strings.moves),
            _moves(context, strings),
            if (summary.provenance case final provenance?) ...<Widget>[
              const SizedBox(height: PlayerSpacing.md),
              _sectionTitle(context, strings.provenance),
              _provenance(context, strings, provenance),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, PlayerPokemonSummaryStrings strings) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                summary.displayLabel,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (summary.nickname.isNotEmpty)
                Text(
                  summary.speciesLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        const SizedBox(width: PlayerSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              strings.levelValue(summary.level),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (summary.isShiny)
              PlayerBadge(
                label: strings.shiny,
                icon: Icons.auto_awesome,
                tone: PlayerBadgeTone.warning,
              ),
          ],
        ),
      ],
    );
  }

  Widget _hpBar(BuildContext context, PlayerPokemonSummaryStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                strings.hp,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            Text(
              strings.hpValue(summary.currentHp, summary.maxHp),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: PlayerSpacing.xs),
        LinearProgressIndicator(
          value: summary.hpRatio,
          color: summary.isFainted ? context.playerColors.danger : null,
        ),
        if (summary.statusLabel case final status?) ...<Widget>[
          const SizedBox(height: PlayerSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: PlayerBadge(
              label: status,
              icon: Icons.healing_outlined,
              tone: PlayerBadgeTone.danger,
            ),
          ),
        ],
      ],
    );
  }

  Widget _identity(BuildContext context, PlayerPokemonSummaryStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SummaryLine(label: strings.species, value: summary.speciesLabel),
        if (summary.formLabel case final form?)
          _SummaryLine(label: strings.form, value: form),
        if (summary.experience case final experience?)
          _SummaryLine(label: strings.experience, value: '$experience'),
        _SummaryLine(label: strings.nature, value: summary.natureLabel),
        _SummaryLine(label: strings.ability, value: summary.abilityLabel),
        if (summary.genderLabel case final gender?)
          _SummaryLine(label: strings.gender, value: gender),
        _SummaryLine(
          label: strings.heldItem,
          value: summary.heldItemLabel ?? strings.none,
        ),
        _SummaryLine(
          label: strings.friendship,
          value: strings.friendshipValue(summary.friendship),
        ),
      ],
    );
  }

  Widget _statsGrid(
    BuildContext context,
    PlayerPokemonSummaryStrings strings,
    RuntimePokemonStatsSummarySnapshot stats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SummaryLine(label: strings.attack, value: '${stats.attack}'),
        _SummaryLine(label: strings.defense, value: '${stats.defense}'),
        _SummaryLine(
          label: strings.specialAttack,
          value: '${stats.specialAttack}',
        ),
        _SummaryLine(
          label: strings.specialDefense,
          value: '${stats.specialDefense}',
        ),
        _SummaryLine(label: strings.speed, value: '${stats.speed}'),
      ],
    );
  }

  Widget _moves(BuildContext context, PlayerPokemonSummaryStrings strings) {
    if (summary.moves.isEmpty) {
      return Text(
        strings.none,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final move in summary.moves)
          _SummaryLine(
            key: ValueKey<String>('pokemon-summary-move-${move.moveId}'),
            label: move.label,
            value: move.hasPpTracking
                ? strings.ppValue(move.currentPp!, move.maxPp!)
                : strings.ppUnavailable,
          ),
      ],
    );
  }

  Widget _provenance(
    BuildContext context,
    PlayerPokemonSummaryStrings strings,
    RuntimePokemonProvenanceSummarySnapshot provenance,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SummaryLine(label: strings.origin, value: provenance.originLabel),
        if (provenance.metMapLabel case final map?)
          _SummaryLine(label: strings.metLocation, value: map),
        if (provenance.metSourceLabel case final source?)
          _SummaryLine(label: strings.metSource, value: source),
        if (provenance.metLevel case final metLevel?)
          _SummaryLine(label: strings.metLevel, value: '$metLevel'),
        if (provenance.ballLabel case final ball?)
          _SummaryLine(label: strings.captureBall, value: ball),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: PlayerSpacing.xs),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: PlayerSpacing.xs / 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: PlayerSpacing.xs),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
}

/// Ouvre la fiche partagée dans le même cadre depuis l'Équipe et le PC.
Future<void> showPlayerPokemonSummaryDialog(
  BuildContext context, {
  required RuntimePokemonSummarySnapshot summary,
  ProjectPresentationSurfaceRole surfaceRole =
      ProjectPresentationSurfaceRole.party,
}) {
  final strings = PlayerPokemonSummaryStrings.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) {
      final availableHeight = MediaQuery.sizeOf(context).height - 32;
      return Dialog(
        insetPadding: const EdgeInsets.all(PlayerSpacing.md),
        child: SizedBox(
          width: 520,
          height: availableHeight.clamp(240, 640).toDouble(),
          child: PlayerPanel(
            elevated: true,
            padding: const EdgeInsets.all(PlayerSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    child: PlayerPokemonSummarySheet(
                      summary: summary,
                      surfaceRole: surfaceRole,
                    ),
                  ),
                ),
                const SizedBox(height: PlayerSpacing.md),
                PlayerActionButton(
                  key: const ValueKey<String>('pokemon-summary-close'),
                  label: strings.close,
                  icon: Icons.close,
                  autofocus: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
