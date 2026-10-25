import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_menu_components.dart';
import '../foundation/player_input_scope.dart';
import '../foundation/player_paged_layout.dart';
import '../foundation/player_image.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';

class RuntimePlayerProfile extends StatefulWidget {
  const RuntimePlayerProfile({super.key, required this.profile});

  final RuntimePlayerProfileSnapshot profile;

  @override
  State<RuntimePlayerProfile> createState() => _RuntimePlayerProfileState();
}

class _RuntimePlayerProfileState extends State<RuntimePlayerProfile> {
  final _focusNode = FocusNode(debugLabel: 'Player profile');
  (double, double, double, bool)? _panelLayout;
  double? _identityHeight;
  double? _progressionHeight;

  bool get _french => Localizations.localeOf(context).languageCode == 'fr';
  String _text(String french, String english) => _french ? french : english;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ModalRoute.of(context)?.isCurrent != false) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focusNode,
    onFocusChange: (_) => setState(() {}),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final companion = PlayerCompanionScope.of(context);
        final wide = MediaQuery.sizeOf(context).aspectRatio > 1 || companion;
        final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.8;
        final gap = companion ? 8.0 : 16.0;
        final portraitHeight = wide ? 56.0 : 80.0;
        final columnWidth = wide
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        final boundedColumns = wide && !largeText;
        final layout = (
          columnWidth,
          constraints.maxHeight,
          MediaQuery.textScalerOf(context).scale(1),
          companion,
        );
        if (_panelLayout != layout) {
          _panelLayout = layout;
          _identityHeight = null;
          _progressionHeight = null;
        }
        final padding = companion ? 8.0 : 12.0;
        Widget panel({
          required String id,
          required List<Widget> children,
          required double? contentHeight,
          required ValueChanged<double> onMeasured,
        }) {
          final child = PlayerMenuPanel(
            key: ValueKey(id),
            padding: EdgeInsets.all(padding),
            child: PlayerPagedList(
              onContentHeightChanged: boundedColumns ? onMeasured : null,
              children: children,
            ),
          );
          return boundedColumns
              ? SizedBox(
                  height: contentHeight == null
                      ? constraints.maxHeight
                      : (contentHeight + padding * 2)
                            .clamp(0, constraints.maxHeight)
                            .toDouble(),
                  child: child,
                )
              : child;
        }

        final identity = panel(
          id: 'profile-identity',
          children: _identityItems(portraitHeight),
          contentHeight: _identityHeight,
          onMeasured: (height) {
            if (_identityHeight != height) {
              setState(() => _identityHeight = height);
            }
          },
        );
        final progression = panel(
          id: 'profile-progression',
          children: _progressionItems(columnWidth - padding * 2),
          contentHeight: _progressionHeight,
          onMeasured: (height) {
            if (_progressionHeight != height) {
              setState(() => _progressionHeight = height);
            }
          },
        );
        return SizedBox.expand(
          key: const ValueKey('runtime-player-detail-profile'),
          child: boundedColumns
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: identity),
                    SizedBox(width: gap),
                    Expanded(child: progression),
                  ],
                )
              : PlayerPagedList(
                  key: const ValueKey('profile-body-pages'),
                  children: [identity, progression],
                ),
        );
      },
    ),
  );

  List<Widget> _identityItems(double portraitHeight) {
    final profile = widget.profile;
    final theme = context.playerMenuTheme;
    final name = profile.playerName.characters.take(40).toString();
    final companion = PlayerCompanionScope.of(context);
    final material = MaterialLocalizations.of(context);
    final currency = profile.currencyLabel?.trim();
    final seconds = profile.playtimeSeconds;
    return [
      Text(
        _text('CARTE DE JOUEUR', 'PLAYER CARD'),
        style: theme.meta.copyWith(fontSize: 10),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              label: profile.playerName,
              excludeSemantics: true,
              child: Text(
                name,
                key: const ValueKey('profile-name'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.title.copyWith(
                  fontSize: companion ? 22 : 26,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            key: const ValueKey('profile-portrait'),
            width: portraitHeight,
            height: portraitHeight,
            child: PlayerMenuPortrait(
              circular: true,
              semanticLabel: _text('Portrait de $name', '$name’s portrait'),
              child: _portrait(),
            ),
          ),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (seconds != null) ...[
            Expanded(
              child: _statistics([
                (
                  id: 'playtime',
                  label: context.playerL10n.playTime,
                  value:
                      '${seconds ~/ 3600}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}',
                ),
              ], stacked: true),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: _statistics([
              (
                id: 'money',
                label: _text('Argent', 'Money'),
                value: [
                  material.formatDecimal(profile.money),
                  if (currency != null && currency.isNotEmpty) currency,
                ].join(' '),
              ),
            ], stacked: true),
          ),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _statistics([
              (
                id: 'badges',
                label: context.playerL10n.badges,
                value: profile.badgeTotal == null
                    ? material.formatDecimal(profile.badgeIds.length)
                    : '${material.formatDecimal(profile.badgeIds.length)} / ${material.formatDecimal(profile.badgeTotal!)}',
              ),
            ], stacked: true),
          ),
          if (profile.pokedex case final pokedex?) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _statistics([
                (
                  id: 'pokedex-total',
                  label: _text('Total du Pokédex', 'Pokédex total'),
                  value: material.formatDecimal(pokedex.total),
                ),
              ], stacked: true),
            ),
          ],
        ],
      ),
    ];
  }

  Widget _portrait() {
    final profile = widget.profile;
    final path = profile.portraitFilePath;
    final fallback = Icon(
      Icons.person_outline_rounded,
      key: const ValueKey('profile-portrait-fallback'),
      size: 48,
      color: context.playerMenuTheme.secondary,
    );
    if (path == null || path.trim().isEmpty) return fallback;
    return PlayerFileImage(
      key: ValueKey(
        'profile-portrait-source-${profile.avatarCharacterId}:$path',
      ),
      path: path,
      width: 80,
      height: 80,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      fallback: fallback,
    );
  }

  List<Widget> _progressionItems(double width) {
    final profile = widget.profile;
    final theme = context.playerMenuTheme;
    final material = MaterialLocalizations.of(context);
    final pokedex = profile.pokedex;
    final statistics = <({String id, String label, String value})>[
      if (pokedex != null) ...[
        (
          id: 'pokedex-seen',
          label: _text('Pokémon vus', 'Pokémon seen'),
          value: material.formatDecimal(pokedex.seen),
        ),
        (
          id: 'pokedex-caught',
          label: _text('Pokémon capturés', 'Pokémon caught'),
          value: material.formatDecimal(pokedex.caught),
        ),
      ],
    ];
    final companion = PlayerCompanionScope.of(context);
    final badgeSize = companion ? 24.0 : 32.0;
    final badgeColumns = companion
        ? 4
        : ((width + 8) / (badgeSize + 8)).floor().clamp(1, 100);
    return [
      Semantics(
        header: true,
        child: Text(
          _text('Progression', 'Progress'),
          style: theme.meta.copyWith(fontSize: 10),
        ),
      ),
      for (final statistic in statistics)
        _statistics([statistic], stacked: false),
      if (profile.badges.isNotEmpty) ...[
        Semantics(
          header: true,
          child: Text(
            _text('Badges obtenus', 'Earned badges'),
            style: theme.meta.copyWith(fontSize: 10),
          ),
        ),
        for (
          var start = 0;
          start < profile.badges.length;
          start += badgeColumns
        )
          Wrap(
            key: ValueKey(
              start == 0 ? 'profile-earned-badges' : 'profile-badge-row-$start',
            ),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final badge in profile.badges.skip(start).take(badgeColumns))
                _badge(badge, size: badgeSize),
            ],
          ),
      ],
      if (profile.locationName?.trim() case final location?
          when location.isNotEmpty)
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: theme.border)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _text('Lieu actuel', 'Current location'),
                  style: theme.meta.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  location,
                  key: const ValueKey('profile-location'),
                  textAlign: TextAlign.end,
                  style: theme.body.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _statistics(
    List<({String id, String label, String value})> statistics, {
    required bool stacked,
  }) {
    final theme = context.playerMenuTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final statistic in statistics)
          Semantics(
            key: ValueKey('profile-stat-${statistic.id}'),
            label: statistic.label,
            value: statistic.value,
            excludeSemantics: true,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: stacked ? 0 : 6),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          statistic.label,
                          style: theme.meta.copyWith(
                            color: theme.secondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statistic.value,
                          style: theme.numbers.copyWith(
                            fontSize: PlayerCompanionScope.of(context)
                                ? 15
                                : 17,
                            height: 1.2,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            statistic.label,
                            style: theme.meta.copyWith(
                              color: theme.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            statistic.value,
                            textAlign: TextAlign.right,
                            style: theme.numbers.copyWith(
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _badge(
    RuntimePlayerProfileBadgeSnapshot badge, {
    required double size,
  }) {
    final path = badge.iconFilePath;
    final fallback = Icon(
      Icons.workspace_premium_outlined,
      size: size * .75,
      color: context.playerMenuTheme.secondary,
    );
    return Semantics(
      key: ValueKey('profile-badge-${badge.id}'),
      image: true,
      label: badge.label,
      excludeSemantics: true,
      child: Tooltip(
        message: badge.label,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SizedBox(
              key: ValueKey('profile-badge-image-${badge.id}'),
              width: size * .75,
              height: size * .75,
              child: path == null || path.trim().isEmpty
                  ? fallback
                  : PlayerFileImage(
                      key: ValueKey('profile-badge-source-${badge.id}:$path'),
                      path: path,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                      fallback: fallback,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
