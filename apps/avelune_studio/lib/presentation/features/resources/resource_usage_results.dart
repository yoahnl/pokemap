import 'package:flutter/material.dart';
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
    final groups = <String, List<ResourceUsageEntry>>{};
    for (final entry in report?.entries ?? <ResourceUsageEntry>[]) {
      groups.putIfAbsent(entry.ownerKind, () => []).add(entry);
    }
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
        () => Text(
          [
            for (final relation in ResourceUsageRelation.values)
              '${_relation(relation)} : ${report.entries.where((entry) => entry.relation == relation).length}',
          ].join(' · '),
        ),
        if (report.entries.isEmpty)
          () => Text(
            report.complete && dirtyOwners.isEmpty && !stale
                ? 'Aucun usage trouvé dans le périmètre complet de cette révision.'
                : 'Aucun résultat disponible. Cela ne signifie pas « inutilisé ».',
          ),
        for (final group in groups.entries) ...[
          () => Text(
            _owner(group.key),
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
                Text('${_relation(entry.relation)} · ${entry.ownerId}'),
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

String _relation(ResourceUsageRelation relation) => switch (relation) {
  ResourceUsageRelation.direct => 'Direct',
  ResourceUsageRelation.indirect => 'Indirect',
  ResourceUsageRelation.technical => 'Conservation technique',
  ResourceUsageRelation.ambiguous => 'Identité ambiguë',
};

String _owner(String owner) => switch (owner) {
  'map' => 'Cartes et instances',
  'element' => 'Définitions de décors',
  'preset' => 'Terrains automatiques',
  'character' => 'Personnages et portraits',
  'scene' => 'Scènes',
  'presentationCinematic' => 'Présentations',
  'media' => 'Médias de présentation',
  'border' || 'borderSnapshot' => 'Bordures et snapshots',
  'smartTileDraft' => 'Brouillons de terrains',
  'dialogueSource' => 'Dialogues',
  'pokemonMedia' => 'Médias Pokémon',
  _ => owner,
};
