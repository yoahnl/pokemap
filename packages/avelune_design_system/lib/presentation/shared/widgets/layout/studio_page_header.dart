import 'package:flutter/material.dart';

import '../../../theme/studio_tokens.dart';

class StudioPageHeader extends StatelessWidget {
  const StudioPageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
    this.alignActionsToEnd = false,
    this.prominent = false,
    this.compact = false,
    this.titleMaxLines,
  }) : _section = false;

  const StudioPageHeader.section({
    super.key,
    required this.title,
    this.actions = const [],
  }) : description = null,
       alignActionsToEnd = true,
       prominent = false,
       compact = true,
       titleMaxLines = null,
       _section = true;

  final String title;
  final String? description;
  final List<Widget> actions;
  final bool alignActionsToEnd;
  final bool prominent;
  final bool compact;
  final int? titleMaxLines;
  final bool _section;

  @override
  Widget build(BuildContext context) =>
      _section ? _buildSection(context) : _buildPage(context);

  Widget _buildPage(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: titleMaxLines,
              overflow: titleMaxLines == null ? null : TextOverflow.ellipsis,
              style: prominent
                  ? Theme.of(context).textTheme.headlineMedium
                  : Theme.of(context).textTheme.titleLarge,
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(description!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        );
        final buttons = Wrap(spacing: 8, runSpacing: 8, children: actions);
        if (!compact &&
            (constraints.maxWidth < 900 ||
                MediaQuery.textScalerOf(context).scale(14) > 20)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              if (actions.isNotEmpty) ...[const SizedBox(height: 12), buttons],
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 16),
            Flexible(
              child: alignActionsToEnd
                  ? Align(alignment: Alignment.centerRight, child: buttons)
                  : buttons,
            ),
          ],
        );
      },
    ),
  );

  Widget _buildSection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.xl),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.xs,
                    vertical: StudioSpacing.m,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.primary, width: 2),
                    ),
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.labelLarge),
                    ),
                  ),
                ),
              ),
            ),
            if (actions.isNotEmpty)
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: StudioSpacing.s,
                    runSpacing: StudioSpacing.s,
                    children: actions,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
