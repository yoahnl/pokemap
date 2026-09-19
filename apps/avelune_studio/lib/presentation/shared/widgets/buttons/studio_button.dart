import 'package:flutter/material.dart';

enum StudioButtonVariant { primary, secondary, quiet, destructive }

class StudioButton extends StatelessWidget {
  const StudioButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.icon,
    this.variant,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final IconData? icon;
  final StudioButtonVariant? variant;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveVariant =
        variant ??
        (secondary
            ? StudioButtonVariant.secondary
            : StudioButtonVariant.primary);
    final action = loading ? null : onPressed;
    final content = icon == null && !loading
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 16),
              const SizedBox(width: 8),
              Flexible(child: Text(label)),
            ],
          );
    return switch (effectiveVariant) {
      StudioButtonVariant.primary => FilledButton(
        onPressed: action,
        child: content,
      ),
      StudioButtonVariant.secondary => OutlinedButton(
        onPressed: action,
        child: content,
      ),
      StudioButtonVariant.quiet => TextButton(
        onPressed: action,
        child: content,
      ),
      StudioButtonVariant.destructive => OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: colors.error),
        onPressed: action,
        child: content,
      ),
    };
  }
}
