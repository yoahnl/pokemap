import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_runtime/map_runtime.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';

/// Présentation battle officielle du shell joueur.
///
/// Flame conserve le terrain, les sprites, la caméra et les effets. Ce widget
/// ne consomme que le snapshot immutable publié par `map_runtime` et renvoie
/// des commandes versionnées au contrôleur unique du runtime.
class PlayerBattleOverlay extends StatelessWidget {
  const PlayerBattleOverlay({
    super.key,
    required this.snapshot,
    required this.onCommand,
    this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<BattlePresentationCommand> onCommand;
  final Widget Function(String assetPath)? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PlayerSpacing.sm),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 560;
            final hudWidth = math.min(
              compact ? constraints.maxWidth * 0.72 : 280.0,
              320.0,
            );
            return Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: hudWidth,
                    child: _BattleHud(snapshot: snapshot.enemyHud),
                  ),
                ),
                Align(
                  alignment: compact
                      ? const Alignment(1, -0.37)
                      : const Alignment(0.92, 0.15),
                  child: SizedBox(
                    width: hudWidth,
                    child: _BattleHud(snapshot: snapshot.playerHud),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 720,
                      maxHeight: constraints.maxHeight * (compact ? 0.58 : 0.5),
                    ),
                    child: _BattleCommandPanel(
                      snapshot: snapshot,
                      onCommand: onCommand,
                      itemIconBuilder: itemIconBuilder,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BattleHud extends StatelessWidget {
  const _BattleHud({required this.snapshot});

  final BattleCommandOverlayHudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final hpRatio = snapshot.maxHp <= 0
        ? 0.0
        : (snapshot.effectiveTargetDisplayedHp / snapshot.maxHp)
            .clamp(0.0, 1.0);
    final hpColor = hpRatio <= 0.2
        ? colors.danger
        : hpRatio <= 0.5
            ? colors.warning
            : colors.success;
    return PlayerPanel(
      padding: const EdgeInsets.all(PlayerSpacing.sm),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      child: Semantics(
        container: true,
        label: '${snapshot.ownerLabel}, ${snapshot.speciesLabel}, '
            '${context.playerL10n.levelLabel(snapshot.level)}, '
            '${context.playerL10n.hpLabel(snapshot.currentHp, snapshot.maxHp)}'
            '${snapshot.statusLabel == null ? '' : ', ${snapshot.statusLabel}'}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      snapshot.speciesLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: PlayerSpacing.xs),
                  Text(
                    context.playerL10n.levelLabel(snapshot.level),
                    style: context.playerTypography.numbersStyle(
                      Theme.of(context).textTheme.labelMedium ??
                          const TextStyle(),
                    ),
                  ),
                ],
              ),
              if (snapshot.statusLabel case final status?) ...<Widget>[
                const SizedBox(height: PlayerSpacing.xxs),
                PlayerBadge(
                  label: status,
                  icon: Icons.warning_amber_rounded,
                  tone: PlayerBadgeTone.warning,
                ),
              ],
              const SizedBox(height: PlayerSpacing.xs),
              TweenAnimationBuilder<double>(
                key: ValueKey<int>(snapshot.hpTweenRevision),
                tween: Tween<double>(
                  begin: snapshot.maxHp <= 0
                      ? 0
                      : (snapshot.effectiveDisplayedHp / snapshot.maxHp)
                          .clamp(0.0, 1.0),
                  end: hpRatio,
                ),
                duration: context.playerMotion.standard == Duration.zero
                    ? Duration.zero
                    : snapshot.hpTweenDuration ?? context.playerMotion.standard,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(PlayerRadii.pill),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: value,
                    color: hpColor,
                    backgroundColor: colors.outline.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(height: PlayerSpacing.xxs),
              Text(
                context.playerL10n.hpLabel(
                  snapshot.currentHp,
                  snapshot.maxHp,
                ),
                style: context.playerTypography.numbersStyle(
                  Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleCommandPanel extends StatelessWidget {
  const _BattleCommandPanel({
    required this.snapshot,
    required this.onCommand,
    required this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<BattlePresentationCommand> onCommand;
  final Widget Function(String assetPath)? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return PlayerPanel(
      elevated: true,
      role: PlayerPanelRole.battleHud,
      padding: const EdgeInsets.all(PlayerSpacing.sm),
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 2 : 1;
            final entryWidth = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - PlayerSpacing.xs) / 2;
            return SingleChildScrollView(
              child: Semantics(
                container: true,
                liveRegion: true,
                label: '${snapshot.battleLabel}, ${snapshot.prompt}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            snapshot.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (snapshot.canGoBack)
                          IconButton(
                            key: const ValueKey<String>('battle-back'),
                            tooltip: context.playerL10n.back,
                            onPressed: snapshot.interactionsEnabled
                                ? () => onCommand(
                                      BattleBackCommand(
                                        snapshotRevision: snapshot.revision,
                                        expectedMode: snapshot.mode,
                                      ),
                                    )
                                : null,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                      ],
                    ),
                    if (snapshot.forcedReplacement) ...<Widget>[
                      const SizedBox(height: PlayerSpacing.xxs),
                      PlayerBadge(
                        label: context.playerL10n.mandatoryReplacement,
                        icon: Icons.swap_horiz_rounded,
                        tone: PlayerBadgeTone.warning,
                      ),
                    ],
                    const SizedBox(height: PlayerSpacing.xxs),
                    Text(
                      snapshot.prompt,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (snapshot.narrationLines.isNotEmpty) ...<Widget>[
                      const SizedBox(height: PlayerSpacing.xxs),
                      Text(snapshot.narrationLines.join('\n')),
                    ],
                    const SizedBox(height: PlayerSpacing.sm),
                    Wrap(
                      spacing: PlayerSpacing.xs,
                      runSpacing: PlayerSpacing.xs,
                      children: <Widget>[
                        for (final entry in snapshot.entries)
                          SizedBox(
                            width: entryWidth,
                            child: _BattleEntryButton(
                              entry: entry,
                              interactionsEnabled: snapshot.interactionsEnabled,
                              autofocus: entry.selected,
                              iconBuilder: itemIconBuilder,
                              onPressed: () => onCommand(
                                BattleSelectEntryCommand(
                                  snapshotRevision: snapshot.revision,
                                  expectedMode: snapshot.mode,
                                  entryIndex: entry.index,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BattleEntryButton extends StatefulWidget {
  const _BattleEntryButton({
    required this.entry,
    required this.interactionsEnabled,
    required this.autofocus,
    required this.iconBuilder,
    required this.onPressed,
  });

  final BattleCommandOverlayEntry entry;
  final bool interactionsEnabled;
  final bool autofocus;
  final Widget Function(String assetPath)? iconBuilder;
  final VoidCallback onPressed;

  @override
  State<_BattleEntryButton> createState() => _BattleEntryButtonState();
}

class _BattleEntryButtonState extends State<_BattleEntryButton> {
  late final FocusNode _focusNode;
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'Battle ${widget.entry.primaryLabel}')
      ..addListener(_handleFocus);
  }

  void _handleFocus() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final enabled = entry.enabled && widget.interactionsEnabled;
    final colors = context.playerColors;
    final foreground = enabled ? colors.textPrimary : colors.textSecondary;
    final accent = _toneColor(colors, entry.tone);
    final disabledReason = entry.secondaryLabel.isEmpty
        ? context.playerL10n.actionUnavailable
        : entry.secondaryLabel;
    return Semantics(
      key: ValueKey<String>('battle-entry-${entry.index}'),
      button: true,
      enabled: enabled,
      selected: entry.selected,
      label: entry.primaryLabel,
      hint: enabled ? entry.secondaryLabel : disabledReason,
      child: Tooltip(
        message: enabled ? entry.primaryLabel : disabledReason,
        child: Material(
          color: entry.selected
              ? accent.withValues(alpha: 0.16)
              : colors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PlayerRadii.sm),
            side: BorderSide(
              color: _focused ? colors.focus : accent,
              width: _focused ? 3 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            onTap: enabled ? widget.onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.all(PlayerSpacing.sm),
                child: Row(
                  children: <Widget>[
                    if (entry.iconAssetPath case final path?)
                      Padding(
                        padding: const EdgeInsets.only(right: PlayerSpacing.sm),
                        child: SizedBox.square(
                          dimension: 36,
                          child: widget.iconBuilder?.call(path) ??
                              Icon(Icons.inventory_2_outlined, color: accent),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            entry.primaryLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: foreground),
                          ),
                          if (entry.secondaryLabel.isNotEmpty)
                            Text(
                              entry.secondaryLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: foreground),
                            ),
                          if (entry.tertiaryLabel case final label?)
                            Text(label),
                          if (entry.statusLabel case final status?)
                            Text(
                              status,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: accent),
                            ),
                        ],
                      ),
                    ),
                    if (entry.trailingLabel case final trailing?)
                      Text(trailing),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _toneColor(
  PokeMapPlayerColors colors,
  BattleCommandOverlayEntryTone tone,
) {
  return switch (tone) {
    BattleCommandOverlayEntryTone.medicine => colors.success,
    BattleCommandOverlayEntryTone.attack ||
    BattleCommandOverlayEntryTone.special ||
    BattleCommandOverlayEntryTone.capture =>
      colors.primary,
    BattleCommandOverlayEntryTone.support ||
    BattleCommandOverlayEntryTone.switching =>
      colors.warning,
    BattleCommandOverlayEntryTone.disabled => colors.textSecondary,
    BattleCommandOverlayEntryTone.neutral => colors.outline,
  };
}
