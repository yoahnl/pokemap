import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_workspace_visuals.dart';

Widget characterStudioFrameThumbnail({
  required MapWorkspaceVisuals visuals,
  required ProjectCharacterEntry character,
  required CharacterAnimationFrame frame,
  required String? sourceAssetId,
  required EntityFacing direction,
  required CharacterAnimationState state,
  required double size,
}) {
  if (visuals is! CharacterWorkspaceVisuals) {
    return const Icon(Icons.image_outlined);
  }
  final preview = character.copyWith(
    animations: [
      CharacterAnimation(
        state: state,
        direction: direction,
        sourceAssetId: sourceAssetId,
        frames: [frame],
      ),
    ],
  );
  return (visuals as CharacterWorkspaceVisuals).characterAnimationThumbnail(
    preview,
    size: size,
    facing: direction,
    state: state,
    elapsedMs: 1,
  );
}
