import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

abstract interface class CharacterWorkspaceVisuals {
  Widget characterThumbnail(
    ProjectCharacterEntry character, {
    double size = 48,
    EntityFacing facing = EntityFacing.south,
  });
  void setCharacterBrush(ProjectCharacterEntry? character);
}
