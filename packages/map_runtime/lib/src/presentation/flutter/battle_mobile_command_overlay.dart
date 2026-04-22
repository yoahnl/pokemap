import 'dart:io';

import 'package:flutter/material.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';

import 'battle_command_overlay_snapshot.dart';

typedef BattleMobileItemIconBuilder = Widget Function(String imagePath);

/// Chrome battle Flutter rendue au-dessus du `GameWidget`.
///
/// Le nom historique du fichier est conservé pour limiter le churn local,
/// mais ce widget n'est plus limité au mobile :
/// - il positionne les deux HUDs battle ;
/// - il rend le prompt et les commandes avec de vrais widgets Flutter ;
/// - il laisse Flame s'occuper seulement du décor, des sprites et des flashes.
class BattleMobileCommandOverlay extends StatelessWidget {
  const BattleMobileCommandOverlay({
    super.key,
    required this.snapshot,
    required this.onEntrySelected,
    this.onBack,
    this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final VoidCallback? onBack;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportClass = BattleSceneLayout.classifyViewport(
          viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
        );
        return Stack(
          key: const Key('battle-mobile-command-overlay'),
          clipBehavior: Clip.none,
          children: <Widget>[
            _positionedRect(
              snapshot.enemyHud.rect,
              IgnorePointer(
                child: _BattleHudCard(
                  key: const Key('battle-mobile-enemy-hud'),
                  snapshot: snapshot.enemyHud,
                ),
              ),
            ),
            _positionedRect(
              snapshot.playerHud.rect,
              IgnorePointer(
                child: _BattleHudCard(
                  key: const Key('battle-mobile-player-hud'),
                  snapshot: snapshot.playerHud,
                ),
              ),
            ),
            _positionedRect(
              snapshot.panelRect,
              _BattleCommandPanelShell(
                viewportClass: viewportClass,
                snapshot: snapshot,
                onEntrySelected: onEntrySelected,
                onBack: snapshot.canGoBack && snapshot.interactionsEnabled
                    ? onBack
                    : null,
                itemIconBuilder: itemIconBuilder,
              ),
            ),
          ],
        );
      },
    );
  }
}

Widget _positionedRect(Rect rect, Widget child) {
  return Positioned(
    left: rect.left,
    top: rect.top,
    width: rect.width,
    height: rect.height,
    child: child,
  );
}

class _BattleHudCard extends StatelessWidget {
  const _BattleHudCard({
    super.key,
    required this.snapshot,
  });

  final BattleCommandOverlayHudSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final hpRatio = snapshot.maxHp <= 0
        ? 0.0
        : (snapshot.currentHp / snapshot.maxHp).clamp(0.0, 1.0);
    final nameLabel = _beautifyBattleLabel(snapshot.speciesLabel);
    final genderLabel = snapshot.genderSymbol?.trim();
    final statusLabel = snapshot.statusLabel?.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final ultraCompact =
            constraints.maxHeight <= 48 || constraints.maxWidth <= 148;
        final compact = ultraCompact ||
            constraints.maxHeight <= 64 ||
            constraints.maxWidth <= 196;
        final showHpValue =
            snapshot.isPlayerSide && constraints.maxWidth >= 134;
        final levelFontSize = ultraCompact
            ? 8.5
            : compact
                ? 9.5
                : 12.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F1E7),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(snapshot.isPlayerSide ? 28 : 14),
              bottomRight: Radius.circular(snapshot.isPlayerSide ? 14 : 28),
            ),
            border: Border.all(color: const Color(0xFF8E959E), width: 1.4),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              ultraCompact ? 8 : 10,
              ultraCompact ? 6 : 8,
              ultraCompact ? 8 : 10,
              ultraCompact ? 6 : 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        nameLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF212938),
                          fontSize: ultraCompact
                              ? 10.5
                              : compact
                                  ? 12.5
                                  : snapshot.isPlayerSide
                                      ? 16.5
                                      : 15.5,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                    if (genderLabel != null && genderLabel.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          genderLabel,
                          style: TextStyle(
                            color: const Color(0xFF4B5A71),
                            fontSize: compact ? 9 : 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    if (statusLabel != null &&
                        statusLabel.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 6),
                      _HudStatusPill(
                        label: statusLabel,
                        fontSize: compact ? 7.5 : 9,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      'Lv.${snapshot.level}',
                      style: TextStyle(
                        color: const Color(0xFF3D495B),
                        fontSize: levelFontSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 4 : 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    _BattleHpChip(compact: compact),
                    SizedBox(width: compact ? 6 : 8),
                    Expanded(
                      child: _BattleHpBar(
                        key: Key(
                          snapshot.isPlayerSide
                              ? 'battle-mobile-player-hp-bar'
                              : 'battle-mobile-enemy-hp-bar',
                        ),
                        keyPrefix: snapshot.isPlayerSide ? 'player' : 'enemy',
                        hpRatio: hpRatio,
                        compact: compact,
                      ),
                    ),
                    if (showHpValue) ...<Widget>[
                      SizedBox(width: compact ? 6 : 8),
                      Text(
                        '${snapshot.currentHp}/${snapshot.maxHp}',
                        key: const Key('battle-mobile-player-hp-value'),
                        style: const TextStyle(
                          color: Color(0xFF364355),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BattleHpChip extends StatelessWidget {
  const _BattleHpChip({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF6C55D),
            Color(0xFFD39128),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF7A5A20), width: 0.9),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 7,
          vertical: compact ? 2 : 3,
        ),
        child: Text(
          'HP',
          style: TextStyle(
            color: const Color(0xFF3E2B00),
            fontSize: compact ? 8 : 9,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _BattleHpBar extends StatelessWidget {
  const _BattleHpBar({
    super.key,
    required this.keyPrefix,
    required this.hpRatio,
    required this.compact,
  });

  final String keyPrefix;
  final double hpRatio;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF42505A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7ECEE), width: 0.9),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: compact ? 7 : 9,
            child: ColoredBox(
              color: const Color(0xFFCBD2D9),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: hpRatio),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return FractionallySizedBox(
                      key: Key('battle-mobile-$keyPrefix-hp-fill'),
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: child,
                    );
                  },
                  child: SizedBox.expand(
                    child: DecoratedBox(
                      key: Key(
                        'battle-mobile-$keyPrefix-hp-fill-decoration',
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color.alphaBlend(
                              const Color(0x66FFFFFF),
                              _hpColor(hpRatio),
                            ),
                            _hpColor(hpRatio),
                          ],
                        ),
                      ),
                    ),
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

class _HudStatusPill extends StatelessWidget {
  const _HudStatusPill({
    required this.label,
    required this.fontSize,
  });

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF94A2B7),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF53637A),
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _BattleCommandPanelShell extends StatelessWidget {
  const _BattleCommandPanelShell({
    required this.viewportClass,
    required this.snapshot,
    required this.onEntrySelected,
    required this.onBack,
    required this.itemIconBuilder,
  });

  final BattleViewportClass viewportClass;
  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final VoidCallback? onBack;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shellPadding = switch (viewportClass) {
          BattleViewportClass.compactPortrait =>
            snapshot.mode == BattleCommandOverlayMode.fight
                ? const EdgeInsets.fromLTRB(10, 10, 10, 10)
                : const EdgeInsets.fromLTRB(12, 12, 12, 12),
          BattleViewportClass.mediumLandscape =>
            const EdgeInsets.fromLTRB(14, 12, 14, 12),
          BattleViewportClass.wideDesktop =>
            const EdgeInsets.fromLTRB(18, 16, 18, 16),
        };
        final body = switch (viewportClass) {
          BattleViewportClass.compactPortrait => _CompactPortraitPanelBody(
              snapshot: snapshot,
              onEntrySelected: onEntrySelected,
              itemIconBuilder: itemIconBuilder,
            ),
          BattleViewportClass.mediumLandscape => _LandscapePanelBody(
              wide: false,
              snapshot: snapshot,
              onEntrySelected: onEntrySelected,
              itemIconBuilder: itemIconBuilder,
            ),
          BattleViewportClass.wideDesktop => _LandscapePanelBody(
              wide: true,
              snapshot: snapshot,
              onEntrySelected: onEntrySelected,
              itemIconBuilder: itemIconBuilder,
            ),
        };
        final showHeader =
            viewportClass == BattleViewportClass.compactPortrait ||
                snapshot.mode != BattleCommandOverlayMode.root ||
                onBack != null ||
                !snapshot.interactionsEnabled;
        final headerGap = snapshot.mode == BattleCommandOverlayMode.fight &&
                viewportClass == BattleViewportClass.compactPortrait
            ? 8.0
            : viewportClass == BattleViewportClass.wideDesktop
                ? 14.0
                : 12.0;
        return DecoratedBox(
          key: Key('battle-mobile-panel-${viewportClass.name}'),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xF0343D37),
                Color(0xF0242B27),
              ],
            ),
            borderRadius: BorderRadius.circular(
              viewportClass == BattleViewportClass.wideDesktop ? 24 : 26,
            ),
            border: Border.all(color: const Color(0x80C7CFC8), width: 1.25),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 16,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: shellPadding,
            child: Column(
              children: <Widget>[
                if (showHeader)
                  _BattlePanelHeader(
                    snapshot: snapshot,
                    onBack: onBack,
                    compact:
                        viewportClass == BattleViewportClass.compactPortrait,
                  ),
                if (showHeader) SizedBox(height: headerGap),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactPortraitPanelBody extends StatelessWidget {
  const _CompactPortraitPanelBody({
    required this.snapshot,
    required this.onEntrySelected,
    required this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final submenuMode = snapshot.mode != BattleCommandOverlayMode.root;
        final promptHeight = submenuMode
            ? (constraints.maxHeight * 0.13).clamp(34.0, 42.0).toDouble()
            : (constraints.maxHeight * 0.22).clamp(50.0, 68.0).toDouble();
        final gap = submenuMode ? 6.0 : 10.0;
        return Column(
          children: <Widget>[
            SizedBox(
              height: promptHeight,
              child: _BattlePromptCard(snapshot: snapshot),
            ),
            SizedBox(height: gap),
            Expanded(
              child: _BattleEntriesSurface(
                viewportClass: BattleViewportClass.compactPortrait,
                snapshot: snapshot,
                onEntrySelected: onEntrySelected,
                itemIconBuilder: itemIconBuilder,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LandscapePanelBody extends StatelessWidget {
  const _LandscapePanelBody({
    required this.wide,
    required this.snapshot,
    required this.onEntrySelected,
    required this.itemIconBuilder,
  });

  final bool wide;
  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    final submenuMode = snapshot.mode != BattleCommandOverlayMode.root;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          flex: submenuMode ? (wide ? 3 : 2) : (wide ? 5 : 4),
          child: _BattlePromptCard(snapshot: snapshot),
        ),
        SizedBox(width: submenuMode ? 10 : (wide ? 16 : 12)),
        Expanded(
          flex: submenuMode ? (wide ? 9 : 8) : (wide ? 7 : 6),
          child: _BattleEntriesSurface(
            viewportClass: wide
                ? BattleViewportClass.wideDesktop
                : BattleViewportClass.mediumLandscape,
            snapshot: snapshot,
            onEntrySelected: onEntrySelected,
            itemIconBuilder: itemIconBuilder,
          ),
        ),
      ],
    );
  }
}

class _BattlePanelHeader extends StatelessWidget {
  const _BattlePanelHeader({
    required this.snapshot,
    required this.onBack,
    this.compact = false,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (onBack != null)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _BattleCircleButton(
              key: const Key('battle-mobile-back-button'),
              icon: Icons.arrow_back_rounded,
              tooltip: 'Retour',
              onPressed: onBack,
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                snapshot.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFF3F5F6),
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              SizedBox(height: compact ? 2 : 3),
              Text(
                compact ? snapshot.prompt : snapshot.battleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: compact
                      ? const Color(0xFFE4E8E5)
                      : const Color(0xFFB7C1C3),
                  fontSize: compact ? 12 : 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: compact ? 0 : 1.1,
                ),
              ),
            ],
          ),
        ),
        if (!snapshot.interactionsEnabled)
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0x334C5A58),
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                'Résolution...',
                style: TextStyle(
                  color: const Color(0xFFF0F4F5),
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BattlePromptCard extends StatelessWidget {
  const _BattlePromptCard({
    required this.snapshot,
  });

  final BattleCommandOverlaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final narration = snapshot.narrationLines
        .where((line) => line.trim().isNotEmpty)
        .take(2)
        .join('\n');
    final submenuMode = snapshot.mode != BattleCommandOverlayMode.root;
    return LayoutBuilder(
      builder: (context, constraints) {
        final microCompact = submenuMode ||
            constraints.maxHeight <= 124 ||
            constraints.maxWidth <= 220;
        final ultraCompact = microCompact || constraints.maxHeight <= 68;
        final compact = ultraCompact || constraints.maxHeight <= 94;
        final showBattleLabel =
            !submenuMode && !ultraCompact && constraints.maxHeight >= 80;
        final showNarration = !submenuMode &&
            !compact &&
            narration.isNotEmpty &&
            constraints.maxHeight >= 118;

        if (microCompact) {
          return DecoratedBox(
            key: const Key('battle-mobile-prompt-card'),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4C9B7), width: 1.1),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  snapshot.prompt,
                  maxLines: constraints.maxHeight <= 66 ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF232B31),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ),
            ),
          );
        }

        return DecoratedBox(
          key: const Key('battle-mobile-prompt-card'),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F1E7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4C9B7), width: 1.1),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                16, compact ? 10 : 14, 16, compact ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showBattleLabel)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1D6C3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        snapshot.battleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF65717B),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                if (showBattleLabel) SizedBox(height: compact ? 6 : 12),
                Text(
                  snapshot.prompt,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF232B31),
                    fontSize: ultraCompact
                        ? 15
                        : compact
                            ? 17
                            : 21,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                if (showNarration) ...<Widget>[
                  const SizedBox(height: 10),
                  Flexible(
                    child: Text(
                      narration,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF546066),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BattleEntriesSurface extends StatelessWidget {
  const _BattleEntriesSurface({
    required this.viewportClass,
    required this.snapshot,
    required this.onEntrySelected,
    required this.itemIconBuilder,
  });

  final BattleViewportClass viewportClass;
  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: snapshot.mode == BattleCommandOverlayMode.root
            ? const Color(0x12000000)
            : const Color(0x26181E1C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x66C3CAC4), width: 1.0),
      ),
      child: switch (snapshot.mode) {
        BattleCommandOverlayMode.root => _BattleRootGrid(
            viewportClass: viewportClass,
            snapshot: snapshot,
            onEntrySelected: onEntrySelected,
          ),
        BattleCommandOverlayMode.fight => _BattleMoveGrid(
            viewportClass: viewportClass,
            snapshot: snapshot,
            onEntrySelected: onEntrySelected,
          ),
        BattleCommandOverlayMode.bag => _BattleBagList(
            snapshot: snapshot,
            onEntrySelected: onEntrySelected,
            itemIconBuilder: itemIconBuilder,
          ),
        _ => _BattleEntryList(
            snapshot: snapshot,
            onEntrySelected: onEntrySelected,
            itemIconBuilder: itemIconBuilder,
          ),
      },
    );
  }
}

class _BattleRootGrid extends StatelessWidget {
  const _BattleRootGrid({
    required this.viewportClass,
    required this.snapshot,
    required this.onEntrySelected,
  });

  final BattleViewportClass viewportClass;
  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactGrid =
            viewportClass == BattleViewportClass.compactPortrait ||
                constraints.maxHeight < 180;
        final gap = compactGrid ? 8.0 : 10.0;
        final entries = snapshot.entries;
        final rows = <List<BattleCommandOverlayEntry>>[];
        for (var index = 0; index < entries.length; index += 2) {
          rows.add(entries.skip(index).take(2).toList());
        }
        return Padding(
          padding: EdgeInsets.all(compactGrid ? 8 : 10),
          child: Column(
            key: const Key('battle-mobile-root-grid'),
            children: <Widget>[
              for (var rowIndex = 0;
                  rowIndex < rows.length;
                  rowIndex++) ...<Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      for (var columnIndex = 0;
                          columnIndex < rows[rowIndex].length;
                          columnIndex++) ...<Widget>[
                        Expanded(
                          child: _BattleRootTile(
                            entry: rows[rowIndex][columnIndex],
                            interactionsEnabled: snapshot.interactionsEnabled,
                            onPressed: () => onEntrySelected(
                              rows[rowIndex][columnIndex].index,
                            ),
                          ),
                        ),
                        if (columnIndex < rows[rowIndex].length - 1)
                          SizedBox(width: gap),
                      ],
                    ],
                  ),
                ),
                if (rowIndex < rows.length - 1) SizedBox(height: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BattleEntryList extends StatelessWidget {
  const _BattleEntryList({
    required this.snapshot,
    required this.onEntrySelected,
    required this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const Key('battle-mobile-entry-list'),
      padding: const EdgeInsets.all(12),
      physics: const BouncingScrollPhysics(),
      itemCount: snapshot.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = snapshot.entries[index];
        return _BattleEntryTile(
          entry: entry,
          interactionsEnabled: snapshot.interactionsEnabled,
          dense: true,
          onPressed: () => onEntrySelected(entry.index),
          itemIconBuilder: itemIconBuilder,
        );
      },
    );
  }
}

class _BattleMoveGrid extends StatelessWidget {
  const _BattleMoveGrid({
    required this.viewportClass,
    required this.snapshot,
    required this.onEntrySelected,
  });

  final BattleViewportClass viewportClass;
  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactPortrait =
            viewportClass == BattleViewportClass.compactPortrait;
        final useTwoColumnGrid = snapshot.entries.length > 1 &&
            (compactPortrait || constraints.maxWidth >= 420);
        final compactTiles = compactPortrait || constraints.maxHeight < 172;
        final padding = compactPortrait ? 8.0 : 12.0;
        final gap = compactPortrait ? 8.0 : 10.0;
        final aspectRatio = compactPortrait
            ? 3.35
            : constraints.maxHeight < 172
                ? 3.6
                : 2.5;

        if (useTwoColumnGrid && snapshot.entries.length <= 4) {
          final rows = <List<BattleCommandOverlayEntry>>[];
          for (var index = 0; index < snapshot.entries.length; index += 2) {
            rows.add(snapshot.entries.skip(index).take(2).toList());
          }
          final compactPortraitRowHeight = compactPortrait
              ? ((constraints.maxHeight - gap) / 2).clamp(44.0, 56.0).toDouble()
              : null;
          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              key: const Key('battle-mobile-entry-grid'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (var rowIndex = 0;
                    rowIndex < rows.length;
                    rowIndex++) ...<Widget>[
                  if (compactPortraitRowHeight != null)
                    SizedBox(
                      height: compactPortraitRowHeight,
                      child: Row(
                        children: <Widget>[
                          for (var columnIndex = 0;
                              columnIndex < rows[rowIndex].length;
                              columnIndex++) ...<Widget>[
                            Expanded(
                              child: _BattleMoveTile(
                                entry: rows[rowIndex][columnIndex],
                                interactionsEnabled:
                                    snapshot.interactionsEnabled,
                                compact: compactTiles,
                                onPressed: () => onEntrySelected(
                                  rows[rowIndex][columnIndex].index,
                                ),
                              ),
                            ),
                            if (columnIndex < rows[rowIndex].length - 1)
                              SizedBox(width: gap),
                          ],
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          for (var columnIndex = 0;
                              columnIndex < rows[rowIndex].length;
                              columnIndex++) ...<Widget>[
                            Expanded(
                              child: _BattleMoveTile(
                                entry: rows[rowIndex][columnIndex],
                                interactionsEnabled:
                                    snapshot.interactionsEnabled,
                                compact: compactTiles,
                                onPressed: () => onEntrySelected(
                                  rows[rowIndex][columnIndex].index,
                                ),
                              ),
                            ),
                            if (columnIndex < rows[rowIndex].length - 1)
                              SizedBox(width: gap),
                          ],
                        ],
                      ),
                    ),
                  if (rowIndex < rows.length - 1) SizedBox(height: gap),
                ],
                if (compactPortraitRowHeight != null) const Spacer(),
              ],
            ),
          );
        }

        if (useTwoColumnGrid) {
          return GridView.builder(
            key: const Key('battle-mobile-entry-grid'),
            padding: EdgeInsets.all(padding),
            itemCount: snapshot.entries.length,
            physics: snapshot.entries.length <= 4
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              childAspectRatio: aspectRatio,
            ),
            itemBuilder: (context, index) {
              final entry = snapshot.entries[index];
              return _BattleMoveTile(
                entry: entry,
                interactionsEnabled: snapshot.interactionsEnabled,
                compact: compactTiles,
                onPressed: () => onEntrySelected(entry.index),
              );
            },
          );
        }

        return ListView.separated(
          key: const Key('battle-mobile-entry-list'),
          padding: EdgeInsets.all(padding),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.entries.length,
          separatorBuilder: (_, __) => SizedBox(height: gap),
          itemBuilder: (context, index) {
            final entry = snapshot.entries[index];
            return _BattleMoveTile(
              entry: entry,
              interactionsEnabled: snapshot.interactionsEnabled,
              compact: false,
              onPressed: () => onEntrySelected(entry.index),
            );
          },
        );
      },
    );
  }
}

class _BattleBagList extends StatelessWidget {
  const _BattleBagList({
    required this.snapshot,
    required this.onEntrySelected,
    required this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    final sortedEntries = _sortedBagEntries(snapshot.entries);
    final sections = <_BattleBagSectionData>[];
    for (final entry in sortedEntries) {
      final label = _bagSectionLabel(entry);
      if (sections.isEmpty || sections.last.label != label) {
        sections.add(_BattleBagSectionData(
            label: label, entries: <BattleCommandOverlayEntry>[entry]));
      } else {
        sections.last.entries.add(entry);
      }
    }

    return ListView(
      key: const Key('battle-mobile-entry-list'),
      padding: const EdgeInsets.all(10),
      physics: const BouncingScrollPhysics(),
      cacheExtent: 1200,
      children: <Widget>[
        for (var sectionIndex = 0;
            sectionIndex < sections.length;
            sectionIndex++) ...<Widget>[
          _BattleBagSectionHeader(
            label: sections[sectionIndex].label,
          ),
          const SizedBox(height: 6),
          for (var entryIndex = 0;
              entryIndex < sections[sectionIndex].entries.length;
              entryIndex++) ...<Widget>[
            _BattleBagTile(
              entry: sections[sectionIndex].entries[entryIndex],
              interactionsEnabled: snapshot.interactionsEnabled,
              onPressed: () => onEntrySelected(
                sections[sectionIndex].entries[entryIndex].index,
              ),
              itemIconBuilder: itemIconBuilder,
            ),
            if (entryIndex < sections[sectionIndex].entries.length - 1)
              const SizedBox(height: 6),
          ],
          if (sectionIndex < sections.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _BattleBagSectionData {
  _BattleBagSectionData({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<BattleCommandOverlayEntry> entries;
}

class _BattleRootTile extends StatelessWidget {
  const _BattleRootTile({
    required this.entry,
    required this.interactionsEnabled,
    required this.onPressed,
  });

  final BattleCommandOverlayEntry entry;
  final bool interactionsEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = _rootPaletteForLabel(
      entry.primaryLabel,
      enabled: entry.enabled,
    );
    final tappable = interactionsEnabled && entry.enabled;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: tappable ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('battle-mobile-entry-${entry.index}'),
          borderRadius: BorderRadius.circular(18),
          splashFactory: NoSplash.splashFactory,
          onTap: tappable ? onPressed : null,
          child: DecoratedBox(
            key: Key('battle-mobile-root-tile-${entry.index}'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  palette.primary,
                  palette.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    entry.selected ? const Color(0xFFF6E8B0) : palette.border,
                width: entry.selected ? 3 : 1.3,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 58;
                final ultraCompact = constraints.maxHeight < 44;
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0x22FFFFFF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: SizedBox(height: compact ? 18 : 28),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 8 : 12,
                        compact ? 7 : 12,
                        compact ? 8 : 12,
                        compact ? 6 : 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            entry.primaryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFFFEFEFE),
                              fontSize: ultraCompact
                                  ? 13
                                  : compact
                                      ? 15
                                      : 18,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (!ultraCompact &&
                              entry.secondaryLabel.isNotEmpty) ...<Widget>[
                            SizedBox(height: compact ? 4 : 8),
                            Text(
                              entry.secondaryLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFF5F0E8),
                                fontSize: compact ? 10 : 11,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleMoveTile extends StatelessWidget {
  const _BattleMoveTile({
    required this.entry,
    required this.interactionsEnabled,
    required this.onPressed,
    required this.compact,
  });

  final BattleCommandOverlayEntry entry;
  final bool interactionsEnabled;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForEntryTone(entry.tone, enabled: entry.enabled);
    final tappable = interactionsEnabled && entry.enabled;
    final trailing = entry.trailingLabel?.trim();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: tappable ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('battle-mobile-entry-${entry.index}'),
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
          splashFactory: NoSplash.splashFactory,
          onTap: tappable ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color.alphaBlend(const Color(0x2CFFFFFF), palette.fill),
                  palette.fill,
                ],
              ),
              borderRadius: BorderRadius.circular(compact ? 16 : 18),
              border: Border.all(
                color:
                    entry.selected ? const Color(0xFFF7F0D8) : palette.border,
                width: entry.selected ? 2.4 : 1.2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 11,
                compact ? 6 : 8,
                compact ? 10 : 11,
                compact ? 6 : 8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          entry.primaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.primaryText,
                            fontSize: compact ? 15 : 17,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                      if (trailing != null && trailing.isNotEmpty && !compact)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 1),
                          child: Text(
                            trailing,
                            maxLines: 1,
                            style: TextStyle(
                              color: palette.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (entry.secondaryLabel.isNotEmpty) ...<Widget>[
                    SizedBox(height: compact ? 2 : 4),
                    Text(
                      entry.secondaryLabel,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.secondaryText,
                        fontSize: compact ? 10 : 11.5,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleBagSectionHeader extends StatelessWidget {
  const _BattleBagSectionHeader({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        DecoratedBox(
          key: Key('battle-mobile-bag-section-$label'),
          decoration: BoxDecoration(
            color: const Color(0x223F4D48),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x55D6DDD9), width: 0.9),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFE7ECE8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BattleBagTile extends StatelessWidget {
  const _BattleBagTile({
    required this.entry,
    required this.interactionsEnabled,
    required this.onPressed,
    required this.itemIconBuilder,
  });

  final BattleCommandOverlayEntry entry;
  final bool interactionsEnabled;
  final VoidCallback onPressed;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForEntryTone(entry.tone, enabled: entry.enabled);
    final tappable = interactionsEnabled && entry.enabled;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: tappable ? 1 : 0.74,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('battle-mobile-entry-${entry.index}'),
          borderRadius: BorderRadius.circular(16),
          splashFactory: NoSplash.splashFactory,
          onTap: tappable ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              color: palette.fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    entry.selected ? const Color(0xFFF7F0D8) : palette.border,
                width: entry.selected ? 2.2 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Row(
                children: <Widget>[
                  if (entry.iconAssetPath != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: KeyedSubtree(
                        key: Key('battle-mobile-entry-icon-${entry.index}'),
                        child: itemIconBuilder?.call(entry.iconAssetPath!) ??
                            _BattleItemIcon(imagePath: entry.iconAssetPath!),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          entry.primaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          entry.statusLabel == null ||
                                  entry.statusLabel!.trim().isEmpty
                              ? entry.secondaryLabel
                              : '${entry.secondaryLabel} · ${entry.statusLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.secondaryText,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.trailingLabel case final trailing?)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        trailing,
                        maxLines: 1,
                        style: TextStyle(
                          color: palette.primaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleEntryTile extends StatelessWidget {
  const _BattleEntryTile({
    required this.entry,
    required this.interactionsEnabled,
    required this.onPressed,
    required this.itemIconBuilder,
    this.dense = false,
  });

  final BattleCommandOverlayEntry entry;
  final bool interactionsEnabled;
  final VoidCallback onPressed;
  final BattleMobileItemIconBuilder? itemIconBuilder;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForEntryTone(entry.tone, enabled: entry.enabled);
    final tappable = interactionsEnabled && entry.enabled;
    final minHeight = switch (entry.kind) {
      BattleCommandOverlayEntryKind.move => 88.0,
      BattleCommandOverlayEntryKind.root => 72.0,
      _ => dense ? 78.0 : 84.0,
    };
    final primaryLabel = switch (entry.kind) {
      BattleCommandOverlayEntryKind.party ||
      BattleCommandOverlayEntryKind.medicineTarget =>
        _beautifyBattleLabel(
          entry.primaryLabel,
        ),
      _ => entry.primaryLabel,
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: tappable ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('battle-mobile-entry-${entry.index}'),
          borderRadius: BorderRadius.circular(20),
          splashFactory: NoSplash.splashFactory,
          onTap: tappable ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              color: palette.fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    entry.selected ? const Color(0xFFF7F0D8) : palette.border,
                width: entry.selected ? 3 : 1.2,
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final ultraCompactTile = constraints.maxHeight <= 72 ||
                      constraints.maxWidth <= 118;
                  final compactTile = ultraCompactTile ||
                      constraints.maxHeight <= 82 ||
                      constraints.maxWidth <= 145;
                  final showSecondary = entry.secondaryLabel.isNotEmpty &&
                      !(entry.kind == BattleCommandOverlayEntryKind.root &&
                          ultraCompactTile);
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      compactTile ? 10 : 14,
                      compactTile ? 8 : 12,
                      compactTile ? 10 : 14,
                      compactTile ? 8 : 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (entry.iconAssetPath != null)
                          Padding(
                            padding: EdgeInsets.only(
                              right: compactTile ? 10 : 12,
                              top: 2,
                            ),
                            child: KeyedSubtree(
                              key: Key(
                                  'battle-mobile-entry-icon-${entry.index}'),
                              child:
                                  itemIconBuilder?.call(entry.iconAssetPath!) ??
                                      _BattleItemIcon(
                                        imagePath: entry.iconAssetPath!,
                                      ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      primaryLabel,
                                      maxLines: entry.kind ==
                                              BattleCommandOverlayEntryKind.root
                                          ? 1
                                          : compactTile
                                              ? 1
                                              : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: palette.primaryText,
                                        fontSize: ultraCompactTile
                                            ? 14
                                            : compactTile
                                                ? 16
                                                : entry.kind ==
                                                        BattleCommandOverlayEntryKind
                                                            .root
                                                    ? 18
                                                    : dense
                                                        ? 20
                                                        : 22,
                                        fontWeight: FontWeight.w900,
                                        height: 1.04,
                                      ),
                                    ),
                                  ),
                                  if (entry.trailingLabel case final trailing?)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        top: 2,
                                      ),
                                      child: Text(
                                        trailing,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: palette.secondaryText,
                                          fontSize: ultraCompactTile
                                              ? 11
                                              : compactTile
                                                  ? 13
                                                  : 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (showSecondary) ...<Widget>[
                                SizedBox(height: compactTile ? 3 : 8),
                                Text(
                                  entry.secondaryLabel,
                                  maxLines: ultraCompactTile
                                      ? 1
                                      : compactTile
                                          ? 1
                                          : entry.kind ==
                                                  BattleCommandOverlayEntryKind
                                                      .move
                                              ? 3
                                              : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.secondaryText,
                                    fontSize: ultraCompactTile
                                        ? 10
                                        : compactTile
                                            ? 11
                                            : dense
                                                ? 14
                                                : 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                              if (!compactTile &&
                                  entry.tertiaryLabel != null) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  entry.tertiaryLabel!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: palette.secondaryText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (entry.statusLabel case final status?)
                          Padding(
                            padding: EdgeInsets.only(
                              left: compactTile ? 8 : 10,
                              top: 2,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: entry.enabled
                                    ? const Color(0x1FD8F1D7)
                                    : const Color(0x22F1E4D8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: entry.enabled
                                        ? const Color(0xFFD2F2D3)
                                        : const Color(0xFFF0E8DB),
                                    fontSize: ultraCompactTile
                                        ? 10
                                        : compactTile
                                            ? 11
                                            : 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleItemIcon extends StatelessWidget {
  const _BattleItemIcon({
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    Widget buildFallback() {
      return const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x664A5560),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFFE8EDF0),
          size: 18,
        ),
      );
    }

    final imageBytes = () {
      try {
        final file = File(imagePath);
        if (!file.existsSync()) {
          return null;
        }
        return file.readAsBytesSync();
      } catch (_) {
        return null;
      }
    }();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 32,
        height: 32,
        child: imageBytes == null
            ? buildFallback()
            : Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => buildFallback(),
              ),
      ),
    );
  }
}

class _BattleCircleButton extends StatelessWidget {
  const _BattleCircleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFF0E8DA),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          splashFactory: NoSplash.splashFactory,
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: const Color(0xFF485564),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleRootPalette {
  const _BattleRootPalette({
    required this.primary,
    required this.secondary,
    required this.border,
  });

  final Color primary;
  final Color secondary;
  final Color border;
}

_BattleRootPalette _rootPaletteForLabel(
  String label, {
  required bool enabled,
}) {
  if (!enabled) {
    return const _BattleRootPalette(
      primary: Color(0xFF717781),
      secondary: Color(0xFF525964),
      border: Color(0xFFD3D8DF),
    );
  }
  return switch (label.trim().toUpperCase()) {
    'FIGHT' => const _BattleRootPalette(
        primary: Color(0xFFF5897D),
        secondary: Color(0xFFD55D59),
        border: Color(0xFFF8D1C8),
      ),
    'BAG' => const _BattleRootPalette(
        primary: Color(0xFFE8B95D),
        secondary: Color(0xFFC48D2B),
        border: Color(0xFFF5E1AF),
      ),
    'POKÉMON' || 'POKEMON' => const _BattleRootPalette(
        primary: Color(0xFF86B665),
        secondary: Color(0xFF4E7E3D),
        border: Color(0xFFD6E7BE),
      ),
    'RUN' => const _BattleRootPalette(
        primary: Color(0xFF6C95D8),
        secondary: Color(0xFF4569B1),
        border: Color(0xFFD8E3FA),
      ),
    _ => const _BattleRootPalette(
        primary: Color(0xFF7A8DA3),
        secondary: Color(0xFF5B6D82),
        border: Color(0xFFD9E2EB),
      ),
  };
}

class _BattleEntryPalette {
  const _BattleEntryPalette({
    required this.fill,
    required this.border,
    required this.primaryText,
    required this.secondaryText,
  });

  final Color fill;
  final Color border;
  final Color primaryText;
  final Color secondaryText;
}

_BattleEntryPalette _paletteForEntryTone(
  BattleCommandOverlayEntryTone tone, {
  required bool enabled,
}) {
  if (!enabled || tone == BattleCommandOverlayEntryTone.disabled) {
    return const _BattleEntryPalette(
      fill: Color(0xFF535861),
      border: Color(0xFF8D95A0),
      primaryText: Color(0xFFF1F2F3),
      secondaryText: Color(0xFFD9DCE0),
    );
  }
  return switch (tone) {
    BattleCommandOverlayEntryTone.attack => const _BattleEntryPalette(
        fill: Color(0xFFC46F62),
        border: Color(0xFFF0CBBB),
        primaryText: Color(0xFFFBF4EE),
        secondaryText: Color(0xFFF3E4DA),
      ),
    BattleCommandOverlayEntryTone.special => const _BattleEntryPalette(
        fill: Color(0xFF5F80BF),
        border: Color(0xFFD6E3FB),
        primaryText: Color(0xFFF7FAFF),
        secondaryText: Color(0xFFE0E9FB),
      ),
    BattleCommandOverlayEntryTone.support => const _BattleEntryPalette(
        fill: Color(0xFF6A9A82),
        border: Color(0xFFD8EBDE),
        primaryText: Color(0xFFF5FAF6),
        secondaryText: Color(0xFFE1EEE3),
      ),
    BattleCommandOverlayEntryTone.switching => const _BattleEntryPalette(
        fill: Color(0xFF496DB0),
        border: Color(0xFFD5E0F7),
        primaryText: Color(0xFFF7FAFF),
        secondaryText: Color(0xFFDCE6FA),
      ),
    BattleCommandOverlayEntryTone.medicine => const _BattleEntryPalette(
        fill: Color(0xFF846748),
        border: Color(0xFFF0E3C6),
        primaryText: Color(0xFFF8F2E8),
        secondaryText: Color(0xFFEEDFCE),
      ),
    BattleCommandOverlayEntryTone.capture => const _BattleEntryPalette(
        fill: Color(0xFF7A4A40),
        border: Color(0xFFF0D7CF),
        primaryText: Color(0xFFF8F1EE),
        secondaryText: Color(0xFFF0E1DC),
      ),
    _ => const _BattleEntryPalette(
        fill: Color(0xFF536779),
        border: Color(0xFFD7E2EB),
        primaryText: Color(0xFFF5F8FB),
        secondaryText: Color(0xFFD7E0E7),
      ),
  };
}

List<BattleCommandOverlayEntry> _sortedBagEntries(
  List<BattleCommandOverlayEntry> entries,
) {
  final sorted = List<BattleCommandOverlayEntry>.of(entries);
  sorted.sort((left, right) {
    final rankCompare = _bagSectionRank(left).compareTo(_bagSectionRank(right));
    if (rankCompare != 0) {
      return rankCompare;
    }
    final labelCompare = left.secondaryLabel.compareTo(right.secondaryLabel);
    if (labelCompare != 0) {
      return labelCompare;
    }
    final nameCompare = left.primaryLabel.compareTo(right.primaryLabel);
    if (nameCompare != 0) {
      return nameCompare;
    }
    return left.index.compareTo(right.index);
  });
  return sorted;
}

int _bagSectionRank(BattleCommandOverlayEntry entry) {
  final normalized = _bagSectionLabel(entry).toLowerCase();
  return switch (normalized) {
    'capture' => 0,
    'medicine' => 1,
    'unsupported' => 2,
    _ => 3,
  };
}

String _bagSectionLabel(BattleCommandOverlayEntry entry) {
  final normalized = entry.secondaryLabel.trim();
  if (normalized.isEmpty) {
    return 'Items';
  }
  return normalized;
}

Color _hpColor(double hpRatio) {
  if (hpRatio <= 0.25) {
    return const Color(0xFFD35B49);
  }
  if (hpRatio <= 0.5) {
    return const Color(0xFFD9A84B);
  }
  return const Color(0xFF62C06E);
}

String _beautifyBattleLabel(String raw) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return raw;
  }
  final separatorsNormalized = normalized
      .replaceAll('-', ' ')
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'));
  return separatorsNormalized
      .map(
        (token) => token.isEmpty
            ? token
            : '${token[0].toUpperCase()}${token.substring(1)}',
      )
      .join(' ');
}
