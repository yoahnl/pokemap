import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_battle_theme.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
import '../theme/pokemap_player_window_theme.dart';

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
final class PlayerBattleViewportLayout {
  const PlayerBattleViewportLayout({
    required this.viewportSize,
    required this.panelRect,
    required this.enemyHudRect,
    required this.playerHudRect,
  });

  final Size viewportSize;
  final Rect panelRect;
  final Rect enemyHudRect;
  final Rect playerHudRect;
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
    this.viewportLayout,
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
  final PlayerBattleViewportLayout? viewportLayout;
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
    if (data.viewportLayout case final layout?
        when _usesCanonicalBattleStructure(context.playerBattleProfile)) {
      return _buildViewportLayout(context, layout);
    }
    return _buildAdaptiveLayout(context);
  }

  Widget _buildViewportLayout(
    BuildContext context,
    PlayerBattleViewportLayout layout,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        if ((viewportSize.width - layout.viewportSize.width).abs() > 0.5 ||
            (viewportSize.height - layout.viewportSize.height).abs() > 0.5) {
          return const SizedBox.shrink();
        }
        final compactPortrait = viewportSize.width < 480 &&
            viewportSize.height > viewportSize.width;
        final resolved = context.playerLayoutTheme?.tryResolve(
          ProjectPresentationSurfaceRole.battleHud,
          constraints,
        );
        final breakpoint = resolved?.breakpoint ??
            const ProjectPresentationLayoutResolver().classify(
              width: viewportSize.width,
              height: viewportSize.height,
            );
        final battle = context.playerBattleProfile;
        final panel = _BattleCommandPanel(
          data: data,
          onAction: onAction,
          itemIconBuilder: itemIconBuilder,
          spacingScale: resolved?.spacingScale ?? 1,
          profile: battle,
          compactPortrait: compactPortrait,
          reservedViewportLayout: true,
        );
        return Stack(
          key: ValueKey<String>(
            'player-battle-responsive-${breakpoint.name}',
          ),
          children: <Widget>[
            Positioned.fromRect(
              rect: layout.enemyHudRect,
              child: GestureDetector(
                key: const ValueKey<String>('battle-hud-target-enemy'),
                behavior: HitTestBehavior.opaque,
                onTap: onHudTargeted,
                child: _BattleHud(
                  data: data.enemy,
                  sideId: 'enemy',
                  profile: battle,
                  dense: true,
                  showDenseOwner: layout.enemyHudRect.height >= 64,
                  showDenseDetails: layout.enemyHudRect.height >= 52,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: layout.playerHudRect,
              child: GestureDetector(
                key: const ValueKey<String>('battle-hud-target-player'),
                behavior: HitTestBehavior.opaque,
                onTap: onHudTargeted,
                child: _BattleHud(
                  data: data.player,
                  sideId: 'player',
                  profile: battle,
                  dense: true,
                  showDenseOwner: layout.playerHudRect.height >= 64,
                  showDenseDetails: layout.playerHudRect.height >= 52,
                ),
              ),
            ),
            Positioned.fromRect(
              rect: layout.panelRect,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => onPanelTargeted?.call(data.panelKind),
                child: panel,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdaptiveLayout(BuildContext context) {
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
            reservedViewportLayout: false,
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
                        dense: false,
                        showDenseOwner: false,
                        showDenseDetails: false,
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
                        dense: false,
                        showDenseOwner: false,
                        showDenseDetails: false,
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
    required this.dense,
    required this.showDenseOwner,
    required this.showDenseDetails,
  });

  final PlayerBattleHudViewData data;
  final String sideId;
  final ProjectBattlePresentationProfile? profile;
  final bool dense;
  final bool showDenseOwner;
  final bool showDenseDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final paletteText = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          context
              .playerSurfacePalette(ProjectPresentationSurfaceRole.battleHud)
              ?.text,
        ) ??
        colors.textPrimary;
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
      padding: EdgeInsets.all(
        dense ? 0 : PlayerSpacing.sm,
      ),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      windowStyleOverride: profile == null
          ? dense
              ? context.playerWindowTheme
                  ?.style(ProjectWindowRole.battle)
                  .copyWith(contentPadding: 0)
              : null
          : _battleWindowStyle(
              id: 'battle-hud-$sideId',
              shape: profile!.hudShape,
              padding: dense ? 0 : 12,
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
              if (dense &&
                  showDenseOwner &&
                  !largeText &&
                  (profile?.showOwnerLabel ?? true))
                Text(
                  data.ownerLabel,
                  key: ValueKey<String>('battle-owner-$sideId'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.playerTypography
                      .combatStyle(
                        Theme.of(context).textTheme.labelSmall ??
                            const TextStyle(),
                      )
                      .copyWith(color: paletteText),
                ),
              if (dense)
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        data.speciesLabel,
                        key: ValueKey<String>('battle-species-$sideId'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.playerTypography
                            .combatStyle((largeText
                                    ? Theme.of(context).textTheme.labelSmall
                                    : Theme.of(context).textTheme.titleSmall) ??
                                const TextStyle())
                            .copyWith(
                              color: paletteText,
                              height: largeText ? 1 : null,
                            ),
                      ),
                    ),
                    if ((profile?.showLevel ?? true) &&
                        (!largeText || showDenseDetails)) ...<Widget>[
                      const SizedBox(width: PlayerSpacing.xxs),
                      Text(
                        context.playerL10n.levelLabel(data.level),
                        key: ValueKey<String>('battle-level-$sideId'),
                        style: context.playerTypography
                            .numbersStyle(
                              Theme.of(context).textTheme.labelSmall ??
                                  const TextStyle(),
                            )
                            .copyWith(
                              color: paletteText,
                              height: largeText ? 1 : null,
                            ),
                      ),
                    ],
                  ],
                )
              else ...<Widget>[
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
                        key: ValueKey<String>('battle-species-$sideId'),
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
              ],
              if (!dense)
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
              if (!dense) const SizedBox(height: PlayerSpacing.xs),
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
              if (dense) ...<Widget>[
                if (!largeText && showDenseDetails)
                  Row(
                    children: <Widget>[
                      if (profile?.showExactHp ?? true)
                        Flexible(
                          child: Text(
                            context.playerL10n.hpLabel(
                              data.currentHp,
                              data.maxHp,
                            ),
                            key: ValueKey<String>('battle-exact-hp-$sideId'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.playerTypography
                                .numbersStyle(
                                  Theme.of(context).textTheme.labelSmall ??
                                      const TextStyle(),
                                )
                                .copyWith(color: paletteText),
                          ),
                        ),
                      const Spacer(),
                      if (data.statusLabel case final status?)
                        Flexible(
                          child: Text(
                            status,
                            key: ValueKey<String>('battle-status-$sideId'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.playerTypography.combatStyle(
                              (Theme.of(context).textTheme.labelSmall ??
                                      const TextStyle())
                                  .copyWith(
                                color: PokeMapPlayerProjectColorResolver
                                        .tryOpaqueHex(profile?.statusColor) ??
                                    colors.warning,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
              ] else if (profile?.showExactHp ?? true) ...<Widget>[
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
    required this.reservedViewportLayout,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final ProjectBattlePresentationProfile? profile;
  final bool compactPortrait;
  final bool reservedViewportLayout;

  @override
  Widget build(BuildContext context) {
    final panelProfile = _panelProfile(profile, data.panelKind);
    if (reservedViewportLayout) {
      return _BattleSeparatedCommandDock(
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        spacingScale: spacingScale,
        profile: profile,
        panelProfile: panelProfile,
      );
    }
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
            final denseRoot = reservedViewportLayout &&
                data.panelKind == PlayerBattlePanelKind.commands &&
                data.commands.length <= 4 &&
                constraints.maxHeight <= 280;
            final splitRoot = denseRoot &&
                constraints.maxWidth >= 700 &&
                constraints.maxHeight <= 180;
            final effectiveLayout =
                denseRoot ? ProjectBattleCommandLayout.grid : layout;
            final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;

            Widget intro() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (!denseRoot || !largeText)
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
                      maxLines: denseRoot ? 1 : null,
                      overflow: denseRoot ? TextOverflow.ellipsis : null,
                      style: context.playerTypography.combatStyle(
                        Theme.of(context).textTheme.bodyLarge ??
                            const TextStyle(),
                      ),
                    ),
                    if (data.narrationLines.isNotEmpty &&
                        !(denseRoot && largeText)) ...<Widget>[
                      SizedBox(height: gap(PlayerSpacing.xxs)),
                      Text(
                        denseRoot
                            ? data.narrationLines.last
                            : data.narrationLines.join('\n'),
                        maxLines: denseRoot ? 1 : null,
                        overflow: denseRoot ? TextOverflow.ellipsis : null,
                        style: context.playerTypography.combatStyle(
                          Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle(),
                        ),
                      ),
                    ],
                  ],
                );

            Widget entries() => LayoutBuilder(
                  builder: (context, entryConstraints) {
                    final columns = denseRoot
                        ? 2
                        : profile == null
                            ? (entryConstraints.maxWidth >= 560 ? 2 : 1)
                            : effectiveLayout == ProjectBattleCommandLayout.list
                                ? 1
                                : panelProfile.columns;
                    final entryWidth = columns == 1
                        ? entryConstraints.maxWidth
                        : (entryConstraints.maxWidth - gap(PlayerSpacing.xs)) /
                            2;
                    if (effectiveLayout == ProjectBattleCommandLayout.radial) {
                      return _BattleRadialCommandLayout(
                        key: ValueKey<String>(
                          'battle-panel-${data.panelKind.name}-${effectiveLayout.name}',
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
                      );
                    }
                    return Wrap(
                      key: ValueKey<String>(
                        'battle-panel-${data.panelKind.name}-${effectiveLayout.name}',
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
                              dense: denseRoot,
                              showProjectIcon: data.panelKind ==
                                      PlayerBattlePanelKind.commands &&
                                  (profile?.showCommandIcons ?? false),
                              selectionColor: PokeMapPlayerProjectColorResolver
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
                    );
                  },
                );

            final content = splitRoot
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: intro(),
                      ),
                      SizedBox(width: gap(PlayerSpacing.sm)),
                      Expanded(flex: 7, child: entries()),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:
                        denseRoot ? MainAxisSize.max : MainAxisSize.min,
                    children: <Widget>[
                      if (denseRoot)
                        Flexible(
                          flex: 2,
                          child: intro(),
                        )
                      else
                        intro(),
                      SizedBox(
                        height: gap(
                          denseRoot ? PlayerSpacing.xs : PlayerSpacing.sm,
                        ),
                      ),
                      if (denseRoot)
                        Expanded(flex: 3, child: entries())
                      else
                        entries(),
                    ],
                  );
            final semantics = Semantics(
              container: true,
              liveRegion: true,
              label: '${data.battleLabel}, ${data.prompt}',
              child: content,
            );
            if (denseRoot) return semantics;
            return SingleChildScrollView(child: semantics);
          },
        ),
      ),
    );
  }
}

class _BattleSeparatedCommandDock extends StatelessWidget {
  const _BattleSeparatedCommandDock({
    required this.data,
    required this.onAction,
    required this.itemIconBuilder,
    required this.spacingScale,
    required this.profile,
    required this.panelProfile,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final ProjectBattlePresentationProfile? profile;
  final ProjectBattlePanelPresentationProfile panelProfile;

  @override
  Widget build(BuildContext context) {
    final panelPadding = panelProfile.padding * spacingScale;
    final panelSurface = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      panelProfile.surfaceColor,
    );
    final panelBorder = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      panelProfile.borderColor,
    );
    final panelText = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      panelProfile.textColor,
    );
    final selectionColor = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      panelProfile.selectionColor,
    );

    PlayerPanel panel({
      required Key key,
      required String id,
      required Widget child,
    }) =>
        PlayerPanel(
          key: key,
          elevated: true,
          role: PlayerPanelRole.battleHud,
          surfaceRole: ProjectPresentationSurfaceRole.battleHud,
          padding: EdgeInsets.all(panelPadding),
          windowStyleOverride: profile == null
              ? null
              : _battleWindowStyle(
                  id: id,
                  shape: panelProfile.shape,
                  padding: panelProfile.padding,
                ),
          surfaceColorOverride: panelSurface,
          borderColorOverride: panelBorder,
          textColorOverride: panelText,
          child: child,
        );

    return RepaintBoundary(
      key: const ValueKey<String>('battle-command-panel'),
      child: SizedBox.expand(
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                flex: 47,
                child: panel(
                  key: const ValueKey<String>('battle-dialogue-panel'),
                  id: 'battle-dialogue',
                  child: _BattleDialoguePane(data: data),
                ),
              ),
              SizedBox(width: PlayerSpacing.xs * spacingScale),
              Expanded(
                flex: 53,
                child: panel(
                  key: const ValueKey<String>('battle-actions-panel'),
                  id: 'battle-actions-${data.panelKind.name}',
                  child: _BattleActionsPane(
                    data: data,
                    onAction: onAction,
                    itemIconBuilder: itemIconBuilder,
                    spacingScale: spacingScale,
                    showProjectIcons:
                        data.panelKind == PlayerBattlePanelKind.commands &&
                            (profile?.showCommandIcons ?? false),
                    selectionColor: selectionColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleDialoguePane extends StatelessWidget {
  const _BattleDialoguePane({required this.data});

  final PlayerBattleViewData data;

  @override
  Widget build(BuildContext context) {
    final visibleText = data.panelKind == PlayerBattlePanelKind.message &&
            data.narrationLines.isNotEmpty
        ? data.narrationLines.last
        : data.prompt;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${data.battleLabel}, ${data.prompt}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (data.forcedReplacement) ...<Widget>[
            Text(
              context.playerL10n.mandatoryReplacement,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.playerTypography.combatStyle(
                Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
              ),
            ),
            const SizedBox(height: PlayerSpacing.xxs),
          ],
          Text(
            visibleText,
            key: const ValueKey<String>('battle-dialogue-prompt'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.playerTypography.combatStyle(
              Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleActionsPane extends StatelessWidget {
  const _BattleActionsPane({
    required this.data,
    required this.onAction,
    required this.itemIconBuilder,
    required this.spacingScale,
    required this.showProjectIcons,
    required this.selectionColor,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final bool showProjectIcons;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final showHeader =
        data.panelKind != PlayerBattlePanelKind.commands || data.canGoBack;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showHeader) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  data.title,
                  key: const ValueKey<String>('battle-actions-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.playerTypography.combatStyle(
                    Theme.of(context).textTheme.titleMedium ??
                        const TextStyle(),
                  ),
                ),
              ),
              if (data.canGoBack)
                IconButton(
                  key: const ValueKey<String>('battle-back'),
                  tooltip: context.playerL10n.back,
                  visualDensity: VisualDensity.compact,
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
          SizedBox(height: PlayerSpacing.xxs * spacingScale),
        ],
        Expanded(
          child: _BattleSeparatedEntries(
            data: data,
            onAction: onAction,
            itemIconBuilder: itemIconBuilder,
            spacingScale: spacingScale,
            showProjectIcons: showProjectIcons,
            selectionColor: selectionColor,
          ),
        ),
      ],
    );
  }
}

class _BattleSeparatedEntries extends StatelessWidget {
  const _BattleSeparatedEntries({
    required this.data,
    required this.onAction,
    required this.itemIconBuilder,
    required this.spacingScale,
    required this.showProjectIcons,
    required this.selectionColor,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final bool showProjectIcons;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    if (data.commands.length <= 4) {
      return _BattleSeparatedGrid(
        key: ValueKey<String>(
          'battle-panel-${data.panelKind.name}-grid',
        ),
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        spacingScale: spacingScale,
        showProjectIcons: showProjectIcons,
        selectionColor: selectionColor,
      );
    }
    return ListView.separated(
      key: ValueKey<String>(
        'battle-panel-${data.panelKind.name}-list',
      ),
      itemCount: data.commands.length,
      separatorBuilder: (context, index) => SizedBox(
        height: PlayerSpacing.xs * spacingScale,
      ),
      itemBuilder: (context, index) => _entry(data.commands[index]),
    );
  }

  Widget _entry(PlayerBattleCommandViewData entry) => _BattleEntryButton(
        entry: entry,
        interactionsEnabled: data.interactionsEnabled,
        autofocus: entry.selected,
        iconBuilder: itemIconBuilder,
        dense: true,
        showSecondaryLabel: false,
        showProjectIcon: showProjectIcons,
        selectionColor: selectionColor,
        onPressed: () => onAction(
          PlayerBattleSelectEntryAction(
            snapshotRevision: data.revision,
            entryIndex: entry.index,
          ),
        ),
      );
}

class _BattleSeparatedGrid extends StatelessWidget {
  const _BattleSeparatedGrid({
    super.key,
    required this.data,
    required this.onAction,
    required this.itemIconBuilder,
    required this.spacingScale,
    required this.showProjectIcons,
    required this.selectionColor,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final bool showProjectIcons;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final rowCount = (data.commands.length + 1) ~/ 2;
    return Column(
      children: <Widget>[
        for (var row = 0; row < rowCount; row++) ...<Widget>[
          if (row > 0) SizedBox(height: PlayerSpacing.xs * spacingScale),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(child: _entry(data.commands[row * 2])),
                SizedBox(width: PlayerSpacing.xs * spacingScale),
                Expanded(
                  child: row * 2 + 1 < data.commands.length
                      ? _entry(data.commands[row * 2 + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _entry(PlayerBattleCommandViewData entry) => _BattleEntryButton(
        entry: entry,
        interactionsEnabled: data.interactionsEnabled,
        autofocus: entry.selected,
        iconBuilder: itemIconBuilder,
        dense: true,
        showSecondaryLabel: false,
        showProjectIcon: showProjectIcons,
        selectionColor: selectionColor,
        onPressed: () => onAction(
          PlayerBattleSelectEntryAction(
            snapshotRevision: data.revision,
            entryIndex: entry.index,
          ),
        ),
      );
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
                      dense: false,
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
    required this.dense,
    this.showSecondaryLabel = true,
    required this.onPressed,
    required this.showProjectIcon,
    required this.selectionColor,
  });

  final PlayerBattleCommandViewData entry;
  final bool interactionsEnabled;
  final bool autofocus;
  final Widget Function(String assetPath)? iconBuilder;
  final bool dense;
  final bool showSecondaryLabel;
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
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final colors = context.playerColors;
    final foreground = enabled ? colors.textPrimary : colors.textSecondary;
    final hasBattlePalette = context.playerSurfacePalette(
          ProjectPresentationSurfaceRole.battleHud,
        ) !=
        null;
    final toneColor = _toneColor(colors, entry.tone);
    final accent = widget.selectionColor ??
        (hasBattlePalette
            ? _commandColor(colors, entry.commandId) ?? toneColor
            : toneColor);
    final surfaceColor = hasBattlePalette
        ? Color.alphaBlend(
            accent.withValues(alpha: entry.selected ? .34 : .24),
            colors.surfaceElevated,
          )
        : entry.selected
            ? accent.withValues(alpha: 0.16)
            : colors.surfaceElevated;
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
          color: surfaceColor,
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
              constraints: BoxConstraints(minHeight: widget.dense ? 48 : 64),
              child: Padding(
                padding: widget.dense
                    ? const EdgeInsets.symmetric(
                        horizontal: PlayerSpacing.xs,
                        vertical: PlayerSpacing.xxs,
                      )
                    : const EdgeInsets.all(PlayerSpacing.sm),
                child: Row(
                  children: <Widget>[
                    if (entry.iconAssetPath case final path?)
                      Padding(
                        padding: EdgeInsets.only(
                          right: widget.dense
                              ? PlayerSpacing.xs
                              : PlayerSpacing.sm,
                        ),
                        child: SizedBox.square(
                          dimension: widget.dense ? 24 : 36,
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
                            maxLines: widget.dense ? 1 : null,
                            overflow:
                                widget.dense ? TextOverflow.ellipsis : null,
                            style: context.playerTypography.combatStyle(
                              (Theme.of(context).textTheme.labelLarge ??
                                      const TextStyle())
                                  .copyWith(color: foreground),
                            ),
                          ),
                          if (widget.showSecondaryLabel &&
                              entry.secondaryLabel.isNotEmpty &&
                              !(widget.dense && largeText))
                            Text(
                              entry.secondaryLabel,
                              maxLines: widget.dense ? 1 : null,
                              overflow:
                                  widget.dense ? TextOverflow.ellipsis : null,
                              style: context.playerTypography.combatStyle(
                                (Theme.of(context).textTheme.bodySmall ??
                                        const TextStyle())
                                    .copyWith(color: foreground),
                              ),
                            ),
                          if (widget.showSecondaryLabel) ...<Widget>[
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
                        ],
                      ),
                    ),
                    if (widget.showSecondaryLabel)
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

bool _usesCanonicalBattleStructure(
  ProjectBattlePresentationProfile? profile,
) =>
    profile == null ||
    (profile.commandLayout == ProjectBattleCommandLayout.grid &&
        profile.commandColumns == 2 &&
        profile.enemyHudPosition == ProjectBattleHudPosition.topStart &&
        profile.playerHudPosition == ProjectBattleHudPosition.bottomEnd);

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

Color? _commandColor(
  PokeMapPlayerColors colors,
  ProjectBattleCommandId? commandId,
) =>
    switch (commandId) {
      ProjectBattleCommandId.fight => colors.primary,
      ProjectBattleCommandId.bag => colors.warning,
      ProjectBattleCommandId.party => colors.success,
      ProjectBattleCommandId.run => colors.focus,
      null => null,
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
