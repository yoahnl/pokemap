import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../cupertino_editor_widgets.dart';

/// Groupe visuel de boutons/cibles de toolbar.
///
/// Cette extraction isole la "skin" du chrome de toolbar sans toucher au
/// wiring Riverpod ni aux callbacks.
class ToolbarCapsuleGroup extends StatelessWidget {
  const ToolbarCapsuleGroup({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visibleChildren =
        children.whereType<Widget>().toList(growable: false);
    return SizedBox(
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.toolbarCapsuleFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF524A64),
            width: 1,
          ),
          boxShadow: EditorChrome.toolbarCapsuleShadows(context),
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
      ),
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
    const accent = EditorChrome.accentPrimary;
    final enabled = widget.onPressed != null;
    final capsule = EditorChrome.toolbarCapsuleFill(context);
    final selectedFill = Color.lerp(capsule, accent, 0.26)!;
    final iconColor = !enabled
        ? CupertinoColors.inactiveGray.resolveFrom(context)
        : (widget.selected ? accent : EditorChrome.primaryLabel(context));
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.selected
            ? selectedFill
            : (_hovered ? EditorChrome.toolbarMutedHoverFill(context) : null),
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
    final labelColor = EditorChrome.primaryLabel(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: EditorChrome.toolbarPulldownTrackFill(context),
        borderRadius: BorderRadius.circular(9),
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
