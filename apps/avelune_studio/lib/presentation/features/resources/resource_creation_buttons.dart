import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/terrains/domain/terrain_draft_compatibility.dart';
import '../../../features/decors/application/decor_source_support.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'resource_catalog.dart';
import 'resource_source_list.dart';

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
  const _PathSourceDialog({
    required this.project,
    required this.visuals,
    this.decor = false,
    this.allowImport = true,
  });

  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final bool decor;
  final bool allowImport;

  @override
  Widget build(BuildContext context) {
    final sources = resourceCatalog(project)
        .where(
          (item) =>
              (!decor && project.settings.dimension == ProjectDimension.threeD
              ? item.model3d != null && item.metadata(project)?.mapId == null
              : item.tileset != null &&
                    (decor
                        ? canCreateDecor(item.tileset!, project)
                        : terrainSourceCompatibilityProblem(item.tileset!) ==
                              null)),
        )
        .toList();
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      child: SizedBox(
        width: (size.width - 48).clamp(0, 650).toDouble(),
        height: (size.height - 80).clamp(260, 600).toDouble(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                decor
                    ? 'Choisir l’image du décor'
                    : project.settings.dimension == ProjectDimension.threeD
                    ? 'Choisir le modèle du chemin'
                    : 'Choisir l’image du chemin',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                !decor && project.settings.dimension == ProjectDimension.threeD
                    ? 'Sélectionnez une pièce unitaire à peindre sur le terrain.'
                    : 'Sélectionnez une planche à grille régulière.',
              ),
              const SizedBox(height: 14),
              Expanded(
                child: sources.isEmpty
                    ? Center(
                        child: Text(
                          !decor &&
                                  project.settings.dimension ==
                                      ProjectDimension.threeD
                              ? 'Aucun modèle disponible. Importez une pièce unitaire partagée dans le projet.'
                              : 'Aucune image compatible. Importez une planche à grille régulière.',
                        ),
                      )
                    : ResourceSourceList(
                        project: project,
                        visuals: visuals,
                        items: sources,
                        forMapPicker: false,
                        onPick: (item) => Navigator.of(context).pop(item),
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
                    label:
                        !decor &&
                            project.settings.dimension ==
                                ProjectDimension.threeD
                        ? 'Importer un modèle'
                        : 'Importer une image',
                    icon: Icons.add_photo_alternate_outlined,
                    onPressed: allowImport
                        ? () =>
                              Navigator.of(context)
                                  .pop(const _ImportPathImage())
                        : null,
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

Future<void> chooseResourceSource({
  required BuildContext context,
  required ProjectManifest project,
  required MapWorkspaceVisuals visuals,
  required ValueChanged<ResourceItem> onChosen,
  required VoidCallback? onImport,
  bool decor = false,
}) async {
  final choice = await showDialog<Object>(
    context: context,
    builder: (context) => _PathSourceDialog(
      project: project,
      visuals: visuals,
      decor: decor,
      allowImport: onImport != null,
    ),
  );
  if (!context.mounted) return;
  if (choice is ResourceItem) onChosen(choice);
  if (choice is _ImportPathImage) onImport?.call();
}
