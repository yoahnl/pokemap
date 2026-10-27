import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_menu_components.dart';
import '../foundation/player_paged_layout.dart';
import 'player_pokemon_image.dart';
import 'runtime_player_actions.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import '../theme/pokemap_player_pokemon_type_theme.dart';
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
    this.showHeader = true,
  });

  final RuntimePokemonSummarySnapshot summary;
  final ProjectPresentationSurfaceRole surfaceRole;
  final Widget? actions;
  final bool showHeader;

  @override
  Widget build(BuildContext context) => PlayerMenuThemeScope(
    role: surfaceRole,
    child: summary.isEgg ? Column(mainAxisSize: MainAxisSize.min, children: [PlayerPokemonImage(summary: summary), Text(summary.displayLabel), Text(Localizations.localeOf(context).languageCode == 'fr' ? 'Un Œuf confié à votre équipe.' : 'An Egg entrusted to your party.'), ?actions]) : _PlayerPokemonSummaryTabs(sheet: this),
  );

  Widget _hpBar(BuildContext context, PlayerPokemonSummaryStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              strings.hpValue(summary.currentHp, summary.maxHp),
              style: context.playerMenuTheme.actionLabel,
            ),
            const SizedBox(width: 4),
            Text(strings.hp, style: context.playerMenuTheme.actionLabel),
          ],
        ),
        const SizedBox(height: PlayerSpacing.xs),
        // The track must not read as a full bar: without an explicit neutral
        // background the theme painted a saturated green behind the fill, so a
        // Pokémon at 20/48 looked untouched. The fill now carries the same
        // threshold bands as the battle HUD.
        LinearProgressIndicator(
          value: summary.hpRatio,
          minHeight: 6,
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

  Widget _statsGrid(
    BuildContext context,
    PlayerPokemonSummaryStrings strings,
    RuntimePokemonStatsSummarySnapshot stats,
  ) {
    final theme = context.playerMenuTheme;
    final values = [
      (strings.hp, summary.maxHp),
      (strings.attack, stats.attack),
      (strings.defense, stats.defense),
      (strings.specialAttack, stats.specialAttack),
      (strings.specialDefense, stats.specialDefense),
      (strings.speed, stats.speed),
    ];
    final columns =
        MediaQuery.sizeOf(context).aspectRatio > 1 &&
            !PlayerCompanionScope.of(context)
        ? 3
        : 2;
    return Column(
      children: [
        for (var start = 0; start < values.length; start += columns)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (
                  var index = start;
                  index < math.min(start + columns, values.length);
                  index++
                ) ...[
                  if (index > start) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: theme.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              values[index].$1,
                              style: theme.actionLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${values[index].$2}',
                            style: theme.actionLabel.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
  var _selectedMove = 0;
  final _tabFocus = FocusNode(debugLabel: 'Pokemon summary tabs');
  late final _tabNodes = [
    _tabFocus,
    for (var i = 1; i < 4; i++) FocusNode(debugLabel: 'Pokemon summary tab $i'),
  ];
  var _tabDirection = 1;

  void _selectTab(int index) {
    setState(() {
      _tabDirection = index >= _tab ? 1 : -1;
      _tab = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabNodes[_tab].canRequestFocus)
        _tabNodes[_tab].requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabFocus.canRequestFocus) _tabFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final node in _tabNodes) {
      node.dispose();
    }
    super.dispose();
  }

  List<Widget> _rows(Widget child) => child is Column
      ? child.children
      : child is Wrap
      ? child.children
      : [child];

  List<Widget> _moveRows(
    BuildContext context,
    PlayerPokemonSummaryStrings strings, {
    bool wide = false,
  }) {
    final moves = widget.sheet.summary.moves;
    if (moves.isEmpty) return [Text(strings.none)];
    final selected = _selectedMove.clamp(0, moves.length - 1);
    final theme = context.playerMenuTheme;
    final move = moves[selected];
    String? typeLabel(RuntimePokemonMoveSummarySnapshot move) {
      final label = move.typeLabel?.trim();
      if (label != null && label.isNotEmpty) return label;
      final id = move.typeId?.trim();
      return id == null || id.isEmpty
          ? null
          : context.playerL10n.battleMoveType(id);
    }

    Widget card(int index) => TextButton(
      key: ValueKey('pokemon-summary-move-${moves[index].moveId}'),
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        backgroundColor: index == selected ? theme.selectionTop : theme.panel,
        foregroundColor: index == selected ? theme.selectionText : theme.text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: theme.border),
        ),
      ),
      onPressed: () => setState(() => _selectedMove = index),
      child: Row(
        children: [
          Expanded(
            child: Text(
              moves[index].label,
              style: theme.actionLabel.copyWith(
                color: index == selected ? theme.selectionText : theme.text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            moves[index].hasPpTracking
                ? strings.ppValue(moves[index].currentPp!, moves[index].maxPp!)
                : strings.ppUnavailable,
            style: theme.actionLabel.copyWith(
              color: index == selected ? theme.selectionText : theme.secondary,
            ),
          ),
        ],
      ),
    );
    final columns = wide ? 2 : 1;
    return [
      for (var start = 0; start < moves.length; start += columns)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (
              var index = start;
              index < math.min(start + columns, moves.length);
              index++
            ) ...[
              if (index > start) const SizedBox(width: 8),
              Expanded(child: card(index)),
            ],
          ],
        ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          key: const ValueKey('pokemon-summary-selected-move'),
          children: [
            Expanded(
              child: Text(
                [move.label, ?typeLabel(move)].join(' · '),
                style: theme.actionLabel,
              ),
            ),
            const SizedBox(width: 8),
            if (move.hasPpTracking)
              Text(
                strings.ppValue(move.currentPp!, move.maxPp!),
                style: theme.actionLabel,
              ),
          ],
        ),
      ),
    ];
  }

  String _typeLabel(String value) => value.isEmpty
      ? value
      : value[0].toUpperCase() + value.substring(1).toLowerCase();

  List<Widget> _summaryRows(
    BuildContext context,
    PlayerPokemonSummaryStrings strings, {
    required bool wide,
  }) {
    final sheet = widget.sheet;
    final summary = sheet.summary;
    final theme = context.playerMenuTheme;
    final provenance = summary.provenance;
    Widget fact(String label, String value) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.meta.copyWith(fontSize: wide ? 10 : 11, height: 1.3),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.body.copyWith(fontSize: wide ? 12 : 14, height: 1.35),
        ),
      ],
    );
    Widget line(String label, String value) => Container(
      padding: EdgeInsets.symmetric(vertical: wide ? 5 : 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.meta.copyWith(fontSize: wide ? 12 : 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.body.copyWith(fontSize: wide ? 12 : 14),
            ),
          ),
        ],
      ),
    );
    final types = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in summary.typeIds)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                PokeMapPlayerPokemonTypeTheme.color(type)
                    .withValues(alpha: .18),
                theme.panel,
              ),
              border: Border(
                left: BorderSide(
                  color: PokeMapPlayerPokemonTypeTheme.color(type),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              _typeLabel(context.playerL10n.battleMoveType(type)),
              style: theme.actionLabel.copyWith(
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: theme.text,
              ),
            ),
          ),
      ],
    );
    final overview = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary.typeIds.isNotEmpty) types,
        SizedBox(height: wide ? 8 : 16),
        sheet._hpBar(context, strings),
        SizedBox(height: wide ? 8 : 16),
        line(strings.heldItem, summary.heldItemLabel ?? strings.none),
        line(strings.ability, summary.abilityLabel),
      ],
    );
    final facts = [
      fact(strings.nature, summary.natureLabel),
      if (provenance != null) fact(strings.origin, provenance.originLabel),
      if (provenance != null)
        fact(
          strings.metLocation,
          provenance.metMapLabel ?? provenance.originLabel,
        ),
    ];
    final extra = <(String, String)>[
      (strings.species, summary.speciesLabel),
      if (summary.formLabel case final value?) (strings.form, value),
      if (summary.experience case final value?) (strings.experience, '$value'),
      if (summary.genderLabel case final value?) (strings.gender, value),
      (strings.friendship, strings.friendshipValue(summary.friendship)),
      if (provenance?.metSourceLabel case final value?)
        (strings.metSource, value),
      if (provenance?.metLevel case final value?) (strings.metLevel, '$value'),
      if (provenance?.ballLabel case final value?) (strings.captureBall, value),
    ];
    final image = PlayerPokemonImage(
      summary: summary,
      width: wide ? 112 : 160,
      height: wide ? 124 : 160,
    );
    return [
      if (wide)
        Row(
          key: const ValueKey('pokemon-summary-overview'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            image,
            const SizedBox(width: 12),
            Expanded(child: overview),
            const SizedBox(width: 16),
            Container(
              width: PlayerCompanionScope.of(context) ? 128 : 150,
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: theme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < facts.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    facts[i],
                  ],
                ],
              ),
            ),
          ],
        )
      else ...[
        Center(key: const ValueKey('pokemon-summary-overview'), child: image),
        overview,
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final entry in facts)
                  SizedBox(
                    width: (constraints.maxWidth - 16) / 2,
                    child: entry,
                  ),
              ],
            ),
          ),
        ),
      ],
      if (summary.isShiny) Text(strings.shiny, style: theme.meta),
      for (var start = 0; start < extra.length; start += 2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: fact(extra[start].$1, extra[start].$2)),
            const SizedBox(width: 16),
            Expanded(
              child: start + 1 < extra.length
                  ? fact(extra[start + 1].$1, extra[start + 1].$2)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
    ];
  }

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
    return RuntimePlayerTabActions(
      resetToken: _tab,
      onPreviousTab: () => _selectTab((_tab - 1) % tabs.length),
      onNextTab: () => _selectTab((_tab + 1) % tabs.length),
      child: Padding(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final rows = switch (_tab) {
              1 => _moveRows(
                context,
                strings,
                wide:
                    constraints.maxWidth >= 450 ||
                    PlayerCompanionScope.of(context),
              ),
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
              _ => _summaryRows(
                context,
                strings,
                wide:
                    MediaQuery.sizeOf(context).aspectRatio > 1 ||
                    PlayerCompanionScope.of(context),
              ),
            };
            final bounded = constraints.hasBoundedHeight;
            final body = PlayerMenuDetailTransition(
              contentKey: ValueKey('pokemon-summary-content-$_tab'),
              direction: _tabDirection,
              child: PlayerPagedList(
                key: ValueKey('pokemon-summary-content-$_tab'),
                sideNavigation: bounded && constraints.maxHeight < 300,
                children: rows,
              ),
            );
            final theme = context.playerMenuTheme;
            final tabStyle = theme.actionLabel.copyWith(
              fontSize: 14,
              height: 1.2,
            );
            final textScaler = MediaQuery.textScalerOf(context);
            final widestTab = tabs
                .map((label) {
                  final painter = TextPainter(
                    text: TextSpan(text: label, style: tabStyle),
                    textDirection: Directionality.of(context),
                    textScaler: textScaler,
                  )..layout();
                  return painter.width;
                })
                .reduce(math.max);
            final tabColumns = (constraints.maxWidth - 24) / 4 >= widestTab + 8
                ? 4
                : 2;
            Widget tab(int i) => PlayerMenuSelectableRow(
              key: ValueKey('pokemon-summary-tab-${ids[i]}'),
              id: 'pokemon-summary-tab-${ids[i]}',
              label: tabs[i],
              selected: _tab == i,
              focusNode: _tabNodes[i],
              tab: true,
              reserveFocusMarker: false,
              showLabel: false,
              labelStyle: tabStyle,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 8,
              ),
              supportingContent: Center(
                child: Text(
                  tabs[i],
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                ),
              ),
              onPressed: () => _selectTab(i),
            );
            final tabsBar = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (
                  var start = 0;
                  start < tabs.length;
                  start += tabColumns
                ) ...[
                  if (start > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      for (
                        var i = start;
                        i < math.min(start + tabColumns, tabs.length);
                        i++
                      ) ...[
                        if (i > start) const SizedBox(width: 8),
                        Expanded(child: tab(i)),
                      ],
                    ],
                  ),
                ],
              ],
            );
            final header = Row(
              children: [
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              summary.speciesLabel,
                              style: context.playerMenuTheme.actionLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.levelValue(summary.level),
                            style: context.playerMenuTheme.actionLabel,
                          ),
                        ],
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
            return Column(
              mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sheet.showHeader &&
                    (!bounded || constraints.maxHeight >= 360)) ...[
                  header,
                  const SizedBox(height: 12),
                ],
                if (bounded) Expanded(child: content) else content,
              ],
            );
          },
        ),
      ),
    );
  }
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
