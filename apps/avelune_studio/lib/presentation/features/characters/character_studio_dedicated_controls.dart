import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/characters/application/character_studio_draft.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_studio_animation_actions.dart';
import 'character_studio_controller.dart';
import 'character_studio_frame_thumbnail.dart';

class CharacterStudioDedicatedControls extends StatelessWidget {
  const CharacterStudioDedicatedControls({
    super.key,
    required this.draft,
    required this.controller,
    required this.visuals,
  });

  final CharacterStudioDraft draft;
  final CharacterStudioController controller;
  final MapWorkspaceVisuals visuals;

  @override
  Widget build(BuildContext context) {
    final direction = controller.previewDirection;
    final key = (controller.animationState, direction);
    final sourceAssetId = draft.sourceAssetIdFor(key);
    if (sourceAssetId == null) return const SizedBox.shrink();
    final frames = draft.framesFor(key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Poses de l’image dédiée · ${_directionName(direction)}'),
        const SizedBox(height: 4),
        SizedBox(
          height: 102,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: frames.length,
            itemBuilder: (context, index) {
              final frame = frames[index];
              if (frame == null) return const SizedBox.shrink();
              final durations = {
                100,
                150,
                200,
                300,
                500,
                frame.durationMs,
              }.toList()..sort();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 62,
                      height: 80,
                      child: StudioAssetPreview(
                        child: characterStudioFrameThumbnail(
                          visuals: visuals,
                          character: draft.previewCharacter,
                          frame: frame,
                          sourceAssetId: sourceAssetId,
                          direction: direction,
                          state: controller.animationState,
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    DropdownButton<int>(
                      value: frame.durationMs,
                      items: [
                        for (final duration in durations)
                          DropdownMenuItem(
                            value: duration,
                            child: Text('$duration ms'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          controller.setFrameDuration(direction, index, value);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _directionName(EntityFacing direction) => switch (direction) {
    EntityFacing.south => 'Bas',
    EntityFacing.west => 'Gauche',
    EntityFacing.east => 'Droite',
    EntityFacing.north => 'Haut',
  };
}
