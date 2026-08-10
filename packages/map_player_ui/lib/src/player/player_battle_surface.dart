import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_theme.dart';

enum PlayerBattleEntryTone {
  neutral,
  attack,
  special,
  support,
  switching,
  medicine,
  capture,
  disabled,
}

@immutable
final class PlayerBattleCommandViewData {
  const PlayerBattleCommandViewData({
    required this.index,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.enabled,
    required this.selected,
    required this.tone,
    this.tertiaryLabel,
    this.trailingLabel,
    this.statusLabel,
    this.iconAssetPath,
  });

  final int index;
  final String primaryLabel;
  final String secondaryLabel;
  final String? tertiaryLabel;
  final String? trailingLabel;
  final String? statusLabel;
  final bool enabled;
  final bool selected;
  final PlayerBattleEntryTone tone;
  final String? iconAssetPath;
}

@immutable
final class PlayerBattleHudViewData {
  const PlayerBattleHudViewData({
    required this.ownerLabel,
    required this.speciesLabel,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    this.displayedHp,
    this.targetDisplayedHp,
    this.hpTweenDuration,
    this.hpTweenRevision = 0,
    this.statusLabel,
  });

  final String ownerLabel;
  final String speciesLabel;
  final int level;
  final int currentHp;
  final int maxHp;
  final int? displayedHp;
  final int? targetDisplayedHp;
  final Duration? hpTweenDuration;
  final int hpTweenRevision;
  final String? statusLabel;

  int get effectiveDisplayedHp => displayedHp ?? currentHp;

  int get effectiveTargetDisplayedHp =>
      targetDisplayedHp ?? effectiveDisplayedHp;
}

@immutable
final class PlayerBattleViewData {
  const PlayerBattleViewData({
    required this.revision,
    required this.enemy,
    required this.player,
    required this.battleLabel,
    required this.title,
    required this.prompt,
    required this.narrationLines,
    required this.commands,
    required this.interactionsEnabled,
    required this.canGoBack,
    this.forcedReplacement = false,
  });

  final int revision;
  final PlayerBattleHudViewData enemy;
  final PlayerBattleHudViewData player;
  final String battleLabel;
  final String title;
  final String prompt;
  final List<String> narrationLines;
  final List<PlayerBattleCommandViewData> commands;
  final bool interactionsEnabled;
  final bool canGoBack;
  final bool forcedReplacement;
}

sealed class PlayerBattleAction {
  const PlayerBattleAction({required this.snapshotRevision});

  final int snapshotRevision;
}

final class PlayerBattleSelectEntryAction extends PlayerBattleAction {
  const PlayerBattleSelectEntryAction({
    required super.snapshotRevision,
    required this.entryIndex,
  });

  final int entryIndex;
}

final class PlayerBattleBackAction extends PlayerBattleAction {
  const PlayerBattleBackAction({required super.snapshotRevision});
}

/// Présentation battle officielle du shell joueur.
///
/// Flame conserve le terrain, les sprites, la caméra et les effets. Ce widget
/// ne consomme que le data immutable publié par `map_runtime` et renvoie
/// des commandes versionnées au contrôleur unique du runtime.
class PlayerBattleSurface extends StatelessWidget {
  const PlayerBattleSurface({
    super.key,
    required this.data,
    required this.onAction,
    this.itemIconBuilder,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = math.max(
            0.0,
            constraints.maxWidth - PlayerSpacing.sm * 2,
          );
          final contentHeight = math.max(
            0.0,
            constraints.maxHeight - PlayerSpacing.sm * 2,
          );
          final resolved = context.playerLayoutTheme?.tryResolve(
            ProjectPresentationSurfaceRole.battleHud,
            constraints,
          );
          final breakpoint = resolved?.breakpoint ??
              const ProjectPresentationLayoutResolver().classify(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              );
          final compact = resolved == null
              ? contentWidth < 560
              : breakpoint == ProjectPresentationBreakpoint.compact;
          final hudWidth = math.min(
            compact ? contentWidth * 0.72 : 280.0,
            320.0,
          );
          final configuredSlot = resolved?.variant.slot;
          final slot =
              compact && configuredSlot == ProjectPresentationLayoutSlot.right
                  ? ProjectPresentationLayoutSlot.bottomCenter
                  : configuredSlot;
          final fullScreen = slot == ProjectPresentationLayoutSlot.fullScreen;
          final alignment = switch (slot) {
            ProjectPresentationLayoutSlot.right => Alignment.centerRight,
            ProjectPresentationLayoutSlot.fullScreen => Alignment.center,
            _ => Alignment.bottomCenter,
          };
          final margin = resolved?.additionalSafeAreaPadding ?? 0;
          final panelMaxWidth =
              resolved == null ? 720.0 : contentWidth * resolved.maxWidthFactor;
          final panel = _BattleCommandPanel(
            data: data,
            onAction: onAction,
            itemIconBuilder: itemIconBuilder,
            spacingScale: resolved?.spacingScale ?? 1,
          );
          final commandPanel = fullScreen
              ? SizedBox(
                  width: math.max(0.0, contentWidth - margin * 2),
                  height: math.max(0.0, contentHeight - margin * 2),
                  child: panel,
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: panelMaxWidth,
                    maxHeight: contentHeight * (compact ? 0.58 : 0.5),
                  ),
                  child: panel,
                );
          return Padding(
            padding: const EdgeInsets.all(PlayerSpacing.sm),
            child: Stack(
              key: ValueKey<String>(
                'player-battle-responsive-${breakpoint.name}',
              ),
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: hudWidth,
                    child: _BattleHud(data: data.enemy),
                  ),
                ),
                Align(
                  alignment: compact
                      ? const Alignment(1, -0.37)
                      : const Alignment(0.92, 0.15),
                  child: SizedBox(
                    width: hudWidth,
                    child: _BattleHud(data: data.player),
                  ),
                ),
                Align(
                  alignment: alignment,
                  child: Padding(
                    padding: EdgeInsets.all(margin),
                    child: commandPanel,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BattleHud extends StatelessWidget {
  const _BattleHud({required this.data});

  final PlayerBattleHudViewData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final hpRatio = data.maxHp <= 0
        ? 0.0
        : (data.effectiveTargetDisplayedHp / data.maxHp).clamp(0.0, 1.0);
    final hpColor = hpRatio <= 0.2
        ? colors.danger
        : hpRatio <= 0.5
            ? colors.warning
            : colors.success;
    return PlayerPanel(
      padding: const EdgeInsets.all(PlayerSpacing.sm),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      child: Semantics(
        container: true,
        label: '${data.ownerLabel}, ${data.speciesLabel}, '
            '${context.playerL10n.levelLabel(data.level)}, '
            '${context.playerL10n.hpLabel(data.currentHp, data.maxHp)}'
            '${data.statusLabel == null ? '' : ', ${data.statusLabel}'}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      data.speciesLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.playerTypography.combatStyle(
                        Theme.of(context).textTheme.titleMedium ??
                            const TextStyle(),
                      ),
                    ),
                  ),
                  const SizedBox(width: PlayerSpacing.xs),
                  Text(
                    context.playerL10n.levelLabel(data.level),
                    style: context.playerTypography.numbersStyle(
                      Theme.of(context).textTheme.labelMedium ??
                          const TextStyle(),
                    ),
                  ),
                ],
              ),
              if (data.statusLabel case final status?) ...<Widget>[
                const SizedBox(height: PlayerSpacing.xxs),
                PlayerBadge(
                  label: status,
                  icon: Icons.warning_amber_rounded,
                  tone: PlayerBadgeTone.warning,
                ),
              ],
              const SizedBox(height: PlayerSpacing.xs),
              TweenAnimationBuilder<double>(
                key: ValueKey<int>(data.hpTweenRevision),
                tween: Tween<double>(
                  begin: data.maxHp <= 0
                      ? 0
                      : (data.effectiveDisplayedHp / data.maxHp)
                          .clamp(0.0, 1.0),
                  end: hpRatio,
                ),
                duration: context.playerMotion.standard == Duration.zero
                    ? Duration.zero
                    : data.hpTweenDuration ?? context.playerMotion.standard,
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
                  data.currentHp,
                  data.maxHp,
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
    required this.data,
    required this.onAction,
    required this.itemIconBuilder,
    required this.spacingScale,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;

  @override
  Widget build(BuildContext context) {
    return PlayerPanel(
      key: const ValueKey<String>('battle-command-panel'),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      padding: EdgeInsets.all(PlayerSpacing.sm * spacingScale),
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double gap(double value) => value * spacingScale;
            final columns = constraints.maxWidth >= 560 ? 2 : 1;
            final entryWidth = columns == 1
                ? constraints.maxWidth
                : (constraints.maxWidth - gap(PlayerSpacing.xs)) / 2;
            return SingleChildScrollView(
              child: Semantics(
                container: true,
                liveRegion: true,
                label: '${data.battleLabel}, ${data.prompt}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            data.title,
                            style: context.playerTypography.combatStyle(
                              Theme.of(context).textTheme.titleLarge ??
                                  const TextStyle(),
                            ),
                          ),
                        ),
                        if (data.canGoBack)
                          IconButton(
                            key: const ValueKey<String>('battle-back'),
                            tooltip: context.playerL10n.back,
                            onPressed: data.interactionsEnabled
                                ? () => onAction(
                                      PlayerBattleBackAction(
                                        snapshotRevision: data.revision,
                                      ),
                                    )
                                : null,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                      ],
                    ),
                    if (data.forcedReplacement) ...<Widget>[
                      SizedBox(height: gap(PlayerSpacing.xxs)),
                      PlayerBadge(
                        label: context.playerL10n.mandatoryReplacement,
                        icon: Icons.swap_horiz_rounded,
                        tone: PlayerBadgeTone.warning,
                      ),
                    ],
                    SizedBox(height: gap(PlayerSpacing.xxs)),
                    Text(
                      data.prompt,
                      style: context.playerTypography.combatStyle(
                        Theme.of(context).textTheme.bodyLarge ??
                            const TextStyle(),
                      ),
                    ),
                    if (data.narrationLines.isNotEmpty) ...<Widget>[
                      SizedBox(height: gap(PlayerSpacing.xxs)),
                      Text(
                        data.narrationLines.join('\n'),
                        style: context.playerTypography.combatStyle(
                          Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle(),
                        ),
                      ),
                    ],
                    SizedBox(height: gap(PlayerSpacing.sm)),
                    Wrap(
                      spacing: gap(PlayerSpacing.xs),
                      runSpacing: gap(PlayerSpacing.xs),
                      children: <Widget>[
                        for (final entry in data.commands)
                          SizedBox(
                            width: entryWidth,
                            child: _BattleEntryButton(
                              entry: entry,
                              interactionsEnabled: data.interactionsEnabled,
                              autofocus: entry.selected,
                              iconBuilder: itemIconBuilder,
                              onPressed: () => onAction(
                                PlayerBattleSelectEntryAction(
                                  snapshotRevision: data.revision,
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

  final PlayerBattleCommandViewData entry;
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
                            style: context.playerTypography.combatStyle(
                              (Theme.of(context).textTheme.labelLarge ??
                                      const TextStyle())
                                  .copyWith(color: foreground),
                            ),
                          ),
                          if (entry.secondaryLabel.isNotEmpty)
                            Text(
                              entry.secondaryLabel,
                              style: context.playerTypography.combatStyle(
                                (Theme.of(context).textTheme.bodySmall ??
                                        const TextStyle())
                                    .copyWith(color: foreground),
                              ),
                            ),
                          if (entry.tertiaryLabel case final label?)
                            Text(
                              label,
                              style: context.playerTypography.combatStyle(
                                Theme.of(context).textTheme.bodySmall ??
                                    const TextStyle(),
                              ),
                            ),
                          if (entry.statusLabel case final status?)
                            Text(
                              status,
                              style: context.playerTypography.combatStyle(
                                (Theme.of(context).textTheme.labelSmall ??
                                        const TextStyle())
                                    .copyWith(color: accent),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (entry.trailingLabel case final trailing?)
                      Text(
                        trailing,
                        style: context.playerTypography.combatStyle(
                          Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle(),
                        ),
                      ),
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
  PlayerBattleEntryTone tone,
) {
  return switch (tone) {
    PlayerBattleEntryTone.medicine => colors.success,
    PlayerBattleEntryTone.attack ||
    PlayerBattleEntryTone.special ||
    PlayerBattleEntryTone.capture =>
      colors.primary,
    PlayerBattleEntryTone.support ||
    PlayerBattleEntryTone.switching =>
      colors.warning,
    PlayerBattleEntryTone.disabled => colors.textSecondary,
    PlayerBattleEntryTone.neutral => colors.outline,
  };
}
