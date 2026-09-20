import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'story_labels.dart';

class StoryMetadataFields extends StatelessWidget {
  const StoryMetadataFields({
    super.key,
    required this.identity,
    required this.title,
    required this.description,
    required this.notes,
    required this.status,
    required this.onCommit,
    this.type,
  });
  final String identity, title;
  final String? description, notes;
  final StorylineStatus? status;
  final StorylineType? type;
  final void Function(String field, String value) onCommit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final field in [
        ('title', 'Nom', title),
        ('description', 'Description', description ?? ''),
        ('notes', 'Notes d’auteur', notes ?? ''),
      ]) ...[
        StudioCommitField(
          key: ValueKey('$identity:${field.$1}'),
          label: field.$2,
          value: field.$3,
          maxLines: field.$1 == 'title' ? 1 : 3,
          onCommit: (value) => onCommit(field.$1, value),
        ),
        const SizedBox(height: 14),
      ],
      if (type != null) ...[
        StudioSelect(
          label: 'Type d’histoire',
          value: type!.name,
          options: {
            for (final value in StorylineType.values)
              value.name: storyTypeLabel(value),
          },
          onChanged: (value) => onCommit('type', value),
        ),
        const SizedBox(height: 14),
      ],
      StudioSelect(
        label: 'Statut d’auteur',
        value: status?.name ?? 'inherit',
        options: {
          if (type == null) 'inherit': 'Non précisé',
          for (final value in StorylineStatus.values)
            value.name: storyStatusLabel(value),
        },
        onChanged: (value) => onCommit('status', value),
      ),
    ],
  );
}

String storyConditionText(ScriptCondition? condition, ProjectManifest project) {
  if (condition == null) return 'Aucune condition définie';
  final flag = condition.params[ScriptConditionParams.flagName];
  final label =
      project.facts.where((f) => f.id == flag).firstOrNull?.label ?? flag;
  return switch (condition.type) {
    ScriptConditionType.flagIsSet => '$label = Oui',
    ScriptConditionType.flagIsUnset => '$label = Non',
    ScriptConditionType.allOf =>
      'Toutes ces conditions : ${condition.children.map((c) => storyConditionText(c, project)).join(' ; ')}',
    ScriptConditionType.anyOf =>
      'Au moins une condition : ${condition.children.map((c) => storyConditionText(c, project)).join(' ; ')}',
    ScriptConditionType.not =>
      'Inverse de : ${condition.children.map((c) => storyConditionText(c, project)).join(' ; ')}',
    _ =>
      'Condition avancée conservée (${condition.type.name}). Son édition n’est pas proposée ici.',
  };
}
