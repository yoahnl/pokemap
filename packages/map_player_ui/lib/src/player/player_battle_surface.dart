import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_battle_theme.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';

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

enum PlayerBattlePanelKind { commands, moves, target, message }

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
    this.commandId,
    this.commandIcon,
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
  final ProjectBattleCommandId? commandId;
  final ProjectBattleCommandIcon? commandIcon;
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
    this.panelKind = PlayerBattlePanelKind.commands,
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
  final PlayerBattlePanelKind panelKind;
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
    this.paintBackground = true,
    this.onPanelTargeted,
    this.onHudTargeted,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final bool paintBackground;
  final ValueChanged<PlayerBattlePanelKind>? onPanelTargeted;
  final VoidCallback? onHudTargeted;

  @override
  Widget build(BuildContext context) => PlayerSurfacePaletteScope(
        role: ProjectPresentationSurfaceRole.battleHud,
        paintBackground: paintBackground,
        child: Builder(builder: _build),
      );

  Widget _build(BuildContext context) {
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
          final compactPortrait = constraints.maxWidth < 480 &&
              constraints.maxHeight > constraints.maxWidth;
          final battle = context.playerBattleProfile;
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
            profile: battle,
            compactPortrait: compactPortrait,
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
                  key: ValueKey<String>(
                    'battle-hud-position-enemy-${(battle?.enemyHudPosition ?? ProjectBattleHudPosition.topStart).name}',
                  ),
                  alignment: _hudAlignment(
                    battle?.enemyHudPosition ??
                        ProjectBattleHudPosition.topStart,
                  ),
                  child: GestureDetector(
                    key: const ValueKey<String>('battle-hud-target-enemy'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onHudTargeted,
                    child: SizedBox(
                      width: hudWidth,
                      child: _BattleHud(
                        data: data.enemy,
                        sideId: 'enemy',
                        profile: battle,
                      ),
                    ),
                  ),
                ),
                Align(
                  key: ValueKey<String>(
                    'battle-hud-position-player-${(battle?.playerHudPosition ?? ProjectBattleHudPosition.bottomEnd).name}',
                  ),
                  alignment: battle == null
                      ? (compact
                          ? const Alignment(1, -0.37)
                          : const Alignment(0.92, 0.15))
                      : _hudAlignment(battle.playerHudPosition),
                  child: GestureDetector(
                    key: const ValueKey<String>('battle-hud-target-player'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onHudTargeted,
                    child: SizedBox(
                      width: hudWidth,
                      child: _BattleHud(
                        data: data.player,
                        sideId: 'player',
                        profile: battle,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: alignment,
                  child: Padding(
                    padding: EdgeInsets.all(margin),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => onPanelTargeted?.call(data.panelKind),
                      child: commandPanel,
                    ),
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
  const _BattleHud({
    required this.data,
    required this.sideId,
    required this.profile,
  });

  final PlayerBattleHudViewData data;
  final String sideId;
  final ProjectBattlePresentationProfile? profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final paletteText = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      context
          .playerSurfacePalette(ProjectPresentationSurfaceRole.battleHud)
          ?.text,
    );
    final hpRatio = data.maxHp <= 0
        ? 0.0
        : (data.effectiveTargetDisplayedHp / data.maxHp).clamp(0.0, 1.0);
    final hpColor = hpRatio <= 0.2
        ? PokeMapPlayerProjectColorResolver.tryOpaqueHex(
              profile?.hpDangerColor,
            ) ??
            colors.danger
        : hpRatio <= 0.5
            ? PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                  profile?.hpWarningColor,
                ) ??
                colors.warning
            : PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                  profile?.hpHealthyColor,
                ) ??
                colors.success;
    return PlayerPanel(
      padding: const EdgeInsets.all(PlayerSpacing.sm),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      windowStyleOverride: profile == null
          ? null
          : _battleWindowStyle(
              id: 'battle-hud-$sideId',
              shape: profile!.hudShape,
              padding: 12,
            ),
      surfaceColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        context
            .playerSurfacePalette(ProjectPresentationSurfaceRole.battleHud)
            ?.surface,
      ),
      borderColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        context
            .playerSurfacePalette(ProjectPresentationSurfaceRole.battleHud)
            ?.border,
      ),
      textColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        context
            .playerSurfacePalette(ProjectPresentationSurfaceRole.battleHud)
            ?.text,
      ),
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
              if (profile?.showOwnerLabel ?? true) ...<Widget>[
                Text(
                  data.ownerLabel,
                  key: ValueKey<String>('battle-owner-$sideId'),
                  style: context.playerTypography
                      .combatStyle(
                        Theme.of(context).textTheme.labelSmall ??
                            const TextStyle(),
                      )
                      .copyWith(color: paletteText),
                ),
                const SizedBox(height: PlayerSpacing.xxs),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      data.speciesLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.playerTypography
                          .combatStyle(
                            Theme.of(context).textTheme.titleMedium ??
                                const TextStyle(),
                          )
                          .copyWith(color: paletteText),
                    ),
                  ),
                  const SizedBox(width: PlayerSpacing.xs),
                  if (profile?.showLevel ?? true)
                    Text(
                      context.playerL10n.levelLabel(data.level),
                      key: ValueKey<String>('battle-level-$sideId'),
                      style: context.playerTypography
                          .numbersStyle(
                            Theme.of(context).textTheme.labelMedium ??
                                const TextStyle(),
                          )
                          .copyWith(color: paletteText),
                    ),
                ],
              ),
              if (data.statusLabel case final status?) ...<Widget>[
                const SizedBox(height: PlayerSpacing.xxs),
                Text(
                  status,
                  key: ValueKey<String>('battle-status-$sideId'),
                  style: context.playerTypography.combatStyle(
                    (Theme.of(context).textTheme.labelSmall ??
                            const TextStyle())
                        .copyWith(
                      color: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                            profile?.statusColor,
                          ) ??
                          colors.warning,
                    ),
                  ),
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
                builder: (context, value, _) => _BattleHpBar(
                  key: ValueKey<String>(
                    'battle-hp-${(profile?.hpBarShape ?? ProjectBattleHpBarShape.rounded).name}-$sideId',
                  ),
                  value: value,
                  shape: profile?.hpBarShape ?? ProjectBattleHpBarShape.rounded,
                  color: hpColor,
                  backgroundColor: colors.outline.withValues(alpha: 0.35),
                ),
              ),
              if (profile?.showExactHp ?? true) ...<Widget>[
                const SizedBox(height: PlayerSpacing.xxs),
                Text(
                  context.playerL10n.hpLabel(
                    data.currentHp,
                    data.maxHp,
                  ),
                  key: ValueKey<String>('battle-exact-hp-$sideId'),
                  style: context.playerTypography
                      .numbersStyle(
                        Theme.of(context).textTheme.labelMedium ??
                            const TextStyle(),
                      )
                      .copyWith(color: paletteText),
                ),
              ],
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
    required this.profile,
    required this.compactPortrait,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final ProjectBattlePresentationProfile? profile;
  final bool compactPortrait;

  @override
  Widget build(BuildContext context) {
    final panelProfile = _panelProfile(profile, data.panelKind);
    final layout = panelProfile.layout == ProjectBattleCommandLayout.radial &&
            compactPortrait
        ? ProjectBattleCommandLayout.grid
        : panelProfile.layout;
    return PlayerPanel(
      key: const ValueKey<String>('battle-command-panel'),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      padding: EdgeInsets.all(panelProfile.padding * spacingScale),
      windowStyleOverride: profile == null
          ? null
          : _battleWindowStyle(
              id: 'battle-${data.panelKind.name}',
              shape: panelProfile.shape,
              padding: panelProfile.padding,
            ),
      surfaceColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panelProfile.surfaceColor,
      ),
      borderColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panelProfile.borderColor,
      ),
      textColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panelProfile.textColor,
      ),
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double gap(double value) => value * spacingScale;
            final columns = profile == null
                ? (constraints.maxWidth >= 560 ? 2 : 1)
                : layout == ProjectBattleCommandLayout.list
                    ? 1
                    : panelProfile.columns;
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
                    if (layout == ProjectBattleCommandLayout.radial)
                      _BattleRadialCommandLayout(
                        key: ValueKey<String>(
                          'battle-panel-${data.panelKind.name}-${layout.name}',
                        ),
                        entries: data.commands,
                        interactionsEnabled: data.interactionsEnabled,
                        iconBuilder: itemIconBuilder,
                        showProjectIcon:
                            data.panelKind == PlayerBattlePanelKind.commands &&
                                (profile?.showCommandIcons ?? false),
                        selectionColor:
                            PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                          panelProfile.selectionColor,
                        ),
                        onAction: onAction,
                        revision: data.revision,
                      )
                    else
                      Wrap(
                        key: ValueKey<String>(
                          'battle-panel-${data.panelKind.name}-${layout.name}',
                        ),
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
                                showProjectIcon: data.panelKind ==
                                        PlayerBattlePanelKind.commands &&
                                    (profile?.showCommandIcons ?? false),
                                selectionColor:
                                    PokeMapPlayerProjectColorResolver
                                        .tryOpaqueHex(
                                  panelProfile.selectionColor,
                                ),
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

class _BattleRadialCommandLayout extends StatelessWidget {
  const _BattleRadialCommandLayout({
    super.key,
    required this.entries,
    required this.interactionsEnabled,
    required this.iconBuilder,
    required this.showProjectIcon,
    required this.selectionColor,
    required this.onAction,
    required this.revision,
  });

  final List<PlayerBattleCommandViewData> entries;
  final bool interactionsEnabled;
  final Widget Function(String assetPath)? iconBuilder;
  final bool showProjectIcon;
  final Color? selectionColor;
  final ValueChanged<PlayerBattleAction> onAction;
  final int revision;

  @override
  Widget build(BuildContext context) {
    const alignments = <Alignment>[
      Alignment.topCenter,
      Alignment.centerRight,
      Alignment.bottomCenter,
      Alignment.centerLeft,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final entryWidth = math.min(180.0, constraints.maxWidth * .34);
        return SizedBox(
          height: 216,
          child: Stack(
            children: <Widget>[
              for (var index = 0; index < entries.length; index++)
                Align(
                  alignment: alignments[index % alignments.length],
                  child: SizedBox(
                    width: entryWidth,
                    child: _BattleEntryButton(
                      entry: entries[index],
                      interactionsEnabled: interactionsEnabled,
                      autofocus: entries[index].selected,
                      iconBuilder: iconBuilder,
                      showProjectIcon: showProjectIcon,
                      selectionColor: selectionColor,
                      onPressed: () => onAction(
                        PlayerBattleSelectEntryAction(
                          snapshotRevision: revision,
                          entryIndex: entries[index].index,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
    required this.showProjectIcon,
    required this.selectionColor,
  });

  final PlayerBattleCommandViewData entry;
  final bool interactionsEnabled;
  final bool autofocus;
  final Widget Function(String assetPath)? iconBuilder;
  final VoidCallback onPressed;
  final bool showProjectIcon;
  final Color? selectionColor;

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
    final accent = widget.selectionColor ?? _toneColor(colors, entry.tone);
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
                    if (entry.iconAssetPath == null &&
                        widget.showProjectIcon &&
                        entry.commandIcon != null)
                      Padding(
                        padding: const EdgeInsets.only(right: PlayerSpacing.sm),
                        child: Icon(
                          _commandIcon(entry.commandIcon!),
                          color: accent,
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

class _BattleHpBar extends StatelessWidget {
  const _BattleHpBar({
    super.key,
    required this.value,
    required this.shape,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final ProjectBattleHpBarShape shape;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (shape == ProjectBattleHpBarShape.segmented) {
      final active = (value * 10).ceil();
      return Row(
        children: <Widget>[
          for (var index = 0; index < 10; index++) ...<Widget>[
            Expanded(
              child: SizedBox(
                height: 8,
                child: ColoredBox(
                  color: index < active ? color : backgroundColor,
                ),
              ),
            ),
            if (index != 9) const SizedBox(width: 2),
          ],
        ],
      );
    }
    final indicator = LinearProgressIndicator(
      minHeight: 8,
      value: value,
      color: color,
      backgroundColor: backgroundColor,
    );
    if (shape == ProjectBattleHpBarShape.flat) return indicator;
    return ClipRRect(
      borderRadius: BorderRadius.circular(PlayerRadii.pill),
      child: indicator,
    );
  }
}

Alignment _hudAlignment(ProjectBattleHudPosition position) =>
    switch (position) {
      ProjectBattleHudPosition.topStart => Alignment.topLeft,
      ProjectBattleHudPosition.topEnd => Alignment.topRight,
      ProjectBattleHudPosition.bottomStart => const Alignment(-1, .35),
      ProjectBattleHudPosition.bottomEnd => const Alignment(1, .35),
    };

ProjectBattlePanelPresentationProfile _panelProfile(
  ProjectBattlePresentationProfile? profile,
  PlayerBattlePanelKind kind,
) {
  if (profile == null) {
    return const ProjectBattlePanelPresentationProfile();
  }
  return switch (kind) {
    PlayerBattlePanelKind.commands => ProjectBattlePanelPresentationProfile(
        layout: profile.commandLayout,
        columns: profile.commandColumns,
        shape: profile.commandShape,
        padding: profile.commandPadding,
        surfaceColor: profile.commandSurfaceColor,
        borderColor: profile.commandBorderColor,
        textColor: profile.commandTextColor,
        selectionColor: profile.commandSelectionColor,
      ),
    PlayerBattlePanelKind.moves => profile.moves,
    PlayerBattlePanelKind.target => profile.target,
    PlayerBattlePanelKind.message => profile.message,
  };
}

ProjectWindowStyleProfile _battleWindowStyle({
  required String id,
  required ProjectWindowShape shape,
  required double padding,
}) =>
    ProjectWindowStyleProfile(
      id: id,
      fillToken: 'battleHudSurface',
      borderToken: 'outline',
      borderWidth: 1,
      cornerRadius: 16,
      contentPadding: padding.round(),
      shadowElevation: 8,
      shape: shape,
    );

IconData _commandIcon(ProjectBattleCommandIcon icon) => switch (icon) {
      ProjectBattleCommandIcon.fight => Icons.sports_martial_arts_rounded,
      ProjectBattleCommandIcon.bag => Icons.backpack_rounded,
      ProjectBattleCommandIcon.party => Icons.groups_rounded,
      ProjectBattleCommandIcon.run => Icons.directions_run_rounded,
    };

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
