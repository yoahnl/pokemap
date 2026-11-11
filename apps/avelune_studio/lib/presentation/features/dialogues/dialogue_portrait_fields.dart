import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import '../../../features/dialogues/application/dialogue_workspace_authoring.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class DialoguePortraitFields extends StatelessWidget {
  const DialoguePortraitFields({
    super.key,
    required this.controller,
    required this.line,
    this.portrait,
  });
  final DialogueWorkspaceController controller;
  final DeLineStep line;
  final Widget Function(String?, String?, double)? portrait;
  @override
  Widget build(BuildContext context) {
    final expressions = controller.expressionChoices(line);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioCommitField(
          key: ValueKey('speaker-${line.id}'),
          label: 'Locuteur (facultatif)',
          value: line.speaker ?? '',
          tryCommit: (speaker) =>
              controller.updateLine(line.id, speaker: speaker),
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Personnage et portrait',
          value: line.characterId ?? '',
          options: controller.lineCharacterChoices,
          onChanged: (id) => controller.selectLineCharacter(line.id, id),
        ),
        const SizedBox(height: 8),
        if (expressions != null)
          StudioSelect(
            label: 'Expression',
            value: line.portraitStateId ?? '',
            options: expressions,
            onChanged: (id) =>
                controller.updateLine(line.id, portraitStateId: id),
          ),
        if (portrait != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: portrait!(line.characterId, line.portraitStateId, 80),
            ),
          ),
        if (controller.lineHasNoPreparedPortrait(line))
          const Text('Sans portrait préparé : le texte reste utilisable.'),
      ],
    );
  }
}
