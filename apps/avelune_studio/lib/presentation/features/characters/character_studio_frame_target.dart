import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/characters/application/character_studio_draft.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_studio_controller.dart';
import 'character_studio_frame_thumbnail.dart';

class CharacterStudioFrameTarget extends StatelessWidget {
  const CharacterStudioFrameTarget({
    super.key,
    required this.direction,
    required this.index,
    required this.draft,
    required this.controller,
    required this.visuals,
    required this.pickedSource,
  });

  final EntityFacing direction;
  final int index;
  final CharacterStudioDraft draft;
  final CharacterStudioController controller;
  final MapWorkspaceVisuals visuals;
  final TilesetSourceRect? pickedSource;

  @override
  Widget build(BuildContext context) {
    final key = (controller.animationState, direction);
    final frames = draft.framesFor(key);
    final frame = index < frames.length ? frames[index] : null;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: DragTarget<TilesetSourceRect>(
        onAcceptWithDetails: (details) =>
            controller.assign(direction, index, details.data),
        builder: (context, candidates, rejected) => Material(
          color: candidates.isNotEmpty || pickedSource != null && frame == null
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Tooltip(
            message: frame == null
                ? 'Déposer ou choisir une pose'
                : 'Maintenir pour retirer cette pose',
            child: InkWell(
              key: ValueKey('character-slot-${direction.name}-$index'),
              onTap: pickedSource == null
                  ? null
                  : () => controller.assign(direction, index, pickedSource!),
              onLongPress: frame == null
                  ? null
                  : () => controller.clear(direction, index),
              child: StudioAssetPreview(
                child: frame == null
                    ? const Icon(Icons.add_photo_alternate_outlined)
                    : characterStudioFrameThumbnail(
                        visuals: visuals,
                        character: draft.previewCharacter,
                        frame: frame,
                        sourceAssetId: draft.sourceAssetIdFor(key),
                        direction: direction,
                        state: controller.animationState,
                        size: 78,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
