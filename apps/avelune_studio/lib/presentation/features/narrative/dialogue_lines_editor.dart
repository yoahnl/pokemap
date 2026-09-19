import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/dialogue_editing_controller.dart';
import '../../../features/narrative/domain/dialogue_draft.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../characters/character_workspace_visuals.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'narrative_name_dialog.dart';
import 'dialogue_portrait_choice.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';

class DialogueLinesEditor extends StatelessWidget {
  const DialogueLinesEditor({
    super.key,
    required this.editor,
    required this.project,
    required this.visuals,
  });
  final DialogueEditingController editor;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  @override
  Widget build(BuildContext context) {
    final branch = editor.branch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StudioTabs<int>(
              items: {
                for (final entry in editor.draft.branches.indexed)
                  entry.$1: entry.$2.name,
              },
              selected: editor.session.branchIndex,
              onChanged: (index) {
                editor.session.branchIndex = index;
                editor.changed();
              },
            ),
            StudioButton(
              label: 'Ajouter une suite',
              secondary: true,
              onPressed: () async {
                final name = await askNarrativeName(context, 'Nom de la suite');
                if (name != null) editor.addBranch(name);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioDraftField(
          label: 'Nom de cette suite',
          value: branch.name,
          onChanged: (name) => editor.updateBranch(branch.copyWith(name: name)),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: StudioButton(
            label: 'Supprimer cette suite',
            variant: StudioButtonVariant.destructive,
            onPressed: editor.session.branchIndex == 0
                ? null
                : () {
                    if (!editor.removeBranch()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cette suite est encore utilisée par un choix. Changez sa destination d’abord.',
                          ),
                        ),
                      );
                    }
                  },
          ),
        ),
        for (final entry in branch.lines.indexed) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Expanded(child: Text('Réplique ${entry.$1 + 1}')),
                StudioTool(
                  label: 'Monter la réplique',
                  icon: Icons.arrow_upward,
                  onPressed: entry.$1 == 0
                      ? null
                      : () => editor.moveLine(entry.$1, -1),
                ),
                StudioTool(
                  label: 'Descendre la réplique',
                  icon: Icons.arrow_downward,
                  onPressed: entry.$1 + 1 == branch.lines.length
                      ? null
                      : () => editor.moveLine(entry.$1, 1),
                ),
                StudioTool(
                  label: 'Supprimer la réplique',
                  icon: Icons.delete_outline,
                  onPressed: () => editor.removeLine(entry.$1),
                ),
              ],
            ),
          ),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'speaker-${branch.id}-${entry.$1}-${entry.$2.speakerId}',
            ),
            initialValue: entry.$2.speakerId ?? '',
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Locuteur'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Sans portrait')),
              for (final character in project.characters)
                DropdownMenuItem(
                  value: character.id,
                  child: Row(
                    children: [
                      if (visuals is CharacterWorkspaceVisuals)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: (visuals as CharacterWorkspaceVisuals)
                              .characterThumbnail(character, size: 28),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          character.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            onChanged: (id) {
              final character = project.characters
                  .where((c) => c.id == id)
                  .firstOrNull;
              editor.line(
                entry.$1,
                DialogueLineDraft(
                  text: entry.$2.text,
                  speakerId: character?.id,
                  portraitStateId:
                      character?.portraits.firstOrNull?.portraitStateId,
                ),
              );
            },
          ),
          DialoguePortraitChoice(
            project: project,
            line: entry.$2,
            onChanged: (line) => editor.line(entry.$1, line),
          ),
          if (entry.$2.speakerId != null &&
              project.characters.any(
                (c) => c.id == entry.$2.speakerId && c.portraits.isEmpty,
              ))
            const StudioNotice(
              'Ce personnage n’a pas de portrait préparé ; le texte reste utilisable.',
            ),
          const SizedBox(height: 8),
          StudioDraftField(
            key: ValueKey('line-${branch.id}-${entry.$1}'),
            label: 'Texte de la réplique ${entry.$1 + 1}',
            value: entry.$2.text,
            lines: 3,
            onChanged: (text) => editor.line(
              entry.$1,
              DialogueLineDraft(
                text: text,
                speakerId: entry.$2.speakerId,
                portraitStateId: entry.$2.portraitStateId,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        StudioButton(
          label: 'Ajouter une réplique',
          secondary: true,
          onPressed: editor.addLine,
        ),
        const SizedBox(height: 20),
        Text('Choix du joueur', style: Theme.of(context).textTheme.titleMedium),
        for (final entry in branch.choices.indexed) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StudioDraftField(
                  label: 'Choix ${entry.$1 + 1}',
                  value: entry.$2.text,
                  onChanged: (text) => editor.choice(
                    entry.$1,
                    DialogueChoiceDraft(
                      text: text,
                      targetId: entry.$2.targetId,
                      outcomeId: entry.$2.outcomeId,
                    ),
                  ),
                ),
              ),
              StudioTool(
                label: 'Supprimer le choix',
                icon: Icons.delete_outline,
                onPressed: () => editor.removeChoice(entry.$1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(
              'target-${branch.id}-${entry.$1}-${entry.$2.targetId}',
            ),
            initialValue: entry.$2.targetId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Puis afficher'),
            items: [
              for (final target in editor.draft.branches)
                DropdownMenuItem(value: target.id, child: Text(target.name)),
            ],
            onChanged: (target) {
              if (target != null) {
                editor.choice(
                  entry.$1,
                  DialogueChoiceDraft(
                    text: entry.$2.text,
                    targetId: target,
                    outcomeId: entry.$2.outcomeId,
                  ),
                );
              }
            },
          ),
        ],
        const SizedBox(height: 10),
        StudioButton(
          label: 'Ajouter un choix',
          secondary: true,
          onPressed: editor.addChoice,
        ),
      ],
    );
  }
}
