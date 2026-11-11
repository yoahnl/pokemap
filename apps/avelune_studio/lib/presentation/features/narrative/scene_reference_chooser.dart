import 'package:flutter/material.dart';

export '../../../features/narrative/application/scene_node_references.dart'
    show sceneNodeReferenceLabel;
import '../../../features/narrative/application/scene_node_references.dart';
import '../../shared/widgets/buttons/studio_button.dart';


Future<SceneNodeReference?> chooseSceneNodeReference(
  BuildContext context, {
  required String title,
  required String empty,
  required List<SceneNodeReference> references,
}) async {
  if (soleSceneNodeReference(references) case final sole?) return sole;
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
