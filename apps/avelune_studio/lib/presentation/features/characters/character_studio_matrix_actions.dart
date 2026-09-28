import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/characters/application/character_studio_draft.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'character_studio_controller.dart';
import 'character_studio_grid_dialog.dart';

class CharacterStudioMatrixActions extends StatelessWidget {
  const CharacterStudioMatrixActions({
    super.key,
    required this.project,
    required this.character,
    required this.source,
    required this.draft,
    required this.controller,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final ProjectRegularAtlasTilesetSource source;
  final CharacterStudioDraft draft;
  final CharacterStudioController controller;

  @override
  Widget build(BuildContext context) {
    final assigned = EntityFacing.values.fold<int>(0, (total, direction) {
      final frames = draft.framesFor((controller.animationState, direction));
      return total + frames.take(3).whereType<CharacterAnimationFrame>().length;
    });
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StudioButton(
          label: 'Découper automatiquement',
          icon: Icons.grid_on,
          secondary: true,
          onPressed: () => controller.assignClassicSheet(source),
        ),
        StudioButton(
          label: 'Ajuster la grille',
          icon: Icons.grid_view,
          secondary: true,
          onPressed: () async {
            final size = await showCharacterStudioGridDialog(
              context,
              source: source,
              tileWidth: project.settings.tileWidth,
              tileHeight: project.settings.tileHeight,
              currentWidth: draft.frameWidth,
              currentHeight: draft.frameHeight,
            );
            if (size != null && context.mounted) {
              controller.setFrameSize(size.$1, size.$2);
            }
          },
        ),
        Text('$assigned / 12 poses renseignées'),
        Text(
          'Source : ${project.tilesets.where((entry) => entry.id == character.tilesetId).firstOrNull?.name ?? character.tilesetId}',
        ),
      ],
    );
  }
}
