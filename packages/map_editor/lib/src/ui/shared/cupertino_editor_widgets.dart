import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show BoxShadow, Colors, Material;
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../theme/theme.dart';
import 'editor_visual_tokens.dart';

abstract final class EditorChrome {
  static bool _isDark(BuildContext context) =>
      MacosTheme.brightnessOf(context) == Brightness.dark;

  static const Color accentPrimary = Color(0xFF6BA8FF);
  static const Color accentCyan = Color(0xFF5FD4E8);
  static const Color accentJade = Color(0xFF5FD4B0);
  static const Color accentWarm = Color(0xFFE8B068);
  static const Color accentCoral = Color(0xFFE8887A);
  static const Color accentPrune = Color(0xFF7A5A92);
  static const Color accentLilac = Color(0xFFC8B0F2);

  /// Rose chaud discret (halos, milieu de dégradé).
  static const Color accentRose = Color(0xFFD898B0);

  /// Magenta profond, usage rare (accents nobles).
  static const Color accentMagentaDeep = Color(0xFF6E4A78);

  /// World Explorer — sarcelle / bleu profond chaleureux (pas gris-bleu admin).
  static const Color islandCoolTint = Color(0xFF3A5A72);

  /// Inspector — violet prune rosé.
  static const Color islandNeutralTint = Color(0xFF5C4670);

  /// Surface Library — ambre / terre chaude.
  static const Color islandWarmTint = Color(0xFF6B5438);

  // --- Accents inspecteur : **chauds & acides** (saturation forte, pas pastel) ---
  static const Color inspectorJoyHoney = Color(0xFFFFC400);
  static const Color inspectorJoyApricot = Color(0xFFFF6B2C);
  static const Color inspectorJoyBlue = Color(0xFFFF9500);
  static const Color inspectorJoyLilac = Color(0xFFFF3D9A);
  static const Color inspectorJoyMint = Color(0xFFC8FF2E);
  static const Color inspectorJoyAmber = Color(0xFFFFB000);
  static const Color inspectorJoyCyan = Color(0xFF00E8D4);
  static const Color inspectorJoyPlum = Color(0xFFD930FF);
  static const Color inspectorJoyCoral = Color(0xFFFF4A2E);
  static const Color inspectorJoyOrchid = Color(0xFFFF1A8C);

  // --- Tokens de structure (seuls fonds d’architecture) ---
  static Color appBackground(BuildContext context) =>
      EditorVisualTokens.appBackground(context);

  /// Fond racine (fenêtre) : dégradé en clair, **couleur unie** en sombre.
  static BoxDecoration appRootDecoration(BuildContext context) {
    final g = EditorVisualTokens.appBackgroundGradient(context);
    if (g != null) {
      return BoxDecoration(gradient: g);
    }
    return BoxDecoration(color: appBackground(context));
  }

  @Deprecated('Use appRootDecoration; dark theme is solid.')
  static LinearGradient appBackgroundGradient(BuildContext context) {
    final g = EditorVisualTokens.appBackgroundGradient(context);
    if (g != null) return g;
    return LinearGradient(
        colors: [appBackground(context), appBackground(context)]);
  }

  static Color islandFill(BuildContext context) =>
      EditorVisualTokens.islandFill(context);

  static Color islandFillElevated(BuildContext context) =>
      EditorVisualTokens.islandFillElevated(context);

  /// Grands îlots : surface **unie**, légèrement teintée si besoin.
  static Color largeIslandSurfaceColor(
    BuildContext context, {
    Color? tint,
  }) =>
      EditorVisualTokens.mainIslandSurface(context, tint: tint);

  static Color toolbarBarFill(BuildContext context) =>
      EditorVisualTokens.toolbarBarColor(context);

  static Color toolbarCapsuleFill(BuildContext context) =>
      EditorVisualTokens.toolbarCapsuleColor(context);

  /// Piste des pulldowns dans la toolbar (lisible, stable).
  static Color toolbarPulldownTrackFill(BuildContext context) =>
      _isDark(context)
          ? Color.lerp(
              EditorVisualTokens.toolbarCapsuleDark,
              accentPrimary,
              0.08,
            )!
          : const Color(0xFFE8ECF2);

  /// Survol discret dans les capsules toolbar.
  static Color toolbarMutedHoverFill(BuildContext context) => _isDark(context)
      ? Color.lerp(
          EditorVisualTokens.toolbarCapsuleDark,
          accentPrimary,
          0.1,
        )!
      : const Color(0x14000000);

  /// Compat : base d’îlot.
  static Color panelBackground(BuildContext context) => islandFill(context);

  /// Compat : surface surélevée dans un îlot.
  static Color elevatedPanelBackground(BuildContext context) =>
      islandFillElevated(context);

  /// Compat : zones « liste » — aligné sur le fond global pour éviter le patchwork.
  static Color scaffoldBackground(BuildContext context) =>
      appBackground(context);

  /// Toujours transparent : le canvas laisse voir le même matériau que l’îlot parent.
  static Color mapCanvasViewportBackground(BuildContext context) =>
      CupertinoColors.transparent;

  /// Compat : pas de vrai dégradé en thème sombre.
  static LinearGradient windowBackdropGradient(BuildContext context) =>
      appBackgroundGradient(context);

  static Color separator(BuildContext context) => _isDark(context)
      ? const Color(0x08FFFFFF)
      : CupertinoColors.separator.resolveFrom(context);

  static Color subtleSeparator(BuildContext context) =>
      _isDark(context) ? const Color(0x06FFFFFF) : const Color(0x14000000);

  static Color subtleLabel(BuildContext context) =>
      CupertinoColors.placeholderText.resolveFrom(context);

  static Color primaryLabel(BuildContext context) =>
      CupertinoColors.label.resolveFrom(context);

  static Color activeAccent(BuildContext context) =>
      CupertinoTheme.of(context).primaryColor;

  static Color statusTint(BuildContext context) =>
      _isDark(context) ? const Color(0xFF3A3A52) : const Color(0xFFF2EBE6);

  static Color errorTint(BuildContext context) =>
      _isDark(context) ? const Color(0xFF32242A) : const Color(0xFFF8E8EA);

  /// Remplissage discret, **opaque** (pas de translucidité type verre).
  static Color chipFill(BuildContext context) => _isDark(context)
      ? Color.lerp(
          islandFillElevated(context),
          accentPrimary,
          0.11,
        )!
      : CupertinoColors.black.withValues(alpha: 0.045);

  /// Badges / compteurs : chaleureux, lisible, surface nette.
  static Color badgeFill(BuildContext context) => _isDark(context)
      ? Color.lerp(
          islandFillElevated(context),
          accentWarm,
          0.16,
        )!
      : accentWarm.withValues(alpha: 0.14);

  static Color sidebarHoverFill(BuildContext context) =>
      _isDark(context) ? const Color(0x1FFFFFFF) : const Color(0x10000000);

  static Color disclosureHoverFill(BuildContext context) =>
      _isDark(context) ? const Color(0x12FFFFFF) : const Color(0x0E000000);

  static Color panelBorder(BuildContext context) =>
      _isDark(context) ? const Color(0x04000000) : const Color(0x14000000);

  /// Contour net des grands îlots (même logique que les tuiles inspecteur).
  static const Color editorIslandRimDark = Color(0xFF4D465E);

  static Color editorIslandRim(BuildContext context) =>
      _isDark(context) ? editorIslandRimDark : const Color(0x22000000);

  /// Petit module en thème clair uniquement (cartes légères).
  static LinearGradient panelGradientLight(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF1F4F8),
      ],
    );
  }

  /// Ombres des grands îlots : **relief net** (aligné sur les tuiles inspecteur).
  static List<BoxShadow> panelShadows(BuildContext context) {
    if (_isDark(context)) {
      return inspectorTileHardShadows(context);
    }
    return const [
      BoxShadow(
        color: Color(0x12000000),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
    ];
  }

  /// Cartes internes : même système d’ombre dure.
  static List<BoxShadow> sectionCardShadows(BuildContext context) {
    if (_isDark(context)) {
      return inspectorTileHardShadows(context);
    }
    return const [
      BoxShadow(
        color: Color(0x0C000000),
        blurRadius: 12,
        offset: Offset(0, 5),
      ),
    ];
  }

  /// Tuiles inspecteur : relief **net**, sans halo coloré ni gros blur.
  static List<BoxShadow> inspectorTileHardShadows(BuildContext context) {
    if (_isDark(context)) {
      return const [
        BoxShadow(
          color: Color(0x72000000),
          blurRadius: 0,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: Color(0x28000000),
          blurRadius: 3,
          offset: Offset(0, 3),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> toolbarCapsuleShadows(BuildContext context) {
    if (_isDark(context)) {
      return const [
        BoxShadow(
          color: Color(0x5C000000),
          blurRadius: 0,
          offset: Offset(0, 1),
        ),
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 2,
          offset: Offset(0, 2),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x10000000),
        blurRadius: 6,
        offset: Offset(0, 3),
      ),
    ];
  }

  static const Color borderSubtle = Color(0x08FFFFFF);
}

class EditorPaneSurface extends StatelessWidget {
  const EditorPaneSurface({
    super.key,
    required this.child,
    this.radius = 26,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.tint,
    this.showBorder = false,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color? tint;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: EditorChrome.panelShadows(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MacosTheme.brightnessOf(context) == Brightness.dark
                ? EditorChrome.largeIslandSurfaceColor(context, tint: tint)
                : null,
            gradient: MacosTheme.brightnessOf(context) == Brightness.dark
                ? null
                : EditorChrome.panelGradientLight(context),
            borderRadius: BorderRadius.circular(radius),
            border: showBorder
                ? Border.all(color: EditorChrome.panelBorder(context))
                : (MacosTheme.brightnessOf(context) == Brightness.dark
                    ? Border.all(
                        color: EditorChrome.editorIslandRim(context),
                        width: 1,
                      )
                    : null),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Îlot visuel unifié : même matériau que les autres panneaux ([EditorPaneSurface]).
typedef EditorIsland = EditorPaneSurface;

/// Fond de ligne sélectionnée, identique à [SidebarItems] (package macos_ui).
Color editorSidebarSelectionColor(BuildContext context) {
  final theme = MacosTheme.of(context);
  final accent = theme.accentColor ?? AccentColor.blue;
  final isDark = theme.brightness == Brightness.dark;
  final isMain = WindowMainStateListener.instance.isMainWindow;

  if (isDark) {
    if (!isMain) {
      return const Color.fromRGBO(72, 56, 118, 0.7);
    }
    return switch (accent) {
      AccentColor.blue => const Color.fromRGBO(88, 62, 152, 0.74),
      AccentColor.purple => const Color.fromRGBO(154, 53, 173, 0.7),
      AccentColor.pink => const Color.fromRGBO(201, 81, 146, 0.7),
      AccentColor.red => const Color.fromRGBO(183, 72, 86, 0.72),
      AccentColor.orange => const Color.fromRGBO(187, 120, 53, 0.72),
      AccentColor.yellow => const Color.fromRGBO(188, 157, 71, 0.72),
      AccentColor.green => const Color.fromRGBO(72, 142, 98, 0.72),
      AccentColor.graphite => const Color.fromRGBO(112, 117, 124, 0.78),
    };
  }

  if (!isMain) {
    return const Color.fromRGBO(213, 213, 208, 1.0);
  }

  return switch (accent) {
    AccentColor.blue => const Color.fromRGBO(9, 129, 255, 0.749),
    AccentColor.purple => const Color.fromRGBO(162, 28, 165, 0.749),
    AccentColor.pink => const Color.fromRGBO(234, 81, 152, 0.749),
    AccentColor.red => const Color.fromRGBO(220, 32, 40, 0.749),
    AccentColor.orange => const Color.fromRGBO(245, 113, 0, 0.749),
    AccentColor.yellow => const Color.fromRGBO(240, 180, 2, 0.749),
    AccentColor.green => const Color.fromRGBO(66, 174, 33, 0.749),
    AccentColor.graphite => const Color.fromRGBO(174, 174, 167, 0.847),
  };
}

/// Titre de section type en-tête [SidebarItem] macos_ui (texte gris, non cliquable).
class EditorSidebarSectionTitle extends StatelessWidget {
  const EditorSidebarSectionTitle(
    this.label, {
    super.key,
    this.leftInset = 0,
  });

  final String label;
  final double leftInset;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(12 + leftInset, 12, 12, 6),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.9,
          color: colors.textMuted,
        ),
      ),
    );
  }
}

/// Ligne de liste pleine largeur, style pilule sélectionnée comme [SidebarItem] (sans la largeur fixe 134 px).
class EditorSidebarListRow extends StatefulWidget {
  const EditorSidebarListRow({
    super.key,
    required this.selected,
    required this.onTap,
    this.leading,
    this.leadingIconUnselectedColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onSecondaryTapDown,
    this.leftIndent = 0,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  /// Si non null et [selected] est false, couleur de l’icône (sinon [MacosTheme.primaryColor]).
  final Color? leadingIconUnselectedColor;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final void Function(TapDownDetails details)? onSecondaryTapDown;
  final double leftIndent;

  @override
  State<EditorSidebarListRow> createState() => _EditorSidebarListRowState();
}

class _EditorSidebarListRowState extends State<EditorSidebarListRow> {
  bool _hovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final theme = MacosTheme.of(context);
    final spacing = 10.0 + theme.visualDensity.horizontal;
    final hasSubtitle = widget.subtitle != null;
    // Hauteur cible:
    // - ligne simple compacte pour titre seul;
    // - ligne étendue pour titre + sous-titre.
    final baseRowHeight = hasSubtitle ? 42.0 : 30.0;
    final minRowHeight = hasSubtitle ? 36.0 : 24.0;
    final maxRowHeight = hasSubtitle ? 56.0 : 44.0;
    final resolvedRowHeight = (baseRowHeight + theme.visualDensity.vertical)
        .clamp(minRowHeight, maxRowHeight)
        .toDouble();

    final fill = widget.selected
        ? colors.surfaceSelected
        : (_hovered
            ? colors.surfaceHover
            : Colors.transparent);

    final fgColor = widget.selected
        ? colors.brandPrimary
        : (_hovered ? colors.textPrimary : colors.textSecondary);

    final subtitleColor = widget.selected
        ? colors.textSecondary
        : colors.textMuted;

    const isDisabled = false;

    final rowContent = Row(
      children: [
        if (widget.leading != null) ...[
          IconTheme.merge(
            data: IconThemeData(
              color: widget.selected
                  ? colors.brandPrimary
                  : (widget.leadingIconUnselectedColor ?? fgColor),
              size: 16,
            ),
            child: MacosIconTheme.merge(
              data: MacosIconThemeData(
                color: widget.selected
                    ? colors.brandPrimary
                    : (widget.leadingIconUnselectedColor ?? fgColor),
                size: 16,
              ),
              child: widget.leading!,
            ),
          ),
          SizedBox(width: spacing),
        ],
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultTextStyle(
                style: TextStyle(
                  color: fgColor,
                  fontSize: 13,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: widget.title,
              ),
              if (hasSubtitle) ...[
                const SizedBox(height: 2),
                Flexible(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                    child: widget.subtitle!,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.trailing != null) ...[
          const SizedBox(width: 8),
          DefaultTextStyle(
            style: TextStyle(
              color: fgColor,
              fontSize: 11,
            ),
            child: widget.trailing!,
          ),
        ],
      ],
    );

    Widget core = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing,
        vertical: 4 + theme.visualDensity.vertical * 0.5,
      ),
      child: SizedBox(
        height: resolvedRowHeight,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Respect constraints to hide subtitle if height gets too low
            final showSubtitle = hasSubtitle && constraints.maxHeight >= 36;
            if (!showSubtitle && hasSubtitle) {
              return Row(
                children: [
                  if (widget.leading != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(
                        color: widget.selected
                            ? colors.brandPrimary
                            : (widget.leadingIconUnselectedColor ?? fgColor),
                        size: 16,
                      ),
                      child: MacosIconTheme.merge(
                        data: MacosIconThemeData(
                          color: widget.selected
                              ? colors.brandPrimary
                              : (widget.leadingIconUnselectedColor ?? fgColor),
                          size: 16,
                        ),
                        child: widget.leading!,
                      ),
                    ),
                    SizedBox(width: spacing),
                  ],
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: fgColor,
                        fontSize: 13,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      child: widget.title,
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              );
            }
            return rowContent;
          },
        ),
      ),
    );

    core = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
        border: _isFocused && !isDisabled
            ? Border.all(color: colors.brandPrimaryBorder, width: 1.2)
            : null,
      ),
      child: Stack(
        children: [
          core,
          Positioned(
            left: 0,
            top: 6,
            bottom: 6,
            child: AnimatedOpacity(
              opacity: widget.selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: colors.brandPrimary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(1.75),
                    bottomRight: Radius.circular(1.75),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(10 + widget.leftIndent, 2, 10, 2),
      child: Semantics(
        button: true,
        selected: widget.selected,
        enabled: true,
        child: FocusableActionDetector(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                widget.onTap();
                return null;
              },
            ),
          },
          onShowHoverHighlight: (val) {
            setState(() => _hovered = val);
          },
          onShowFocusHighlight: (val) {
            setState(() => _isFocused = val);
          },
          child: GestureDetector(
            onTap: widget.onTap,
            onSecondaryTapDown: widget.onSecondaryTapDown,
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: core,
            ),
          ),
        ),
      ),
    );
  }
}

class EditorHorizontalDivider extends StatelessWidget {
  const EditorHorizontalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              colors.divider,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class EditorVerticalDivider extends StatelessWidget {
  const EditorVerticalDivider({super.key, this.indent = 8});

  final double indent;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(vertical: indent),
      color: colors.divider,
    );
  }
}

/// Bouton icône compact pour barres d’outils (équivalent iOS d’IconButton).
class EditorToolbarIconButton extends StatelessWidget {
  const EditorToolbarIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
    this.iconSize = 20,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final child = MacosIcon(icon, size: iconSize, color: color);
    final button = CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: child,
    );
    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Semantics(
      label: tooltip,
      button: true,
      child: button,
    );
  }
}

/// Remplace [ExpansionTile] pour un style liste iOS.
class CupertinoDisclosureTile extends StatefulWidget {
  const CupertinoDisclosureTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.children = const <Widget>[],
    this.initiallyExpanded = false,
    this.tilePadding = EdgeInsets.zero,
    this.childrenPadding = EdgeInsets.zero,
    this.onSecondaryTapDown,

    /// En-tête pleine largeur, typographie / icônes comme la sidebar macos_ui.
    this.useEditorMacosSidebarDisclosureStyle = false,

    /// Enveloppe l’en-tête (ex. [DragTarget] / [Draggable]) après le geste secondaire.
    this.wrapHeader,
  });

  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget> children;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry tilePadding;
  final EdgeInsetsGeometry childrenPadding;

  /// Clic droit sur la ligne d’en-tête (menu contextuel).
  final void Function(TapDownDetails details)? onSecondaryTapDown;
  final bool useEditorMacosSidebarDisclosureStyle;
  final Widget Function(Widget header)? wrapHeader;

  @override
  State<CupertinoDisclosureTile> createState() =>
      _CupertinoDisclosureTileState();
}

class _CupertinoDisclosureTileState extends State<CupertinoDisclosureTile> {
  late bool _expanded = widget.initiallyExpanded;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final chevronColor = colors.textMuted;
    final titleMergeStyle = widget.useEditorMacosSidebarDisclosureStyle
        ? TextStyle(
            color: _hovered ? colors.textPrimary : colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          )
        : CupertinoTheme.of(context).textTheme.textStyle;

    Widget header = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        decoration: widget.useEditorMacosSidebarDisclosureStyle
            ? BoxDecoration(
                color: _hovered
                    ? colors.surfaceHover
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: CupertinoButton(
          padding: widget.tilePadding,
          minimumSize: Size.zero,
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Transform.rotate(
                angle: _expanded ? math.pi / 2 : 0,
                child: Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: chevronColor,
                ),
              ),
              if (widget.leading != null) ...[
                const SizedBox(width: 6),
                if (widget.useEditorMacosSidebarDisclosureStyle)
                  IconTheme.merge(
                    data: IconThemeData(
                      color: _hovered ? colors.textPrimary : colors.textSecondary,
                      size: 16,
                    ),
                    child: MacosIconTheme.merge(
                      data: MacosIconThemeData(
                        color: _hovered ? colors.textPrimary : colors.textSecondary,
                        size: 16,
                      ),
                      child: widget.leading!,
                    ),
                  )
                else
                  widget.leading!,
              ],
              if (widget.leading != null) const SizedBox(width: 8),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: titleMergeStyle,
                  child: widget.title,
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
    if (widget.useEditorMacosSidebarDisclosureStyle) {
      header = SizedBox(
        width: double.infinity,
        child: header,
      );
    }
    if (widget.onSecondaryTapDown != null) {
      header = GestureDetector(
        onSecondaryTapDown: widget.onSecondaryTapDown,
        behavior: HitTestBehavior.opaque,
        child: header,
      );
    }
    if (widget.wrapHeader != null) {
      header = widget.wrapHeader!(header);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (_expanded)
          Padding(
            padding: widget.childrenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.children,
            ),
          ),
      ],
    );
  }
}

/// Titre de feuille / formulaire modale (style macOS).
TextStyle editorMacosSheetTitleStyle(BuildContext context) =>
    MacosTheme.of(context).typography.title2;

/// Libellé de champ dans une feuille formulaire.
TextStyle editorMacosFormLabelStyle(BuildContext context) =>
    MacosTheme.of(context).typography.caption1.copyWith(
          fontWeight: FontWeight.w600,
        );

/// Entrée pour [showMacosEditorActionsSheet].
class MacosEditorSheetAction<T> {
  const MacosEditorSheetAction({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final bool isDestructive;
}

MacosThemeData _editorFallbackMacosThemeData(BuildContext context) {
  return MediaQuery.platformBrightnessOf(context) == Brightness.dark
      ? MacosThemeData.dark()
      : MacosThemeData.light();
}

/// Liste de choix dans une [MacosSheet] (remplace l’ancienne action sheet iOS).
Future<T?> showMacosListPicker<T>({
  required BuildContext context,
  required List<T> items,
  required String Function(T value) labelOf,
  String title = 'Choose',
}) {
  if (items.isEmpty) {
    return Future<T?>.value();
  }
  final maxH = MediaQuery.sizeOf(context).height * 0.55;
  return showMacosSheet<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final themeData =
          MacosTheme.maybeOf(ctx) ?? _editorFallbackMacosThemeData(ctx);
      return MacosTheme(
        data: themeData,
        child: Builder(
          builder: (themedCtx) {
            return Center(
              child: MacosSheet(
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 72, vertical: 44),
                child: SizedBox(
                  width: 380,
                  height: maxH,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: editorMacosSheetTitleStyle(themedCtx),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (c, i) {
                              final e = items[i];
                              return PushButton(
                                controlSize: ControlSize.large,
                                secondary: true,
                                onPressed: () => Navigator.of(c).pop(e),
                                child: Text(
                                  labelOf(e),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        PushButton(
                          controlSize: ControlSize.large,
                          secondary: true,
                          onPressed: () => Navigator.of(themedCtx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

/// Compatibilité : même API que l’ancien sélecteur, rendu macOS.
Future<T?> showCupertinoListPicker<T>({
  required BuildContext context,
  required List<T> items,
  required String Function(T value) labelOf,
  String title = 'Choose',
}) {
  return showMacosListPicker<T>(
    context: context,
    items: items,
    labelOf: labelOf,
    title: title,
  );
}

/// Menu d’actions vertical (équivalent d’une action sheet iOS).
Future<T?> showMacosEditorActionsSheet<T>({
  required BuildContext context,
  Widget? title,
  required List<MacosEditorSheetAction<T>> actions,
  String cancelLabel = 'Cancel',
}) {
  return showMacosSheet<T>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Center(
      child: MacosSheet(
        insetPadding: const EdgeInsets.symmetric(horizontal: 72, vertical: 44),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  DefaultTextStyle(
                    style: editorMacosSheetTitleStyle(ctx),
                    textAlign: TextAlign.center,
                    child: title,
                  ),
                  const SizedBox(height: 14),
                ],
                for (final a in actions) ...[
                  PushButton(
                    controlSize: ControlSize.large,
                    secondary: true,
                    color: a.isDestructive ? MacosColors.appleRed : null,
                    onPressed: () => Navigator.of(ctx).pop(a.value),
                    child: Text(a.label),
                  ),
                  const SizedBox(height: 8),
                ],
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(cancelLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Menu contextuel ancré près du pointeur (clic droit), sans feuille centrée.
Future<T?> showMacosEditorContextMenu<T>({
  required BuildContext context,
  required Offset globalPosition,
  required List<MacosEditorSheetAction<T>> actions,
}) {
  if (actions.isEmpty) return Future<T?>.value();
  final overlayState = Overlay.of(context);
  final overlayBox = overlayState.context.findRenderObject()! as RenderBox;
  final local = overlayBox.globalToLocal(globalPosition);

  final brightness = MacosTheme.brightnessOf(context);
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFECECEC);
  final labelColor = MacosTheme.of(context).typography.body.color ??
      (isDark ? CupertinoColors.white : CupertinoColors.black);

  const horizontalPadding = 12.0;
  const verticalItemPadding = 8.0;
  const minMenuWidth = 200.0;

  late OverlayEntry entry;
  final completer = Completer<T?>();

  void dismiss([T? value]) {
    if (entry.mounted) entry.remove();
    if (!completer.isCompleted) completer.complete(value);
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final maxW = overlayBox.size.width;
      final maxH = overlayBox.size.height;
      const estimatedRow = 13.0 + verticalItemPadding * 2;
      final menuHeight = actions.length * estimatedRow + 4;
      var left = local.dx;
      var top = local.dy;
      if (left + minMenuWidth > maxW - 8) {
        left = maxW - minMenuWidth - 8;
      }
      if (left < 8) left = 8;
      if (top + menuHeight > maxH - 8) {
        top = maxH - menuHeight - 8;
      }
      if (top < 8) top = 8;

      return Stack(
        children: [
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => dismiss(),
            ),
          ),
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EditorChrome.borderSubtle),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: minMenuWidth),
                    child: IntrinsicWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final a in actions)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => dismiss(a.value),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: verticalItemPadding,
                                  ),
                                  child: Text(
                                    a.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: a.isDestructive
                                          ? MacosColors.appleRed
                                          : labelColor,
                                    ),
                                  ),
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
        ],
      );
    },
  );

  overlayState.insert(entry);
  return completer.future;
}

/// Point d’ancrage sous un widget (ex. bouton « … »).
Offset editorMenuAnchorBelowWidget(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) {
    return Offset.zero;
  }
  return box.localToGlobal(Offset(0, box.size.height));
}

/// Formulaire compact dans une feuille macOS (remplace CupertinoPopupSurface).
Future<T?> showMacosEditorModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double maxWidth = 460,
}) {
  return showMacosSheet<T>(
    context: context,
    builder: (ctx) => Center(
      child: MacosSheet(
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: builder(ctx),
          ),
        ),
      ),
    ),
  );
}

/// Feuille avec hauteur **bornée** (fraction de l’écran) mais **sans hauteur
/// minimale** : le contenu définit la taille ; défilement géré par le builder
/// (p.ex. [SingleChildScrollView] avec tout le formulaire).
Future<T?> showMacosEditorTallSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double heightFraction = 0.85,
  double maxWidth = 720,
}) {
  return showMacosSheet<T>(
    context: context,
    builder: (ctx) {
      final s = MediaQuery.sizeOf(ctx);
      final maxH = s.height * heightFraction;
      final w = math.min(maxWidth, s.width - 56);
      return Center(
        child: MacosSheet(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: w, maxHeight: maxH),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

Widget _editorMacosAlertAppIcon(IconData icon) {
  return SizedBox(
    width: 56,
    height: 56,
    child: Center(child: MacosIcon(icon, size: 48)),
  );
}

/// Alerte une action ([MacosAlertDialog] / [showMacosAlertDialog]).
Future<void> showCupertinoEditorAlert(
  BuildContext context, {
  required String message,
  String title = 'Notice',
  String okLabel = 'OK',
  IconData icon = CupertinoIcons.info_circle_fill,
}) {
  return showMacosAlertDialog<void>(
    context: context,
    builder: (ctx) => MacosAlertDialog(
      appIcon: _editorMacosAlertAppIcon(icon),
      title: Text(title),
      message: Text(message),
      primaryButton: PushButton(
        controlSize: ControlSize.large,
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(okLabel),
      ),
    ),
  );
}

/// Alerte deux choix : retourne `true` si l’utilisateur active le bouton principal.
Future<bool> showMacosEditorTwoChoiceAlert(
  BuildContext context, {
  required String title,
  required String message,
  String secondaryLabel = 'Cancel',
  required String primaryLabel,
  bool primaryIsDestructive = false,
  IconData icon = CupertinoIcons.exclamationmark_triangle_fill,
}) async {
  var chosePrimary = false;
  await showMacosAlertDialog<void>(
    context: context,
    builder: (ctx) => MacosAlertDialog(
      appIcon: _editorMacosAlertAppIcon(icon),
      title: Text(title),
      message: Text(message),
      secondaryButton: PushButton(
        controlSize: ControlSize.large,
        secondary: true,
        onPressed: () => Navigator.of(ctx).pop(),
        child: Text(secondaryLabel),
      ),
      primaryButton: PushButton(
        controlSize: ControlSize.large,
        color: primaryIsDestructive ? MacosColors.appleRed : null,
        onPressed: () {
          chosePrimary = true;
          Navigator.of(ctx).pop();
        },
        child: Text(primaryLabel),
      ),
    ),
  );
  return chosePrimary;
}

/// Feuille modale avec un champ texte (style macOS).
///
/// [compact]: marges réduites, titre discret, champs et boutons plus petits
/// (libellés courts, renommages simples).
Future<bool> showMacosEditorPromptSheet(
  BuildContext context, {
  required String title,
  required TextEditingController controller,
  String? placeholder,
  String cancelLabel = 'Cancel',
  String confirmLabel = 'OK',
  bool requireNonEmpty = true,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  bool compact = false,
}) async {
  var saved = false;
  await showMacosSheet<void>(
    context: context,
    builder: (ctx) {
      final typo = MacosTheme.of(ctx).typography;
      final titleStyle = compact
          ? typo.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: (typo.body.fontSize ?? 13) + 1,
            )
          : typo.title2;
      final innerPad = compact
          ? const EdgeInsets.fromLTRB(16, 14, 16, 12)
          : const EdgeInsets.all(24);
      final fieldGap = compact ? 10.0 : 16.0;
      final beforeButtons = compact ? 14.0 : 24.0;
      final sheetWidth = compact ? 268.0 : 340.0;
      final btnSize = compact ? ControlSize.regular : ControlSize.large;
      final btnGap = compact ? 8.0 : 12.0;

      final sheetBody = Padding(
        padding: innerPad,
        child: SizedBox(
          width: sheetWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              SizedBox(height: fieldGap),
              MacosTextField(
                controller: controller,
                placeholder: placeholder,
                autofocus: true,
                keyboardType: keyboardType ?? TextInputType.text,
                inputFormatters: inputFormatters,
              ),
              SizedBox(height: beforeButtons),
              Row(
                children: [
                  Expanded(
                    child: PushButton(
                      controlSize: btnSize,
                      secondary: true,
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(cancelLabel),
                    ),
                  ),
                  SizedBox(width: btnGap),
                  Expanded(
                    child: PushButton(
                      controlSize: btnSize,
                      onPressed: () {
                        if (requireNonEmpty && controller.text.trim().isEmpty) {
                          return;
                        }
                        saved = true;
                        Navigator.of(ctx).pop();
                      },
                      child: Text(confirmLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      // La route modale est plein écran : sans [Center], le [MacosSheet] étire
      // son fond sur toute la fenêtre (vide sous les boutons).
      final sheet = compact
          ? MacosSheet(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 56, vertical: 28),
              child: sheetBody,
            )
          : MacosSheet(child: sheetBody);
      return Center(child: sheet);
    },
  );
  return saved;
}
