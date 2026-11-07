import 'package:flutter/material.dart';

import '../../../features/narrative/application/scene_node_references.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../scenes/scene_inspector.dart';

String sceneNodeReferenceLabel(SceneNodeReference reference) =>
    '${reference.scene.name} · ${sceneNodeName(reference.scene.graph, reference.node.id)}';

Future<SceneNodeReference?> chooseSceneNodeReference(
  BuildContext context, {
  required String title,
  required String empty,
  required List<SceneNodeReference> references,
}) async {
  if (references.length == 1) return references.single;
  return showDialog<SceneNodeReference>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (references.isEmpty) Text(empty),
              for (final reference in references)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: StudioButton(
                    label: sceneNodeReferenceLabel(reference),
                    icon: Icons.account_tree_outlined,
                    secondary: true,
                    onPressed: () => Navigator.pop(context, reference),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        StudioButton(
          label: references.isEmpty ? 'Fermer' : 'Annuler',
          secondary: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
