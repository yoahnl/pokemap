import 'dart:io';

import 'package:flutter/material.dart';

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
            constraints.maxHeight <= 58 || constraints.maxWidth <= 160;
        final compact = ultraCompact ||
            constraints.maxHeight <= 78 ||
            constraints.maxWidth <= 210;
        final showOwnerRow = !ultraCompact && constraints.maxHeight >= 66;
        final verticalPadding = ultraCompact
            ? 5.0
            : compact
                ? 7.0
                : 9.0;
        final horizontalPadding = ultraCompact
            ? 7.0
            : compact
                ? 9.0
                : 12.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xF5F5EFE2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF7B8694), width: 1.4),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              verticalPadding,
              horizontalPadding,
              verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (showOwnerRow)
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          snapshot.ownerLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF687586),
                            fontSize: compact ? 8 : 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                      if (statusLabel != null &&
                          statusLabel.isNotEmpty) ...<Widget>[
                        const SizedBox(width: 6),
                        _HudStatusPill(
                          label: statusLabel,
                          fontSize: compact ? 8 : 10,
                        ),
                      ],
                    ],
                  ),
                if (showOwnerRow) SizedBox(height: compact ? 2 : 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        nameLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFF212938),
                          fontSize: ultraCompact
                              ? 10
                              : compact
                                  ? 12
                                  : snapshot.isPlayerSide
                                      ? 16
                                      : 15,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ),
                    if (genderLabel != null &&
                        genderLabel.isNotEmpty &&
                        !compact &&
                        constraints.maxHeight >= 76)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 1),
                        child: Text(
                          genderLabel,
                          style: const TextStyle(
                            color: Color(0xFF4B5A71),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(left: compact ? 4 : 8, top: 1),
                      child: Text(
                        'Lv.${snapshot.level}',
                        style: TextStyle(
                          color: const Color(0xFF3D495B),
                          fontSize: ultraCompact
                              ? 9
                              : compact
                                  ? 10
                                  : 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 4 : 6),
                Row(
                  children: <Widget>[
                    if (!ultraCompact)
                      Text(
                        'HP',
                        style: TextStyle(
                          color: const Color(0xFFB87D2F),
                          fontSize: compact ? 8 : 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    if (!ultraCompact) const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: ultraCompact
                              ? 5
                              : compact
                                  ? 6
                                  : 8,
                          child: ColoredBox(
                            color: const Color(0xFFBCC5CF),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(end: hpRatio),
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return FractionallySizedBox(
                                    widthFactor: value,
                                    alignment: Alignment.centerLeft,
                                    child: child,
                                  );
                                },
                                child: ColoredBox(color: _hpColor(hpRatio)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (snapshot.isPlayerSide && !compact) ...<Widget>[
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${snapshot.currentHp}/${snapshot.maxHp}',
                      style: const TextStyle(
                        color: Color(0xFF364355),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
    required this.snapshot,
    required this.onEntrySelected,
    required this.onBack,
    required this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final VoidCallback? onBack;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLandscape =
            constraints.maxWidth >= 560 && constraints.maxHeight < 196;
        final useSplitLayout = !compactLandscape &&
            constraints.maxWidth >= 700 &&
            constraints.maxHeight >= 200;
        final stackedPromptHeight =
            (constraints.maxHeight * 0.30).clamp(62.0, 104.0).toDouble();
        final shellPadding = compactLandscape
            ? const EdgeInsets.fromLTRB(10, 10, 10, 10)
            : const EdgeInsets.fromLTRB(12, 12, 12, 12);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xF0283130),
                Color(0xF2212826),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x66E2E6D8), width: 1.3),
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
                _BattlePanelHeader(
                  snapshot: snapshot,
                  onBack: onBack,
                  compact: compactLandscape,
                ),
                SizedBox(height: compactLandscape ? 8 : 10),
                Expanded(
                  child: compactLandscape
                      ? _BattleEntriesSurface(
                          snapshot: snapshot,
                          onEntrySelected: onEntrySelected,
                          itemIconBuilder: itemIconBuilder,
                        )
                      : useSplitLayout
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(
                                  flex: 4,
                                  child: _BattlePromptCard(snapshot: snapshot),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 6,
                                  child: _BattleEntriesSurface(
                                    snapshot: snapshot,
                                    onEntrySelected: onEntrySelected,
                                    itemIconBuilder: itemIconBuilder,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: <Widget>[
                                SizedBox(
                                  height: stackedPromptHeight,
                                  child: _BattlePromptCard(snapshot: snapshot),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _BattleEntriesSurface(
                                    snapshot: snapshot,
                                    onEntrySelected: onEntrySelected,
                                    itemIconBuilder: itemIconBuilder,
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            ),
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final microCompact =
            constraints.maxHeight <= 108 || constraints.maxWidth <= 220;
        final ultraCompact = microCompact || constraints.maxHeight <= 68;
        final compact = ultraCompact || constraints.maxHeight <= 94;
        final showBattleLabel = !ultraCompact && constraints.maxHeight >= 80;
        final showNarration =
            !compact && narration.isNotEmpty && constraints.maxHeight >= 118;

        if (microCompact) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF1E9DB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6D716D), width: 1.1),
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
          decoration: BoxDecoration(
            color: const Color(0xFFF1E9DB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6D716D), width: 1.1),
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
    required this.snapshot,
    required this.onEntrySelected,
    required this.itemIconBuilder,
  });

  final BattleCommandOverlaySnapshot snapshot;
  final ValueChanged<int> onEntrySelected;
  final BattleMobileItemIconBuilder? itemIconBuilder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC1A201F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x667D8A88), width: 1.0),
      ),
      child: switch (snapshot.mode) {
        BattleCommandOverlayMode.root => _BattleRootGrid(
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
        final singleRowGrid = snapshot.entries.length <= 4 &&
            constraints.maxWidth >= 520 &&
            constraints.maxHeight <= 110;
        final crossAxisCount = singleRowGrid
            ? snapshot.entries.length.clamp(1, 4).toInt()
            : constraints.maxWidth < 300
                ? 1
                : 2;
        final compactGrid = singleRowGrid ||
            constraints.maxWidth < 420 ||
            constraints.maxHeight < 180;
        final gridPadding = EdgeInsets.all(singleRowGrid ? 8 : 12);
        return GridView.builder(
          key: const Key('battle-mobile-root-grid'),
          padding: gridPadding,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: singleRowGrid ? 8 : 10,
            crossAxisSpacing: singleRowGrid ? 8 : 10,
            mainAxisExtent: singleRowGrid
                ? (constraints.maxHeight - gridPadding.vertical)
                    .clamp(40.0, 68.0)
                    .toDouble()
                : null,
            childAspectRatio: singleRowGrid
                ? 3.4
                : crossAxisCount == 1
                    ? 3.2
                    : compactGrid
                        ? 1.24
                        : 1.46,
          ),
          itemBuilder: (context, index) {
            final entry = snapshot.entries[index];
            return _BattleEntryTile(
              entry: entry,
              interactionsEnabled: snapshot.interactionsEnabled,
              onPressed: () => onEntrySelected(entry.index),
              itemIconBuilder: itemIconBuilder,
              rootIcon: _rootIconForEntry(entry.primaryLabel),
            );
          },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final useFightGrid = snapshot.mode == BattleCommandOverlayMode.fight &&
            constraints.maxWidth >= 700;
        if (useFightGrid) {
          return GridView.builder(
            key: const Key('battle-mobile-entry-grid'),
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.entries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.95,
            ),
            itemBuilder: (context, index) {
              final entry = snapshot.entries[index];
              return _BattleEntryTile(
                entry: entry,
                interactionsEnabled: snapshot.interactionsEnabled,
                onPressed: () => onEntrySelected(entry.index),
                itemIconBuilder: itemIconBuilder,
              );
            },
          );
        }
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
              dense: snapshot.mode != BattleCommandOverlayMode.fight,
              onPressed: () => onEntrySelected(entry.index),
              itemIconBuilder: itemIconBuilder,
            );
          },
        );
      },
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
    this.rootIcon,
  });

  final BattleCommandOverlayEntry entry;
  final bool interactionsEnabled;
  final VoidCallback onPressed;
  final BattleMobileItemIconBuilder? itemIconBuilder;
  final bool dense;
  final IconData? rootIcon;

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
                        if (rootIcon != null)
                          Padding(
                            padding: EdgeInsets.only(
                              right: compactTile ? 10 : 12,
                              top: 2,
                            ),
                            child: Icon(
                              rootIcon,
                              color: palette.primaryText,
                              size: ultraCompactTile
                                  ? 16
                                  : compactTile
                                      ? 18
                                      : 22,
                            ),
                          ),
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
        color: const Color(0xFF4A5968),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              color: const Color(0xFFF5F7F9),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
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

IconData? _rootIconForEntry(String label) {
  return switch (label.trim().toUpperCase()) {
    'FIGHT' => Icons.flash_on_rounded,
    'BAG' => Icons.backpack_outlined,
    'POKÉMON' || 'POKEMON' => Icons.catching_pokemon_rounded,
    'RUN' => Icons.directions_run_rounded,
    _ => null,
  };
}
