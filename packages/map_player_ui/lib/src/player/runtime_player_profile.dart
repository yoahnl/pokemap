import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_menu_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_menu_theme.dart';
import 'runtime_player_actions.dart';

class RuntimePlayerProfile extends StatefulWidget {
  const RuntimePlayerProfile({super.key, required this.profile});

  final RuntimePlayerProfileSnapshot profile;

  @override
  State<RuntimePlayerProfile> createState() => _RuntimePlayerProfileState();
}

class _RuntimePlayerProfileState extends State<RuntimePlayerProfile> {
  final _scrollController = ScrollController();
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
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _scroll(double amount, {bool absolute = false}) {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    final target = (absolute ? amount : position.pixels + amount)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < 0.5) return false;
    _scrollController.jumpTo(target);
    return true;
  }

  Object? _input(RuntimePlayerLogicalIntent intent) {
    if (intent.action == PlayerInputAction.down && _scroll(96) ||
        intent.action == PlayerInputAction.up && _scroll(-96)) {
      return null;
    }
    return Actions.maybeInvoke(context, intent);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final page = _scrollController.hasClients
        ? _scrollController.position.viewportDimension * .8
        : 0.0;
    final moved = switch (event.logicalKey) {
      LogicalKeyboardKey.pageDown => _scroll(page),
      LogicalKeyboardKey.pageUp => _scroll(-page),
      LogicalKeyboardKey.home => _scroll(0, absolute: true),
      LogicalKeyboardKey.end => _scroll(double.infinity, absolute: true),
      _ => false,
    };
    return moved ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Actions(
        actions: {
          RuntimePlayerLogicalIntent:
              CallbackAction<RuntimePlayerLogicalIntent>(onInvoke: _input),
        },
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _key,
          onFocusChange: (_) => setState(() {}),
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 1024 ||
                MediaQuery.textScalerOf(context).scale(1) >= 1.8;
            final minimumHeight = !compact && constraints.hasBoundedHeight
                ? constraints.maxHeight
                : 0.0;
            return KeyedSubtree(
              key: const ValueKey('runtime-player-detail-profile'),
              child: SingleChildScrollView(
                key: const ValueKey('profile-body-scroll'),
                controller: _scrollController,
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _identity(compact, minimumHeight),
                          const SizedBox(height: 24),
                          _progression(minimumHeight),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 416,
                              child: _identity(compact, minimumHeight)),
                          const SizedBox(width: 24),
                          Expanded(
                              flex: 856, child: _progression(minimumHeight)),
                        ],
                      ),
              ),
            );
          }),
        ),
      );

  Widget _identity(bool compact, double minimumHeight) {
    final profile = widget.profile;
    final theme = context.playerMenuTheme;
    final location = profile.locationName?.trim();
    final name = profile.playerName.characters.take(40).toString();
    return PlayerMenuPanel(
      key: const ValueKey('profile-identity'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minHeight: (minimumHeight - 48).clamp(0, double.infinity)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: SizedBox(
                key: const ValueKey('profile-portrait'),
                width: compact ? 144 : 256,
                height: compact ? 144 : 288,
                child: PlayerMenuPortrait(
                  semanticLabel: _text('Portrait de $name', '$name’s portrait'),
                  child: _portrait(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              label: profile.playerName,
              excludeSemantics: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    border: _focusNode.hasFocus
                        ? Border(
                            bottom: BorderSide(color: theme.focus, width: 2))
                        : null),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(name,
                      key: const ValueKey('profile-name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.title),
                ),
              ),
            ),
            if (location != null && location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(location,
                  key: const ValueKey('profile-location'),
                  style: theme.body.copyWith(color: theme.secondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _portrait() {
    final profile = widget.profile;
    final path = profile.portraitFilePath;
    final fallback = Icon(Icons.person_outline_rounded,
        key: const ValueKey('profile-portrait-fallback'),
        size: 144,
        color: context.playerMenuTheme.secondary);
    if (path == null || path.trim().isEmpty) return fallback;
    return Image(
      key: ValueKey(
          'profile-portrait-source-${profile.avatarCharacterId}:$path'),
      image: FileImage(File(path)),
      width: 256,
      height: 288,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      frameBuilder: (_, child, frame, synchronouslyLoaded) =>
          frame == null ? fallback : child,
      errorBuilder: (_, error, stack) => fallback,
    );
  }

  Widget _progression(double minimumHeight) {
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
    return PlayerMenuPanel(
      key: const ValueKey('profile-progression'),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minHeight: (minimumHeight - 48).clamp(0, double.infinity)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
                header: true,
                child:
                    Text(_text('Progression', 'Progress'), style: theme.title)),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final columns = constraints.maxWidth / scale >= 720;
              final split = (statistics.length / 2).ceil();
              Widget table(
                      List<({String id, String label, String value})> rows) =>
                  _statistics(rows,
                      stacked: constraints.maxWidth / scale < 340);
              return columns
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: table(statistics.take(split).toList())),
                        const SizedBox(width: 32),
                        Expanded(child: table(statistics.skip(split).toList())),
                      ],
                    )
                  : table(statistics);
            }),
            if (profile.badges.isNotEmpty) ...[
              const SizedBox(height: 32),
              Semantics(
                  header: true,
                  child: Text(_text('Badges obtenus', 'Earned badges'),
                      style: theme.subtitle)),
              const SizedBox(height: 16),
              Wrap(
                key: const ValueKey('profile-earned-badges'),
                spacing: 16,
                runSpacing: 16,
                children: [for (final badge in profile.badges) _badge(badge)],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statistics(List<({String id, String label, String value})> statistics,
      {required bool stacked}) {
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
                        Text(statistic.label,
                            style: theme.body.copyWith(color: theme.secondary)),
                        const SizedBox(height: 4),
                        Text(statistic.value, style: theme.numbers),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(statistic.label,
                              style:
                                  theme.body.copyWith(color: theme.secondary)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(statistic.value,
                              textAlign: TextAlign.right, style: theme.numbers),
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
    final fallback = Icon(Icons.workspace_premium_outlined,
        size: 48, color: context.playerMenuTheme.secondary);
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
                  : Image(
                      key: ValueKey('profile-badge-source-${badge.id}:$path'),
                      image: FileImage(File(path)),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                      frameBuilder: (_, child, frame, synchronouslyLoaded) =>
                          frame == null ? fallback : child,
                      errorBuilder: (_, error, stack) => fallback,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
