import 'package:flutter/material.dart';
import '../../../features/cinematics/application/cinematic_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_tool.dart';

class CinematicDocumentToolbar extends StatelessWidget {
  const CinematicDocumentToolbar({
    super.key,
    required this.controller,
    required this.onDuplicate,
    required this.onDelete,
    required this.onReload,
    required this.onArchive,
  });
  final CinematicWorkspaceController controller;
  final VoidCallback onDuplicate, onDelete, onReload, onArchive;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${controller.active!.asset.title}${controller.active!.dirty ? ' · brouillon' : ''}',
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        StudioTool(
          label: 'Dupliquer la cinématique',
          icon: Icons.copy,
          onPressed: onDuplicate,
        ),
        StudioTool(
          label: 'Archiver ou restaurer la cinématique',
          icon: Icons.archive_outlined,
          onPressed: onArchive,
        ),
        StudioTool(
          label: 'Recharger la cinématique',
          icon: Icons.refresh,
          onPressed: onReload,
        ),
        StudioTool(
          label: 'Supprimer la cinématique',
          icon: Icons.delete_outline,
          onPressed: onDelete,
        ),
      ],
    ),
  );
}
