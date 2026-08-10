import 'package:map_core/map_core.dart';

import '../../application/character_custom_animation_runtime_controller.dart';
import 'overworld_actor_component.dart';

final class FlameCharacterCustomAnimationRuntimeActor
    implements CharacterCustomAnimationRuntimeActor {
  const FlameCharacterCustomAnimationRuntimeActor({
    required this.actorId,
    required this.component,
  });

  @override
  final String actorId;

  final OverworldActorComponent component;

  @override
  ProjectCharacterEntry get character => component.character;

  @override
  EntityFacing get facing => component.facing;

  @override
  bool canPlayCustomAnimation(CharacterCustomAnimationClip clip) =>
      component.canPlayCustomAnimation(clip);

  @override
  void playCustomAnimation(CharacterCustomAnimationClip clip) =>
      component.playCustomAnimation(clip);

  @override
  void restoreBase(EntityFacing facing) => component.restoreBase(facing);
}
