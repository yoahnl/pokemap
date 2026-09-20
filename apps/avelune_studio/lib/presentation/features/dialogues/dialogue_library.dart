import 'package:flutter/material.dart';
import '../../../features/dialogues/application/dialogue_workspace_controller.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'dialogue_view_state.dart';

class DialogueLibrary extends StatelessWidget {
  const DialogueLibrary({
    super.key,
    required this.controller,
    required this.views,
    required this.changed,
    required this.onOpen,
    required this.onCreate,
  });
  final DialogueWorkspaceController controller;
  final DialogueViewStore views;
  final VoidCallback changed, onCreate;
  final ValueChanged<String> onOpen;
  @override
  Widget build(BuildContext context) {
    final query = views.search.text.trim().toLowerCase();
    final entries = controller.entries
        .where(
          (e) =>
              e.name.toLowerCase().contains(query) &&
              (views.folderId.isEmpty || e.folderId == views.folderId),
        )
        .toList();
    return StudioPanel(
      compact: true,
      title: 'Dialogues',
      children: [
        StudioSearchField(
          controller: views.search,
          label: 'Rechercher un dialogue',
          hint: 'Nom du dialogue…',
          onChanged: (_) => changed(),
        ),
        const SizedBox(height: 10),
        if (controller.project.dialogueFolders.isNotEmpty) ...[
          StudioSelect(
            label: 'Dossier',
            value: views.folderId,
            options: {
              '': 'Tous les dialogues',
              for (final f in controller.project.dialogueFolders) f.id: f.name,
            },
            onChanged: (id) {
              views.folderId = id;
              changed();
            },
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final session = controller.session(entry.id);
              final folder = controller.project.dialogueFolders
                  .where((f) => f.id == entry.folderId)
                  .firstOrNull;
              return StudioChoice(
                key: ValueKey('dialogue-library-${entry.id}'),
                label: entry.name,
                selected: controller.activeId == entry.id,
                leading: const StudioIconTile(
                  icon: Icons.forum_outlined,
                  tone: StudioTone.feature,
                ),
                subtitle:
                    '${folder?.name ?? 'Dialogues du projet'}\n${session == null ? 'Contenu à ouvrir' : '${session.document.nodes.length} suites${session.dirty ? ' · brouillon' : ''}'}',
                onTap: () => onOpen(entry.id),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        StudioButton(
          label: 'Nouveau dialogue',
          icon: Icons.add,
          onPressed: controller.busy ? null : onCreate,
        ),
      ],
    );
  }
}
