import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../foundation/player_components.dart';
import '../foundation/player_input_scope.dart';
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

enum PlayerBattleDisplay { full, hudOnly, commandsOnly }

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
    this.experienceProgressTarget,
    this.xpTweenDuration,
    this.xpTweenRevision = 0,
    this.isRevealed = true,
  });

  /// BETA-BAT-028 : la barre est-elle entrée en scène ? Pendant l'intro, la
  /// référence les fait glisser après le message d'apparition — l'ennemi
  /// depuis le haut, le joueur depuis le bas.
  final bool isRevealed;

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
  final double? experienceProgressTarget;
  final Duration? xpTweenDuration;
  final int xpTweenRevision;

  int get effectiveDisplayedHp => displayedHp ?? currentHp;

  int get effectiveTargetDisplayedHp =>
      targetDisplayedHp ?? effectiveDisplayedHp;

  double? get effectiveTargetExperienceProgress =>
      experienceProgressTarget ?? experienceProgress;
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
final class PlayerBattleAdditionalHud {
  const PlayerBattleAdditionalHud({
    required this.identity,
    required this.rect,
    required this.data,
    required this.isPlayerSide,
  });

  final String identity;
  final Rect rect;
  final PlayerBattleHudViewData data;
  final bool isPlayerSide;
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
    this.additionalHuds = const [],
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
  final List<PlayerBattleAdditionalHud> additionalHuds;
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
    this.display = PlayerBattleDisplay.full,
    this.onPanelTargeted,
    this.onHudTargeted,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final bool paintBackground;
  final PlayerBattleDisplay display;
  final ValueChanged<PlayerBattlePanelKind>? onPanelTargeted;
  final VoidCallback? onHudTargeted;

  @override
  Widget build(BuildContext context) => PlayerSurfacePaletteScope(
    role: ProjectPresentationSurfaceRole.battleHud,
    paintBackground: paintBackground,
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    if (display == PlayerBattleDisplay.commandsOnly) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PlayerSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) => _BattleSeparatedCommandDock(
              data: data,
              onAction: onAction,
              itemIconBuilder: itemIconBuilder,
              spacingScale: 1,
              profile: context.playerBattleProfile,
              panelProfile: _panelProfile(
                context.playerBattleProfile,
                data.panelKind,
              ),
              stacked: true,
              companion: true,
            ),
          ),
        ),
      );
    }
    if (data.viewportLayout case final layout?
        when data.additionalHuds.isNotEmpty ||
            _usesCanonicalBattleStructure(context.playerBattleProfile)) {
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
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        if ((viewportSize.width - layout.viewportSize.width).abs() > 0.5 ||
            (viewportSize.height - layout.viewportSize.height).abs() > 0.5) {
          return const SizedBox.shrink();
        }
        final safe = MediaQuery.paddingOf(context);
        final captionRect = layout.panelRect.isEmpty
            ? Rect.fromLTRB(
                math.max(18, safe.left),
                viewportSize.height - math.max(18, safe.bottom) - 80,
                viewportSize.width - math.max(18, safe.right),
                viewportSize.height - math.max(18, safe.bottom),
              )
            : layout.panelRect;
        final compactPortrait =
            viewportSize.width < 480 &&
            viewportSize.height > viewportSize.width;
        final resolved = context.playerLayoutTheme?.tryResolve(
          ProjectPresentationSurfaceRole.battleHud,
          constraints,
        );
        final breakpoint =
            resolved?.breakpoint ??
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
          key: ValueKey<String>('player-battle-responsive-${breakpoint.name}'),
          children: <Widget>[
            for (final hud in data.additionalHuds)
              Positioned.fromRect(
                key: ValueKey(hud.identity),
                rect: hud.rect,
                child: AnimatedSlide(
                  offset: hud.data.isRevealed
                      ? Offset.zero
                      : Offset(0, hud.isPlayerSide ? 2 : -2),
                  duration: context.playerMotion.standard == Duration.zero
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: _BattleHud(
                    data: hud.data,
                    sideId: hud.isPlayerSide ? 'player' : 'enemy',
                    identity: hud.identity,
                    profile: battle,
                    dense: true,
                  ),
                ),
              ),
            Positioned.fromRect(
              rect: layout.enemyHudRect,
              // BETA-BAT-028 : parité `show_team_info` — la barre glisse en
              // 0,2 s après le message d'apparition, l'ennemi depuis le haut.
              child: AnimatedSlide(
                offset: data.enemy.isRevealed
                    ? Offset.zero
                    : const Offset(0, -2),
                duration: context.playerMotion.standard == Duration.zero
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
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
            ),
            Positioned.fromRect(
              rect: layout.playerHudRect,
              // Le joueur glisse depuis le BAS, comme la référence.
              child: AnimatedSlide(
                offset: data.player.isRevealed
                    ? Offset.zero
                    : const Offset(0, 2),
                duration: context.playerMotion.standard == Duration.zero
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                curve: Curves.easeOut,
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
            ),
            if (display == PlayerBattleDisplay.hudOnly &&
                data.panelKind == PlayerBattlePanelKind.message)
              Positioned.fromRect(
                rect: captionRect,
                child: _BattlePrimaryDialogue(data: data, profile: battle),
              )
            else if (display != PlayerBattleDisplay.hudOnly)
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
          final breakpoint =
              resolved?.breakpoint ??
              const ProjectPresentationLayoutResolver().classify(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
              );
          final compact = resolved == null
              ? contentWidth < 560
              : breakpoint == ProjectPresentationBreakpoint.compact;
          final compactPortrait =
              constraints.maxWidth < 480 &&
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
          final panelMaxWidth = resolved == null
              ? 720.0
              : contentWidth * resolved.maxWidthFactor;
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
                          ProjectBattleHudPosition.bottomEnd => const Alignment(
                            1,
                            .25,
                          ),
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
                if (display == PlayerBattleDisplay.hudOnly &&
                    data.panelKind == PlayerBattlePanelKind.message)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: contentWidth,
                      height: math.min(120, contentHeight * .24),
                      child: _BattlePrimaryDialogue(
                        data: data,
                        profile: battle,
                      ),
                    ),
                  )
                else if (display != PlayerBattleDisplay.hudOnly)
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
    this.identity,
    required this.profile,
    required this.dense,
  });

  final PlayerBattleHudViewData data;
  final String sideId;
  final String? identity;
  final ProjectBattlePresentationProfile? profile;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final chrome = context.playerBattleChrome;
    final hpRatio = data.maxHp <= 0
        ? 0.0
        : (data.effectiveTargetDisplayedHp / data.maxHp).clamp(0.0, 1.0);
    final hpColor = hpRatio > .5 && profile?.hpHealthyColor == null
        ? chrome.hpHealthy
        : playerHpColorFor(
            context,
            hpRatio,
            healthyHex: profile?.hpHealthyColor,
            warningHex: profile?.hpWarningColor,
            dangerHex: profile?.hpDangerColor,
          );
    final usesLigueShape =
        profile == null || profile?.hudShape == ProjectWindowShape.rounded;
    final showExactHp = profile?.showExactHp ?? sideId == 'player';
    final hpBarShape = profile?.hpBarShape ?? ProjectBattleHpBarShape.rounded;
    final experience = data.experienceProgress?.clamp(0.0, 1.0);
    final text = context.playerTypography
        .combatStyle(const TextStyle())
        .copyWith(
          color: chrome.hudText,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.1,
          letterSpacing: -.3,
        );
    final number = context.playerTypography
        .numbersStyle(const TextStyle())
        .copyWith(
          color: chrome.hudText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.1,
          letterSpacing: 0,
        );
    return Material(
      color: chrome.hudSurface,
      shape: switch (profile?.hudShape) {
        ProjectWindowShape.rectangle => const RoundedRectangleBorder(),
        ProjectWindowShape.capsule => const StadiumBorder(),
        ProjectWindowShape.cutCorner => const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        ProjectWindowShape.speech => const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        _ => _BattleBevelShape(accent: chrome.focus, leading: true),
      },
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 6, 20, 6),
        child: LayoutBuilder(
          builder: (context, constraints) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Semantics(
                key: ValueKey<String>(
                  'battle-hud-semantics-${identity ?? sideId}',
                ),
                container: true,
                label:
                    '${data.ownerLabel}, ${data.speciesLabel}, ${context.playerL10n.levelLabel(data.level)}, ${context.playerL10n.hpLabel(data.currentHp, data.maxHp)}${experience == null ? '' : ', ${(experience * 100).round()} %'}',
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    data.speciesLabel,
                                    key: ValueKey<String>(
                                      'battle-species-${identity ?? sideId}',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text,
                                  ),
                                ),
                                if (data.genderSymbol case final gender?) ...[
                                  const SizedBox(width: 6),
                                  _BattleGenderSymbol(
                                    key: ValueKey<String>(
                                      'battle-gender-${identity ?? sideId}',
                                    ),
                                    symbol: gender,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (profile?.showLevel ?? true)
                            const SizedBox(width: 8),
                          if (profile?.showLevel ?? true)
                            Text(
                              context.playerL10n.levelLabel(data.level),
                              key: ValueKey<String>(
                                'battle-level-${identity ?? sideId}',
                              ),
                              style: number,
                            ),
                        ],
                      ),
                      SizedBox(
                        key: ValueKey<String>(
                          'battle-hud-divider-${identity ?? sideId}',
                        ),
                        height: 3,
                      ),
                      TweenAnimationBuilder<double>(
                        key: ValueKey<int>(data.hpTweenRevision),
                        tween: Tween<double>(
                          begin: data.effectiveDisplayedHp.toDouble(),
                          end: data.effectiveTargetDisplayedHp.toDouble(),
                        ),
                        duration: context.playerMotion.standard == Duration.zero
                            ? Duration.zero
                            : data.hpTweenDuration ??
                                  context.playerMotion.standard,
                        builder: (context, hp, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _BattleHpBar(
                                    key: ValueKey<String>(
                                      'battle-hp-${hpBarShape.name}-$sideId',
                                    ),
                                    value: data.maxHp <= 0
                                        ? 0
                                        : (hp / data.maxHp).clamp(0.0, 1.0),
                                    shape: hpBarShape,
                                    color: hpColor,
                                    backgroundColor: chrome.hudEdge.withValues(
                                      alpha: .25,
                                    ),
                                    height: 6,
                                  ),
                                ),
                              ],
                            ),
                            if (showExactHp) ...[
                              const SizedBox(height: 3),
                              Text(
                                usesLigueShape
                                    ? '${hp.round()} / ${data.maxHp}'
                                    : context.playerL10n.hpFraction(
                                        hp.round(),
                                        data.maxHp,
                                      ),
                                key: ValueKey<String>(
                                  'battle-exact-hp-${identity ?? sideId}',
                                ),
                                textAlign: TextAlign.left,
                                style: number.copyWith(fontSize: 15),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (data.statusLabel case final status?) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _BattleStatusBadge(
                            key: ValueKey<String>(
                              'battle-status-badge-$sideId',
                            ),
                            label: status,
                            color:
                                PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                                  profile?.statusColor,
                                ) ??
                                context.playerColors.warning,
                            dense: true,
                          ),
                        ),
                      ],
                      if (experience case final progress?) ...[
                        const SizedBox(height: 3),
                        TweenAnimationBuilder<double>(
                          key: ValueKey<String>(
                            'battle-xp-tween-$sideId-${data.xpTweenRevision}',
                          ),
                          tween: Tween<double>(
                            begin: progress,
                            end:
                                (data.effectiveTargetExperienceProgress ??
                                        progress)
                                    .clamp(0.0, 1.0),
                          ),
                          duration:
                              context.playerMotion.standard == Duration.zero
                              ? Duration.zero
                              : data.xpTweenDuration ??
                                    context.playerMotion.standard,
                          builder: (context, xp, _) => Row(
                            children: [
                              Text(
                                context.playerL10n.experienceAbbreviation,
                                style: number.copyWith(
                                  fontSize: 9,
                                  color: chrome.experience,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _BattleExperienceBar(
                                  key: ValueKey<String>(
                                    'battle-xp-${identity ?? sideId}',
                                  ),
                                  value: xp,
                                  color: chrome.experience,
                                  backgroundColor: chrome.hudEdge.withValues(
                                    alpha: .18,
                                  ),
                                  height: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
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
              .copyWith(color: color, fontWeight: FontWeight.w900, height: 1),
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
        '♂' => context.playerBattleChrome.experience,
        _ => context.playerColors.textSecondary,
      },
    ),
  );
}

class _BattlePrimaryDialogue extends StatelessWidget {
  const _BattlePrimaryDialogue({required this.data, required this.profile});

  final PlayerBattleViewData data;
  final ProjectBattlePresentationProfile? profile;

  @override
  Widget build(BuildContext context) {
    final panel = _panelProfile(profile, PlayerBattlePanelKind.message);
    if (panel.surfaceColor == null &&
        panel.textColor == null &&
        panel.borderColor == null &&
        panel.shape == ProjectWindowShape.rounded) {
      final chrome = context.playerBattleChrome;
      return Material(
        key: const ValueKey<String>('battle-dialogue-panel'),
        color: chrome.hudSurface,
        shape: _BattleBevelShape(accent: chrome.focus, leading: true),
        clipBehavior: Clip.antiAlias,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: chrome.hudText),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 20, 8),
            child: _BattleDialoguePane(
              data: data,
              onBack: null,
              showChrome: false,
              foregroundColor: chrome.hudText,
            ),
          ),
        ),
      );
    }
    return PlayerPanel(
      key: const ValueKey<String>('battle-dialogue-panel'),
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      padding: const EdgeInsets.all(PlayerSpacing.sm),
      windowStyleOverride: _battleWindowStyle(
        id: 'battle-primary-dialogue',
        shape: panel.shape,
        padding: PlayerSpacing.sm,
      ),
      surfaceColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panel.surfaceColor,
      ),
      borderColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panel.borderColor,
      ),
      textColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panel.textColor,
      ),
      child: _BattleDialoguePane(data: data, onBack: null, showChrome: false),
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
    final panel = _panelProfile(profile, data.panelKind);
    if (reservedViewportLayout || _usesCanonicalBattleStructure(profile)) {
      return _BattleSeparatedCommandDock(
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        spacingScale: spacingScale,
        profile: profile,
        panelProfile: panel,
        stacked: compactPortrait,
      );
    }
    final onBack =
        data.canGoBack && !data.forcedReplacement && data.interactionsEnabled
        ? () =>
              onAction(PlayerBattleBackAction(snapshotRevision: data.revision))
        : null;
    Widget entry(PlayerBattleCommandViewData value) => _BattleEntryButton(
      entry: value,
      interactionsEnabled: data.interactionsEnabled,
      autofocus: value.selected,
      iconBuilder: itemIconBuilder,
      dense: true,
      onPressed: () => onAction(
        PlayerBattleSelectEntryAction(
          snapshotRevision: data.revision,
          entryIndex: value.index,
        ),
      ),
      showProjectIcon: profile?.showCommandIcons ?? true,
      selectionColor: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panel.selectionColor,
      ),
    );
    return PlayerPanel(
      key: const ValueKey('battle-command-panel'),
      elevated: true,
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      padding: EdgeInsets.all(panel.padding * spacingScale),
      windowStyleOverride: profile == null
          ? null
          : _battleWindowStyle(
              id: 'battle-${data.panelKind.name}',
              shape: panel.shape,
              padding: panel.padding,
            ),
      surfaceColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panel.surfaceColor,
      ),
      borderColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panel.borderColor,
      ),
      textColorOverride: PokeMapPlayerProjectColorResolver.tryOpaqueHex(
        panel.textColor,
      ),
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showHeader = constraints.maxHeight >= 260;
            final titleStyle = context.playerTypography.combatStyle(
              Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
            );
            final promptStyle = context.playerTypography.combatStyle(
              Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            );
            double lineHeight(String text, TextStyle style) {
              final painter =
                  TextPainter(
                    text: TextSpan(
                      text: text,
                      style: DefaultTextStyle.of(context).style.merge(style),
                    ),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: 1,
                    ellipsis: '…',
                  )..layout(
                    maxWidth: math.max(
                      1.0,
                      constraints.maxWidth - (onBack == null ? 0 : 60),
                    ),
                  );
              final height = painter.height;
              painter.dispose();
              return height;
            }

            final headerHeight = math.max(
              72.0,
              lineHeight(data.title, titleStyle) +
                  lineHeight(data.prompt, promptStyle),
            );
            final height =
                constraints.maxHeight - (showHeader ? headerHeight + 12 : 0);
            final radial =
                panel.layout == ProjectBattleCommandLayout.radial &&
                !compactPortrait &&
                constraints.maxWidth >= 420 &&
                height >= 216;
            final layout = radial
                ? ProjectBattleCommandLayout.radial
                : panel.layout == ProjectBattleCommandLayout.list
                ? ProjectBattleCommandLayout.list
                : ProjectBattleCommandLayout.grid;
            final entries = radial
                ? _BattleRadialCommandLayout(
                    key: ValueKey('battle-panel-${data.panelKind.name}-radial'),
                    entries: data.commands,
                    interactionsEnabled: data.interactionsEnabled,
                    iconBuilder: itemIconBuilder,
                    showProjectIcon: profile?.showCommandIcons ?? true,
                    selectionColor:
                        PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                          panel.selectionColor,
                        ),
                    onAction: onAction,
                    revision: data.revision,
                  )
                : _BattlePagedEntries(
                    key: ValueKey(
                      'battle-panel-${data.panelKind.name}-${layout.name}',
                    ),
                    data: data,
                    entryBuilder: entry,
                    bag: data.commands.any((entry) => entry.isBagItem),
                    columnsOverride: layout == ProjectBattleCommandLayout.list
                        ? 1
                        : panel.columns,
                    onBack: showHeader ? null : onBack,
                  );
            return Semantics(
              container: true,
              liveRegion: true,
              label: '${data.battleLabel}, ${data.prompt}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showHeader)
                    SizedBox(
                      height: headerHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  data.forcedReplacement
                                      ? context.playerL10n.mandatoryReplacement
                                      : data.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: titleStyle,
                                ),
                                Text(
                                  data.prompt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: promptStyle,
                                ),
                              ],
                            ),
                          ),
                          if (onBack != null) const SizedBox(width: 12),
                          if (onBack != null)
                            IconButton(
                              key: const ValueKey('battle-back'),
                              tooltip: context.playerL10n.back,
                              onPressed: onBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                        ],
                      ),
                    ),
                  if (showHeader) const SizedBox(height: 12),
                  Expanded(child: entries),
                ],
              ),
            );
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
    this.companion = false,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final ProjectBattlePresentationProfile? profile;
  final ProjectBattlePanelPresentationProfile panelProfile;
  final bool stacked;
  final bool companion;

  @override
  Widget build(BuildContext context) {
    final chrome = context.playerBattleChrome;
    final controller = PlayerInputScope.usesController(context);
    final visibleText = data.panelKind == PlayerBattlePanelKind.moves
        ? context.playerL10n.battleChooseMove
        : data.panelKind == PlayerBattlePanelKind.message &&
              data.narrationLines.isNotEmpty
        ? data.narrationLines.last
        : data.prompt;
    final onBack =
        data.canGoBack && !data.forcedReplacement && data.interactionsEnabled
        ? () =>
              onAction(PlayerBattleBackAction(snapshotRevision: data.revision))
        : null;
    if (data.panelKind == PlayerBattlePanelKind.message &&
        !data.interactionsEnabled) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: math.min(80, MediaQuery.textScalerOf(context).scale(52)),
          child: _BattlePrimaryDialogue(data: data, profile: profile),
        ),
      );
    }
    return PlayerPanel(
      key: const ValueKey<String>('battle-command-panel'),
      role: PlayerPanelRole.battleHud,
      surfaceRole: ProjectPresentationSurfaceRole.battleHud,
      windowStyleOverride:
          _battleWindowStyle(
            id: 'battle-dock-${data.panelKind.name}',
            shape: profile == null
                ? ProjectWindowShape.rounded
                : panelProfile.shape,
            padding:
                panelProfile.surfaceColor != null ||
                    panelProfile.padding != 12 ||
                    panelProfile.shape != ProjectWindowShape.rounded
                ? panelProfile.padding
                : companion
                ? 16
                : stacked
                ? 6
                : 0,
          ).copyWith(
            borderWidth: 0,
            cornerRadius: 3,
            shadowElevation: 0,
            fillOpacity: panelProfile.surfaceColor == null ? 0 : 1,
          ),
      surfaceColorOverride:
          PokeMapPlayerProjectColorResolver.tryOpaqueHex(
            panelProfile.surfaceColor,
          ) ??
          chrome.dockSurface,
      textColorOverride:
          PokeMapPlayerProjectColorResolver.tryOpaqueHex(
            panelProfile.textColor,
          ) ??
          chrome.dockText,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sidePanel =
                !stacked &&
                constraints.maxWidth < 420 &&
                constraints.maxHeight > 230;
            final compact =
                sidePanel ||
                constraints.maxHeight < 250 ||
                (MediaQuery.textScalerOf(context).scale(1) > 1.4 &&
                    constraints.maxHeight < 340);
            final pagedBag =
                compact &&
                !stacked &&
                data.commands.length > 2 &&
                data.commands.every((entry) => entry.isBagItem);
            final moveRail =
                !sidePanel &&
                compact &&
                data.panelKind == PlayerBattlePanelKind.moves;
            final showHeader =
                data.panelKind != PlayerBattlePanelKind.commands &&
                data.panelKind != PlayerBattlePanelKind.moves &&
                (sidePanel ||
                    !moveRail &&
                        !pagedBag &&
                        !(controller &&
                            !stacked &&
                            data.panelKind == PlayerBattlePanelKind.moves) &&
                        (!compact ||
                            data.panelKind != PlayerBattlePanelKind.commands ||
                            data.forcedReplacement));
            final selectedMove =
                data.commands.where((entry) => entry.selected).firstOrNull ??
                data.commands.firstOrNull;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeader)
                  SizedBox(
                    key: const ValueKey('battle-dialogue-panel'),
                    height: sidePanel
                        ? (MediaQuery.textScalerOf(context).scale(1) > 1.4
                              ? 56
                              : 40)
                        : data.forcedReplacement
                        ? 88
                        : compact
                        ? (MediaQuery.textScalerOf(context).scale(1) > 1.4
                              ? 56
                              : 42)
                        : 72,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (data.panelKind !=
                                      PlayerBattlePanelKind.moves &&
                                  ((!compact && !sidePanel) ||
                                      data.forcedReplacement))
                                Text(
                                  data.forcedReplacement
                                      ? context.playerL10n.mandatoryReplacement
                                      : data.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: chrome.textSecondary),
                                ),
                              Text(
                                visibleText,
                                key: const ValueKey('battle-dialogue-prompt'),
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.playerTypography.combatStyle(
                                  (Theme.of(context).textTheme.titleMedium ??
                                          const TextStyle())
                                      .copyWith(
                                        color: chrome.dockText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              if (data.panelKind == PlayerBattlePanelKind.moves)
                                Text(
                                  data.player.speciesLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: chrome.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        if (stacked &&
                            !companion &&
                            data.panelKind == PlayerBattlePanelKind.moves &&
                            selectedMove != null)
                          IconButton(
                            key: const ValueKey('battle-move-info'),
                            tooltip: selectedMove.primaryLabel,
                            onPressed: () =>
                                _showBattleMoveInfo(context, selectedMove),
                            color: chrome.dockText,
                            icon: const Icon(Icons.info_outline_rounded),
                          ),
                        if (onBack != null && !sidePanel && !companion)
                          const SizedBox(width: 12),
                        if (onBack != null && !sidePanel && !companion)
                          IconButton(
                            key: const ValueKey('battle-back'),
                            tooltip: context.playerL10n.back,
                            onPressed: onBack,
                            color: chrome.dockText,
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                      ],
                    ),
                  ),
                if (showHeader) SizedBox(height: sidePanel ? 8 : 12),
                Expanded(
                  key: const ValueKey('battle-actions-panel'),
                  child: data.panelKind == PlayerBattlePanelKind.message
                      ? _BattleActionsPane(
                          data: data,
                          onAction: onAction,
                          itemIconBuilder: itemIconBuilder,
                          spacingScale: spacingScale,
                          showProjectIcons: false,
                          selectionColor: chrome.focus,
                          foregroundColor: chrome.dockText,
                        )
                      : _BattleDockEntries(
                          data: data,
                          onAction: onAction,
                          itemIconBuilder: itemIconBuilder,
                          profile: profile,
                          controller: controller,
                          landscape: !stacked,
                          sidePanel: sidePanel,
                          companion: companion,
                          showCollectionBack: pagedBag,
                          showMoveRail: moveRail,
                          selectionColor:
                              PokeMapPlayerProjectColorResolver.tryOpaqueHex(
                                panelProfile.selectionColor,
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

class _BattleDockEntries extends StatelessWidget {
  const _BattleDockEntries({
    required this.data,
    required this.onAction,
    required this.itemIconBuilder,
    required this.profile,
    required this.controller,
    required this.landscape,
    required this.selectionColor,
    this.showCollectionBack = false,
    this.showMoveRail = false,
    this.sidePanel = false,
    this.companion = false,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final ProjectBattlePresentationProfile? profile;
  final bool controller;
  final bool landscape;
  final Color? selectionColor;
  final bool showCollectionBack;
  final bool showMoveRail;
  final bool sidePanel;
  final bool companion;

  Widget _entry(PlayerBattleCommandViewData entry, {bool singleLine = false}) =>
      _BattleEntryButton(
        singleLine: singleLine,
        commandFontSize: entry.commandId == ProjectBattleCommandId.fight
            ? (companion
                  ? 27
                  : sidePanel
                  ? 26
                  : landscape
                  ? 23
                  : 24)
            : (companion
                  ? 23
                  : sidePanel
                  ? 18
                  : 19),
        entry: entry,
        interactionsEnabled: data.interactionsEnabled,
        autofocus: entry.selected,
        iconBuilder: itemIconBuilder,
        dense: true,
        showProjectIcon: profile?.showCommandIcons ?? true,
        showSecondaryLabel: entry.commandId == null,
        selectionColor: selectionColor,
        onPressed: () => onAction(
          PlayerBattleSelectEntryAction(
            snapshotRevision: data.revision,
            entryIndex: entry.index,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final fight = data.commands
        .where((entry) => entry.commandId == ProjectBattleCommandId.fight)
        .firstOrNull;
    if (fight != null &&
        data.commands.every((entry) => entry.commandId != null)) {
      final rest = data.commands.where((entry) => entry != fight).toList();
      if (profile?.commands == null) {
        rest.sort(
          (a, b) =>
              _commandOrder(a.commandId).compareTo(_commandOrder(b.commandId)),
        );
      }
      if (sidePanel) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in [fight, ...rest]) ...[
              if (entry != fight) const SizedBox(height: 8),
              Expanded(child: _entry(entry)),
            ],
          ],
        );
      }
      final ordered = [fight, ...rest];
      return Column(
        key: const ValueKey('battle-root-grid'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var row = 0; row < (ordered.length + 1) ~/ 2; row++) ...[
            if (row > 0) const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _entry(ordered[row * 2])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: row * 2 + 1 < ordered.length
                        ? _entry(ordered[row * 2 + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
    final moves =
        data.commands.isNotEmpty &&
        data.commands.every((entry) => entry.moveTypeId != null);
    if (moves) {
      final selected =
          data.commands.where((entry) => entry.selected).firstOrNull ??
          data.commands.first;
      final info = _BattleFooterButton(
        key: const ValueKey('battle-move-info'),
        label: 'Infos',
        compactPaint: sidePanel,
        icon: Icons.info_outline_rounded,
        leadingAccent: true,
        onPressed: () => _showBattleMoveInfo(context, selected),
      );
      final back = _BattleFooterButton(
        key: const ValueKey('battle-back'),
        label: context.playerL10n.back,
        compactPaint: sidePanel,
        icon: Icons.arrow_back_rounded,
        onPressed:
            data.canGoBack &&
                !data.forcedReplacement &&
                data.interactionsEnabled
            ? () => onAction(
                PlayerBattleBackAction(snapshotRevision: data.revision),
              )
            : null,
      );
      final grid = _BattleSeparatedEntries(
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        spacingScale: 1,
        showProjectIcons: false,
        selectionColor: selectionColor,
        fixedMoveGrid: true,
      );
      if (showMoveRail) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: grid),
            const SizedBox(width: 12),
            SizedBox(
              width: 106,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: info),
                  const SizedBox(height: 8),
                  Expanded(child: back),
                ],
              ),
            ),
          ],
        );
      }
      return Column(
        key: sidePanel ? const ValueKey('battle-controller-moves') : null,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: sidePanel
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < data.commands.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        Expanded(child: _entry(data.commands[i])),
                      ],
                    ],
                  )
                : grid,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: info),
                const SizedBox(width: 12),
                Expanded(child: back),
              ],
            ),
          ),
        ],
      );
    }
    return _BattleSeparatedEntries(
      data: data,
      onAction: onAction,
      itemIconBuilder: itemIconBuilder,
      spacingScale: 1,
      showProjectIcons: profile?.showCommandIcons ?? true,
      selectionColor: selectionColor,
      fixedMoveGrid: moves,
      showCollectionBack: showCollectionBack,
    );
  }
}

Future<void> _showBattleMoveInfo(
  BuildContext context,
  PlayerBattleCommandViewData selected,
) => showDialog<void>(
  context: context,
  builder: (context) => Dialog(
    child: PlayerPanel(
      padding: const EdgeInsets.all(PlayerSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            selected.primaryLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            [
              if (selected.moveTypeId case final type?)
                context.playerL10n.battleMoveType(type),
              ?selected.tertiaryLabel,
              ?selected.trailingLabel,
              ?selected.statusLabel,
            ].join(' · '),
          ),
          const SizedBox(height: 16),
          PlayerActionButton(
            label: context.playerL10n.close,
            icon: Icons.close_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  ),
);

class _BattleDialoguePane extends StatelessWidget {
  const _BattleDialoguePane({
    required this.data,
    required this.onBack,
    this.showChrome = true,
    this.foregroundColor,
  });

  final PlayerBattleViewData data;
  final VoidCallback? onBack;
  final bool showChrome;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final visibleText =
        data.panelKind == PlayerBattlePanelKind.message &&
            data.narrationLines.isNotEmpty
        ? data.narrationLines.last
        : data.prompt;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '${data.battleLabel}, ${data.prompt}',
      child: Row(
        children: <Widget>[
          if (showChrome)
            Icon(
              Icons.eco_outlined,
              size: 18,
              color: context.playerBattleChrome.outline,
            ),
          if (showChrome) const SizedBox(width: PlayerSpacing.xs),
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
                      .copyWith(
                        fontWeight: FontWeight.w800,
                        color: foregroundColor,
                      ),
                ),
              ],
            ),
          ),
          if (showChrome) const SizedBox(width: PlayerSpacing.xs),
          if (showChrome && onBack == null)
            Icon(
              Icons.eco_outlined,
              size: 18,
              color: context.playerBattleChrome.outline,
            )
          else if (onBack != null)
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
    this.fixedMoveGrid = false,
    this.showCollectionBack = false,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final bool showProjectIcons;
  final Color? selectionColor;
  final bool fixedMoveGrid;
  final bool showCollectionBack;

  @override
  Widget build(BuildContext context) {
    final bagEntries =
        data.commands.isNotEmpty &&
        data.commands.every((entry) => entry.isBagItem);
    if (bagEntries || data.commands.length > 4) {
      return _BattlePagedEntries(
        key: ValueKey(
          'battle-paged-${data.panelKind.name}-${bagEntries ? 'bag' : 'choices'}',
        ),
        data: data,
        entryBuilder: _entry,
        bag: bagEntries,
        onBack:
            showCollectionBack &&
                data.canGoBack &&
                data.interactionsEnabled &&
                !data.forcedReplacement
            ? () => onAction(
                PlayerBattleBackAction(snapshotRevision: data.revision),
              )
            : null,
      );
    }
    if (data.commands.length <= 4) {
      return _BattleSeparatedGrid(
        key: ValueKey<String>('battle-panel-${data.panelKind.name}-grid'),
        data: data,
        onAction: onAction,
        itemIconBuilder: itemIconBuilder,
        spacingScale: spacingScale,
        showProjectIcons: showProjectIcons,
        selectionColor: selectionColor,
        fixedTwoRows: fixedMoveGrid,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _entry(PlayerBattleCommandViewData entry, {bool singleLine = false}) =>
      _BattleEntryButton(
        singleLine: singleLine,
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
    this.fixedTwoRows = false,
  });

  final PlayerBattleViewData data;
  final ValueChanged<PlayerBattleAction> onAction;
  final Widget Function(String assetPath)? itemIconBuilder;
  final double spacingScale;
  final bool showProjectIcons;
  final Color? selectionColor;
  final bool fixedTwoRows;

  @override
  Widget build(BuildContext context) {
    final rowCount = fixedTwoRows ? 2 : (data.commands.length + 1) ~/ 2;
    return Column(
      children: <Widget>[
        for (var row = 0; row < rowCount; row++) ...<Widget>[
          if (row > 0)
            SizedBox(height: math.max(8.0, PlayerSpacing.xs * spacingScale)),
          Expanded(
            child: Row(
              crossAxisAlignment: fixedTwoRows
                  ? CrossAxisAlignment.stretch
                  : CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: row * 2 < data.commands.length
                      ? _entry(data.commands[row * 2])
                      : const SizedBox.shrink(),
                ),
                SizedBox(width: math.max(8.0, PlayerSpacing.xs * spacingScale)),
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

class _BattlePagedEntries extends StatefulWidget {
  const _BattlePagedEntries({
    super.key,
    required this.data,
    required this.entryBuilder,
    required this.bag,
    this.onBack,
    this.columnsOverride,
  });
  final PlayerBattleViewData data;
  final Widget Function(PlayerBattleCommandViewData entry) entryBuilder;
  final bool bag;
  final VoidCallback? onBack;
  final int? columnsOverride;

  @override
  State<_BattlePagedEntries> createState() => _BattlePagedEntriesState();
}

class _BattlePagedEntriesState extends State<_BattlePagedEntries> {
  int? _page;

  @override
  void didUpdateWidget(covariant _BattlePagedEntries oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = widget.data.commands
        .where((entry) => entry.selected)
        .firstOrNull
        ?.index;
    final oldSelected = oldWidget.data.commands
        .where((entry) => entry.selected)
        .firstOrNull
        ?.index;
    if (selected != oldSelected) _page = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          widget.columnsOverride ?? (constraints.maxWidth >= 300 ? 2 : 1);
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final rowHeight = widget.bag ? 64.0 : 58.0;
      final rowsWithoutPager = math.max(
        1,
        ((constraints.maxHeight + 8) /
                (rowHeight * math.min(textScale, 1.4) + 8))
            .floor(),
      );
      final needsPager =
          widget.data.commands.length > columns * rowsWithoutPager;
      final rows = (needsPager || widget.onBack != null)
          ? math.max(
              1,
              ((constraints.maxHeight - 60) /
                      (rowHeight * math.min(textScale, 1.4) + 8))
                  .floor(),
            )
          : rowsWithoutPager;
      final capacity = rows * columns;
      final pages = math.max(
        1,
        (widget.data.commands.length / capacity).ceil(),
      );
      final selected = widget.data.commands.indexWhere(
        (entry) => entry.selected,
      );
      final page = (_page ?? math.max(0, selected) ~/ capacity).clamp(
        0,
        pages - 1,
      );
      final visible = widget.data.commands
          .skip(page * capacity)
          .take(capacity)
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                for (
                  var row = 0;
                  row < (visible.length / columns).ceil();
                  row++
                ) ...[
                  if (row > 0) const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var column = 0; column < columns; column++) ...[
                          if (column > 0) const SizedBox(width: 8),
                          Expanded(
                            child: row * columns + column < visible.length
                                ? widget.entryBuilder(
                                    visible[row * columns + column],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (needsPager || widget.onBack != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      key: const ValueKey('battle-back'),
                      tooltip: context.playerL10n.back,
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  IconButton(
                    key: const ValueKey('battle-page-previous'),
                    tooltip: context.playerL10n.back,
                    onPressed: page > 0
                        ? () => setState(() => _page = page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    '${page + 1} / $pages',
                    key: const ValueKey('battle-page-label'),
                  ),
                  IconButton(
                    key: const ValueKey('battle-page-next'),
                    tooltip: context.playerL10n.next,
                    onPressed: page + 1 < pages
                        ? () => setState(() => _page = page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    },
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
    this.singleLine = false,
    this.commandFontSize,
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
  final bool singleLine;
  final double? commandFontSize;
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
    final profile = context.playerBattleProfile;
    final panel = _panelProfile(
      profile,
      entry.moveTypeId == null
          ? PlayerBattlePanelKind.commands
          : PlayerBattlePanelKind.moves,
    );
    final authoredChrome =
        panel.surfaceColor != null ||
        panel.textColor != null ||
        panel.selectionColor != null ||
        panel.borderColor != null ||
        panel.shape != ProjectWindowShape.rounded ||
        panel.padding != 12;
    if (!authoredChrome &&
        (entry.commandId != null || entry.moveTypeId != null)) {
      return _LigueBattleEntry(
        entry: entry,
        enabled: enabled,
        focused: _focused,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onPressed: widget.onPressed,
        commandFontSize: widget.commandFontSize,
        showProjectIcon: widget.showProjectIcon,
      );
    }
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
        ? _commandColor(chrome, entry.commandId) ?? toneColor
        : _moveTypeColor(context, moveTypeId);
    final selectionAccent =
        widget.selectionColor ??
        (entry.moveTypeId != null
            ? chrome.moveFocus
            : entry.commandId == null
            ? chrome.focus
            : chrome.dockText);
    final frameAccent = entry.selected || _focused
        ? selectionAccent
        : accent.withValues(alpha: .72);
    final command = entry.commandId != null;
    final move = moveTypeId != null;
    final surfaceColor = move
        ? !enabled
              ? chrome.moveDisabled
              : entry.selected || _focused
              ? chrome.moveSelected
              : chrome.moveSurface
        : command
        ? accent
        : entry.selected || _focused
        ? chrome.surfaceSelected
        : chrome.surfaceRaised;
    final foreground = !enabled
        ? move
              ? chrome.moveDisabledText
              : chrome.textSecondary
        : move
        ? chrome.moveText
        : command
        ? _battleReadableForeground(surfaceColor, chrome.dockText, chrome)
        : chrome.textPrimary;
    final bagCategoryLabel = bagItem
        ? _battleBagCategoryLabel(context.playerL10n, entry.tone)
        : null;
    final details = <String>[
      ?moveTypeLabel,
      ?bagCategoryLabel,
      ?entry.tertiaryLabel,
      ?entry.trailingLabel,
      if (!bagItem) ?entry.statusLabel,
      if (bagItem && !entry.enabled) context.playerL10n.actionUnavailable,
    ].join(', ');
    final disabledReason = details.isEmpty
        ? context.playerL10n.actionUnavailable
        : details;
    final shape = RoundedRectangleBorder(
      borderRadius: command
          ? const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(3),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(3),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(3),
            ),
      side: BorderSide(
        color: frameAccent,
        width: _focused || entry.selected ? 3 : 1,
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
        triggerMode: TooltipTriggerMode.manual,
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
              child: Container(
                foregroundDecoration: move && (entry.selected || _focused)
                    ? BoxDecoration(
                        border: Border.all(color: chrome.moveOutline, width: 5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          topRight: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(3),
                        ),
                      )
                    : null,
                decoration: move
                    ? BoxDecoration(
                        border: Border(
                          left: BorderSide(color: accent, width: 5),
                        ),
                      )
                    : null,
                child: Padding(
                  padding: move
                      ? EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: largeText ? 4 : 7,
                        )
                      : widget.dense
                      ? EdgeInsets.symmetric(
                          horizontal: PlayerSpacing.xs,
                          vertical: largeText ? 3 : PlayerSpacing.xxs,
                        )
                      : const EdgeInsets.all(PlayerSpacing.sm),
                  child: LayoutBuilder(
                    builder: (context, entryConstraints) {
                      final showCursor =
                          entry.selected &&
                          !move &&
                          !command &&
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
                            child: widget.singleLine
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.primaryLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: foreground,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      if (entry.trailingLabel case final pp?)
                                        Text(
                                          pp,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(color: foreground),
                                        ),
                                    ],
                                  )
                                : bagItem
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
                                      if (entry.iconAssetPath case final path?)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            right: widget.dense
                                                ? PlayerSpacing.xs
                                                : PlayerSpacing.sm,
                                          ),
                                          child: SizedBox.square(
                                            dimension: widget.dense ? 24 : 36,
                                            child:
                                                widget.iconBuilder?.call(
                                                  path,
                                                ) ??
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
                                            color: command
                                                ? foreground
                                                : accent,
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
                                              textAlign: TextAlign.start,
                                              maxLines: widget.dense ? 1 : null,
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
                                                          color: foreground,
                                                          fontSize:
                                                              command &&
                                                                  entry.commandId ==
                                                                      ProjectBattleCommandId
                                                                          .fight
                                                              ? 22
                                                              : null,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                            ),
                                            if (widget.showSecondaryLabel &&
                                                entry
                                                    .secondaryLabel
                                                    .isNotEmpty &&
                                                !(widget.dense && largeText))
                                              Text(
                                                entry.secondaryLabel,
                                                maxLines: widget.dense
                                                    ? 1
                                                    : null,
                                                overflow: widget.dense
                                                    ? TextOverflow.ellipsis
                                                    : null,
                                                style: context.playerTypography
                                                    .combatStyle(
                                                      (Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall ??
                                                              const TextStyle())
                                                          .copyWith(
                                                            color: foreground,
                                                          ),
                                                    ),
                                              ),
                                            if (widget.showSecondaryLabel) ...<
                                              Widget
                                            >[
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
                                                              color: accent,
                                                            ),
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
                                    showDetails:
                                        widget.showSecondaryLabel && !largeText,
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
      ),
    );
  }
}

class _BattleBevelShape extends ShapeBorder {
  const _BattleBevelShape({this.accent, this.leading = false});

  final Color? accent;
  final bool leading;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final bevel = math.min(17.0, rect.width / 5);
    return Path()
      ..moveTo(rect.left + bevel, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right - bevel, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  ShapeBorder scale(double t) => this;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (accent == null) return;
    final bevel = math.min(17.0, rect.width / 5);
    final edge = Path();
    if (leading) {
      edge
        ..moveTo(rect.left + bevel, rect.top)
        ..lineTo(rect.left + bevel + 6, rect.top)
        ..lineTo(rect.left + 6, rect.bottom)
        ..lineTo(rect.left, rect.bottom);
    } else {
      edge
        ..moveTo(rect.right - 6, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right - bevel, rect.bottom)
        ..lineTo(rect.right - bevel - 6, rect.bottom);
    }
    canvas.drawPath(edge..close(), Paint()..color = accent!);
  }
}

class _LigueBattleEntry extends StatelessWidget {
  const _LigueBattleEntry({
    required this.entry,
    required this.enabled,
    required this.focused,
    required this.focusNode,
    required this.autofocus,
    required this.onPressed,
    required this.commandFontSize,
    required this.showProjectIcon,
  });

  final PlayerBattleCommandViewData entry;
  final bool enabled;
  final bool focused;
  final FocusNode focusNode;
  final bool autofocus;
  final VoidCallback onPressed;
  final double? commandFontSize;
  final bool showProjectIcon;

  @override
  Widget build(BuildContext context) {
    final chrome = context.playerBattleChrome;
    final selected = enabled && (entry.selected || focused);
    final surface = !enabled
        ? chrome.moveDisabled
        : selected
        ? chrome.moveSelected
        : chrome.moveSurface;
    final ink = !enabled
        ? chrome.moveDisabledText
        : selected
        ? chrome.moveSurface
        : chrome.moveText;
    final muted = selected
        ? chrome.moveSurface.withValues(alpha: .72)
        : enabled
        ? chrome.moveMuted
        : chrome.moveDisabledText.withValues(alpha: .8);
    final inheritedStyle = DefaultTextStyle.of(context).style;
    final nameStyle = context.playerTypography
        .combatStyle(inheritedStyle)
        .copyWith(
          color: ink,
          fontSize: 15,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -.3,
        );
    final details = [
      if (entry.moveTypeId case final type?)
        context.playerL10n.battleMoveType(type),
      ?entry.tertiaryLabel,
      ?entry.trailingLabel,
      ?entry.statusLabel,
    ].join(', ');
    return Semantics(
      key: ValueKey<String>('battle-entry-${entry.index}'),
      button: true,
      enabled: enabled,
      selected: selected,
      label: entry.primaryLabel,
      hint: details.isNotEmpty
          ? details
          : enabled
          ? null
          : context.playerL10n.actionUnavailable,
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Material(
            color: surface,
            animationDuration: context.playerMotion.standard == Duration.zero
                ? Duration.zero
                : const Duration(milliseconds: 150),
            shape: _BattleBevelShape(accent: selected ? chrome.focus : null),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              focusNode: focusNode,
              autofocus: autofocus,
              onTap: enabled ? onPressed : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, 6),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final move = entry.moveTypeId;
                      if (move == null) {
                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.primaryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: nameStyle.copyWith(
                                  fontSize: commandFontSize ?? 18,
                                ),
                              ),
                            ),
                            if (showProjectIcon) ...[
                              const SizedBox(width: 8),
                              if (entry.commandId ==
                                      ProjectBattleCommandId.party &&
                                  (entry.commandIcon == null ||
                                      entry.commandIcon ==
                                          ProjectBattleCommandIcon.party))
                                CustomPaint(
                                  size: const Size.square(20),
                                  painter: _BattleBallPainter(
                                    chrome.experience,
                                    selected
                                        ? chrome.moveSurface
                                        : chrome.moveText,
                                  ),
                                )
                              else
                                Icon(
                                  _commandIcon(
                                    entry.commandIcon ??
                                        switch (entry.commandId) {
                                          ProjectBattleCommandId.fight =>
                                            ProjectBattleCommandIcon.fight,
                                          ProjectBattleCommandId.bag =>
                                            ProjectBattleCommandIcon.bag,
                                          ProjectBattleCommandId.run =>
                                            ProjectBattleCommandIcon.run,
                                          _ => ProjectBattleCommandIcon.party,
                                        },
                                  ),
                                  size: 20,
                                  color: ink,
                                ),
                            ],
                          ],
                        );
                      }
                      final tall = constraints.maxHeight > 72;
                      final typeColor = chrome.typeBadge(move);
                      final icon = Container(
                        key: ValueKey('battle-type-icon-${entry.index}'),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: typeColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          switch (move.toLowerCase()) {
                            'grass' || 'bug' => Icons.eco_rounded,
                            'fire' => Icons.local_fire_department_rounded,
                            'water' || 'ice' => Icons.water_drop_rounded,
                            'electric' => Icons.bolt_rounded,
                            'poison' => Icons.science_rounded,
                            _ => Icons.adjust_rounded,
                          },
                          size: 14,
                          color: chrome.moveSurface,
                        ),
                      );
                      final type = _BattleMoveInfoBadge(
                        label: context.playerL10n.battleMoveType(move),
                        background: typeColor,
                        foreground: chrome.moveSurface,
                        border: typeColor,
                        horizontalPadding: 5,
                      );
                      final name = Text(
                        entry.primaryLabel,
                        key: ValueKey('battle-move-name-${entry.index}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle.copyWith(fontSize: tall ? 14 : 14.8),
                      );
                      final detail = Text(
                        entry.statusLabel ?? entry.tertiaryLabel ?? '',
                        key: ValueKey('battle-move-detail-${entry.index}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle.copyWith(
                          fontSize: 10,
                          color: muted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      );
                      final ppNumber = (entry.trailingLabel ?? '')
                          .replaceFirst(
                            RegExp(r'^\s*PP\s*', caseSensitive: false),
                            '',
                          )
                          .replaceAll(RegExp(r'\s*/\s*'), ' / ');
                      final ppStyle = context.playerTypography
                          .numbersStyle(nameStyle)
                          .copyWith(fontSize: tall ? 14 : 14.8);
                      double measure(String value, TextStyle style) {
                        final painter = TextPainter(
                          text: TextSpan(
                            text: value,
                            style: inheritedStyle.merge(style),
                          ),
                          textDirection: Directionality.of(context),
                          textScaler: MediaQuery.textScalerOf(context),
                        )..layout();
                        final width = painter.width;
                        painter.dispose();
                        return width;
                      }

                      final badgeStyle = context.playerTypography
                          .numbersStyle(
                            Theme.of(context).textTheme.labelSmall ??
                                const TextStyle(),
                          )
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            letterSpacing: .3,
                            height: 1,
                          );
                      final badgeWidth =
                          measure(
                            context.playerL10n.battleMoveType(move),
                            badgeStyle,
                          ) +
                          12;
                      final ppWidth = measure(ppNumber, ppStyle) + 2;
                      final pp = SizedBox(
                        width: ppWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ppNumber,
                              key: ValueKey('battle-pp-number-${entry.index}'),
                              maxLines: 1,
                              softWrap: false,
                              style: ppStyle,
                            ),
                            Text(
                              'PP',
                              key: ValueKey('battle-pp-caption-${entry.index}'),
                              style: ppStyle.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      );
                      final sizedType = SizedBox(
                        width: badgeWidth,
                        key: ValueKey('battle-type-badge-${entry.index}'),
                        child: type,
                      );
                      if (constraints.maxWidth < 120 ||
                          (MediaQuery.textScalerOf(context).scale(1) > 1.4 &&
                              constraints.maxHeight < 160)) {
                        return Row(
                          children: [
                            if (constraints.maxWidth >= 60) ...[
                              icon,
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: name,
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            sizedType,
                                            const SizedBox(width: 8),
                                            pp,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      if (tall) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Row(
                              children: [
                                icon,
                                const SizedBox(width: 6),
                                Expanded(child: name),
                              ],
                            ),
                            if (badgeWidth + ppWidth + 4 <=
                                constraints.maxWidth)
                              Row(children: [sizedType, const Spacer(), pp])
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: sizedType,
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: pp,
                                  ),
                                ],
                              ),
                            detail,
                          ],
                        );
                      }
                      if (constraints.maxWidth < 200) {
                        return Row(
                          children: [
                            icon,
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: name,
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            sizedType,
                                            const SizedBox(width: 8),
                                            pp,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          icon,
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                name,
                                const SizedBox(height: 2),
                                detail,
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          sizedType,
                          const SizedBox(width: 6),
                          pp,
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (selected && PlayerInputScope.usesController(context))
            Positioned(
              left: -15,
              top: 0,
              bottom: 0,
              child: Center(
                child: CustomPaint(
                  key: ValueKey('battle-selection-cursor-${entry.index}'),
                  size: const Size(14, 28),
                  painter: _BattleSelectionPainter(
                    chrome.moveSurface,
                    chrome.focus,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BattleSelectionPainter extends CustomPainter {
  const _BattleSelectionPainter(this.outline, this.accent);

  final Color outline;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final chevron = Path()
      ..moveTo(2, 3)
      ..lineTo(size.width - 3, size.height / 2)
      ..lineTo(2, size.height - 3);
    for (final (color, width) in [(outline, 7.0), (accent, 4.0)]) {
      canvas.drawPath(
        chevron,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_BattleSelectionPainter oldDelegate) =>
      outline != oldDelegate.outline || accent != oldDelegate.accent;
}

class _BattleFooterButton extends StatelessWidget {
  const _BattleFooterButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.leadingAccent = false,
    this.compactPaint = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool leadingAccent;
  final bool compactPaint;

  @override
  Widget build(BuildContext context) {
    final chrome = context.playerBattleChrome;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: chrome.moveSurface.withValues(alpha: 0),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: compactPaint ? 8 : 0),
              child: Ink(
                key: ValueKey('battle-footer-paint-$label'),
                decoration: ShapeDecoration(
                  color: chrome.moveSurface,
                  shape: _BattleBevelShape(
                    accent: leadingAccent ? chrome.focus : null,
                    leading: true,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 18, color: chrome.moveText),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.playerTypography
                              .combatStyle(const TextStyle())
                              .copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: chrome.moveText,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleBallPainter extends CustomPainter {
  const _BattleBallPainter(this.blue, this.edge);

  final Color blue;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 1;
    canvas.drawCircle(center, radius, Paint()..color = blue);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(1, center.dy),
      Offset(size.width - 1, center.dy),
      Paint()
        ..color = edge
        ..strokeWidth = 2,
    );
    canvas.drawCircle(center, 3.5, Paint()..color = edge);
    canvas.drawCircle(center, 1.5, Paint()..color = blue);
  }

  @override
  bool shouldRepaint(_BattleBallPainter oldDelegate) =>
      blue != oldDelegate.blue || edge != oldDelegate.edge;
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
    final category = _battleBagCategoryLabel(context.playerL10n, entry.tone);
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
                      side: BorderSide(color: accent.withValues(alpha: .74)),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final chrome = context.playerBattleChrome;
      final compact = constraints.maxHeight < 70;
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.4;
      final muted = entry.enabled ? chrome.moveMuted : chrome.moveDisabledText;
      final badgeColor = entry.enabled
          ? chrome.typeBadge(entry.moveTypeId ?? '')
          : chrome.hudEdge;
      final nameStyle = context.playerTypography
          .combatStyle(const TextStyle())
          .copyWith(
            fontSize: compact ? 14 : 16,
            height: 1.15,
            letterSpacing: -.2,
            color: foreground,
            fontWeight: FontWeight.w700,
          );
      final detailStyle = context.playerTypography
          .combatStyle(const TextStyle())
          .copyWith(
            fontSize: compact ? 10 : 11,
            height: 1.1,
            letterSpacing: 0,
            color: muted,
            fontWeight: FontWeight.w400,
          );
      final name = Text(
        entry.primaryLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: nameStyle,
      );
      final badge = _BattleMoveInfoBadge(
        label: typeLabel,
        background: badgeColor,
        foreground: chrome.dockText,
        border: badgeColor,
      );
      final status = entry.statusLabel;
      final bottom = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (status != null && !largeText)
            Expanded(
              child: Text(
                status,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: detailStyle,
              ),
            )
          else
            const Spacer(),
          if (entry.trailingLabel case final pp?) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                pp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: detailStyle.copyWith(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      );
      if (compact) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: name),
                const SizedBox(width: 8),
                badge,
              ],
            ),
            const SizedBox(height: 4),
            bottom,
          ],
        );
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          name,
          Align(alignment: Alignment.centerLeft, child: badge),
          bottom,
        ],
      );
    },
  );
}

class _BattleMoveInfoBadge extends StatelessWidget {
  const _BattleMoveInfoBadge({
    required this.label,
    required this.background,
    required this.foreground,
    required this.border,
    this.horizontalPadding = 7,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color border;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 2),
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
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: .3,
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

bool _usesCanonicalBattleStructure(ProjectBattlePresentationProfile? profile) =>
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
}) => ProjectWindowStyleProfile(
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

Color _battleReadableForeground(
  Color background,
  Color preferred,
  PokeMapPlayerBattleChrome chrome,
) {
  double contrast(Color foreground) {
    final first = foreground.computeLuminance();
    final second = background.computeLuminance();
    return (math.max(first, second) + .05) / (math.min(first, second) + .05);
  }

  if (contrast(preferred) >= 4.5) return preferred;
  final alternatives = [chrome.hudText, chrome.underplate, chrome.textPrimary];
  return alternatives.reduce((a, b) => contrast(a) >= contrast(b) ? a : b);
}

int _commandOrder(ProjectBattleCommandId? commandId) => switch (commandId) {
  ProjectBattleCommandId.fight => 0,
  ProjectBattleCommandId.party => 1,
  ProjectBattleCommandId.bag => 2,
  ProjectBattleCommandId.run => 3,
  null => 4,
};

Color? _commandColor(
  PokeMapPlayerBattleChrome chrome,
  ProjectBattleCommandId? commandId,
) => switch (commandId) {
  ProjectBattleCommandId.fight => chrome.commandFight,
  ProjectBattleCommandId.bag => chrome.commandBag,
  ProjectBattleCommandId.party => chrome.commandParty,
  ProjectBattleCommandId.run => chrome.commandRun,
  null => null,
};

Color _moveTypeColor(BuildContext context, String typeId) {
  final colors = context.playerColors;
  final chrome = context.playerBattleChrome;
  return switch (typeId.trim().toLowerCase()) {
    'fire' => chrome.typeFire,
    'water' || 'ice' => chrome.typeWater,
    'flying' => colors.focus,
    'electric' => chrome.typeElectric,
    'grass' || 'bug' => chrome.typeGrass,
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
    'normal' => chrome.typeNormal,
    _ => chrome.textSecondary,
  };
}

String _battleBagCategoryLabel(
  PokeMapPlayerLocalizations localizations,
  PlayerBattleEntryTone tone,
) => switch (tone) {
  PlayerBattleEntryTone.medicine => localizations.battleBagMedicine,
  PlayerBattleEntryTone.capture => localizations.battleBagCapture,
  _ => localizations.battleBagOther,
};

Color _toneColor(PokeMapPlayerColors colors, PlayerBattleEntryTone tone) {
  return switch (tone) {
    PlayerBattleEntryTone.medicine => colors.success,
    PlayerBattleEntryTone.attack ||
    PlayerBattleEntryTone.capture => colors.primary,
    PlayerBattleEntryTone.special => colors.focus,
    PlayerBattleEntryTone.support ||
    PlayerBattleEntryTone.switching => colors.warning,
    PlayerBattleEntryTone.disabled => colors.textSecondary,
    PlayerBattleEntryTone.neutral => colors.outline,
  };
}
