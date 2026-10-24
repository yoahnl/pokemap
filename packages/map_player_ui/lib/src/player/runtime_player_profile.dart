import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_menu_components.dart';
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
        final compact =
            constraints.maxWidth < 600 ||
            constraints.maxHeight < 300 ||
            MediaQuery.textScalerOf(context).scale(1) >= 1.8;
        final portraitHeight = (constraints.maxHeight - (compact ? 64 : 112))
            .clamp(
              32.0,
              compact || constraints.maxWidth < 1024 ? 144.0 : 288.0,
            );
        final identity = _identityItems(portraitHeight);
        final progression = _progressionItems(
          compact
              ? constraints.maxWidth
              : (constraints.maxWidth - 24) * 856 / 1272 - 48,
        );
        return SizedBox.expand(
          key: const ValueKey('runtime-player-detail-profile'),
          child: compact
              ? PlayerPagedList(
                  key: const ValueKey('profile-body-pages'),
                  children: [...identity, ...progression],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 416,
                      child: PlayerMenuPanel(
                        key: const ValueKey('profile-identity'),
                        child: PlayerPagedList(children: identity),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 856,
                      child: PlayerMenuPanel(
                        key: const ValueKey('profile-progression'),
                        child: PlayerPagedList(children: progression),
                      ),
                    ),
                  ],
                ),
        );
      },
    ),
  );

  List<Widget> _identityItems(double portraitHeight) {
    final profile = widget.profile;
    final theme = context.playerMenuTheme;
    final location = profile.locationName?.trim();
    final name = profile.playerName.characters.take(40).toString();
    return [
      Center(
        child: SizedBox(
          key: const ValueKey('profile-portrait'),
          width: portraitHeight < 256 ? portraitHeight : 256,
          height: portraitHeight,
          child: PlayerMenuPortrait(
            semanticLabel: _text('Portrait de $name', '$name’s portrait'),
            child: _portrait(),
          ),
        ),
      ),
      Semantics(
        header: true,
        label: profile.playerName,
        excludeSemantics: true,
        child: Text(
          name,
          key: const ValueKey('profile-name'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.title,
        ),
      ),
      if (location != null && location.isNotEmpty)
        Text(
          location,
          key: const ValueKey('profile-location'),
          style: theme.body.copyWith(color: theme.secondary),
        ),
    ];
  }

  Widget _portrait() {
    final profile = widget.profile;
    final path = profile.portraitFilePath;
    final fallback = Icon(
      Icons.person_outline_rounded,
      key: const ValueKey('profile-portrait-fallback'),
      size: 144,
      color: context.playerMenuTheme.secondary,
    );
    if (path == null || path.trim().isEmpty) return fallback;
    return PlayerFileImage(
      key: ValueKey(
        'profile-portrait-source-${profile.avatarCharacterId}:$path',
      ),
      path: path,
      width: 256,
      height: 288,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      fallback: fallback,
    );
  }

  List<Widget> _progressionItems(double width) {
    final profile = widget.profile;
    final l10n = context.playerL10n;
    final theme = context.playerMenuTheme;
    final material = MaterialLocalizations.of(context);
    final currency = profile.currencyLabel?.trim();
    final seconds = profile.playtimeSeconds;
    final pokedex = profile.pokedex;
    final badgeCount = material.formatDecimal(profile.badgeIds.length);
    final total = profile.badgeTotal;
    final statistics = <({String id, String label, String value})>[
      if (seconds != null)
        (
          id: 'playtime',
          label: l10n.playTime,
          value:
              '${seconds ~/ 3600}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}',
        ),
      (
        id: 'money',
        label: _text('Argent', 'Money'),
        value: [
          material.formatDecimal(profile.money),
          if (currency != null && currency.isNotEmpty) currency,
        ].join(' '),
      ),
      (
        id: 'badges',
        label: l10n.badges,
        value: total == null
            ? badgeCount
            : '$badgeCount / ${material.formatDecimal(total)}',
      ),
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
        (
          id: 'pokedex-total',
          label: _text('Total du Pokédex', 'Pokédex total'),
          value: material.formatDecimal(pokedex.total),
        ),
      ],
    ];
    final badgeColumns = (width / 96).floor().clamp(1, 100);
    return [
      Semantics(
        header: true,
        child: Text(_text('Progression', 'Progress'), style: theme.title),
      ),
      for (final statistic in statistics)
        _statistics([statistic], stacked: false),
      if (profile.badges.isNotEmpty) ...[
        Semantics(
          header: true,
          child: Text(
            _text('Badges obtenus', 'Earned badges'),
            style: theme.subtitle,
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
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final badge in profile.badges.skip(start).take(badgeColumns))
                _badge(badge),
            ],
          ),
      ],
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
              padding: const EdgeInsets.only(bottom: 20),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          statistic.label,
                          style: theme.body.copyWith(color: theme.secondary),
                        ),
                        const SizedBox(height: 4),
                        Text(statistic.value, style: theme.numbers),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            statistic.label,
                            style: theme.body.copyWith(color: theme.secondary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            statistic.value,
                            textAlign: TextAlign.right,
                            style: theme.numbers,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }

  Widget _badge(RuntimePlayerProfileBadgeSnapshot badge) {
    final path = badge.iconFilePath;
    final fallback = Icon(
      Icons.workspace_premium_outlined,
      size: 48,
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
          width: 80,
          height: 80,
          child: Center(
            child: SizedBox(
              key: ValueKey('profile-badge-image-${badge.id}'),
              width: 64,
              height: 64,
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
