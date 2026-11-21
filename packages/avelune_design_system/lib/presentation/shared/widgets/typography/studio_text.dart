import 'package:flutter/material.dart';

class StudioCaption extends StatelessWidget {
  const StudioCaption(this.text, {super.key, this.textAlign});

  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      textAlign: textAlign,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class StudioEyebrow extends StatelessWidget {
  const StudioEyebrow(this.text, {super.key, this.singleLine = false});

  final String text;
  final bool singleLine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: singleLine ? 1 : null,
      overflow: singleLine ? TextOverflow.ellipsis : null,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }
}
