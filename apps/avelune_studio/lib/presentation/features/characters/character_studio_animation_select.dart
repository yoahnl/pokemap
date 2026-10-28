import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_select.dart';
import 'character_studio_controller.dart';

class CharacterStudioAnimationSelect extends StatelessWidget {
  const CharacterStudioAnimationSelect({super.key, required this.controller});

  final CharacterStudioController controller;

  static const labels = {
    CharacterAnimationState.idle: 'Repos',
    CharacterAnimationState.walk: 'Marche',
    CharacterAnimationState.run: 'Course',
    CharacterAnimationState.climb: 'Échelle',
    CharacterAnimationState.bicycleIdle: 'Vélo au repos',
    CharacterAnimationState.bicycle: 'Vélo',
    CharacterAnimationState.surfIdle: 'Surf au repos',
    CharacterAnimationState.surf: 'Surf en déplacement',
    CharacterAnimationState.surfEnter: 'Entrée dans l’eau',
    CharacterAnimationState.surfExit: 'Sortie de l’eau',
  };

  @override
  Widget build(BuildContext context) => StudioSelect(
    label: 'Animation du personnage',
    value: controller.animationState.name,
    options: {for (final entry in labels.entries) entry.key.name: entry.value},
    onChanged: (value) => controller.setAnimationState(
      CharacterAnimationState.values.byName(value),
    ),
  );
}
