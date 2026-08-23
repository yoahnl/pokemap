import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../localization/player_localizations.dart';
import '../theme/pokemap_player_layout_theme.dart';
import '../theme/pokemap_player_battle_theme.dart';
import '../theme/pokemap_player_theme.dart';
import 'player_hp_tone.dart';
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
    this.moveTypeId,
    this.isBagItem = false,
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
  final String? moveTypeId;
  final bool isBagItem;
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
    this.genderSymbol,
    this.experienceProgress,
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
  final String? genderSymbol;
  final double? experienceProgress;

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
          final portraitViewport = constraints.maxHeight > constraints.maxWidth;
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
                      : portraitViewport
                          ? switch (battle.playerHudPosition) {
                              ProjectBattleHudPosition.bottomStart =>
                                const Alignment(-1, .25),
                              ProjectBattleHudPosition.bottomEnd =>
                                const Alignment(1, .25),
                              _ => _hudAlignment(battle.playerHudPosition),
                            }
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
  });

  final PlayerBattleHudViewData data;
  final String sideId;
  final ProjectBattlePresentationProfile? profile;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final chrome = context.playerBattleChrome;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    const densePadding = PlayerSpacing.xs;
    final paletteSurface = chrome.surface;
    final paletteText = chrome.textPrimary;
    final paletteBorder = chrome.outline;
    final hpRatio = data.maxHp <= 0
        ? 0.0
        : (data.effectiveTargetDisplayedHp / data.maxHp).clamp(0.0, 1.0);
    // One resolver for the three HP bands, shared with the summary sheet.
    final hpColor = playerHpColorFor(
      context,
      hpRatio,
      healthyHex: profile?.hpHealthyColor,
      warningHex: profile?.hpWarningColor,
      dangerHex: profile?.hpDangerColor,
    );
    final statusColor = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
          profile?.statusColor,
        ) ??
        colors.warning;
    final experienceProgress = data.experienceProgress?.clamp(0.0, 1.0);
    final hpBarShape = profile?.hpBarShape ?? ProjectBattleHpBarShape.rounded;
    final showExactHp = profile?.showExactHp ?? sideId == 'player';
    final hudWindowStyle = profile == null
        ? _battleWindowStyle(
            id: 'battle-hud-$sideId',
            shape: ProjectWindowShape.cutCorner,
            padding: dense ? densePadding : 12,
          ).copyWith(
            cornerRadius: 14,
          )
        : _battleWindowStyle(
            id: 'battle-hud-$sideId',
            shape: profile!.hudShape,
            padding: dense ? densePadding : 12,
          );
    return PlayerPanel(
      padding: EdgeInsets.all(
        dense ? densePadding : PlayerSpacing.sm,
      ),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      windowStyleOverride: hudWindowStyle,
      surfaceColorOverride: paletteSurface,
      borderColorOverride: paletteBorder,
      textColorOverride: paletteText,
      child: Semantics(
        key: ValueKey<String>('battle-hud-semantics-$sideId'),
        container: true,
        label: '${data.ownerLabel}, ${data.speciesLabel}'
            '${data.genderSymbol == null ? '' : ' ${data.genderSymbol}'}, '
            '${context.playerL10n.levelLabel(data.level)}, '
            '${context.playerL10n.hpLabel(data.currentHp, data.maxHp)}'
            '${data.statusLabel == null ? '' : ', ${data.statusLabel}'}'
            '${experienceProgress == null ? '' : ', ${context.playerL10n.experienceProgressLabel((experienceProgress * 100).round())}'}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (!largeText)
                    if (data.statusLabel case final status?) ...<Widget>[
                      Flexible(
                        child: _BattleStatusBadge(
                          key: ValueKey<String>(
                            'battle-status-badge-$sideId',
                          ),
                          label: status,
                          color: statusColor,
                          dense: dense,
                        ),
                      ),
                      const SizedBox(width: PlayerSpacing.xxs),
                    ],
                  Expanded(
                    child: Text(
                      data.speciesLabel,
                      key: ValueKey<String>('battle-species-$sideId'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.playerTypography
                          .combatStyle(
                            (dense
                                    ? Theme.of(context).textTheme.labelMedium
                                    : Theme.of(context)
                                        .textTheme
                                        .titleMedium) ??
                                const TextStyle(),
                          )
                          .copyWith(
                            color: paletteText,
                            fontWeight: FontWeight.w800,
                            height: largeText ? 1 : 1.1,
                          ),
                    ),
                  ),
                  if (data.genderSymbol case final gender?) ...<Widget>[
                    const SizedBox(width: PlayerSpacing.xxs),
                    _BattleGenderSymbol(
                      key: ValueKey<String>('battle-gender-$sideId'),
                      symbol: gender,
                    ),
                  ],
                  if ((profile?.showLevel ?? true) &&
                      (!largeText || !dense)) ...<Widget>[
                    const SizedBox(width: PlayerSpacing.xxs),
                    Text(
                      context.playerL10n.levelLabel(data.level),
                      key: ValueKey<String>('battle-level-$sideId'),
                      maxLines: 1,
                      style: context.playerTypography
                          .numbersStyle(
                            Theme.of(context).textTheme.labelSmall ??
                                const TextStyle(),
                          )
                          .copyWith(
                            color: paletteText,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                    ),
                  ],
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: dense ? 2 : PlayerSpacing.xxs,
                ),
                child: SizedBox(
                  key: ValueKey<String>('battle-hud-divider-$sideId'),
                  height: 1,
                  child: ColoredBox(
                    color: paletteBorder.withValues(alpha: .48),
                  ),
                ),
              ),
              // Recette 2026-08-23 (22-57-18) : la barre animait pendant que
              // le texte affichait l'état FINAL (data.currentHp) — le nombre
              // sautait de 15/15 à 9/15 avant tout impact. Un SEUL tween
              // pilote désormais la barre ET le texte : même valeur, même
              // horloge, en PV réels pour l'arrondi du nombre.
              TweenAnimationBuilder<double>(
                key: ValueKey<int>(data.hpTweenRevision),
                tween: Tween<double>(
                  begin: data.effectiveDisplayedHp.toDouble(),
                  end: data.effectiveTargetDisplayedHp.toDouble(),
                ),
                duration: context.playerMotion.standard == Duration.zero
                    ? Duration.zero
                    : data.hpTweenDuration ?? context.playerMotion.standard,
                builder: (context, animatedHp, _) => Row(
                  children: <Widget>[
                    if (!largeText) ...<Widget>[
                      Text(
                        context.playerL10n.hpAbbreviation,
                        key: ValueKey<String>('battle-hp-label-$sideId'),
                        style: context.playerTypography
                            .combatStyle(
                              Theme.of(context).textTheme.labelSmall ??
                                  const TextStyle(),
                            )
                            .copyWith(
                              color: hpColor,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                      ),
                      const SizedBox(width: PlayerSpacing.xxs),
                    ],
                    Expanded(
                      child: _BattleHpBar(
                        key: ValueKey<String>(
                          'battle-hp-${hpBarShape.name}-$sideId',
                        ),
                        value: data.maxHp <= 0
                            ? 0
                            : (animatedHp / data.maxHp).clamp(0.0, 1.0),
                        shape: hpBarShape,
                        color: hpColor,
                        backgroundColor:
                            colors.outline.withValues(alpha: 0.35),
                        height: dense
                            ? largeText
                                ? 4
                                : 5
                            : 6,
                      ),
                    ),
                    if (showExactHp && !largeText) ...<Widget>[
                      const SizedBox(width: PlayerSpacing.xxs),
                      Text(
                        context.playerL10n.hpFraction(
                          animatedHp.round(),
                          data.maxHp,
                        ),
                        key: ValueKey<String>('battle-exact-hp-$sideId'),
                        maxLines: 1,
                        style: context.playerTypography
                            .numbersStyle(
                              Theme.of(context).textTheme.labelSmall ??
                                  const TextStyle(),
                            )
                            .copyWith(
                              color: paletteText,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (experienceProgress case final progress?
                  when !dense || !largeText) ...<Widget>[
                SizedBox(height: dense ? 2 : PlayerSpacing.xxs),
                Row(
                  children: <Widget>[
                    if (!largeText) ...<Widget>[
                      Text(
                        context.playerL10n.experienceAbbreviation,
                        key: ValueKey<String>('battle-xp-label-$sideId'),
                        style: context.playerTypography
                            .numbersStyle(
                              Theme.of(context).textTheme.labelSmall ??
                                  const TextStyle(),
                            )
                            .copyWith(
                              color: chrome.water,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                      ),
                      const SizedBox(width: PlayerSpacing.xxs),
                    ],
                    Expanded(
                      child: _BattleExperienceBar(
                        key: ValueKey<String>('battle-xp-$sideId'),
                        value: progress,
                        color: chrome.water,
                        backgroundColor: chrome.outline.withValues(alpha: 0.28),
                        height: dense ? 2 : 3,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleStatusBadge extends StatelessWidget {
  const _BattleStatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.dense,
  });

  final String label;
  final Color color;
  final bool dense;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dense ? 38 : 72),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: color.withValues(alpha: 0.9)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.playerTypography
                  .combatStyle(
                    Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
                  )
                  .copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
          ),
        ),
      );
}

class _BattleExperienceBar extends StatelessWidget {
  const _BattleExperienceBar({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    required this.height,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(PlayerRadii.pill),
        child: LinearProgressIndicator(
          value: value,
          minHeight: height,
          color: color,
          backgroundColor: backgroundColor,
        ),
      );
}

class _BattleGenderSymbol extends StatelessWidget {
  const _BattleGenderSymbol({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) => Semantics(
        label: symbol,
        child: Icon(
          switch (symbol) {
            '♀' => Icons.female_rounded,
            '♂' => Icons.male_rounded,
            _ => Icons.circle_outlined,
          },
          size: 14,
          color: switch (symbol) {
            '♀' => context.playerColors.danger,
            '♂' => context.playerColors.focus,
            _ => context.playerColors.textSecondary,
          },
        ),
      );
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
        stacked: compactPortrait,
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
                    // Radial needs a box that can host a card left, right and
                    // centred: in a narrow landscape dock it overflowed the
                    // panel and clipped the bottom command. The authored layout
                    // still wins wherever it fits; otherwise the 2x2 grid that
                    // already works in portrait takes over.
                    const radialMinimumWidth = 420.0;
                    const radialMinimumHeight = 216.0;
                    final radialFits =
                        entryConstraints.maxWidth >= radialMinimumWidth &&
                            (!entryConstraints.hasBoundedHeight ||
                                entryConstraints.maxHeight >=
                                    radialMinimumHeight);
                    // The key names what was RENDERED, not what was authored,
                    // so a fallback cannot masquerade as a radial dock.
                    final renderedLayout =
                        effectiveLayout == ProjectBattleCommandLayout.radial &&
                                !radialFits
                            ? ProjectBattleCommandLayout.grid
                            : effectiveLayout;
                    if (renderedLayout == ProjectBattleCommandLayout.radial) {
                      return _BattleRadialCommandLayout(
                        key: ValueKey<String>(
                          'battle-panel-${data.panelKind.name}-${renderedLayout.name}',
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
                        'battle-panel-${data.panelKind.name}-${renderedLayout.name}',
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
    required this.stacked,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final ProjectBattlePresentationProfile? profile;
  final ProjectBattlePanelPresentationProfile panelProfile;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final resolvedPanelPadding = stacked
        ? panelProfile.padding
        : math.min(panelProfile.padding, PlayerSpacing.xs);
    final panelPadding = resolvedPanelPadding * spacingScale;
    final chrome = context.playerBattleChrome;
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
        ) ??
        chrome.focus;
    final surface = panelSurface ?? chrome.surface;
    final border = panelBorder ?? chrome.outline;
    final foreground = panelText ?? chrome.textPrimary;
    final divider = border.withValues(alpha: .62);
    final onBack = data.canGoBack && data.interactionsEnabled
        ? () => onAction(
              PlayerBattleBackAction(snapshotRevision: data.revision),
            )
        : null;
    final dialogue = KeyedSubtree(
      key: const ValueKey<String>('battle-dialogue-panel'),
      child: _BattleDialoguePane(data: data, onBack: onBack),
    );
    final actions = KeyedSubtree(
      key: const ValueKey<String>('battle-actions-panel'),
      child: _BattleActionsPane(
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        spacingScale: spacingScale,
        showProjectIcons: data.panelKind == PlayerBattlePanelKind.commands &&
            (profile?.showCommandIcons ?? false),
        selectionColor: selectionColor,
        foregroundColor: foreground,
      ),
    );

    return PlayerPanel(
      key: const ValueKey<String>('battle-command-panel'),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      padding: EdgeInsets.all(panelPadding),
      windowStyleOverride: _battleWindowStyle(
        id: 'battle-field-manual-${data.panelKind.name}',
        shape:
            profile == null ? ProjectWindowShape.cutCorner : panelProfile.shape,
        padding: resolvedPanelPadding,
      ),
      surfaceColorOverride: surface,
      borderColorOverride: border,
      textColorOverride: foreground,
      child: RepaintBoundary(
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (!stacked) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(flex: 36, child: dialogue),
                    VerticalDivider(
                      width: PlayerSpacing.xs * spacingScale,
                      thickness: 1,
                      color: divider,
                    ),
                    Expanded(flex: 64, child: actions),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Flexible(
                    flex: largeText
                        ? 5
                        : data.forcedReplacement
                            ? 3
                            : 2,
                    child: dialogue,
                  ),
                  Divider(
                    height: PlayerSpacing.sm * spacingScale,
                    thickness: 1,
                    color: divider,
                  ),
                  Expanded(
                    flex: data.commands.any((entry) => entry.isBagItem) ? 8 : 6,
                    child: actions,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BattleDialoguePane extends StatelessWidget {
  const _BattleDialoguePane({required this.data, required this.onBack});

  final PlayerBattleViewData data;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final visibleText = data.panelKind == PlayerBattlePanelKind.message &&
            data.narrationLines.isNotEmpty
        ? data.narrationLines.last
        : data.prompt;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${data.battleLabel}, ${data.prompt}',
      child: Row(
        children: <Widget>[
          Icon(
            Icons.eco_outlined,
            size: 18,
            color: context.playerBattleChrome.outline,
          ),
          const SizedBox(width: PlayerSpacing.xs),
          Expanded(
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
                      Theme.of(context).textTheme.labelSmall ??
                          const TextStyle(),
                    ),
                  ),
                  const SizedBox(height: PlayerSpacing.xxs),
                ],
                Text(
                  visibleText,
                  key: const ValueKey<String>('battle-dialogue-prompt'),
                  maxLines: largeText ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.playerTypography
                      .combatStyle(
                        Theme.of(context).textTheme.bodyLarge ??
                            const TextStyle(),
                      )
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(width: PlayerSpacing.xs),
          if (onBack == null)
            Icon(
              Icons.eco_outlined,
              size: 18,
              color: context.playerBattleChrome.outline,
            )
          else
            IconButton(
              key: const ValueKey<String>('battle-back'),
              tooltip: context.playerL10n.back,
              visualDensity: VisualDensity.compact,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
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
    required this.foregroundColor,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final bool showProjectIcons;
  final Color? selectionColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(color: foregroundColor),
      child: _BattleSeparatedEntries(
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        spacingScale: spacingScale,
        showProjectIcons: showProjectIcons,
        selectionColor: selectionColor,
      ),
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
    final bagEntries = data.commands.isNotEmpty &&
        data.commands.every((entry) => entry.isBagItem);
    if (bagEntries) {
      return _BattleBagGrid(
        key: ValueKey<String>(
          'battle-panel-${data.panelKind.name}-bag-grid',
        ),
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        spacingScale: spacingScale,
        selectionColor: selectionColor,
      );
    }
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
        showSecondaryLabel: entry.moveTypeId != null || entry.isBagItem,
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
        showSecondaryLabel: entry.moveTypeId != null || entry.isBagItem,
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

class _BattleBagGrid extends StatelessWidget {
  const _BattleBagGrid({
    super.key,
    required this.data,
    required this.onAction,
    required this.itemIconBuilder,
    required this.spacingScale,
    required this.selectionColor,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 300 ? 2 : 1;
        return GridView.builder(
          key: const ValueKey<String>('battle-bag-items'),
          padding: EdgeInsets.zero,
          itemCount: data.commands.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: PlayerSpacing.xs * spacingScale,
            mainAxisSpacing: PlayerSpacing.xs * spacingScale,
            mainAxisExtent: largeText ? 64 : 56,
          ),
          itemBuilder: (context, index) {
            final entry = data.commands[index];
            return _BattleEntryButton(
              entry: entry,
              interactionsEnabled: data.interactionsEnabled,
              autofocus: entry.selected,
              iconBuilder: itemIconBuilder,
              dense: true,
              showSecondaryLabel: true,
              showProjectIcon: false,
              selectionColor: selectionColor,
              onPressed: () => onAction(
                PlayerBattleSelectEntryAction(
                  snapshotRevision: data.revision,
                  entryIndex: entry.index,
                ),
              ),
            );
          },
        );
      },
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
    final bagItem = entry.isBagItem;
    final moveTypeId = entry.moveTypeId;
    final chrome = context.playerBattleChrome;
    final moveTypeLabel = moveTypeId == null
        ? null
        : context.playerL10n.battleMoveType(moveTypeId);
    final toneColor = _toneColor(colors, entry.tone);
    final accent = moveTypeId == null
        ? _commandColor(colors, entry.commandId) ?? toneColor
        : _moveTypeColor(context, moveTypeId);
    final selectionAccent = widget.selectionColor ?? chrome.focus;
    final frameAccent = entry.selected || _focused
        ? selectionAccent
        : accent.withValues(alpha: .72);
    final surfaceColor = entry.selected || _focused
        ? chrome.surfaceSelected
        : chrome.surfaceRaised;
    final foreground = enabled ? chrome.textPrimary : chrome.textSecondary;
    final bagCategoryLabel = bagItem
        ? _battleBagCategoryLabel(context.playerL10n, entry.tone)
        : null;
    final details = <String>[
      if (moveTypeLabel != null) moveTypeLabel,
      if (bagCategoryLabel != null) bagCategoryLabel,
      if (entry.tertiaryLabel case final tertiary?) tertiary,
      if (entry.trailingLabel case final trailing?) trailing,
      if (!bagItem)
        if (entry.statusLabel case final status?) status,
      if (bagItem && !entry.enabled) context.playerL10n.actionUnavailable,
    ].join(', ');
    final disabledReason =
        details.isEmpty ? context.playerL10n.actionUnavailable : details;
    final shape = BeveledRectangleBorder(
      borderRadius: BorderRadius.circular(PlayerRadii.sm),
      side: BorderSide(
        color: frameAccent,
        width: _focused || entry.selected ? 2.5 : 1.25,
      ),
    );
    return Semantics(
      key: ValueKey<String>('battle-entry-${entry.index}'),
      button: true,
      enabled: enabled,
      selected: entry.selected,
      label: entry.primaryLabel,
      hint: enabled ? details : disabledReason,
      child: Tooltip(
        message: enabled && details.isNotEmpty
            ? '${entry.primaryLabel} · $details'
            : enabled
                ? entry.primaryLabel
                : disabledReason,
        child: Material(
          color: surfaceColor,
          elevation: entry.selected || _focused ? 3 : 0,
          shadowColor: chrome.underplate,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            onTap: enabled ? widget.onPressed : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.dense ? 48 : 64),
              child: Padding(
                padding: widget.dense
                    ? EdgeInsets.symmetric(
                        horizontal: PlayerSpacing.xs,
                        vertical: largeText ? 3 : PlayerSpacing.xxs,
                      )
                    : const EdgeInsets.all(PlayerSpacing.sm),
                child: LayoutBuilder(
                  builder: (context, entryConstraints) {
                    final showCursor = entry.selected &&
                        entryConstraints.maxWidth >= 150 &&
                        !largeText;
                    return Row(
                      children: <Widget>[
                        if (showCursor) ...<Widget>[
                          Icon(
                            Icons.play_arrow_rounded,
                            key: ValueKey<String>(
                              'battle-selection-cursor-${entry.index}',
                            ),
                            size: widget.dense ? 20 : 24,
                            color: selectionAccent,
                          ),
                          const SizedBox(width: PlayerSpacing.xxs),
                        ],
                        Expanded(
                          child: bagItem
                              ? _BattleBagEntryContent(
                                  entry: entry,
                                  accent: accent,
                                  foreground: foreground,
                                  dense: widget.dense,
                                  showDetails:
                                      widget.showSecondaryLabel && !largeText,
                                  iconBuilder: widget.iconBuilder,
                                )
                              : moveTypeLabel == null
                                  ? Row(
                                      children: <Widget>[
                                        if (entry.iconAssetPath
                                            case final path?)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              right: widget.dense
                                                  ? PlayerSpacing.xs
                                                  : PlayerSpacing.sm,
                                            ),
                                            child: SizedBox.square(
                                              dimension: widget.dense ? 24 : 36,
                                              child: widget.iconBuilder
                                                      ?.call(path) ??
                                                  Icon(
                                                    Icons.inventory_2_outlined,
                                                    color: accent,
                                                  ),
                                            ),
                                          ),
                                        if (entry.iconAssetPath == null &&
                                            widget.showProjectIcon &&
                                            entry.commandIcon != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: PlayerSpacing.sm,
                                            ),
                                            child: Icon(
                                              _commandIcon(entry.commandIcon!),
                                              color: accent,
                                            ),
                                          ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Text(
                                                entry.primaryLabel,
                                                maxLines:
                                                    widget.dense ? 1 : null,
                                                overflow: widget.dense
                                                    ? TextOverflow.ellipsis
                                                    : null,
                                                style: context.playerTypography
                                                    .combatStyle(
                                                  (Theme.of(context)
                                                              .textTheme
                                                              .labelLarge ??
                                                          const TextStyle())
                                                      .copyWith(
                                                          color: foreground),
                                                ),
                                              ),
                                              if (widget.showSecondaryLabel &&
                                                  entry.secondaryLabel
                                                      .isNotEmpty &&
                                                  !(widget.dense && largeText))
                                                Text(
                                                  entry.secondaryLabel,
                                                  maxLines:
                                                      widget.dense ? 1 : null,
                                                  overflow: widget.dense
                                                      ? TextOverflow.ellipsis
                                                      : null,
                                                  style: context
                                                      .playerTypography
                                                      .combatStyle(
                                                    (Theme.of(context)
                                                                .textTheme
                                                                .bodySmall ??
                                                            const TextStyle())
                                                        .copyWith(
                                                            color: foreground),
                                                  ),
                                                ),
                                              if (widget
                                                  .showSecondaryLabel) ...<Widget>[
                                                if (entry.tertiaryLabel
                                                    case final label?)
                                                  Text(
                                                    label,
                                                    style: context
                                                        .playerTypography
                                                        .combatStyle(
                                                      Theme.of(context)
                                                              .textTheme
                                                              .bodySmall ??
                                                          const TextStyle(),
                                                    ),
                                                  ),
                                                if (entry.statusLabel
                                                    case final status?)
                                                  Text(
                                                    status,
                                                    style: context
                                                        .playerTypography
                                                        .combatStyle(
                                                      (Theme.of(context)
                                                                  .textTheme
                                                                  .labelSmall ??
                                                              const TextStyle())
                                                          .copyWith(
                                                              color: accent),
                                                    ),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (widget.showSecondaryLabel)
                                          if (entry.trailingLabel
                                              case final trailing?)
                                            Text(
                                              trailing,
                                              style: context.playerTypography
                                                  .combatStyle(
                                                Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium ??
                                                    const TextStyle(),
                                              ),
                                            ),
                                      ],
                                    )
                                  : _BattleMoveEntryContent(
                                      entry: entry,
                                      typeLabel: moveTypeLabel,
                                      accent: accent,
                                      foreground: foreground,
                                      dense: widget.dense,
                                      showDetails: widget.showSecondaryLabel &&
                                          !largeText,
                                      selected: entry.selected,
                                    ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleBagEntryContent extends StatelessWidget {
  const _BattleBagEntryContent({
    required this.entry,
    required this.accent,
    required this.foreground,
    required this.dense,
    required this.showDetails,
    required this.iconBuilder,
  });

  final PlayerBattleCommandViewData entry;
  final Color accent;
  final Color foreground;
  final bool dense;
  final bool showDetails;
  final Widget Function(String assetPath)? iconBuilder;

  @override
  Widget build(BuildContext context) {
    final chrome = context.playerBattleChrome;
    final iconSize = dense ? 36.0 : 44.0;
    final category = _battleBagCategoryLabel(
      context.playerL10n,
      entry.tone,
    );
    final badgeSurface = accent.withValues(alpha: .2);
    final badgeForeground = accent;
    final path = entry.iconAssetPath;
    final icon = path == null
        ? Icon(Icons.inventory_2_rounded, color: accent)
        : iconBuilder?.call(path) ??
            Icon(Icons.inventory_2_rounded, color: accent);

    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: ShapeDecoration(
            color: chrome.surfaceSelected,
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(PlayerRadii.sm),
              side: BorderSide(color: accent.withValues(alpha: .68)),
            ),
          ),
          child: SizedBox.square(
            dimension: iconSize,
            child: Padding(
              padding: const EdgeInsets.all(PlayerSpacing.xxs),
              child: KeyedSubtree(
                key: ValueKey<String>('battle-bag-thumbnail-${entry.index}'),
                child: icon,
              ),
            ),
          ),
        ),
        SizedBox(width: dense ? PlayerSpacing.xs : PlayerSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      entry.primaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.playerTypography.combatStyle(
                        (Theme.of(context).textTheme.labelLarge ??
                                const TextStyle())
                            .copyWith(color: foreground),
                      ),
                    ),
                  ),
                  if (entry.trailingLabel case final quantity?) ...<Widget>[
                    const SizedBox(width: PlayerSpacing.xxs),
                    Text(
                      quantity,
                      key: ValueKey<String>(
                        'battle-bag-quantity-${entry.index}',
                      ),
                      maxLines: 1,
                      style: context.playerTypography.combatStyle(
                        (Theme.of(context).textTheme.labelMedium ??
                                const TextStyle())
                            .copyWith(color: foreground),
                      ),
                    ),
                  ],
                ],
              ),
              if (showDetails) ...<Widget>[
                const SizedBox(height: PlayerSpacing.xxs),
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: badgeSurface,
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: accent.withValues(alpha: .74),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PlayerSpacing.xs,
                      vertical: 1,
                    ),
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.playerTypography.combatStyle(
                        (Theme.of(context).textTheme.labelSmall ??
                                const TextStyle())
                            .copyWith(color: badgeForeground),
                      ),
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

class _BattleMoveEntryContent extends StatelessWidget {
  const _BattleMoveEntryContent({
    required this.entry,
    required this.typeLabel,
    required this.accent,
    required this.foreground,
    required this.dense,
    required this.showDetails,
    required this.selected,
  });

  final PlayerBattleCommandViewData entry;
  final String typeLabel;
  final Color accent;
  final Color foreground;
  final bool dense;
  final bool showDetails;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final category = context.playerL10n.battleMoveCategory(
      entry.tertiaryLabel,
    );
    final detailLabel = <String>[
      typeLabel,
      if (category != null) category,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          entry.primaryLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.playerTypography
              .combatStyle(
                Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
              )
              .copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
        ),
        if (showDetails) ...<Widget>[
          SizedBox(height: dense ? 3 : PlayerSpacing.xxs),
          Row(
            children: <Widget>[
              if (selected) ...<Widget>[
                Icon(
                  _moveTypeIcon(entry.moveTypeId),
                  size: dense ? 16 : 18,
                  color: accent,
                ),
                const SizedBox(width: PlayerSpacing.xxs),
                Expanded(
                  child: Text(
                    detailLabel,
                    key: ValueKey<String>(
                      'battle-move-detail-${entry.index}',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.playerTypography
                        .combatStyle(
                          Theme.of(context).textTheme.labelSmall ??
                              const TextStyle(),
                        )
                        .copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ] else
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _BattleMoveInfoBadge(
                      label: typeLabel,
                      background: accent.withValues(alpha: .16),
                      foreground: accent,
                      border: accent.withValues(alpha: .72),
                    ),
                  ),
                ),
              if (entry.trailingLabel case final pp?) ...<Widget>[
                const SizedBox(width: PlayerSpacing.xxs),
                Text(
                  pp,
                  maxLines: 1,
                  style: context.playerTypography
                      .numbersStyle(
                        Theme.of(context).textTheme.labelSmall ??
                            const TextStyle(),
                      )
                      .copyWith(
                        color: context.playerBattleChrome.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _BattleMoveInfoBadge extends StatelessWidget {
  const _BattleMoveInfoBadge({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: ShapeDecoration(
          color: background,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: border, width: 1.25),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.playerTypography
                .numbersStyle(
                  Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
                )
                .copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
          ),
        ),
      );
}

class _BattleHpBar extends StatelessWidget {
  const _BattleHpBar({
    super.key,
    required this.value,
    required this.shape,
    required this.color,
    required this.backgroundColor,
    required this.height,
  });

  final double value;
  final ProjectBattleHpBarShape shape;
  final Color color;
  final Color backgroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (shape == ProjectBattleHpBarShape.segmented) {
      final active = (value * 10).ceil();
      return LayoutBuilder(
        builder: (context, constraints) {
          final gap = math.min(2.0, constraints.maxWidth / 40);
          return Row(
            children: <Widget>[
              for (var index = 0; index < 10; index++) ...<Widget>[
                Expanded(
                  child: SizedBox(
                    height: height,
                    child: ColoredBox(
                      color: index < active ? color : backgroundColor,
                    ),
                  ),
                ),
                if (index != 9) SizedBox(width: gap),
              ],
            ],
          );
        },
      );
    }
    final indicator = LinearProgressIndicator(
      minHeight: height,
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
      borderWidth: 2,
      cornerRadius: 12,
      contentPadding: padding.round(),
      shadowElevation: 4,
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

IconData _moveTypeIcon(String? typeId) =>
    switch (typeId?.trim().toLowerCase()) {
      'water' || 'ice' => Icons.water_drop_rounded,
      'fire' => Icons.local_fire_department_rounded,
      'electric' => Icons.bolt_rounded,
      'grass' || 'bug' => Icons.eco_rounded,
      _ => Icons.circle_outlined,
    };

Color _moveTypeColor(BuildContext context, String typeId) {
  final colors = context.playerColors;
  final chrome = context.playerBattleChrome;
  return switch (typeId.trim().toLowerCase()) {
    'fire' => colors.danger,
    'water' || 'ice' => chrome.water,
    'flying' => colors.focus,
    'electric' => colors.warning,
    'grass' || 'bug' => colors.success,
    'fighting' => Color.alphaBlend(
        colors.danger.withValues(alpha: .72),
        colors.warning,
      ),
    'poison' || 'psychic' || 'ghost' || 'fairy' => colors.primary,
    'ground' || 'rock' => Color.alphaBlend(
        colors.warning.withValues(alpha: .76),
        colors.outline,
      ),
    'dragon' => Color.alphaBlend(
        colors.primary.withValues(alpha: .58),
        colors.focus,
      ),
    'dark' => Color.alphaBlend(
        colors.scrim.withValues(alpha: .72),
        colors.outline,
      ),
    'steel' => colors.outline,
    'normal' => chrome.normal,
    _ => chrome.textSecondary,
  };
}

String _battleBagCategoryLabel(
  PokeMapPlayerLocalizations localizations,
  PlayerBattleEntryTone tone,
) =>
    switch (tone) {
      PlayerBattleEntryTone.medicine => localizations.battleBagMedicine,
      PlayerBattleEntryTone.capture => localizations.battleBagCapture,
      _ => localizations.battleBagOther,
    };

Color _toneColor(
  PokeMapPlayerColors colors,
  PlayerBattleEntryTone tone,
) {
  return switch (tone) {
    PlayerBattleEntryTone.medicine => colors.success,
    PlayerBattleEntryTone.attack ||
    PlayerBattleEntryTone.capture =>
      colors.primary,
    PlayerBattleEntryTone.special => colors.focus,
    PlayerBattleEntryTone.support ||
    PlayerBattleEntryTone.switching =>
      colors.warning,
    PlayerBattleEntryTone.disabled => colors.textSecondary,
    PlayerBattleEntryTone.neutral => colors.outline,
  };
}
