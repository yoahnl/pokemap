import 'package:flutter/material.dart';
import '../../../theme/studio_tokens.dart';
import '../inputs/studio_choice.dart';

class StudioDestination {
  const StudioDestination({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool selected;
}

class StudioTopBar extends StatelessWidget {
  const StudioTopBar({super.key, this.projectName, this.actions = const []});
  final String? projectName;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.nightlight_round,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Avelune Studio',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (projectName != null)
                  Text(
                    projectName!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ),
        ],
      ),
    );
  }
}

class StudioAppShell extends StatelessWidget {
  const StudioAppShell({
    super.key,
    required this.child,
    this.projectName,
    this.destinations = const [],
    this.actions = const [],
  });
  final Widget child;
  final String? projectName;
  final List<StudioDestination> destinations;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      StudioTopBar(projectName: projectName, actions: actions),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 1480 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (destinations.isNotEmpty)
                  StudioNavigationRail(
                    destinations: destinations,
                    compact: compact,
                  ),
                Expanded(child: child),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class StudioNavigationRail extends StatelessWidget {
  const StudioNavigationRail({
    super.key,
    required this.destinations,
    this.compact = false,
  });
  final List<StudioDestination> destinations;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: compact
        ? StudioMetrics.compactNavigationWidth
        : StudioMetrics.navigationWidth,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border(
        right: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    ),
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      children: [
        for (final destination in destinations)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: compact
                ? Semantics(
                    selected: destination.selected,
                    child: IconButton(
                      tooltip: destination.label,
                      onPressed: destination.onTap,
                      icon: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(destination.icon),
                          const SizedBox(height: 6),
                          Text(
                            destination.label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: destination.selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        foregroundColor: destination.selected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            StudioMetrics.controlRadius,
                          ),
                        ),
                      ),
                    ),
                  )
                : StudioChoice(
                    label: destination.label,
                    leading: Icon(destination.icon),
                    selected: destination.selected,
                    onTap: destination.onTap,
                  ),
          ),
      ],
    ),
  );
}
