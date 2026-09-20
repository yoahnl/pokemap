import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'story_labels.dart';

Future<(String, StorylineType)?> askStoryCreation(BuildContext context) {
  var title = '';
  var type = StorylineType.main;
  return showDialog<(String, StorylineType)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, changed) => AlertDialog(
        title: const Text('Nouvelle histoire'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nom de l’histoire',
                ),
                onChanged: (value) => changed(() => title = value),
              ),
              const SizedBox(height: 16),
              StudioSelect(
                label: 'Type d’histoire',
                value: type.name,
                options: {
                  for (final t in StorylineType.values)
                    t.name: storyTypeLabel(t),
                },
                onChanged: (value) =>
                    changed(() => type = StorylineType.values.byName(value)),
              ),
            ],
          ),
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
          StudioButton(
            label: 'Créer',
            onPressed: title.trim().isEmpty
                ? null
                : () => Navigator.pop(context, (title.trim(), type)),
          ),
        ],
      ),
    ),
  );
}
