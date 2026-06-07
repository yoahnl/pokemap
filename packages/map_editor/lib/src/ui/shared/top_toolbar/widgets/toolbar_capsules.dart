import 'package:flutter/cupertino.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

import '../../../../theme/theme.dart';

/// Groupe visuel de boutons/cibles de toolbar.
///
/// Cette extraction isole la "skin" du chrome de toolbar sans toucher au
/// wiring Riverpod ni aux callbacks.
class ToolbarCapsuleGroup extends StatelessWidget {
  const ToolbarCapsuleGroup({
    super.key,
    required this.children,
    this.title,
    this.selected = false,
  });

  final List<Widget> children;
  final String? title;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final visibleChildren =
        children.whereType<Widget>().toList(growable: false);
    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    final capsule = Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? colors.brandPrimaryBorder : colors.borderSubtle,
          width: 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: colors.brandPrimary.withValues(alpha: 0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < visibleChildren.length; index++) ...[
              visibleChildren[index],
              if (index < visibleChildren.length - 1)
                const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );

    final Widget content;
    if (title == null) {
      content = capsule;
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              title!,
              style: TextStyle(
                color: selected ? colors.brandPrimary : colors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          capsule,
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: content,
    );
  }
}

/// Bouton iconique de toolbar.
///
/// On garde le petit état local de hover ici, car c'est un détail purement UI
/// qui n'a rien à faire dans le shell principal.
class ToolbarCapsuleButton extends StatefulWidget {
  const ToolbarCapsuleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  State<ToolbarCapsuleButton> createState() => _ToolbarCapsuleButtonState();
}

class _ToolbarCapsuleButtonState extends State<ToolbarCapsuleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final enabled = widget.onPressed != null;
    final selectedFill = colors.surfaceSelected;
    final iconColor = !enabled
        ? colors.textDisabled
        : (widget.selected ? colors.brandPrimary : colors.textSecondary);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.selected
            ? selectedFill
            : (_hovered ? colors.surfaceHover : null),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: MacosIcon(
        widget.icon,
        size: 17,
        color: iconColor,
      ),
    );

    return MacosTooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      ),
    );
  }
}

/// Pulldown stylé utilisé dans la bande de contexte.
class ToolbarCapsulePulldown extends StatelessWidget {
  const ToolbarCapsulePulldown({
    super.key,
    required this.label,
    required this.items,
  });

  final String label;
  final List<MacosPulldownMenuEntry> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final labelColor = colors.textPrimary;
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: colors.borderSubtle,
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 32,
        child: MacosPulldownButton(
          items: items,
          title: label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
