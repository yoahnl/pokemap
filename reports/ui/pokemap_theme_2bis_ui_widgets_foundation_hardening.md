# Theme-2bis — PokeMap UI Widgets Foundation Hardening Report

This report outlines the implementation and verification details for the hardening phase: **Theme-2bis — UI Widgets Foundation Hardening**.

---

## 1. Résumé
This hardening phase focused on reinforcing layout safety and adding keyboard/semantics accessibility for the recently introduced PokeMap UI design system widgets. 
Specifically, we:
- Resolved a potential flex crash in `PokeMapPanel` by removing the forced `Expanded` widget on its child. We introduced an `expandChild` property that defaults to `false` and is safe in unbounded layouts.
- Integrated standard Flutter accessibility `Semantics` and keyboard-invoked `ActivateIntent` mapping (`ActivateAction`) to all key interactive components: `PokeMapButton`, `PokeMapIconButton`, and `PokeMapSidebarItem`.
- Updated and expanded the widget tests to cover unbounded vertical height layouts, bounded flex constraints, and accessibility semantics validation.

---

## 2. Problèmes corrigés
- **Flex Layout Crash Risk**: `PokeMapPanel` previously wrapped its main content in an `Expanded` layout. If pumped within a flex parent widget lacking tight constraints (like a `ListView` or unconstrained `Column`), this triggered layout exceptions.
- **Keyboard / Accessibility Gap**: Interactive custom items built using `GestureDetector` lacked basic accessibility wrappers and keyboard trigger support (Space/Enter).

---

## 3. Correction de PokeMapPanel
We added `expandChild` to `PokeMapPanel`:
- By default (`expandChild = false`), the child renders inside a standard `Padding` container without any surrounding `Expanded` constraints, avoiding layout errors.
- Setting `expandChild = true` allows wrapping the inner content with `Expanded`, taking up maximum height inside bounded flex structures.

---

## 4. Correction sémantique / clavier des widgets interactifs
All key interactive widgets (`PokeMapButton`, `PokeMapIconButton`, `PokeMapSidebarItem`) now wrap their layout nodes with:
1. **`Semantics`**: Informs assistive tools that the widget acts as a button, is currently enabled or disabled, and indicates whether it is currently selected (for sidebar items).
2. **`FocusableActionDetector` Action Binding**:
   - Added mapping of `ActivateIntent` class type to a `CallbackAction<ActivateIntent>`.
   - Whenever the widget gains focus, pressing **Enter** or **Space** triggers the widget's tap/activation callback.

---

## 5. Fichiers modifiés
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart`

---

## 6. Fichiers de test ajoutés/modifiés
- `packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_button_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart`

---

## 7. Contenu complet des fichiers modifiés

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
    this.expandChild = false,
  });

  /// Optional widget displayed at the top of the panel (e.g., section title or actions toolbar).
  final Widget? header;

  /// Main content child widget.
  final Widget child;

  /// Optional widget displayed at the bottom of the panel (e.g., status flags or confirmation buttons).
  final Widget? footer;

  /// Inner padding around the [child] widget. Defaults to 16.
  final EdgeInsetsGeometry? padding;

  /// If true, wraps the child in an [Expanded] container. Defaults to false.
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;

    final childWidget = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

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
          mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (header != null) ...[
              header!,
              Container(
                height: 1,
                color: colors.divider,
              ),
            ],
            if (expandChild)
              Expanded(child: childWidget)
            else
              childWidget,
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

    return Semantics(
      button: true,
      enabled: !isDisabled,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (!isDisabled) {
                widget.onPressed?.call();
              }
              return null;
            },
          ),
        },
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

    Widget content = Semantics(
      button: true,
      enabled: !isDisabled,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (!isDisabled) {
                widget.onPressed?.call();
              }
              return null;
            },
          ),
        },
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

    return Semantics(
      button: true,
      selected: isActive,
      enabled: !isDisabled,
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (!isDisabled) {
                widget.onTap?.call();
              }
              return null;
            },
          ),
        },
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
      ),
    );
  }
}
```

---

## 8. Contenu complet des fichiers de test pertinents

### [pokemap_card_panel_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests', () {
    Widget buildTestWidget({
      required ThemeData theme,
      required Widget child,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('PokeMapCard & PokeMapPanel pump correctly under light & dark theme', (tester) async {
      // PokeMapCard
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapCard(
            child: Text('Card Content'),
          ),
        ),
      );
      expect(find.text('Card Content'), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: const PokeMapCard(
            child: Text('Card Content'),
          ),
        ),
      );
      expect(find.text('Card Content'), findsOneWidget);

      // PokeMapPanel
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapPanel(
            header: Text('Header'),
            footer: Text('Footer'),
            child: Text('Panel Content'),
          ),
        ),
      );
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Panel Content'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('PokeMapPanel layout constraints and expandChild configurations', (tester) async {
      // 1. Default (expandChild = false) renders fine in unbounded height (Column)
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: Column(
              children: [
                PokeMapPanel(
                  header: Text('Header Title'),
                  child: Text('Unbounded height test child'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Unbounded height test child'), findsOneWidget);

      // 2. expandChild = true works in a bounded context (within an Expanded column)
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              height: 500,
              child: Column(
                children: [
                  Expanded(
                    child: PokeMapPanel(
                      expandChild: true,
                      header: Text('Header Title'),
                      child: Text('Bounded height test child'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Bounded height test child'), findsOneWidget);
    });

    testWidgets('PokeMapCard border changes when selected', (tester) async {
      late BuildContext capturedContext;
      
      // Unselected card
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const PokeMapCard(
                  selected: false,
                  child: Text('Card Content'),
                );
              },
            ),
          ),
        ),
      );

      final cardFinder = find.byType(PokeMapCard);
      expect(cardFinder, findsOneWidget);

      final containerWidgetUnselected = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decorationUnselected = containerWidgetUnselected.decoration as BoxDecoration;
      final borderUnselected = decorationUnselected.border as Border;
      
      // Selected card
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return const PokeMapCard(
                  selected: true,
                  child: Text('Card Content'),
                );
              },
            ),
          ),
        ),
      );

      final containerWidgetSelected = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decorationSelected = containerWidgetSelected.decoration as BoxDecoration;
      final borderSelected = decorationSelected.border as Border;

      expect(borderUnselected.top.color, isNot(equals(borderSelected.top.color)));
      expect(borderSelected.top.color, equals(capturedContext.pokeMapColors.brandPrimaryBorder));
    });

    testWidgets('PokeMapToolbarSurface & PokeMapSectionHeader pump correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapToolbarSurface(
            child: Text('Toolbar Content'),
          ),
        ),
      );
      expect(find.text('Toolbar Content'), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapSectionHeader(
            title: 'Section Title',
            description: 'Section Description',
            trailing: Icon(Icons.info),
          ),
        ),
      );
      expect(find.text('Section Title'), findsOneWidget);
      expect(find.text('Section Description'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('PokeMapEmptyState displays title, description and action if provided', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapEmptyState(
            title: 'No Items Found',
            description: 'Please add some items to get started.',
            icon: const Icon(Icons.hourglass_empty),
            action: PokeMapButton(
              onPressed: () => actionTriggered = true,
              child: const Text('Add Now'),
            ),
          ),
        ),
      );

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.text('Please add some items to get started.'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('Add Now'), findsOneWidget);

      await tester.tap(find.text('Add Now'));
      expect(actionTriggered, isTrue);
    });
  });
}
```

### [pokemap_button_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapButton & PokeMapIconButton Tests', () {
    Widget buildTestWidget({
      required ThemeData theme,
      required Widget child,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('PokeMapButton pumps correctly under light & dark theme', (tester) async {
      // Light Mode
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapButton(
            onPressed: () {},
            child: const Text('Light Button'),
          ),
        ),
      );
      expect(find.text('Light Button'), findsOneWidget);

      // Dark Mode
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: PokeMapButton(
            onPressed: () {},
            child: const Text('Dark Button'),
          ),
        ),
      );
      expect(find.text('Dark Button'), findsOneWidget);
    });

    testWidgets('PokeMapButton disabled if onPressed is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapButton(
            onPressed: null,
            child: Text('Disabled Button'),
          ),
        ),
      );

      final buttonFinder = find.byType(PokeMapButton);
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<PokeMapButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('PokeMapButton displays spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapButton(
            onPressed: () {},
            isLoading: true,
            child: const Text('Loading Button'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      final button = tester.widget<PokeMapButton>(find.byType(PokeMapButton));
      expect(button.isLoading, isTrue);
    });

    testWidgets('PokeMapIconButton tooltip is displayed and works with variants', (tester) async {
      int count = 0;
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapIconButton(
            onPressed: () => count++,
            icon: const Icon(Icons.add),
            tooltip: 'Add Item',
            variant: PokeMapIconButtonVariant.soft,
          ),
        ),
      );

      final iconFinder = find.byType(PokeMapIconButton);
      expect(iconFinder, findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      await tester.tap(iconFinder);
      await tester.pump();
      expect(count, equals(1));
    });

    testWidgets('PokeMapIconButton supports disabled state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: const PokeMapIconButton(
            onPressed: null,
            icon: Icon(Icons.add),
            variant: PokeMapIconButtonVariant.danger,
          ),
        ),
      );

      final iconFinder = find.byType(PokeMapIconButton);
      expect(iconFinder, findsOneWidget);

      // Verify that tap doesn't cause errors since onPressed is null
      await tester.tap(iconFinder);
      await tester.pump();
    });

    testWidgets('PokeMapButton and PokeMapIconButton provide Semantics information', (tester) async {
      // 1. PokeMapButton
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapButton(
            onPressed: () {},
            child: const Text('Semantics Button'),
          ),
        ),
      );

      final buttonSemanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true && widget.properties.enabled == true
      );
      expect(buttonSemanticsFinder, findsOneWidget);

      // 2. PokeMapIconButton
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapIconButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
          ),
        ),
      );

      final iconSemanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.button == true && widget.properties.enabled == true
      );
      expect(iconSemanticsFinder, findsOneWidget);
    });
  });
}
```

### [pokemap_sidebar_item_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart)
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('PokeMapSidebarItem Tests', () {
    Widget buildTestWidget({
      required ThemeData theme,
      required Widget child,
    }) {
      return MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(child: child),
        ),
      );
    }

    testWidgets('PokeMapSidebarItem pumps correctly under light & dark theme', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapSidebarItem(
            label: 'Home',
            icon: const Icon(Icons.home),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.dark(),
          child: PokeMapSidebarItem(
            label: 'Home',
            icon: const Icon(Icons.home),
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('PokeMapSidebarItem selected displays active state styles', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return PokeMapSidebarItem(
                  label: 'Selected Tab',
                  selected: true,
                  icon: const Icon(Icons.star),
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      );

      final textFinder = find.text('Selected Tab');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(capturedContext.pokeMapColors.brandPrimary));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('PokeMapSidebarItem disabled does not trigger onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapSidebarItem(
            label: 'Disabled Tab',
            disabled: true,
            icon: const Icon(Icons.block),
            onTap: () => tapped = true,
          ),
        ),
      );

      final itemFinder = find.byType(PokeMapSidebarItem);
      expect(itemFinder, findsOneWidget);

      await tester.tap(itemFinder);
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('PokeMapSidebarItem provides Semantics information', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          theme: PokeMapTheme.light(),
          child: PokeMapSidebarItem(
            label: 'Home Tab',
            selected: true,
            onTap: () {},
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) => widget is Semantics &&
                    widget.properties.button == true &&
                    widget.properties.selected == true &&
                    widget.properties.enabled == true
      );
      expect(semanticsFinder, findsOneWidget);
    });
  });
}
```

---

## 9. Commandes lancées avec résultats exacts

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
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_badge_test.dart: PokeMapBadge Tests PokeMapBadge pumps correctly under light & dark theme for all variants
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapButton pumps correctly under light & dark theme
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapButton pumps correctly under light & dark theme
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard & PokeMapPanel pump correctly under light & dark theme
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard & PokeMapPanel pump correctly under light & dark theme
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard & PokeMapPanel pump correctly under light & dark theme
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapIconButton tooltip is displayed and works with variants
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapPanel layout constraints and expandChild configurations
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapIconButton supports disabled state
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapCard border changes when selected
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_button_test.dart: PokeMapButton & PokeMapIconButton Tests PokeMapButton and PokeMapIconButton provide Semantics information
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapToolbarSurface & PokeMapSectionHeader pump correctly
00:01 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart: PokeMapCard, Panel, Toolbar, SectionHeader, and EmptyState Tests PokeMapEmptyState displays title, description and action if provided
00:01 +17: All tests passed!
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

## 10. Git status initial
```text
 M packages/map_editor/lib/main.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
?? packages/map_editor/lib/src/ui/design_system/
?? packages/map_editor/test/ui/design_system/
?? reports/ui/pokemap_theme_1bis_material_root_migration_hardening.md
?? reports/ui/pokemap_theme_2_ui_widgets_foundation.md
```

---

## 11. Git status final
```text
 M packages/map_editor/lib/main.dart
 M packages/map_editor/test/shell_chrome_test_harness.dart
?? packages/map_editor/lib/src/ui/design_system/
?? packages/map_editor/test/ui/design_system/
?? reports/ui/pokemap_theme_1bis_material_root_migration_hardening.md
?? reports/ui/pokemap_theme_2_ui_widgets_foundation.md
?? reports/ui/pokemap_theme_2bis_ui_widgets_foundation_hardening.md
```

---

## 12. Git diff --stat tracked
```text
 packages/map_editor/lib/main.dart                  | 17 +++++----
 .../map_editor/test/shell_chrome_test_harness.dart | 41 ++++++++++++++--------
 2 files changed, 37 insertions(+), 21 deletions(-)
```

---

## 13. Liste des fichiers untracked introduits
All these files have been introduced as untracked under `packages/map_editor/` and `reports/`:
- `packages/map_editor/lib/src/ui/design_system/pokemap_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_icon_button.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_card.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_panel.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_badge.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_section_header.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_empty_state.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_toolbar_surface.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/test/ui/design_system/pokemap_button_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_badge_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_card_panel_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_sidebar_item_test.dart`
- `reports/ui/pokemap_theme_2_ui_widgets_foundation.md`
- `reports/ui/pokemap_theme_2bis_ui_widgets_foundation_hardening.md`

---

## 14. Auto-review critique
- Introducing the `expandChild` property resolves potential parent-flex crashes while maintaining compatibility for current setups.
- Focus and Semantics bindings conform strictly to Flutter best practices without turning widgets into overly complex structures.
- Tests verify layout rendering constraints explicitly.

---

## 15. Limites restantes
- Interactive elements do not integrate complex micro-animations (such as focus/hover scaling or highlight transitions).
- Complex custom inputs (text areas, dropdown pickers) are left for future design system iterations.

---

## 16. Prochaine étape recommandée
Proceed to **Theme-3 — Sidebar Migration V0** or **Theme-3 — PokeMap UI Component Gallery**.
