import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
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
    final project = controller.project;
    final character = project.characters
        .where((c) => c.id == line.characterId)
        .firstOrNull;
    final states = {
      for (final state in project.characterStudioCatalog.portraitStates)
        state.id: state.displayName,
    };
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
          options: {
            '': 'Sans personnage',
            for (final c in project.characters) c.id: c.name,
          },
          onChanged: (id) {
            final c = project.characters.where((c) => c.id == id).firstOrNull;
            controller.updateLine(
              line.id,
              characterId: id,
              clearPortrait: id.isEmpty,
              speaker: c?.name,
              portraitStateId: c?.portraits.firstOrNull?.portraitStateId,
            );
          },
        ),
        const SizedBox(height: 8),
        if (character != null && character.portraits.isNotEmpty)
          StudioSelect(
            label: 'Expression',
            value: line.portraitStateId ?? '',
            options: {
              '': 'Sans portrait',
              for (final p in character.portraits)
                p.portraitStateId:
                    states[p.portraitStateId] ?? p.portraitStateId,
            },
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
        if (character?.portraits.isEmpty ?? true)
          const Text('Sans portrait préparé : le texte reste utilisable.'),
      ],
    );
  }
}
