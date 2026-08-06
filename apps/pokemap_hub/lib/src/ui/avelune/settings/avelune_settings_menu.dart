import 'package:flutter/material.dart';

import '../avelune_theme.dart';

/// One destination in the Avelune settings sheet.
@immutable
final class AveluneSettingsEntry {
  const AveluneSettingsEntry({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSelected,
  });

  final String id;
  final IconData icon;
  final String title;

  /// Live state for this destination — never a placeholder. Callers project it
  /// from the real snapshot so the sheet reads as a status board.
  final String subtitle;
  final VoidCallback onSelected;
}

/// Destination list of the approved settings sheet.
///
/// Presentational on purpose: the shell owns the data and the routing, so this
/// widget can be pumped on its own and cannot invent state.
class AveluneSettingsMenu extends StatelessWidget {
  const AveluneSettingsMenu({
    super.key,
    required this.entries,
    this.caption,
  });

  final List<AveluneSettingsEntry> entries;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;

    return Column(
      key: const ValueKey<String>('avelune-settings-menu'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (caption case final text?) ...<Widget>[
          Text(
            text,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12.5,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AveluneSpacing.md),
        ],
        for (final entry in entries) ...<Widget>[
          _AveluneSettingsRow(entry: entry),
          if (entry != entries.last) const SizedBox(height: AveluneSpacing.sm),
        ],
      ],
    );
  }
}

class _AveluneSettingsRow extends StatelessWidget {
  const _AveluneSettingsRow({required this.entry});

  final AveluneSettingsEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.aveluneColors;
    return AvelunePressable(
      key: ValueKey<String>('avelune-settings-row-${entry.id}'),
      semanticLabel: '${entry.title}, ${entry.subtitle}',
      onPressed: entry.onSelected,
      borderRadius: AveluneShapes.lg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised.withValues(alpha: 0.62),
          borderRadius: AveluneShapes.lg,
          border: Border.all(color: colors.outline.withValues(alpha: 0.6)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AveluneSpacing.md,
            vertical: AveluneSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Icon(entry.icon, size: 20, color: colors.accentBright),
              const SizedBox(width: AveluneSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AveluneSpacing.hairline),
                    Text(
                      entry.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AveluneSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
