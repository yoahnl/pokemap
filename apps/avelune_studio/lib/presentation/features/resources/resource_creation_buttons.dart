import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/terrains/domain/terrain_draft_compatibility.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'resource_catalog.dart';
import 'resource_preview.dart';

List<Widget> resourceCreationButtons({
  required BuildContext context,
  required ProjectManifest project,
  required MapWorkspaceVisuals visuals,
  required VoidCallback onCreateBorder,
  required ValueChanged<ResourceItem> onCreatePath,
  required VoidCallback onImport,
  VoidCallback? onCharacters,
}) => [
  if (onCharacters != null)
    StudioButton(
      label: 'Personnages',
      icon: Icons.people_outline,
      secondary: true,
      onPressed: onCharacters,
    ),
  StudioButton(
    label: 'Créer une bordure',
    icon: Icons.timeline,
    secondary: true,
    onPressed: onCreateBorder,
  ),
  StudioButton(
    label: 'Créer un chemin',
    icon: Icons.route_outlined,
    secondary: true,
    onPressed: () async {
      final choice = await showDialog<Object>(
        context: context,
        builder: (context) =>
            _PathSourceDialog(project: project, visuals: visuals),
      );
      if (!context.mounted) return;
      if (choice is ResourceItem) onCreatePath(choice);
      if (choice is _ImportPathImage) onImport();
    },
  ),
];

class _PathSourceDialog extends StatelessWidget {
  const _PathSourceDialog({required this.project, required this.visuals});

  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;

  @override
  Widget build(BuildContext context) {
    final sources = resourceCatalog(project)
        .where(
          (item) =>
              item.tileset != null &&
              terrainSourceCompatibilityProblem(item.tileset!) == null,
        )
        .toList();
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      child: SizedBox(
        width: (size.width - 48).clamp(0, 650).toDouble(),
        height: (size.height - 80)
            .clamp(260, (260 + sources.length * 92).clamp(300, 540))
            .toDouble(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choisir l’image du chemin',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text('Sélectionnez une planche à grille régulière.'),
              const SizedBox(height: 14),
              Expanded(
                child: sources.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune image compatible. Importez une planche à grille régulière pour créer un chemin.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: sources.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = sources[index];
                          return InkWell(
                            key: ValueKey('path-source-${item.id}'),
                            onTap: () => Navigator.of(context).pop(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  resourcePreview(
                                    item,
                                    project,
                                    visuals,
                                    size: 72,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Text(item.name)),
                                  const Icon(Icons.arrow_forward),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  StudioButton(
                    label: 'Fermer',
                    secondary: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  StudioButton(
                    label: 'Importer une image',
                    icon: Icons.add_photo_alternate_outlined,
                    onPressed: () =>
                        Navigator.of(context).pop(const _ImportPathImage()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ImportPathImage {
  const _ImportPathImage();
}
