import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_badge.dart';

class DialogueDocumentToolbar extends StatelessWidget {
  const DialogueDocumentToolbar({
    super.key,
    required this.name,
    required this.dirty,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onReload,
    required this.onPreview,
  });
  final String name;
  final bool dirty;
  final VoidCallback? onRename;
  final VoidCallback onDuplicate, onDelete, onReload, onPreview;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(name, style: Theme.of(context).textTheme.titleMedium),
        StudioBadge(
          dirty ? 'Brouillon' : 'Enregistré',
          tone: dirty ? StudioTone.warning : StudioTone.success,
        ),
        StudioTool(
          label: 'Renommer le dialogue',
          icon: Icons.edit_outlined,
          onPressed: onRename,
        ),
        StudioTool(
          label: 'Dupliquer le dialogue',
          icon: Icons.copy,
          onPressed: onDuplicate,
        ),
        StudioTool(
          label: 'Supprimer le dialogue',
          icon: Icons.delete_outline,
          onPressed: onDelete,
        ),
        StudioTool(
          label: 'Recharger le dialogue',
          icon: Icons.refresh,
          onPressed: onReload,
        ),
        StudioTool(
          label: 'Afficher le test de dialogue',
          icon: Icons.chat_outlined,
          onPressed: onPreview,
        ),
      ],
    ),
  );
}
