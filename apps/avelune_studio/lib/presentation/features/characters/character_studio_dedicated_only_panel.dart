import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/characters/application/character_studio_draft.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_studio_controller.dart';
import 'character_studio_dedicated_controls.dart';

class CharacterStudioDedicatedOnlyPanel extends StatelessWidget {
  const CharacterStudioDedicatedOnlyPanel({
    super.key,
    required this.hasAtlas,
    required this.draft,
    required this.controller,
    required this.visuals,
    required this.onImport,
  });

  final bool hasAtlas;
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
        hasAtlas
            ? 'La planche de ce personnage ne peut pas être lue. Ses animations existantes sont conservées.'
            : 'Ce personnage utilise des images dédiées. Choisissez le mouvement et la direction à modifier.',
      ),
      Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<CharacterAnimationState>(
            value: controller.animationState,
            items: const [
              DropdownMenuItem(
                value: CharacterAnimationState.walk,
                child: Text('Marche'),
              ),
              DropdownMenuItem(
                value: CharacterAnimationState.idle,
                child: Text('Repos'),
              ),
              DropdownMenuItem(
                value: CharacterAnimationState.run,
                child: Text('Course'),
              ),
            ],
            onChanged: (value) {
              if (value != null) controller.setAnimationState(value);
            },
          ),
          DropdownButton<EntityFacing>(
            value: controller.previewDirection,
            items: const [
              DropdownMenuItem(value: EntityFacing.south, child: Text('Bas')),
              DropdownMenuItem(value: EntityFacing.west, child: Text('Gauche')),
              DropdownMenuItem(value: EntityFacing.east, child: Text('Droite')),
              DropdownMenuItem(value: EntityFacing.north, child: Text('Haut')),
            ],
            onChanged: (value) {
              if (value != null) controller.setPreviewDirection(value);
            },
          ),
        ],
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
