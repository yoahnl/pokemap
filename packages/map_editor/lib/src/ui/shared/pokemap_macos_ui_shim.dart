import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/theme.dart';

// --- App and Window shims ---

class MacosApp extends StatelessWidget {
  const MacosApp({
    super.key,
    this.home,
    this.theme,
    this.darkTheme,
    this.themeMode,
    this.title = '',
  });

  final Widget? home;
  final MacosThemeData? theme;
  final MacosThemeData? darkTheme;
  final ThemeMode? themeMode;
  final String title;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: home,
      theme: theme?.context != null ? Theme.of(theme!.context!) : ThemeData.light(),
      darkTheme: darkTheme?.context != null ? Theme.of(darkTheme!.context!) : ThemeData.dark(),
      themeMode: themeMode,
      title: title,
    );
  }
}

class MacosWindow extends StatelessWidget {
  const MacosWindow({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: child,
    );
  }
}

class MacosScaffold extends StatelessWidget {
  const MacosScaffold({
    super.key,
    required this.children,
    this.toolBar,
    this.backgroundColor,
  });

  final List<Widget> children;
  final Widget? toolBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.transparent,
      appBar: toolBar != null ? PreferredSize(
        preferredSize: const Size.fromHeight(52.0),
        child: toolBar!,
      ) : null,
      body: Row(
        children: [
          for (final child in children)
            if (child is ResizablePane)
              SizedBox(width: child.minSize, child: child)
            else
              Expanded(child: child),
        ],
      ),
    );
  }
}

class ContentArea extends StatelessWidget {
  const ContentArea({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext, ScrollController) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, ScrollController());
  }
}

enum ResizableSide {
  left,
  right,
}

class ResizablePane extends StatelessWidget {
  const ResizablePane({
    super.key,
    required this.child,
    required this.minSize,
    required this.maxSize,
    required this.startSize,
    required this.resizableSide,
    this.decoration,
  });

  const ResizablePane.noScrollBar({
    super.key,
    required this.child,
    required this.minSize,
    required this.maxSize,
    required this.startSize,
    required this.resizableSide,
    this.decoration,
  });

  final Widget child;
  final double minSize;
  final double maxSize;
  final double startSize;
  final ResizableSide resizableSide;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      child: child,
    );
  }
}

// --- Theme shim ---

class MacosTheme extends StatelessWidget {
  const MacosTheme({
    super.key,
    required this.data,
    required this.child,
  });

  final MacosThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }

  static Brightness brightnessOf(BuildContext context) {
    return Theme.of(context).brightness;
  }

  static MacosThemeData of(BuildContext context) {
    return MacosThemeData(context);
  }

  static MacosThemeData? maybeOf(BuildContext context) {
    return MacosThemeData(context);
  }
}

class MacosThemeData {
  final BuildContext? context;
  MacosThemeData(this.context);

  factory MacosThemeData.dark() => MacosThemeData(null);
  factory MacosThemeData.light() => MacosThemeData(null);

  Brightness get brightness => context != null ? Theme.of(context!).brightness : Brightness.light;
  Color get primaryColor => context != null ? Theme.of(context!).colorScheme.primary : Colors.blue;
  Color get canvasColor => context != null ? Theme.of(context!).colorScheme.surface : Colors.white;
  Color get dividerColor => context != null ? Theme.of(context!).dividerColor : Colors.grey;
  AccentColor get accentColor => AccentColor.blue;
  VisualDensity get visualDensity => context != null ? Theme.of(context!).visualDensity : VisualDensity.comfortable;
  
  MacosTypography get typography => MacosTypography(context);

  MacosThemeData copyWith({
    AccentColor? accentColor,
    Color? primaryColor,
    Color? canvasColor,
    Color? dividerColor,
    VisualDensity? visualDensity,
  }) {
    return this;
  }
}

class MacosTypography {
  final BuildContext? context;
  MacosTypography(this.context);

  TextStyle get title2 => (context != null ? Theme.of(context!).textTheme.titleLarge : null)?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ) ?? const TextStyle(fontWeight: FontWeight.w700, fontSize: 20);

  TextStyle get caption1 => (context != null ? Theme.of(context!).textTheme.bodySmall : null)?.copyWith(
        fontSize: 11,
      ) ?? const TextStyle(fontSize: 11);

  TextStyle get body => (context != null ? Theme.of(context!).textTheme.bodyMedium : null) ?? const TextStyle();
}

// --- Colors shim ---

class MacosColors {
  static const Color transparent = Color(0x00000000);
  static const Color white = Colors.white;
  static const Color disabledControlTextColor = Color(0x56FFFFFF);
}

// --- Icons shim ---

class MacosIcon extends StatelessWidget {
  const MacosIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
  });

  final IconData icon;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: size,
    );
  }
}

class MacosIconTheme extends StatelessWidget {
  const MacosIconTheme({
    super.key,
    required this.data,
    required this.child,
  });
  
  final MacosIconThemeData data;
  final Widget child;
  
  static Widget merge({
    required MacosIconThemeData data,
    required Widget child,
  }) {
    return IconTheme.merge(
      data: IconThemeData(
        color: data.color,
        size: data.size,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(
        color: data.color,
        size: data.size,
      ),
      child: child,
    );
  }
}

class MacosIconThemeData {
  const MacosIconThemeData({this.color, this.size});
  final Color? color;
  final double? size;
}

// --- Buttons & Tooltips shim ---

class MacosIconButton extends StatelessWidget {
  const MacosIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.backgroundColor,
    this.hoverColor,
    this.boxConstraints,
    this.borderRadius,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? hoverColor;
  final BoxConstraints? boxConstraints;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    Widget button = CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: icon,
    );

    if (boxConstraints != null) {
      button = ConstrainedBox(
        constraints: boxConstraints!,
        child: Center(child: button),
      );
    }

    if (backgroundColor != null || borderRadius != null) {
      button = DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: button,
      );
    }

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        child: button,
      );
    }

    return button;
  }
}

class MacosTooltip extends StatelessWidget {
  const MacosTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: child,
    );
  }
}

enum ControlSize {
  regular,
  large,
  small,
  mini,
}

enum AccentColor {
  blue,
  purple,
  pink,
  red,
  orange,
  yellow,
  green,
  graphite,
}

class PushButton extends StatelessWidget {
  const PushButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.controlSize = ControlSize.regular,
    this.secondary = false,
    this.color,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final ControlSize controlSize;
  final bool secondary;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    
    final Color buttonColor;
    if (color != null) {
      buttonColor = color!;
    } else if (secondary) {
      buttonColor = colors.surfaceSubtle;
    } else {
      buttonColor = colors.brandPrimary;
    }

    final textColor = secondary 
        ? colors.textPrimary 
        : colors.textInverse;

    final padding = controlSize == ControlSize.large
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    return CupertinoButton(
      padding: padding,
      color: buttonColor,
      disabledColor: colors.surfaceSubtle.withValues(alpha: 0.5),
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(8),
      minSize: 0,
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: textColor,
          fontSize: controlSize == ControlSize.large ? 13 : 12,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}

// --- Text Fields & Dropdowns shim ---

class MacosTextField extends StatelessWidget {
  const MacosTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.enabled,
    this.onChanged,
    this.obscureText = false,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final ValueChanged<String>? onChanged;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      autofocus: autofocus,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      enabled: enabled ?? true,
      onChanged: onChanged,
      obscureText: obscureText,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
      style: TextStyle(
        color: colors.textPrimary,
        fontSize: 13,
      ),
      placeholderStyle: TextStyle(
        color: colors.textMuted,
        fontSize: 13,
      ),
    );
  }
}

class MacosPopupButton<T> extends StatelessWidget {
  const MacosPopupButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.disabledHint,
  });

  final T? value;
  final List<MacosPopupMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Widget? hint;
  final Widget? disabledHint;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        onChanged: onChanged,
        hint: hint,
        disabledHint: disabledHint,
        dropdownColor: colors.surfaceBase,
        icon: Icon(CupertinoIcons.chevron_down, size: 14, color: colors.textSecondary),
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        isExpanded: true,
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item.value,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: colors.textPrimary),
                child: item.child,
              ),
            ),
        ],
      ),
    );
  }
}

class MacosPopupMenuItem<T> {
  const MacosPopupMenuItem({
    this.key,
    required this.value,
    required this.child,
  });

  final Key? key;
  final T value;
  final Widget child;
}

abstract class MacosPulldownMenuEntry {
  const MacosPulldownMenuEntry();
}

class MacosPulldownMenuItem extends MacosPulldownMenuEntry {
  const MacosPulldownMenuItem({
    required this.label,
    required this.title,
    required this.onTap,
  });

  final String label;
  final Widget title;
  final VoidCallback onTap;
}

class MacosPulldownMenuDivider extends MacosPulldownMenuEntry {
  const MacosPulldownMenuDivider();
}

class MacosPulldownButton extends StatelessWidget {
  const MacosPulldownButton({
    super.key,
    required this.items,
    this.icon,
    this.title,
    this.style,
    this.onTap,
  });

  final List<MacosPulldownMenuEntry> items;
  final IconData? icon;
  final String? title;
  final TextStyle? style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    Widget trigger;
    if (title != null) {
      trigger = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title!, style: style),
          const SizedBox(width: 4),
          Icon(CupertinoIcons.chevron_down, size: 12, color: style?.color),
        ],
      );
    } else {
      trigger = Icon(icon ?? CupertinoIcons.ellipsis, size: 16, color: colors.textPrimary);
    }

    return PopupMenuButton<VoidCallback>(
      tooltip: '',
      onSelected: (callback) => callback(),
      child: Center(child: trigger),
      itemBuilder: (context) {
        return items.map((item) {
          if (item is MacosPulldownMenuItem) {
            return PopupMenuItem<VoidCallback>(
              value: item.onTap,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: colors.textPrimary),
                child: item.title,
              ),
            );
          }
          return const PopupMenuDivider() as PopupMenuEntry<VoidCallback>;
        }).toList();
      },
    );
  }
}

// --- Dialogs & Sheets shim ---

Future<T?> showMacosSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  Color? barrierColor,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ?? Colors.black54,
    builder: (ctx) => builder(ctx),
  );
}

class MacosSheet extends StatelessWidget {
  const MacosSheet({
    super.key,
    required this.child,
    this.insetPadding,
  });

  final Widget child;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Dialog(
      insetPadding: insetPadding ?? const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
      backgroundColor: colors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.borderSubtle,
        ),
      ),
      child: child,
    );
  }
}

Future<T?> showMacosAlertDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showDialog<T>(
    context: context,
    builder: builder,
  );
}

class MacosAlertDialog extends StatelessWidget {
  const MacosAlertDialog({
    super.key,
    required this.appIcon,
    required this.title,
    required this.message,
    this.primaryButton,
    this.secondaryButton,
  });

  final Widget appIcon;
  final Widget title;
  final Widget message;
  final Widget? primaryButton;
  final Widget? secondaryButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return AlertDialog(
      icon: appIcon,
      title: title,
      content: message,
      backgroundColor: colors.surfaceBase,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      actions: [
        if (secondaryButton != null) secondaryButton!,
        if (primaryButton != null) primaryButton!,
      ],
    );
  }
}

class ProgressCircle extends StatelessWidget {
  const ProgressCircle({super.key});
  @override
  Widget build(BuildContext context) {
    return const CupertinoActivityIndicator();
  }
}

// --- Compatibility bridge & legacy Toolbar components ---

class PokeMapMacosCompatibilityBridge extends StatelessWidget {
  const PokeMapMacosCompatibilityBridge({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

abstract class ToolbarItem extends StatelessWidget {
  const ToolbarItem({super.key});
}

class ToolBar extends StatelessWidget {
  const ToolBar({
    super.key,
    required this.title,
    this.height = 52.0,
    this.titleWidth = 280.0,
    this.automaticallyImplyLeading = false,
    this.centerTitle = false,
    this.padding,
    this.dividerColor,
    this.decoration,
    this.actions = const [],
  });

  final Widget title;
  final double height;
  final double titleWidth;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final EdgeInsetsGeometry? padding;
  final Color? dividerColor;
  final BoxDecoration? decoration;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MacosSlider extends StatelessWidget {
  const MacosSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.splits,
    this.activeColor,
    this.thumbColor,
    this.discrete = false,
    this.color,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? splits;
  final Color? activeColor;
  final Color? thumbColor;
  final bool discrete;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: splits,
      activeColor: activeColor ?? color,
      thumbColor: thumbColor ?? CupertinoColors.white,
    );
  }
}

class MacosSwitch extends StatelessWidget {
  const MacosSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.trackColor,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      trackColor: trackColor,
    );
  }
}

class WindowMainStateListener {
  static final WindowMainStateListener instance = WindowMainStateListener._();
  WindowMainStateListener._();
  bool get isMainWindow => true;
}

class CustomToolbarItem extends ToolbarItem {
  const CustomToolbarItem({
    super.key,
    required this.inToolbarBuilder,
    required this.inOverflowedBuilder,
  });

  final WidgetBuilder inToolbarBuilder;
  final WidgetBuilder inOverflowedBuilder;

  @override
  Widget build(BuildContext context) {
    return inToolbarBuilder(context);
  }
}

class ToolBarSpacer extends ToolbarItem {
  const ToolBarSpacer({super.key, this.spacerUnits = 1});

  final int spacerUnits;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: spacerUnits * 8.0);
  }
}

class ToolbarOverflowMenuItem extends StatelessWidget {
  const ToolbarOverflowMenuItem({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Text(label);
  }
}
