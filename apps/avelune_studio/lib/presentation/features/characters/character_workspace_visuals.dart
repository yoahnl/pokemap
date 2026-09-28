import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

abstract interface class CharacterWorkspaceVisuals implements Listenable {
  ProjectRegularAtlasTilesetSource? characterAtlas(
    ProjectCharacterEntry character,
  );
  Widget characterThumbnail(
    ProjectCharacterEntry character, {
    double size = 48,
    EntityFacing facing = EntityFacing.south,
  });
  Widget characterAnimationThumbnail(
    ProjectCharacterEntry character, {
    required double size,
    required EntityFacing facing,
    required CharacterAnimationState state,
    required int elapsedMs,
  });
  void setCharacterBrush(ProjectCharacterEntry? character);
}
