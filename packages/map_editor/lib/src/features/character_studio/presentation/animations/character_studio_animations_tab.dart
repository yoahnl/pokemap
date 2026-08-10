import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_animation_matrix_model.dart';
import 'animation_matrix.dart';

class CharacterStudioAnimationsTab extends StatefulWidget {
  const CharacterStudioAnimationsTab({
    super.key,
    required this.project,
    required this.character,
    required this.onManageDefinitions,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final VoidCallback onManageDefinitions;

  @override
  State<CharacterStudioAnimationsTab> createState() =>
      _CharacterStudioAnimationsTabState();
}

class _CharacterStudioAnimationsTabState
    extends State<CharacterStudioAnimationsTab> {
  CharacterAnimationSlotKey? _selectedKey;

  @override
  Widget build(BuildContext context) {
    final model = CharacterAnimationMatrixModel.build(
      project: widget.project,
      character: widget.character,
    );
    final slots = model.slotsFor(CharacterAnimationMatrixFilter.all);
    final selectedKey = slots.any((slot) => slot.key == _selectedKey)
        ? _selectedKey
        : slots.firstOrNull?.key;

    return Padding(
      key: const ValueKey<String>('character-studio-animations-tab'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animations de ${widget.character.name}',
                      style: TextStyle(
                        color: context.pokeMapColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Base requise · marche, course et animations custom optionnelles',
                      style: TextStyle(
                        color: context.pokeMapColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PokeMapButton(
                key: const ValueKey<String>(
                  'character-studio-manage-animation-definitions',
                ),
                onPressed: widget.onManageDefinitions,
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(CupertinoIcons.slider_horizontal_3),
                child: const Text('Animations globales'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: AnimationMatrix(
              model: model,
              selectedKey: selectedKey,
              onSelected: (key) => setState(() => _selectedKey = key),
            ),
          ),
        ],
      ),
    );
  }
}
