import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/design_system/foundation/avelune_spacing_tokens.dart';
import 'package:pokemap_hub/presentation/design_system/theme/avelune_theme_extensions.dart';

class AveluneSectionLabel extends StatelessWidget {
  const AveluneSectionLabel({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: colors.brass),
        const SizedBox(width: AveluneSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textPrimary,
                  letterSpacing: 1.1,
                ),
          ),
        ),
        if (trailing case final trailing?) ...<Widget>[
          const SizedBox(width: AveluneSpacing.sm),
          trailing,
        ],
      ],
    );
  }
}
