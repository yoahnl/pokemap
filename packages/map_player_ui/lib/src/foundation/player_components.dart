import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_window_theme.dart';

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
    this.role = PlayerPanelRole.standard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final PlayerPanelRole role;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final semantic = context.playerSemanticTheme;
    final windowTheme = context.playerWindowTheme;
    final windowRole = switch (role) {
      PlayerPanelRole.dialogue => ProjectWindowRole.dialogue,
      PlayerPanelRole.menu => ProjectWindowRole.pauseMenu,
      _ => null,
    };
    final windowStyle = windowTheme == null || windowRole == null
        ? null
        : windowTheme.style(windowRole);
    final surface = switch (role) {
      PlayerPanelRole.standard =>
        elevated ? colors.surfaceElevated : colors.surface,
      PlayerPanelRole.title => semantic.titleSurface,
      PlayerPanelRole.dialogue => semantic.dialogueSurface,
      PlayerPanelRole.menu => semantic.menuSurface,
      PlayerPanelRole.overworldHud => semantic.overworldHudSurface,
      PlayerPanelRole.battleHud => semantic.battleHudSurface,
    };
    return Material(
      color: windowStyle == null
          ? surface
          : windowTheme!.resolveToken(windowStyle.fillToken, semantic),
      elevation: windowStyle == null
          ? (elevated ? 8 : 0)
          : windowStyle.shadowElevation.toDouble(),
      shadowColor: Theme.of(context).colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          windowStyle?.cornerRadius.toDouble() ?? PlayerRadii.md,
        ),
        side: windowStyle?.borderWidth == 0
            ? BorderSide.none
            : BorderSide(
                color: windowStyle == null
                    ? colors.outline
                    : windowTheme!.resolveToken(
                        windowStyle.borderToken,
                        semantic,
                      ),
                width: windowStyle?.borderWidth.toDouble() ?? 1,
              ),
      ),
      child: Padding(
        padding: windowStyle == null
            ? padding
            : EdgeInsets.all(windowStyle.contentPadding.toDouble()),
        child: child,
      ),
    );
  }
}

enum PlayerPanelRole {
  standard,
  title,
  dialogue,
  menu,
  overworldHud,
  battleHud,
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
    this.quiet = false,
    this.expandContent = false,
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
  final bool quiet;
  final bool expandContent;
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
      mainAxisSize: widget.expandContent ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Icon(widget.icon),
        const SizedBox(width: PlayerSpacing.sm),
        if (widget.expandContent)
          Expanded(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: context.playerTypography.bodyStyle(
                Theme.of(context).textTheme.labelLarge ??
                    DefaultTextStyle.of(context).style,
              ),
            ),
          )
        else
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: context.playerTypography.bodyStyle(
                Theme.of(context).textTheme.labelLarge ??
                    DefaultTextStyle.of(context).style,
              ),
            ),
          ),
        if (widget.trailing != null) ...<Widget>[
          const SizedBox(width: PlayerSpacing.sm),
          Flexible(child: widget.trailing!),
        ],
      ],
    );
    final button = widget.quiet
        ? TextButton(
            onPressed: widget.onPressed,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: colors.textSecondary,
            ),
            child: buttonChild,
          )
        : widget.secondary
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

enum PlayerProgressStepState { pending, active, completed }

@immutable
final class PlayerProgressStepData {
  const PlayerProgressStepData({
    required this.label,
    required this.state,
    this.key,
  });

  final String label;
  final PlayerProgressStepState state;
  final Key? key;
}

class PlayerProgressCard extends StatelessWidget {
  const PlayerProgressCard({
    super.key,
    required this.title,
    required this.stage,
    this.value,
    this.progressLabel,
    this.remainingLabel,
    this.steps = const <PlayerProgressStepData>[],
    this.onCancel,
  });

  final String title;
  final String stage;
  final double? value;
  final String? progressLabel;
  final String? remainingLabel;
  final List<PlayerProgressStepData> steps;
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (progressLabel case final label?)
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: context.playerColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: PlayerSpacing.xs),
              Text(stage),
              const SizedBox(height: PlayerSpacing.md),
              LinearProgressIndicator(value: value),
              if (remainingLabel case final label?) ...<Widget>[
                const SizedBox(height: PlayerSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.playerColors.textSecondary,
                      ),
                ),
              ],
              if (steps.isNotEmpty) ...<Widget>[
                const SizedBox(height: PlayerSpacing.md),
                Divider(color: context.playerColors.outline),
                const SizedBox(height: PlayerSpacing.xs),
                for (final step in steps) _PlayerProgressStep(step: step),
              ],
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

class _PlayerProgressStep extends StatelessWidget {
  const _PlayerProgressStep({required this.step});

  final PlayerProgressStepData step;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final (icon, color) = switch (step.state) {
      PlayerProgressStepState.completed => (
          Icons.check_circle_rounded,
          colors.success
        ),
      PlayerProgressStepState.active => (
          Icons.radio_button_checked_rounded,
          colors.primary
        ),
      PlayerProgressStepState.pending => (
          Icons.radio_button_unchecked_rounded,
          colors.textSecondary
        ),
    };
    return Padding(
      key: step.key,
      padding: const EdgeInsets.symmetric(vertical: PlayerSpacing.xxs),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(width: PlayerSpacing.sm),
          Expanded(
            child: Text(
              step.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: step.state == PlayerProgressStepState.pending
                        ? colors.textSecondary
                        : colors.textPrimary,
                    fontWeight: step.state == PlayerProgressStepState.active
                        ? FontWeight.w700
                        : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
