import 'package:flutter/cupertino.dart';

import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_studio_session.dart';

class SmartTileImageStage extends StatelessWidget {
  const SmartTileImageStage({
    super.key,
    required this.selectedChoice,
    required this.isBusy,
    required this.canContinue,
    required this.onChoiceSelected,
    required this.onChooseProjectImage,
    required this.onChooseRegisteredAtlas,
    required this.onImportImage,
    required this.onContinue,
    this.selectedSource,
    this.errorMessage,
  });

  final SmartTileStudioSourceChoice? selectedChoice;
  final bool isBusy;
  final bool canContinue;
  final ValueChanged<SmartTileStudioSourceChoice> onChoiceSelected;
  final VoidCallback onChooseProjectImage;
  final VoidCallback onChooseRegisteredAtlas;
  final VoidCallback? onImportImage;
  final VoidCallback onContinue;
  final Widget? selectedSource;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Choisir l’image source',
          description:
              'Importez une image ou réutilisez une ressource déjà canonique dans le projet.',
        ),
        const SizedBox(height: 12),
        PokeMapAssetCard(
          key: const Key('smart-tiles-source-project-image'),
          thumbnail: const Icon(CupertinoIcons.photo, size: 22),
          label: 'Image du projet',
          description: 'Importer une image ou choisir un tileset existant.',
          selected: selectedChoice == SmartTileStudioSourceChoice.projectImage,
          onPressed: () => onChoiceSelected(
            SmartTileStudioSourceChoice.projectImage,
          ),
        ),
        const SizedBox(height: 8),
        PokeMapAssetCard(
          key: const Key('smart-tiles-source-registered-atlas'),
          thumbnail: const Icon(CupertinoIcons.square_grid_3x2, size: 22),
          label: 'Atlas Smart Tile enregistré',
          description: 'Reprendre une grille déjà confirmée dans ce projet.',
          selected:
              selectedChoice == SmartTileStudioSourceChoice.registeredAtlas,
          onPressed: () => onChoiceSelected(
            SmartTileStudioSourceChoice.registeredAtlas,
          ),
        ),
        if (selectedChoice == SmartTileStudioSourceChoice.projectImage) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapButton(
                key: const Key('smart-tiles-import-project-image'),
                onPressed: isBusy ? null : onImportImage,
                isLoading: isBusy,
                leading: const Icon(CupertinoIcons.arrow_down_doc, size: 15),
                child: const Text('Importer une image'),
              ),
              PokeMapButton(
                key: const Key('smart-tiles-choose-project-image'),
                onPressed: isBusy ? null : onChooseProjectImage,
                variant: PokeMapButtonVariant.secondary,
                leading:
                    const Icon(CupertinoIcons.photo_on_rectangle, size: 15),
                child: const Text('Choisir dans le projet'),
              ),
            ],
          ),
        ],
        if (selectedChoice == SmartTileStudioSourceChoice.registeredAtlas) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: PokeMapButton(
              key: const Key('smart-tiles-choose-registered-atlas'),
              onPressed: isBusy ? null : onChooseRegisteredAtlas,
              variant: PokeMapButtonVariant.secondary,
              leading: const Icon(CupertinoIcons.square_grid_3x2, size: 15),
              child: const Text('Choisir un atlas'),
            ),
          ),
        ],
        if (selectedSource != null) ...[
          const SizedBox(height: 12),
          selectedSource!,
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          PokeMapBadge(
            key: const Key('smart-tiles-source-error'),
            label: errorMessage!,
            variant: PokeMapBadgeVariant.warning,
          ),
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-next-step'),
            onPressed: canContinue ? onContinue : null,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: const Text('Détecter la grille'),
          ),
        ),
      ],
    );
  }
}
