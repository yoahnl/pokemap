import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show BoxShadow, Colors, Material;
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

/// Couleurs et séparateurs pour l’éditeur en thème sombre type iOS.
abstract final class EditorChrome {
  static Color panelBackground(BuildContext context) =>
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);

  static Color scaffoldBackground(BuildContext context) =>
      CupertinoColors.systemGroupedBackground.resolveFrom(context);

  static Color separator(BuildContext context) =>
      CupertinoColors.separator.resolveFrom(context);

  static Color subtleLabel(BuildContext context) =>
      CupertinoColors.placeholderText.resolveFrom(context);

  static Color primaryLabel(BuildContext context) =>
      CupertinoColors.label.resolveFrom(context);

  static Color activeAccent(BuildContext context) =>
      CupertinoTheme.of(context).primaryColor;

  static const Color borderSubtle = Color(0x1AFFFFFF);
}

class EditorHorizontalDivider extends StatelessWidget {
  const EditorHorizontalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: EditorChrome.separator(context),
    );
  }
}

class EditorVerticalDivider extends StatelessWidget {
  const EditorVerticalDivider({super.key, this.indent = 8});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(vertical: indent),
      color: EditorChrome.separator(context),
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

  @override
  State<CupertinoDisclosureTile> createState() =>
      _CupertinoDisclosureTileState();
}

class _CupertinoDisclosureTileState extends State<CupertinoDisclosureTile> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final chevronColor =
        CupertinoColors.secondaryLabel.resolveFrom(context);
    Widget header = CupertinoButton(
      padding: widget.tilePadding,
      minimumSize: Size.zero,
      onPressed: () => setState(() => _expanded = !_expanded),
      child: Row(
        children: [
          Transform.rotate(
            angle: _expanded ? math.pi / 2 : 0,
            child: MacosIcon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: chevronColor,
            ),
          ),
          if (widget.leading != null) ...[
            const SizedBox(width: 6),
            widget.leading!,
          ],
          if (widget.leading != null) const SizedBox(width: 8),
          Expanded(
            child: DefaultTextStyle.merge(
              style: CupertinoTheme.of(context).textTheme.textStyle,
              child: widget.title,
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
    if (widget.onSecondaryTapDown != null) {
      header = GestureDetector(
        onSecondaryTapDown: widget.onSecondaryTapDown,
        behavior: HitTestBehavior.opaque,
        child: header,
      );
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
      return Center(
        child: MacosSheet(
          insetPadding: const EdgeInsets.symmetric(horizontal: 72, vertical: 44),
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
                    style: editorMacosSheetTitleStyle(ctx),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
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
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
}) async {
  var saved = false;
  await showMacosSheet<void>(
    context: context,
    builder: (ctx) => MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: MacosTheme.of(ctx).typography.title2,
              ),
              const SizedBox(height: 16),
              MacosTextField(
                controller: controller,
                placeholder: placeholder,
                autofocus: true,
                keyboardType: keyboardType ?? TextInputType.text,
                inputFormatters: inputFormatters,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: PushButton(
                      controlSize: ControlSize.large,
                      secondary: true,
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PushButton(
                      controlSize: ControlSize.large,
                      onPressed: () {
                        if (requireNonEmpty &&
                            controller.text.trim().isEmpty) {
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
      ),
    ),
  );
  return saved;
}
