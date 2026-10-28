import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/characters/application/character_studio_draft.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_studio_controller.dart';
import 'character_studio_animation_select.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'character_studio_dedicated_controls.dart';
import 'character_workspace_visuals.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';

class CharacterStudioDedicatedOnlyPanel extends StatelessWidget {
  const CharacterStudioDedicatedOnlyPanel({
    super.key,
    required this.hasAtlas,
    required this.draft,
    required this.controller,
    required this.visuals,
    required this.onImport,
    this.elapsedMs = 0,
  });

  final bool hasAtlas;
  final int elapsedMs;
  final CharacterStudioDraft draft;
  final CharacterStudioController controller;
  final MapWorkspaceVisuals visuals;
  final void Function(CharacterAnimationState, EntityFacing) onImport;

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Images dédiées',
    compact: true,
    children: [
      Text(
        controller.animationState == CharacterAnimationState.bicycle ||
                controller.animationState == CharacterAnimationState.bicycleIdle
            ? 'Le vélo demande huit animations dédiées : repos et déplacement dans quatre directions. Importez une planche de quatre poses sur quatre directions.'
            : hasAtlas
            ? 'La planche de ce personnage ne peut pas être lue. Ses animations existantes sont conservées.'
            : 'Ce personnage utilise des images dédiées. Choisissez le mouvement et la direction à modifier.',
      ),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: CharacterStudioAnimationSelect(controller: controller),
          ),
          SizedBox(
            width: 180,
            child: StudioSelect(
              label: 'Direction de l’aperçu',
              value: controller.previewDirection.name,
              options: const {
                'south': 'Bas',
                'west': 'Gauche',
                'east': 'Droite',
                'north': 'Haut',
              },
              onChanged: (value) => controller.setPreviewDirection(
                EntityFacing.values.byName(value),
              ),
            ),
          ),
        ],
      ),
      SizedBox(
        height: 160,
        child: StudioAssetPreview(
          child:
              visuals is CharacterWorkspaceVisuals &&
                  draft.previewCharacter.animations.any(
                    (animation) =>
                        animation.state == controller.animationState &&
                        animation.direction == controller.previewDirection &&
                        animation.frames.isNotEmpty,
                  )
              ? (visuals as CharacterWorkspaceVisuals)
                    .characterAnimationThumbnail(
                      draft.previewCharacter,
                      size: 140,
                      facing: controller.previewDirection,
                      state: controller.animationState,
                      elapsedMs: (elapsedMs * controller.playbackSpeed).round(),
                    )
              : const Text('Aucune pose pour cette direction'),
        ),
      ),
      CharacterStudioDedicatedControls(
        draft: draft,
        controller: controller,
        visuals: visuals,
      ),
      StudioButton(
        label: 'Importer une animation dédiée',
        icon: Icons.upload_file_outlined,
        secondary: true,
        onPressed: () =>
            onImport(controller.animationState, controller.previewDirection),
      ),
    ],
  );
}
