import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';
import '../pokemap_icon_button.dart';

enum PokeMapCinematicLayerKind {
  visual,
  visualFolder,
  audio,
  captions,
  markers,
}

extension PokeMapCinematicLayerKindX on PokeMapCinematicLayerKind {
  IconData get icon => switch (this) {
    PokeMapCinematicLayerKind.visual => Icons.layers_outlined,
    PokeMapCinematicLayerKind.visualFolder => Icons.folder_outlined,
    PokeMapCinematicLayerKind.audio => Icons.music_note_rounded,
    PokeMapCinematicLayerKind.captions => Icons.closed_caption_outlined,
    PokeMapCinematicLayerKind.markers => Icons.bookmark_border_rounded,
  };
}

class PokeMapCinematicLayerRow extends StatefulWidget {
  const PokeMapCinematicLayerRow({
    super.key,
    required this.kind,
    required this.label,
    required this.visible,
    required this.locked,
    required this.visibilityLabel,
    required this.lockLabel,
    required this.dragLabel,
    this.selected = false,
    this.indent = 0,
    this.diagnosticLabel,
    this.onSelect,
    this.onVisibilityChanged,
    this.onLockChanged,
    this.dragHandle,
    this.focusNode,
  });

  final PokeMapCinematicLayerKind kind;
  final String label;
  final bool visible;
  final bool locked;
  final String visibilityLabel;
  final String lockLabel;
  final String dragLabel;
  final bool selected;
  final int indent;
  final String? diagnosticLabel;
  final VoidCallback? onSelect;
  final ValueChanged<bool>? onVisibilityChanged;
  final ValueChanged<bool>? onLockChanged;
  final Widget? dragHandle;
  final FocusNode? focusNode;

  @override
  State<PokeMapCinematicLayerRow> createState() =>
      _PokeMapCinematicLayerRowState();
}

class _PokeMapCinematicLayerRowState extends State<PokeMapCinematicLayerRow> {
  bool _hovered = false;
  bool _focused = false;

  void _activate() => widget.onSelect?.call();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final diagnostic = widget.diagnosticLabel?.trim();
    final semanticLabel = diagnostic == null || diagnostic.isEmpty
        ? widget.label
        : '${widget.label}. $diagnostic';
    final background = widget.selected
        ? colors.cardSelected
        : _hovered
        ? colors.cardHover
        : colors.cardSurface;
    final foreground = widget.visible
        ? colors.textPrimary
        : colors.textDisabled;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      selected: widget.selected,
      label: semanticLabel,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        enabled: widget.onSelect != null,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              left: BorderSide(
                color: widget.selected || _focused
                    ? colors.brandPrimary
                    : colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(color: colors.divider),
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: widget.indent * 16.0),
            child: Row(
              children: [
                Semantics(
                  label: widget.dragLabel,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: SizedBox.square(
                      dimension: 32,
                      child:
                          widget.dragHandle ??
                          Icon(
                            Icons.drag_indicator_rounded,
                            size: 16,
                            color: colors.textMuted,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onSelect == null ? null : _activate,
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Icon(widget.kind.icon, size: 16, color: foreground),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 12,
                                  fontWeight: widget.selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (diagnostic != null && diagnostic.isNotEmpty)
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: colors.warning,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                PokeMapIconButton(
                  semanticLabel: widget.visibilityLabel,
                  tooltip: widget.visibilityLabel,
                  onPressed: widget.onVisibilityChanged == null
                      ? null
                      : () => widget.onVisibilityChanged!(!widget.visible),
                  icon: Icon(
                    widget.visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  size: 32,
                ),
                PokeMapIconButton(
                  semanticLabel: widget.lockLabel,
                  tooltip: widget.lockLabel,
                  onPressed: widget.onLockChanged == null
                      ? null
                      : () => widget.onLockChanged!(!widget.locked),
                  icon: Icon(
                    widget.locked
                        ? Icons.lock_outline_rounded
                        : Icons.lock_open_rounded,
                  ),
                  size: 32,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PokeMapCinematicLayerGroupHeader extends StatelessWidget {
  const PokeMapCinematicLayerGroupHeader({
    super.key,
    required this.label,
    required this.expanded,
    required this.hidden,
    required this.locked,
    required this.toggleLabel,
    required this.stateLabel,
    required this.onToggleExpanded,
    this.trailing,
  });

  final String label;
  final bool expanded;
  final bool hidden;
  final bool locked;
  final String toggleLabel;
  final String stateLabel;
  final VoidCallback? onToggleExpanded;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: stateLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceSubtle,
          border: Border(bottom: BorderSide(color: colors.divider)),
        ),
        child: Row(
          children: [
            PokeMapIconButton(
              semanticLabel: toggleLabel,
              tooltip: toggleLabel,
              onPressed: onToggleExpanded,
              icon: Icon(
                expanded
                    ? Icons.expand_more_rounded
                    : Icons.chevron_right_rounded,
              ),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (hidden)
              Icon(
                Icons.visibility_off_outlined,
                size: 15,
                color: colors.textMuted,
              ),
            if (locked) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline_rounded,
                size: 15,
                color: colors.textMuted,
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
