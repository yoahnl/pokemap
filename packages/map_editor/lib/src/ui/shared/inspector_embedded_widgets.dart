import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        BorderSide,
        BoxShadow,
        Colors,
        Material,
        PopupMenuButton,
        PopupMenuItem,
        RoundedRectangleBorder;

import 'cupertino_editor_widgets.dart';

/// Padding standard du corps des tuiles inspecteur (contenu sous l’en-tête).
const EdgeInsets kInspectorTileBodyPadding =
    EdgeInsets.fromLTRB(10, 8, 10, 10);

class InspectorEmbeddedSectionLabel extends StatelessWidget {
  const InspectorEmbeddedSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.secondaryLabel.resolveFrom(context),
      ),
    );
  }
}

/// Bandeau d’aide / statut en bas de section (contraste lisible sur tuile teintée).
class InspectorEmbeddedFootnote extends StatelessWidget {
  const InspectorEmbeddedFootnote({
    super.key,
    required this.text,
    required this.accent,
  });

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.05),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          height: 1.25,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

/// Menu déroulant ancré (pilule + liste), même look sur toutes les tuiles.
class InspectorEmbeddedDropdown extends StatelessWidget {
  const InspectorEmbeddedDropdown({
    super.key,
    required this.accent,
    required this.fieldLabel,
    required this.valueLabel,
    required this.orderedIds,
    required this.selectedMenuValue,
    required this.idToLabel,
    required this.onSelected,
    this.selectedIdForCheck,
    this.tooltip,
  });

  final Color accent;
  final String fieldLabel;
  final String valueLabel;
  final List<String> orderedIds;
  final String selectedMenuValue;
  final String? selectedIdForCheck;
  final String Function(String id) idToLabel;
  final ValueChanged<String> onSelected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = EditorChrome.primaryLabel(context);
    final canOpen = orderedIds.isNotEmpty;
    final child = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canOpen
              ? accent.withValues(alpha: 0.5)
              : CupertinoColors.systemGrey.resolveFrom(context),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fieldLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: secondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valueLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_down,
            size: 14,
            color: canOpen ? accent : secondary,
          ),
        ],
      ),
    );

    if (!canOpen) {
      return Opacity(opacity: 0.55, child: child);
    }

    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: tooltip ?? fieldLabel,
        padding: EdgeInsets.zero,
        splashRadius: 20,
        offset: const Offset(0, 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accent.withValues(alpha: 0.35)),
        ),
        color: EditorChrome.islandFillElevated(context),
        elevation: 3,
        initialValue: orderedIds.contains(selectedMenuValue)
            ? selectedMenuValue
            : orderedIds.first,
        onSelected: onSelected,
        itemBuilder: (menuCtx) => [
          for (final id in orderedIds)
            PopupMenuItem<String>(
              value: id,
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child:
                        selectedIdForCheck != null && id == selectedIdForCheck
                            ? Icon(
                                CupertinoIcons.checkmark,
                                size: 14,
                                color: accent,
                              )
                            : null,
                  ),
                  Expanded(
                    child: Text(
                      idToLabel(id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: selectedIdForCheck != null &&
                                id == selectedIdForCheck
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        child: child,
      ),
    );
  }
}

class InspectorEmbeddedPrimaryCapsule extends StatelessWidget {
  const InspectorEmbeddedPrimaryCapsule({
    super.key,
    required this.accent,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.prominent = false,
    this.enabled = true,
  });

  final Color accent;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool prominent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = EditorChrome.primaryLabel(context);
    final muted = CupertinoColors.placeholderText.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: enabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: !enabled
              ? EditorChrome.largeIslandSurfaceColor(context)
              : prominent
                  ? Color.lerp(
                      EditorChrome.largeIslandSurfaceColor(
                        context,
                        tint: accent.withValues(alpha: 0.22),
                      ),
                      accent.withValues(alpha: 0.15),
                      0.35,
                    )
                  : EditorChrome.largeIslandSurfaceColor(
                      context,
                      tint: accent.withValues(alpha: 0.08),
                    ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: enabled ? 0.5 : 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.1),
              blurRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? (prominent ? accent : fg) : muted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: enabled ? fg : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InspectorEmbeddedSecondaryCapsule extends StatelessWidget {
  const InspectorEmbeddedSecondaryCapsule({
    super.key,
    required this.accent,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final Color accent;
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = EditorChrome.primaryLabel(context);
    final muted = CupertinoColors.placeholderText.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: enabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: accent.withValues(alpha: enabled ? 0.07 : 0.03),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: enabled ? 0.42 : 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: enabled ? accent : muted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: enabled ? fg : muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
