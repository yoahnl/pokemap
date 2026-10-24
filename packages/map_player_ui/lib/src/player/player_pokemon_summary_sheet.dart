import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import 'player_pokemon_image.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_hp_tone.dart';
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
    this.actions,
  });

  final RuntimePokemonSummarySnapshot summary;
  final ProjectPresentationSurfaceRole surfaceRole;
  final Widget? actions;

  @override
  Widget build(BuildContext context) => PlayerMenuThemeScope(
    role: surfaceRole,
    child: _PlayerPokemonSummaryTabs(sheet: this),
  );

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
        // The track must not read as a full bar: without an explicit neutral
        // background the theme painted a saturated green behind the fill, so a
        // Pokémon at 20/48 looked untouched. The fill now carries the same
        // threshold bands as the battle HUD.
        LinearProgressIndicator(
          value: summary.hpRatio,
          color: playerHpColorFor(context, summary.hpRatio),
          backgroundColor: context.playerColors.outline.withValues(alpha: 0.35),
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
      return Text(strings.none, style: Theme.of(context).textTheme.bodyMedium);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final move in summary.moves)
          // The snapshot carries the move type and nobody rendered it: the
          // sheet dropped a canonical field while its test claimed every one
          // reached the screen.
          _SummaryLine(
            key: ValueKey<String>('pokemon-summary-move-${move.moveId}'),
            label: (move.typeLabel?.trim() ?? '').isEmpty
                ? move.label
                : '${move.label} · ${move.typeLabel}',
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
}

class _PlayerPokemonSummaryTabs extends StatefulWidget {
  const _PlayerPokemonSummaryTabs({required this.sheet});
  final PlayerPokemonSummarySheet sheet;

  @override
  State<_PlayerPokemonSummaryTabs> createState() =>
      _PlayerPokemonSummaryTabsState();
}

class _PlayerPokemonSummaryTabsState extends State<_PlayerPokemonSummaryTabs> {
  var _tab = 0;

  List<Widget> _rows(Widget child) => child is Column
      ? child.children
      : child is Wrap
      ? child.children
      : [child];

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final summary = sheet.summary;
    final strings = PlayerPokemonSummaryStrings.of(context);
    final french = Localizations.localeOf(context).languageCode == 'fr';
    final tabs = french
        ? ['Résumé', 'Capacités', 'Stats', 'Actions']
        : ['Summary', 'Moves', 'Stats', 'Actions'];
    final ids = ['summary', 'moves', 'stats', 'actions'];
    final rows = switch (_tab) {
      1 => _rows(sheet._moves(context, strings)),
      2 =>
        summary.stats == null
            ? <Widget>[Text(strings.none)]
            : _rows(sheet._statsGrid(context, strings, summary.stats!)),
      3 =>
        sheet.actions == null
            ? <Widget>[
                Text(
                  '${strings.heldItem} : ${summary.heldItemLabel ?? strings.none}',
                ),
              ]
            : _rows(sheet.actions!),
      _ => <Widget>[
        _SummaryLine(
          label: french ? 'Nom' : 'Name',
          value: summary.displayLabel,
        ),
        if (summary.isShiny) Text(strings.shiny),
        sheet._hpBar(context, strings),
        ..._rows(sheet._identity(context, strings)),
        if (summary.provenance case final provenance?)
          ..._rows(sheet._provenance(context, strings, provenance)),
      ],
    };
    return PlayerPanel(
      surfaceRole: sheet.surfaceRole,
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.hasBoundedHeight;
          final body = PlayerMenuDetailTransition(
            contentKey: ValueKey('pokemon-summary-content-$_tab'),
            child: PlayerPagedList(
              key: ValueKey('pokemon-summary-content-$_tab'),
              sideNavigation: bounded && constraints.maxHeight < 300,
              children: rows,
            ),
          );
          final compactTabs =
              constraints.maxHeight < 320 ||
              constraints.maxWidth < 500 &&
                  MediaQuery.textScalerOf(context).scale(1) >= 1.5;
          final tabsBar = Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    selected: _tab == i,
                    child: TextButton(
                      key: ValueKey('pokemon-summary-tab-${ids[i]}'),
                      autofocus: i == 0,
                      onPressed: () => setState(() => _tab = i),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        animationDuration:
                            context.playerMenuTheme.selectionDuration,
                        backgroundColor: _tab == i
                            ? context.playerMenuTheme.accent.withValues(
                                alpha: .14,
                              )
                            : context.playerMenuTheme.base.withValues(alpha: 0),
                        foregroundColor: _tab == i
                            ? context.playerMenuTheme.text
                            : context.playerMenuTheme.secondary,
                        side: BorderSide(
                          width: 1.5,
                          color: _tab == i
                              ? context.playerMenuTheme.focus
                              : context.playerMenuTheme.border.withValues(
                                  alpha: .3,
                                ),
                        ),
                      ),
                      child: compactTabs
                          ? Tooltip(
                              message: tabs[i],
                              child: Icon(
                                [
                                  Icons.info_outline,
                                  Icons.bolt,
                                  Icons.bar_chart,
                                  Icons.more_horiz,
                                ][i],
                                semanticLabel: tabs[i],
                              ),
                            )
                          : Text(tabs[i], textAlign: TextAlign.center),
                    ),
                  ),
                ),
              ],
            ],
          );
          final header = Row(
            children: [
              PlayerPokemonImage(
                summary: summary,
                thumbnail: true,
                width: 48,
                height: 48,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      strings.levelValue(summary.level),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          );
          final content = Column(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tabsBar,
              const SizedBox(height: 8),
              if (bounded) Expanded(child: body) else body,
            ],
          );
          if (bounded &&
              constraints.maxHeight < 300 &&
              constraints.maxWidth >= 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: constraints.maxWidth * .28, child: header),
                const SizedBox(width: 16),
                Expanded(child: content),
              ],
            );
          }
          return Column(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 8),
              if (bounded) Expanded(child: content) else content,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = Theme.of(context).textTheme.bodyMedium;
      final labelSize = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final labelWidth = math.min(labelSize.width, constraints.maxWidth * .8);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(label, style: style),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(value, textAlign: TextAlign.end, style: style),
            ),
          ],
        ),
      );
    },
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
  final locale = Localizations.localeOf(context);
  final mediaQuery = MediaQuery.of(context);
  final opaque =
      context
          .dependOnInheritedWidgetOfExactType<PlayerMenuThemeScope>()
          ?.opaque ??
      false;
  return showDialog<void>(
    context: context,
    builder: (context) {
      final availableHeight = mediaQuery.size.height - 32;
      return Localizations.override(
        context: context,
        locale: locale,
        delegates: PokeMapPlayerLocalizations.localizationsDelegates,
        child: MediaQuery(
          data: mediaQuery,
          child: PlayerMenuThemeScope(
            role: surfaceRole,
            opaque: opaque,
            child: Dialog(
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
                        child: PlayerPokemonSummarySheet(
                          summary: summary,
                          surfaceRole: surfaceRole,
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
            ),
          ),
        ),
      );
    },
  );
}
