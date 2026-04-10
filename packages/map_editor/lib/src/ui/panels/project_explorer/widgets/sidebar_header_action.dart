import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../shared/cupertino_editor_widgets.dart';

/// Action compacte utilisée dans les entêtes de tuiles du navigateur projet.
///
/// Ce widget n'embarque qu'un petit état de survol purement visuel. Le sortir
/// du panneau principal évite de laisser tout le chrome de section collé au
/// shell de l'explorer.
class SidebarHeaderAction extends StatefulWidget {
  const SidebarHeaderAction({
    super.key,
    required this.enabled,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.hoverFill,
  });

  final bool enabled;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? hoverFill;

  @override
  State<SidebarHeaderAction> createState() => _SidebarHeaderActionState();
}

class _SidebarHeaderActionState extends State<SidebarHeaderAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return MacosTooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        child: GestureDetector(
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered && enabled
                  ? (widget.hoverFill ??
                      CupertinoColors.systemFill.resolveFrom(context))
                  : CupertinoColors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: MacosIcon(
              widget.icon,
              size: 16,
              color: enabled
                  ? (widget.iconColor ?? EditorChrome.primaryLabel(context))
                  : CupertinoColors.inactiveGray.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }
}
