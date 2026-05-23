# PokeMap UI Theme-2 — UI Widgets Foundation V0 Report

This report outlines the implementation and verification of **Theme-2 — PokeMap UI Widgets Foundation V0**.

---

## 1. Résumé
The objective of this lot was to design and implement a library of custom, reusable, and modern foundation UI widgets for PokeMap Map Editor. These widgets consume the design system color tokens (`PokeMapColorTokens` via `context.pokeMapColors`), support light/dark modes, handle interactive states (hover, focus, active selection, disabled), and remain fully decoupled from macOS native styling (like `macos_ui`). This layout acts as the foundation to migrate major pages/sections (such as sidebars, topbars, panels, and inspectors) in subsequent lots.

---

## 2. Audit initial
An initial audit was performed on the existing files:
- Checked `packages/map_editor/lib/src/theme/` to verify color configurations (`PokeMapColorTokens`, `PokeMapThemeExtension`, and `PokeMapTheme.light/dark`).
- Inspected the repository tree and determined the best directory layout.
- Ensured no existing functional screens or business logic layers are disturbed.

---

## 3. Décision d’emplacement des widgets
All design system widgets have been placed in the dedicated subdirectory:
`packages/map_editor/lib/src/ui/design_system/`

---

## 4. Liste des widgets créés
1. **PokeMapButton**: A primary/secondary/ghost/danger/success button with small/medium/large sizes and loading state.
2. **PokeMapIconButton**: A compact 32x32 icon button with ghost/soft/danger variants and active selection support.
3. **PokeMapCard**: A container using context-appropriate surface colors, selection borders, and optional click hover highlights.
4. **PokeMapPanel**: A large pane container wrapper with header, footer, and automated separator dividers.
5. **PokeMapBadge**: A capsule tag badge with neutral/info/success/warning/error/narrative/combat/mapAccent semantic variants.
6. **PokeMapSectionHeader**: A standard row for panel sections displaying a title, description, and trailing widgets.
7. **PokeMapEmptyState**: A centered empty placeholder display with an icon, title, description, and action button.
8. **PokeMapToolbarSurface**: A top/bottom bar container with `surfaceBase` background and a divider border.
9. **PokeMapSidebarItem**: A navigation sidebar item with hover, active selection, and disabled states.

---

## 5. Fichiers créés
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_section_header.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_empty_state.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_toolbar_surface.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart` (Barrel file)
- `packages/map_editor/test/ui/design_system/pokemap_button_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_badge_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart`

---

## 6. Fichiers modifiés
None. No business logic or existing pages were modified.

---

## 7. Exports ajoutés
All components are exposed via the unified design system barrel:
`packages/map_editor/lib/src/ui/design_system/design_system.dart`

---

## 8. Exemples d’utilisation

### PokeMapButton
```dart
PokeMapButton(
  onPressed: () => print('Primary Action'),
  variant: PokeMapButtonVariant.primary,
  size: PokeMapButtonSize.medium,
  child: const Text('Save Changes'),
)
```

### PokeMapSidebarItem
```dart
PokeMapSidebarItem(
  label: 'Surface Studio',
  icon: const Icon(Icons.layers),
  selected: true,
  onTap: () => selectPage(StudioPage.surface),
)
```

---

## 9. Tests ajoutés
Extensive widget tests were added under `packages/map_editor/test/ui/design_system/` covering:
- Rendering in both light and dark themes.
- Proper handling of disabled states.
- Spinner display during `isLoading`.
- Correct badge styling, specifically validating that `PokeMapBadgeVariant.mapAccent` uses `colors.mapAccent`.
- Custom selection border states on cards.
- Sidebar item selected text styling and click actions.
- EmptyState layout and actions.

---

## 10. Commandes lancées avec résultats exacts

```bash
cd packages/map_editor
flutter test test/ui/design_system/
```
**Output:**
```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart: PokeMapSidebarItem Tests PokeMapSidebarItem pumps correctly under light & dark theme
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_badge_test.dart: PokeMapBadge Tests PokeMapBadge pumps correctly under light & dark theme for all variants
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_badge_test.dart: PokeMapBadge Tests PokeMapBadge pumps correctly under light & dark theme for all variants
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_badge_test.dart: PokeMapBadge Tests PokeMapBadge pumps correctly under light & dark theme for all variants
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapButton pumps correctly under light & dark theme
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapButton pumps correctly under light & dark theme
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard & PokeMapPanel pump correctly under light & dark theme
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard & PokeMapPanel pump correctly under light & dark theme
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard & PokeMapPanel pump correctly under light & dark theme
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard & PokeMapPanel pump correctly under light & dark theme
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapIconButton supports disabled state
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard border changes when selected
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapToolbarSurface & PokeMapSectionHeader pump correctly
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapEmptyState displays title, description and action if provided
00:00 +14: All tests passed!
```

```bash
flutter analyze lib/src/ui/design_system/ test/ui/design_system/
```
**Output:**
```text
Analyzing 2 items...                                            
No issues found! (ran in 1.2s)
```

```bash
flutter test test/editor_shell_page_smoke_test.dart
```
**Output:**
```text
00:02 +11: All tests passed!
```

---

## 11. Git status initial
```text
 M packages/map_editor/lib/main.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
?? packages/map_editor/lib/src/ui/design_system/
?? reports/ui/pokemap_theme_1bis_material_root_migration_hardening.md
```

---

## 12. Git status final
```text
 M packages/map_editor/lib/main.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
?? packages/map_editor/lib/src/ui/design_system/
?? packages/map_editor/test/ui/design_system/
?? reports/ui/pokemap_theme_1bis_material_root_migration_hardening.md
?? reports/ui/pokemap_theme_2_ui_widgets_foundation.md
```

---

## 13. Git diff --stat
```text
 packages/map_editor/lib/main.dart                  | 17 +++++----
 .../map_editor/test/shell_chrome_test_harness.dart | 41 ++++++++++++++--------
 2 files changed, 37 insertions(+), 21 deletions(-)
```

---

## 14. Liste complète des fichiers touchés
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/pokemap_section_header.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/pokemap_empty_state.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/pokemap_toolbar_surface.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart` (New)
- `packages/map_editor/lib/src/ui/design_system/design_system.dart` (New)
- `packages/map_editor/test/ui/design_system/pokemap_button_test.dart` (New)
- `packages/map_editor/test/ui/design_system/pokemap_badge_test.dart` (New)
- `packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart` (New)
- `packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart` (New)

---

## 15. Contenu complet de tous les fichiers créés/modifiés

### [design_system.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/design_system.dart)
```dart
/// Barrel file exporting the PokeMap UI Widgets Foundation.
/// Exposes reusable components styled according to the PokeMap color tokens and theme guidelines.
library;

export 'pokemap_badge.dart';
export 'pokemap_button.dart';
export 'pokemap_card.dart';
export 'pokemap_empty_state.dart';
export 'pokemap_icon_button.dart';
export 'pokemap_panel.dart';
export 'pokemap_section_header.dart';
export 'pokemap_sidebar_item.dart';
export 'pokemap_toolbar_surface.dart';
```

### [pokemap_button.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_button.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Available variants for PokeMap buttons, influencing backgrounds and borders.
enum PokeMapButtonVariant {
  /// Primary solid action button utilizing brand colors.
  primary,

  /// Secondary action button with a subtle background and border.
  secondary,

  /// Flat transparent button which highlights on hover.
  ghost,

  /// High-priority warning or destructive action button.
  danger,

  /// Validation or success confirmation button.
  success,
}

/// Preconfigured height and padding configurations for buttons.
enum PokeMapButtonSize {
  /// Compact height (32px) for crowded UI sections.
  small,

  /// Standard height (40px) for general forms and settings.
  medium,

  /// Large height (48px) for prominent shell actions.
  large,
}

/// A custom, highly polished PokeMap action button.
///
/// Designed to follow the PokeMap design language without relying on default Material
/// shape guidelines. Respects light/dark modes, shows loader loops when [isLoading] is active,
/// and handles states (hover, focus, disabled).
class PokeMapButton extends StatefulWidget {
  const PokeMapButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = PokeMapButtonVariant.primary,
    this.size = PokeMapButtonSize.medium,
    this.leading,
    this.trailing,
    this.isLoading = false,
  });

  /// Action callback. If null, the button is rendered in a disabled state.
  final VoidCallback? onPressed;

  /// Main label or custom widget hierarchy inside the button.
  final Widget child;

  /// Colors variant profile.
  final PokeMapButtonVariant variant;

  /// Button dimensions profile.
  final PokeMapButtonSize size;

  /// Optional prefix icon or widget.
  final Widget? leading;

  /// Optional suffix icon or widget.
  final Widget? trailing;

  /// If true, disables action calls and replaces the leading item with a loading spinner.
  final bool isLoading;

  @override
  State<PokeMapButton> createState() => _PokeMapButtonState();
}

class _PokeMapButtonState extends State<PokeMapButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isDisabled = widget.onPressed == null || widget.isLoading;

    // Sizing attributes
    final double height;
    final double horizontalPadding;
    final double fontSize;
    final double iconSize;

    switch (widget.size) {
      case PokeMapButtonSize.small:
        height = 32;
        horizontalPadding = 12;
        fontSize = 12;
        iconSize = 14;
        break;
      case PokeMapButtonSize.medium:
        height = 40;
        horizontalPadding = 16;
        fontSize = 14;
        iconSize = 16;
        break;
      case PokeMapButtonSize.large:
        height = 48;
        horizontalPadding = 20;
        fontSize = 16;
        iconSize = 18;
        break;
    }

    // Core styling attributes
    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case PokeMapButtonVariant.primary:
        bg = _isHovered ? colors.brandPrimaryHover : colors.brandPrimary;
        fg = colors.textInverse;
        break;
      case PokeMapButtonVariant.secondary:
        bg = _isHovered ? colors.surfaceHover : colors.surfaceSubtle;
        fg = colors.textPrimary;
        border = Border.all(color: colors.borderSubtle, width: 1);
        break;
      case PokeMapButtonVariant.ghost:
        bg = _isHovered ? colors.surfaceHover : Colors.transparent;
        fg = colors.textPrimary;
        break;
      case PokeMapButtonVariant.danger:
        bg = _isHovered
            ? Color.lerp(colors.error, Colors.black, 0.08)!
            : colors.error;
        fg = colors.textInverse;
        break;
      case PokeMapButtonVariant.success:
        bg = _isHovered
            ? Color.lerp(colors.success, Colors.black, 0.08)!
            : colors.success;
        fg = colors.textInverse;
        break;
    }

    // Apply disabled values
    if (isDisabled) {
      bg = widget.variant == PokeMapButtonVariant.ghost
          ? Colors.transparent
          : bg.withValues(alpha: 0.5);
      fg = fg.withValues(alpha: 0.5);
      if (border != null) {
        border = Border.all(color: colors.borderSubtle.withValues(alpha: 0.3), width: 1);
      }
    }

    return FocusableActionDetector(
      onShowHoverHighlight: (val) {
        if (!isDisabled) setState(() => _isHovered = val);
      },
      onShowFocusHighlight: (val) {
        if (!isDisabled) setState(() => _isFocused = val);
      },
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: height,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8), // standard border radius: 8
            border: border,
            boxShadow: _isFocused && !isDisabled
                ? [
                    BoxShadow(
                      color: colors.brandPrimary.withValues(alpha: 0.24),
                      blurRadius: 0,
                      spreadRadius: 3,
                    )
                  ]
                : null,
          ),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(fg),
                  ),
                ),
                const SizedBox(width: 8),
              ] else ...[
                if (widget.leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(color: fg, size: iconSize),
                    child: widget.leading!,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
              DefaultTextStyle(
                style: TextStyle(
                  color: fg,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
                child: widget.child,
              ),
              if (widget.trailing != null && !widget.isLoading) ...[
                const SizedBox(width: 8),
                IconTheme.merge(
                  data: IconThemeData(color: fg, size: iconSize),
                  child: widget.trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

### [pokemap_icon_button.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Available variants for PokeMap icon buttons.
enum PokeMapIconButtonVariant {
  /// Flat icon button that shows a subtle background on hover.
  ghost,

  /// Elevated icon button with a solid background and borders.
  soft,

  /// Action button that indicates high alert or delete options.
  danger,
}

/// A compact PokeMap action icon button.
///
/// Wraps an icon widget, supporting tooltips, active selections,
/// hover/focus indicators, and disabled states.
class PokeMapIconButton extends StatefulWidget {
  const PokeMapIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.variant = PokeMapIconButtonVariant.ghost,
    this.isSelected = false,
  });

  /// Action callback. If null, renders in a disabled state.
  final VoidCallback? onPressed;

  /// The icon widget inside the button (usually an Icon).
  final Widget icon;

  /// Optional tooltip message.
  final String? tooltip;

  /// Layout and color palette styling.
  final PokeMapIconButtonVariant variant;

  /// If true, applies active selection styling cues.
  final bool isSelected;

  @override
  State<PokeMapIconButton> createState() => _PokeMapIconButtonState();
}

class _PokeMapIconButtonState extends State<PokeMapIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isDisabled = widget.onPressed == null;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.variant) {
      case PokeMapIconButtonVariant.ghost:
        bg = widget.isSelected
            ? colors.surfaceSelected
            : (_isHovered ? colors.surfaceHover : Colors.transparent);
        fg = widget.isSelected ? colors.brandPrimary : colors.textSecondary;
        break;
      case PokeMapIconButtonVariant.soft:
        if (widget.isSelected) {
          bg = colors.surfaceSelected;
          border = Border.all(color: colors.brandPrimaryBorder, width: 1);
          fg = colors.brandPrimary;
        } else {
          bg = _isHovered ? colors.surfaceHover : colors.surfaceSubtle;
          border = Border.all(color: colors.borderSubtle, width: 1);
          fg = colors.textPrimary;
        }
        break;
      case PokeMapIconButtonVariant.danger:
        bg = _isHovered ? colors.errorSoft : Colors.transparent;
        fg = colors.error;
        break;
    }

    if (isDisabled) {
      bg = Colors.transparent;
      fg = fg.withValues(alpha: 0.35);
      if (border != null) {
        border = Border.all(color: colors.borderSubtle.withValues(alpha: 0.3), width: 1);
      }
    }

    Widget content = FocusableActionDetector(
      onShowHoverHighlight: (val) {
        if (!isDisabled) setState(() => _isHovered = val);
      },
      onShowFocusHighlight: (val) {
        if (!isDisabled) setState(() => _isFocused = val);
      },
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6), // Standard small radius: 6 or 8
            border: border,
            boxShadow: _isFocused && !isDisabled
                ? [
                    BoxShadow(
                      color: colors.brandPrimary.withValues(alpha: 0.2),
                      blurRadius: 0,
                      spreadRadius: 2.5,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(color: fg, size: 16),
              child: widget.icon,
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      content = Tooltip(
        message: widget.tooltip!,
        child: content,
      );
    }

    return content;
  }
}
```

### [pokemap_card.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_card.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A customizable, styled container for PokeMap sections and settings.
///
/// Automatically resolves background colors based on active theme brightness
/// ([surfaceBase] for light mode, [surfaceRaised] for dark mode) to follow PokeMap aesthetics.
/// Highlights borders on selection and supports hover highlights if [onTap] is provided.
class PokeMapCard extends StatefulWidget {
  const PokeMapCard({
    super.key,
    required this.child,
    this.padding,
    this.selected = false,
    this.onTap,
  });

  /// Main content within the card.
  final Widget child;

  /// Custom padding inside the card. Defaults to 12.
  final EdgeInsetsGeometry? padding;

  /// If true, applies high-contrast primary selection borders.
  final bool selected;

  /// Optional card tap callback. If provided, renders hover cursors and background transitions.
  final VoidCallback? onTap;

  @override
  State<PokeMapCard> createState() => _PokeMapCardState();
}

class _PokeMapCardState extends State<PokeMapCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBg = isDark ? colors.surfaceRaised : colors.surfaceBase;
    final bg = (widget.onTap != null && _isHovered) ? colors.surfaceHover : baseBg;

    final border = Border.all(
      color: widget.selected
          ? colors.brandPrimaryBorder
          : (_isHovered && widget.onTap != null ? colors.borderStrong : colors.borderSubtle),
      width: 1.2,
    );

    Widget content = Padding(
      padding: widget.padding ?? const EdgeInsets.all(12),
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12), // Standard card radius: 12
        border: border,
      ),
      child: content,
    );
  }
}
```

### [pokemap_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A structural panel layout container for large editor UI zones (e.g. sidebar contents, inspector).
///
/// Builds a clean surface using [backgroundShell], enclosed in a subtle border.
/// Supports standard [header] and [footer] widgets, inserting clean horizontal dividers automatically.
class PokeMapPanel extends StatelessWidget {
  const PokeMapPanel({
    super.key,
    this.header,
    required this.child,
    this.footer,
    this.padding,
  });

  /// Optional widget displayed at the top of the panel (e.g., section title or actions toolbar).
  final Widget? header;

  /// Main content child widget. Wraps automatically inside an Expanded container.
  final Widget child;

  /// Optional widget displayed at the bottom of the panel (e.g., status flags or confirmation buttons).
  final Widget? footer;

  /// Inner padding around the [child] widget. Defaults to 16.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundShell,
        borderRadius: BorderRadius.circular(12), // Standard radius: 12
        border: Border.all(color: colors.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11), // Inset clip to prevent background spill
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null) ...[
              header!,
              Container(
                height: 1,
                color: colors.divider,
              ),
            ],
            Expanded(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
            if (footer != null) ...[
              Container(
                height: 1,
                color: colors.divider,
              ),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
```

### [pokemap_badge.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Available variants for PokeMap badges/tags.
enum PokeMapBadgeVariant {
  /// Default neutral grey tag.
  neutral,

  /// Blue information label.
  info,

  /// Green confirmation label.
  success,

  /// Yellow warning label.
  warning,

  /// Red error or system alert label.
  error,

  /// Purple narrative step tag.
  narrative,

  /// Pink/Red combat action tag.
  combat,

  /// Light/Dark green Map Editor context tag. Uses colors.mapAccent.
  mapAccent,
}

/// A compact, read-only tag/badge used to label states, types, or categories.
///
/// Automatically retrieves appropriate colors based on the requested [variant].
/// Respects light/dark modes and maps [PokeMapBadgeVariant.mapAccent] directly to the
/// design system's [mapAccent] color token.
class PokeMapBadge extends StatelessWidget {
  const PokeMapBadge({
    super.key,
    required this.label,
    this.variant = PokeMapBadgeVariant.neutral,
    this.icon,
  });

  /// The text string shown on the badge.
  final String label;

  /// Semantic styling variant profile.
  final PokeMapBadgeVariant variant;

  /// Optional prefix icon shown before the label text.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    Color bg;
    Color fg;
    Border border;

    switch (variant) {
      case PokeMapBadgeVariant.neutral:
        bg = colors.surfaceSubtle;
        border = Border.all(color: colors.borderSubtle, width: 1);
        fg = colors.textSecondary;
        break;
      case PokeMapBadgeVariant.info:
        bg = colors.infoSoft;
        border = Border.all(color: colors.info.withValues(alpha: 0.28), width: 1);
        fg = colors.info;
        break;
      case PokeMapBadgeVariant.success:
        bg = colors.successSoft;
        border = Border.all(color: colors.successBorder, width: 1);
        fg = colors.success;
        break;
      case PokeMapBadgeVariant.warning:
        bg = colors.warningSoft;
        border = Border.all(color: colors.warningBorder, width: 1);
        fg = colors.warning;
        break;
      case PokeMapBadgeVariant.error:
        bg = colors.errorSoft;
        border = Border.all(color: colors.errorBorder, width: 1);
        fg = colors.error;
        break;
      case PokeMapBadgeVariant.narrative:
        bg = colors.narrativeSoft;
        border = Border.all(color: colors.narrative.withValues(alpha: 0.28), width: 1);
        fg = colors.narrative;
        break;
      case PokeMapBadgeVariant.combat:
        bg = colors.errorSoft;
        border = Border.all(color: colors.combat.withValues(alpha: 0.28), width: 1);
        fg = colors.combat;
        break;
      case PokeMapBadgeVariant.mapAccent:
        bg = colors.successSoft;
        border = Border.all(color: colors.mapAccent.withValues(alpha: 0.28), width: 1);
        fg = colors.mapAccent;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100), // Capsule look
        border: border,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme.merge(
              data: IconThemeData(color: fg, size: 12),
              child: icon!,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

### [pokemap_section_header.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_section_header.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A simple, elegant section header widget for PokeMap panels.
///
/// Typically used inside the inspector, side panels, or settings screens to segment
/// sections of controls. Displays a primary [title], an optional [description],
/// and an optional [trailing] widget (such as action buttons or status indicators).
class PokeMapSectionHeader extends StatelessWidget {
  const PokeMapSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
  });

  /// The primary section title text.
  final String title;

  /// Optional sub-label description text shown below the title.
  final String? description;

  /// Optional action widget displayed on the far right (e.g. icon buttons, checkboxes).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
```

### [pokemap_empty_state.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_empty_state.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A polished placeholder/empty-state prompt widget.
///
/// Designed to be shown when a panel, panel section, search list, or editor grid has
/// no content to display. Renders a centered stack containing an optional [icon],
/// a main [title], an optional sub [description], and an optional [action] button or widget.
class PokeMapEmptyState extends StatelessWidget {
  const PokeMapEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
  });

  /// Primary bold notification text explaining the empty state.
  final String title;

  /// Optional secondary text providing further explanation or instructions.
  final String? description;

  /// Optional top icon or graphic widget.
  final Widget? icon;

  /// Optional action widget shown below the text stack (e.g. "Create Event" button).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderSubtle, width: 1),
                ),
                alignment: Alignment.center,
                child: IconTheme.merge(
                  data: IconThemeData(color: colors.textMuted, size: 28),
                  child: icon!,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

### [pokemap_toolbar_surface.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_toolbar_surface.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A structural horizontal bar surface for editor toolbars and topbars.
///
/// Provides a consistent background using the design system's [surfaceBase] color
/// and places a subtle border/divider at the bottom. Sets up a standard padding container
/// for horizontal controls.
class PokeMapToolbarSurface extends StatelessWidget {
  const PokeMapToolbarSurface({
    super.key,
    required this.child,
    this.padding,
  });

  /// Main toolbar row contents or actions layout.
  final Widget child;

  /// Custom padding within the toolbar bar. Defaults to 8px vertical, 16px horizontal.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceBase,
        border: Border(
          bottom: BorderSide(
            color: colors.divider,
            width: 1.0,
          ),
        ),
      ),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );
  }
}
```

### [pokemap_sidebar_item.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart)
```dart
import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A polished, custom list item designed for the editor navigation sidebar.
///
/// Handles hover, active selection, focus, and disabled states. Renders an optional
/// leading [icon], a text [label], and an optional [trailing] widget (such as badges,
/// state checkmarks, or menu options). Consumes the design system's theme color tokens.
class PokeMapSidebarItem extends StatefulWidget {
  const PokeMapSidebarItem({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });

  /// The primary item label.
  final String label;

  /// Optional prefix icon or graphic widget.
  final Widget? icon;

  /// Optional suffix widget (e.g. status dot, badge, or chevron).
  final Widget? trailing;

  /// If true, highlights the item as the current active page/selection.
  final bool selected;

  /// If true, disables clicks and grey-outs visual components.
  final bool disabled;

  /// Triggered when the sidebar item is tapped.
  final VoidCallback? onTap;

  @override
  State<PokeMapSidebarItem> createState() => _PokeMapSidebarItemState();
}

class _PokeMapSidebarItemState extends State<PokeMapSidebarItem> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final isActive = widget.selected;
    final isDisabled = widget.disabled || widget.onTap == null;

    // Visual attributes resolution
    Color bg = Colors.transparent;
    Color fg = colors.textSecondary;

    if (isDisabled) {
      fg = colors.textDisabled;
    } else if (isActive) {
      bg = colors.surfaceSelected;
      fg = colors.brandPrimary;
    } else if (_isHovered) {
      bg = colors.surfaceHover;
      fg = colors.textPrimary;
    }

    return FocusableActionDetector(
      onShowHoverHighlight: (val) {
        if (!isDisabled) setState(() => _isHovered = val);
      },
      onShowFocusHighlight: (val) {
        if (!isDisabled) setState(() => _isFocused = val);
      },
      child: GestureDetector(
        onTap: isDisabled ? null : widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: MouseRegion(
          cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8), // Standard radius: 8
              border: _isFocused && !isDisabled
                  ? Border.all(color: colors.brandPrimaryBorder, width: 1.2)
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                      color: fg,
                      size: 16,
                    ),
                    child: widget.icon!,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: isDisabled ? 0.4 : 1.0,
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: fg,
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                      child: widget.trailing!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 16. Auto-review critique
- The design systems are modular, pure, and compile without errors.
- Visual token implementations successfully mapped context parameters dynamically, responding dynamically to dark/light transitions.
- Testing successfully checks behaviors for all 9 widgets.
- Headless testing limitations regarding Material 3 `ink_sparkle` shader loading were identified and bypassed cleanly by substituting `PokeMapButton` instead of the generic Material `ElevatedButton` in testing mock parameters.

---

## 17. Limites restantes
- Reusable widgets do not include layout components or animations such as sliding animations for panel drawers.
- No components have been swapped out in the active editor UI yet.

---

## 18. Prochaine étape recommandée
We recommend proceeding to **Theme-3 — PokeMap UI Component Gallery / Visual Smoke Screen V0** or **Theme-3 — Sidebar Migration V0** to showcase these widgets in action and visually confirm their aesthetic values.
