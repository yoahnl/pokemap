import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../localization/player_localizations.dart';
import '../theme/pokemap_player_theme.dart';
import '../theme/pokemap_player_surface_palette_theme.dart';
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
    this.surfaceRole,
    this.windowStyleOverride,
    this.surfaceColorOverride,
    this.borderColorOverride,
    this.textColorOverride,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool elevated;
  final PlayerPanelRole role;
  final ProjectPresentationSurfaceRole? surfaceRole;
  final ProjectWindowStyleProfile? windowStyleOverride;
  final Color? surfaceColorOverride;
  final Color? borderColorOverride;
  final Color? textColorOverride;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    final semantic = context.playerSemanticTheme;
    final windowTheme = context.playerWindowTheme;
    final tokenResolver = windowTheme ??
        PokeMapPlayerWindowTheme(legacyProjectPresentationWindows);
    final palette =
        surfaceRole == null ? null : context.playerSurfacePalette(surfaceRole!);
    final assignment = surfaceRole == null
        ? null
        : projectPresentationSurfaceAssignment(surfaceRole!);
    final windowRole = assignment?.windowRole ??
        switch (role) {
          PlayerPanelRole.dialogue => ProjectWindowRole.dialogue,
          PlayerPanelRole.menu => ProjectWindowRole.pauseMenu,
          _ => null,
        };
    final inheritedWindowStyle = windowTheme == null || windowRole == null
        ? null
        : windowTheme.style(windowRole);
    final windowStyle = windowStyleOverride ?? inheritedWindowStyle;
    final surface = assignment == null
        ? switch (role) {
            PlayerPanelRole.standard =>
              elevated ? colors.surfaceElevated : colors.surface,
            PlayerPanelRole.title => semantic.titleSurface,
            PlayerPanelRole.dialogue => semantic.dialogueSurface,
            PlayerPanelRole.menu => semantic.menuSurface,
            PlayerPanelRole.overworldHud => semantic.overworldHudSurface,
            PlayerPanelRole.battleHud => semantic.battleHudSurface,
          }
        : switch (assignment.themeToken) {
            ProjectPresentationSurfaceThemeToken.titleSurface =>
              semantic.titleSurface,
            ProjectPresentationSurfaceThemeToken.dialogueSurface =>
              semantic.dialogueSurface,
            ProjectPresentationSurfaceThemeToken.menuSurface =>
              semantic.menuSurface,
            ProjectPresentationSurfaceThemeToken.overworldHudSurface =>
              semantic.overworldHudSurface,
            ProjectPresentationSurfaceThemeToken.battleHudSurface =>
              semantic.battleHudSurface,
          };
    final paletteSurface = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      palette?.surface,
    );
    final paletteBorder = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      palette?.border,
    );
    final paletteText = PokeMapPlayerProjectColorResolver.tryOpaqueHex(
      palette?.text,
    );
    final resolvedSurface = surfaceColorOverride ??
        paletteSurface ??
        (windowStyle == null
            ? surface
            : tokenResolver.resolveToken(windowStyle.fillToken, semantic));
    final resolvedBorder = borderColorOverride ??
        paletteBorder ??
        (windowStyle == null
            ? colors.outline
            : tokenResolver.resolveToken(windowStyle.borderToken, semantic));
    final side = windowStyle?.borderWidth == 0
        ? BorderSide.none
        : BorderSide(
            color: resolvedBorder,
            width: windowStyle?.borderWidth.toDouble() ?? 1,
          );
    final shape = _playerPanelShape(windowStyle, side);
    final panel = Material(
      color: windowStyle == null
          ? resolvedSurface
          : resolvedSurface.withValues(alpha: windowStyle.fillOpacity),
      elevation: windowStyle == null
          ? (elevated ? 8 : 0)
          : windowStyle.shadowElevation.toDouble(),
      shadowColor: Theme.of(context).colorScheme.shadow,
      shape: shape,
      child: DefaultTextStyle.merge(
        style: textColorOverride == null && paletteText == null
            ? null
            : TextStyle(color: textColorOverride ?? paletteText),
        child: Padding(
          padding: windowStyle == null
              ? padding
              : EdgeInsets.all(windowStyle.contentPadding.toDouble()),
          child: child,
        ),
      ),
    );
    var resolvedTheme = Theme.of(context);
    if (palette != null) {
      resolvedTheme = PokeMapPlayerTheme.withSurfacePalette(
        resolvedTheme,
        palette,
      );
    }
    if (textColorOverride case final textColor?) {
      resolvedTheme = resolvedTheme.copyWith(
        textTheme: resolvedTheme.textTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        ),
      );
    }
    if (palette == null && textColorOverride == null) return panel;
    return Theme(data: resolvedTheme, child: panel);
  }
}

ShapeBorder _playerPanelShape(
  ProjectWindowStyleProfile? style,
  BorderSide side,
) {
  final radius = style?.cornerRadius.toDouble() ?? PlayerRadii.md;
  return switch (style?.shape ?? ProjectWindowShape.rounded) {
    ProjectWindowShape.rectangle => RoundedRectangleBorder(side: side),
    ProjectWindowShape.rounded => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side,
      ),
    ProjectWindowShape.capsule => StadiumBorder(side: side),
    ProjectWindowShape.cutCorner => BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: side,
      ),
    ProjectWindowShape.speech => _PlayerSpeechBubbleBorder(
        side: side,
        radius: radius,
      ),
  };
}

final class _PlayerSpeechBubbleBorder extends ShapeBorder {
  const _PlayerSpeechBubbleBorder({
    required this.side,
    required this.radius,
  });

  final BorderSide side;

  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.only(
        left: side.width,
        top: side.width,
        right: side.width,
        bottom: side.width + 10,
      );

  @override
  ShapeBorder scale(double t) => _PlayerSpeechBubbleBorder(
        side: side.scale(t),
        radius: radius * t,
      );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(side.width), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final body =
        Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - 10);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)))
      ..moveTo(body.left + 28, body.bottom)
      ..lineTo(body.left + 40, rect.bottom)
      ..lineTo(body.left + 52, body.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      getOuterPath(rect, textDirection: textDirection),
      side.toPaint()..style = PaintingStyle.stroke,
    );
  }
}

class PlayerPortraitFrame extends StatelessWidget {
  const PlayerPortraitFrame({
    super.key,
    required this.child,
    required this.dimension,
  });

  final Widget child;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final colors = context.playerColors;
    return Container(
      width: dimension,
      height: dimension,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(PlayerRadii.md),
        border: Border.all(color: colors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PlayerRadii.md - 1),
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
    this.minimumHeight = 48,
    this.shape,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledOpacity = 1,
  })  : assert(minimumHeight >= 48),
        assert(disabledOpacity >= 0 && disabledOpacity <= 1);

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
  final double minimumHeight;
  final OutlinedBorder? shape;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double disabledOpacity;

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
    final buttonChild = Builder(
      builder: (buttonContext) {
        final labelStyle = buttonContext.playerTypography.bodyStyle(
          DefaultTextStyle.of(buttonContext).style,
        );
        return Row(
          mainAxisSize:
              widget.expandContent ? MainAxisSize.max : MainAxisSize.min,
          children: <Widget>[
            Icon(widget.icon),
            const SizedBox(width: PlayerSpacing.sm),
            if (widget.expandContent)
              Expanded(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              )
            else
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: labelStyle,
                ),
              ),
            if (widget.trailing != null) ...<Widget>[
              const SizedBox(width: PlayerSpacing.sm),
              Flexible(child: widget.trailing!),
            ],
          ],
        );
      },
    );
    final hasStyleOverride = widget.foregroundColor != null ||
        widget.backgroundColor != null ||
        widget.shape != null;
    final button = widget.quiet
        ? TextButton(
            onPressed: widget.onPressed,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              foregroundColor: widget.foregroundColor ?? colors.textSecondary,
              backgroundColor: widget.backgroundColor,
              shape: widget.shape,
            ),
            child: buttonChild,
          )
        : widget.secondary
            ? OutlinedButton(
                onPressed: widget.onPressed,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                style: hasStyleOverride
                    ? OutlinedButton.styleFrom(
                        foregroundColor: widget.foregroundColor,
                        backgroundColor: widget.backgroundColor,
                        shape: widget.shape,
                      )
                    : null,
                child: buttonChild,
              )
            : FilledButton(
                onPressed: widget.onPressed,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                style: hasStyleOverride
                    ? FilledButton.styleFrom(
                        foregroundColor: widget.foregroundColor,
                        backgroundColor: widget.backgroundColor,
                        shape: widget.shape,
                      )
                    : null,
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
          constraints: BoxConstraints(minHeight: widget.minimumHeight),
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
          child: !enabled && widget.disabledOpacity < 1
              ? Opacity(
                  opacity: widget.disabledOpacity,
                  child: SizedBox(width: double.infinity, child: button),
                )
              : SizedBox(width: double.infinity, child: button),
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
