import 'package:flutter/material.dart';

import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';

class PlayerSurface extends StatelessWidget {
  const PlayerSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PlayerSpacing.lg),
    this.maxWidth,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: context.playerColors.background,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? double.infinity,
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      );
}

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PlayerSpacing.lg),
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    return Material(
      color: elevated ? colors.surfaceElevated : colors.surface,
      elevation: elevated ? 8 : 0,
      shadowColor: Theme.of(context).colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PlayerRadii.md),
        side: BorderSide(color: colors.outline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PlayerActionButton extends StatefulWidget {
  const PlayerActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.disabledReason,
    this.autofocus = false,
    this.secondary = false,
    this.trailing,
    this.focusNode,
    this.showFocusHighlight = true,
    this.selected = false,
    this.shortcutLabel,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? disabledReason;
  final bool autofocus;
  final bool secondary;
  final Widget? trailing;
  final FocusNode? focusNode;
  final bool showFocusHighlight;
  final bool selected;
  final String? shortcutLabel;

  @override
  State<PlayerActionButton> createState() => _PlayerActionButtonState();
}

class _PlayerActionButtonState extends State<PlayerActionButton> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ??
        FocusNode(debugLabel: 'Player action: ${widget.label}');
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = context.playerColors;
    final motion = context.playerMotion;
    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(widget.icon),
        const SizedBox(width: PlayerSpacing.sm),
        Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
        if (widget.trailing != null) ...<Widget>[
          const SizedBox(width: PlayerSpacing.sm),
          widget.trailing!,
        ],
      ],
    );
    final button = widget.secondary
        ? OutlinedButton(
            onPressed: widget.onPressed,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            child: buttonChild,
          )
        : FilledButton(
            onPressed: widget.onPressed,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            child: buttonChild,
          );
    return Semantics(
      key: ValueKey<String>('player-action-semantics-${widget.label}'),
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.label,
      hint: _semanticsHint(enabled),
      child: Tooltip(
        message: enabled ? widget.label : widget.disabledReason ?? widget.label,
        child: AnimatedContainer(
          key: const ValueKey<String>('player-action-focus-frame'),
          duration: motion.fast,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PlayerRadii.sm + 3),
            border: Border.all(
              color: _focused && widget.showFocusHighlight
                  ? colors.focus
                  : colors.focus.withValues(alpha: 0),
              width: _focused && widget.showFocusHighlight ? 3 : 1,
            ),
          ),
          child: SizedBox(width: double.infinity, child: button),
        ),
      ),
    );
  }

  String? _semanticsHint(bool enabled) {
    final parts = <String>[
      if (!enabled && widget.disabledReason != null) widget.disabledReason!,
      if (widget.shortcutLabel != null) widget.shortcutLabel!,
    ];
    return parts.isEmpty ? null : parts.join('. ');
  }
}

class PlayerBadge extends StatelessWidget {
  const PlayerBadge({
    super.key,
    required this.label,
    required this.icon,
    this.tone = PlayerBadgeTone.neutral,
  });

  final String label;
  final IconData icon;
  final PlayerBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final foreground = switch (tone) {
      PlayerBadgeTone.neutral => colors.textSecondary,
      PlayerBadgeTone.success => colors.success,
      PlayerBadgeTone.warning => colors.warning,
      PlayerBadgeTone.danger => colors.danger,
    };
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: foreground.withValues(alpha: 0.12),
          border: Border.all(color: foreground),
          borderRadius: BorderRadius.circular(PlayerRadii.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PlayerSpacing.sm,
            vertical: PlayerSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: PlayerSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  softWrap: true,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PlayerBadgeTone { neutral, success, warning, danger }

class PlayerEmptyState extends StatelessWidget {
  const PlayerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => PlayerPanel(
        child: Semantics(
          container: true,
          header: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 52, color: context.playerColors.primary),
              const SizedBox(height: PlayerSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: PlayerSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: PlayerSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: action!,
                ),
              ],
            ],
          ),
        ),
      );
}

class PlayerProgressCard extends StatelessWidget {
  const PlayerProgressCard({
    super.key,
    required this.title,
    required this.stage,
    this.value,
    this.onCancel,
  });

  final String title;
  final String stage;
  final double? value;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => PlayerPanel(
        elevated: true,
        child: Semantics(
          liveRegion: true,
          label: '$title, $stage',
          value: value == null ? null : '${(value! * 100).round()} %',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: PlayerSpacing.xs),
              Text(stage),
              const SizedBox(height: PlayerSpacing.md),
              LinearProgressIndicator(value: value),
              if (onCancel != null) ...<Widget>[
                const SizedBox(height: PlayerSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onCancel,
                    child: Text(context.playerL10n.cancel),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
