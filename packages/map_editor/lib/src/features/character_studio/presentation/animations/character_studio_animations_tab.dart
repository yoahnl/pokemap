import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_animation_matrix_model.dart';
import '../../application/character_studio_media_resolver.dart';
import 'animation_matrix.dart';
import 'character_animation_source_editor.dart';

class CharacterStudioAnimationsTab extends StatefulWidget {
  const CharacterStudioAnimationsTab({
    super.key,
    required this.project,
    required this.character,
    required this.projectRootPath,
    required this.projectRevision,
    required this.mediaResolver,
    required this.isSaving,
    required this.onManageDefinitions,
    required this.onImportSource,
    required this.onSaveClip,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final String projectRootPath;
  final String projectRevision;
  final CharacterStudioMediaResolverContract mediaResolver;
  final bool isSaving;
  final VoidCallback onManageDefinitions;
  final Future<bool> Function(CharacterAnimationMatrixSlot slot) onImportSource;
  final Future<bool> Function(
    CharacterAnimationMatrixSlot slot,
    List<CharacterAnimationFrame> frames,
    bool loop,
  )
  onSaveClip;

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
    final selectedSlot = selectedKey == null ? null : model.slot(selectedKey);

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final matrix = AnimationMatrix(
                  model: model,
                  selectedKey: selectedKey,
                  onSelected: (key) => setState(() => _selectedKey = key),
                );
                final editor = selectedSlot == null
                    ? const PokeMapEmptyState(
                        title: 'Aucun slot sélectionné',
                        description:
                            'Sélectionnez une direction dans la matrice.',
                      )
                    : CharacterAnimationSourceEditor(
                        key: ValueKey<String>(
                          'animation-source-${selectedSlot.key.stableId}',
                        ),
                        slot: selectedSlot,
                        projectRootPath: widget.projectRootPath,
                        projectRevision: widget.projectRevision,
                        mediaResolver: widget.mediaResolver,
                        enabled: !widget.isSaving,
                        onImportSource: () async {
                          await widget.onImportSource(selectedSlot);
                        },
                        onFramesChanged: (frames) async {
                          await widget.onSaveClip(
                            selectedSlot,
                            frames,
                            selectedSlot.loop,
                          );
                        },
                        onLoopChanged: (loop) async {
                          await widget.onSaveClip(
                            selectedSlot,
                            selectedSlot.frames,
                            loop,
                          );
                        },
                      );
                if (constraints.maxWidth >= 1080) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 11, child: matrix),
                      const SizedBox(width: 12),
                      Expanded(flex: 9, child: editor),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 11, child: matrix),
                    const SizedBox(height: 12),
                    Expanded(flex: 9, child: editor),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
