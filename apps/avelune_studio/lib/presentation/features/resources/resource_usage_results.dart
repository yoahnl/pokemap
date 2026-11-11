import 'package:flutter/material.dart';
import '../../../features/resources/application/resource_usage_presentation.dart';
import '../../../features/resources/domain/resource_usage_port.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class ResourceUsageResults extends StatelessWidget {
  const ResourceUsageResults({
    super.key,
    required this.report,
    required this.error,
    required this.dirtyOwners,
    required this.stale,
    required this.onOpen,
    required this.canOpen,
  });
  final ResourceUsageReport? report;
  final String? error;
  final List<String> dirtyOwners;
  final bool stale;
  final ValueChanged<ResourceUsageEntry> onOpen;
  final bool Function(ResourceUsageEntry entry) canOpen;

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    final groups = groupResourceUsageEntries(report);
    final rows = <Widget Function()>[
      () => const Text(
        'Lecture seule du projet enregistré. L’analyse ne sauvegarde rien '
        'et ne donne aucune autorisation de suppression.',
      ),
      if (error != null)
        () => Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      if (dirtyOwners.isNotEmpty)
        () => Text(
          'Brouillons non analysés : ${dirtyOwners.join(' · ')}. '
          'Les usages créés uniquement en mémoire restent à résoudre '
          'avant toute décision risquée.',
        ),
      if (report != null) ...[
        () => SelectableText('Révision : ${report.revision}'),
        for (final issue in report.coverageIssues) () => Text(issue),
        () => Text(resourceUsageRelationSummary(report)),
        if (resourceUsageEmptyMessage(
              report,
              dirtyOwners: dirtyOwners,
              stale: stale,
            )
            case final message?)
          () => Text(message),
        for (final group in groups.entries) ...[
          () => Text(
            resourceUsageOwnerLabel(group.key),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final entry in group.value)
            () => StudioPanel(
              compact: true,
              children: [
                Text(
                  entry.ownerLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text('${resourceUsageRelationLabel(entry.relation)} · ${entry.ownerId}'),
                const SizedBox(height: 6),
                SelectableText(entry.location),
                if (!stale && canOpen(entry)) ...[
                  const SizedBox(height: 8),
                  StudioButton(
                    key: ValueKey(
                      'resource-usage-open-${entry.ownerKind}:${entry.ownerId}:${entry.location}:${entry.relation.name}',
                    ),
                    label: 'Ouvrir le propriétaire',
                    icon: Icons.open_in_new,
                    secondary: true,
                    onPressed: () => onOpen(entry),
                  ),
                ],
              ],
            ),
        ],
      ],
    ];
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: rows[index](),
      ),
    );
  }
}
