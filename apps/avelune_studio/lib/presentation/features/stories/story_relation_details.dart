import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import 'story_labels.dart';
import 'story_metadata_fields.dart';

class StoryRelationDetails extends StatelessWidget {
  const StoryRelationDetails({
    super.key,
    required this.project,
    required this.projection,
    required this.edge,
    required this.onDisconnect,
    required this.onStructure,
  });
  final ProjectManifest project;
  final StorylineProgressionProjection projection;
  final StorylineProgressionEdge edge;
  final VoidCallback onDisconnect, onStructure;

  @override
  Widget build(BuildContext context) {
    String name(String id) =>
        projection.nodes.where((n) => n.id == id).firstOrNull?.label ?? id;
    final owner = project.storylines
        .where((s) => s.id == edge.source.storylineId)
        .firstOrNull;
    final relation = owner?.relationships
        .where((r) => r.id == edge.source.relationshipId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Relation', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(
          name(edge.fromNodeId),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.arrow_downward, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(progressionLabel(edge.kind))),
            ],
          ),
        ),
        Text(
          name(edge.toNodeId),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 18),
        Text(
          'Document propriétaire : ${owner?.title ?? edge.source.storylineId ?? 'Contexte dérivé'}',
        ),
        const SizedBox(height: 10),
        Text(
          'Origine : ${switch (edge.source.kind) {
            StorylineProgressionSourceKind.ownership => 'Appartenance dans l’histoire',
            StorylineProgressionSourceKind.chapterOrder => 'Classement des chapitres',
            StorylineProgressionSourceKind.stepOrder => 'Classement des étapes',
            StorylineProgressionSourceKind.outcomeEffect => 'Effet d’un résultat déclaré',
            StorylineProgressionSourceKind.relationship => 'Relation entre histoires',
            StorylineProgressionSourceKind.stepCondition => 'Condition de l’étape',
          }}',
        ),
        if (relation != null) ...[
          const SizedBox(height: 14),
          Text(storyConditionText(relation.condition, project)),
          if (relation.anchor case final anchor?)
            Text('Ancre : ${anchor.kind.name} · ${anchor.targetId}'),
          if (relation.availability case final availability?) ...[
            Text(
              'Période : ${availability.startAnchor.targetId} → ${availability.endAnchor?.targetId ?? 'sans fin précisée'}',
            ),
            Text(
              'Disponible : ${storyConditionText(availability.availabilityCondition, project)}',
            ),
            Text(
              'Expire : ${storyConditionText(availability.expiresCondition, project)}',
            ),
            if (availability.requiredOutcomeIds.isNotEmpty)
              Text(
                'Résultats requis : ${availability.requiredOutcomeIds.join(', ')}',
              ),
          ],
          if (relation.notes case final notes?) Text(notes),
        ],
        const SizedBox(height: 18),
        if (edge.editability == StorylineProgressionEdgeEditability.reversible)
          StudioButton(
            label: 'Déconnecter',
            icon: Icons.link_off,
            secondary: true,
            onPressed: onDisconnect,
          )
        else ...[
          StudioNotice(
            edge.readOnlyReason ??
                'Relation dérivée conservée en lecture seule.',
          ),
          if (edge.kind == StorylineProgressionEdgeKind.authorOrder)
            StudioButton(
              label: 'Réordonner dans Structure',
              onPressed: onStructure,
            ),
        ],
        const SizedBox(height: 18),
        const StudioNotice(
          'Ces relations décrivent le projet. Elles ne modifient pas une partie jouée.',
        ),
        const SizedBox(height: 14),
        SelectableText(
          'Référence : ${edge.id}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
