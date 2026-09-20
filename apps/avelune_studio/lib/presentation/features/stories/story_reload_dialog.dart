import 'package:flutter/material.dart';
import '../../../features/stories/application/story_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';

Future<void> reloadStory(
  BuildContext context,
  StoryWorkspaceController controller,
  String id,
) async {
  final story = controller.stories.where((s) => s.id == id).firstOrNull;
  if (story == null || controller.busy) return;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Recharger « ${story.title} » ?'),
      content: const Text(
        'Les modifications non enregistrées de cette histoire seront abandonnées. Les autres brouillons restent ouverts.',
      ),
      actions: [
        StudioButton(
          label: 'Conserver le brouillon',
          secondary: true,
          onPressed: () => Navigator.pop(context, false),
        ),
        StudioButton(
          label: 'Recharger cette histoire',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (accepted != true || !context.mounted || controller.busy) return;
  final reloaded = await controller.reload(id, expectedStory: story);
  if (!reloaded && context.mounted && controller.error != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(controller.error!)));
  }
}
