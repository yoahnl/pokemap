import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class DialogueSuiteActions extends StatelessWidget {
  const DialogueSuiteActions({
    super.key,
    required this.controller,
    required this.node,
  });
  final DialogueWorkspaceController controller;
  final DialogueEditorNode node;
  void run(VoidCallback action) {
    final previous = controller.error;
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    if (controller.error != null && controller.error != previous) return;
    action();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioButton(
        label: 'Commencer ici',
        secondary: true,
        icon: Icons.play_circle_outline,
        onPressed: () => run(() => controller.selectEntry(node.id)),
      ),
      const SizedBox(height: 8),
      StudioButton(
        label: 'Essayer depuis cette suite',
        secondary: true,
        onPressed: () =>
            run(() => controller.startPreview(nodeTitle: node.title)),
      ),
      const SizedBox(height: 8),
      StudioButton(
        label: 'Dupliquer la suite',
        secondary: true,
        icon: Icons.copy,
        onPressed: () => run(() => controller.duplicateNode(node.id)),
      ),
    ],
  );
}
