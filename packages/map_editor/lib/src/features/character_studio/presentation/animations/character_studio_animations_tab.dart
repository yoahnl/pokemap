import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_animation_matrix_model.dart';
import '../../application/character_studio_media_resolver.dart';
import '../preview/character_studio_sprite_thumbnail.dart';
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
    this.onCreateDefinition,
    this.legacySourceLoader,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final String projectRootPath;
  final String projectRevision;
  final CharacterStudioMediaResolverContract mediaResolver;
  final bool isSaving;
  final VoidCallback onManageDefinitions;
  final VoidCallback? onCreateDefinition;
  final Future<Uint8List> Function(String path)? legacySourceLoader;
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
    final selectedRow = selectedKey == null
        ? null
        : model.rows
              .where((row) => row.slots.any((slot) => slot.key == selectedKey))
              .firstOrNull;

    return Padding(
      key: const ValueKey<String>('character-studio-animations-tab'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final heading = Column(
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
              );
              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'character-studio-create-custom-animation',
                    ),
                    onPressed:
                        widget.onCreateDefinition ?? widget.onManageDefinitions,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.add),
                    child: const Text('Animation custom'),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'character-studio-manage-animation-definitions',
                    ),
                    onPressed: widget.onManageDefinitions,
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.slider_horizontal_3),
                    child: const Text('Gérer le catalogue'),
                  ),
                ],
              );
              if (constraints.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [heading, const SizedBox(height: 8), actions],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final matrix = AnimationMatrix(
                  model: model,
                  selectedKey: selectedKey,
                  thumbnailBuilder: _animationThumbnail,
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
                        animationLabel: selectedRow?.displayName,
                        legacySourcePath: _legacySourcePath(selectedSlot),
                        legacyFrameWidth:
                            widget.character.frameWidth *
                            widget.project.settings.tileWidth,
                        legacyFrameHeight:
                            widget.character.frameHeight *
                            widget.project.settings.tileHeight,
                        legacySourceLoader: widget.legacySourceLoader,
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

  String? _legacySourcePath(CharacterAnimationMatrixSlot slot) {
    if (slot.key.kind != CharacterAnimationDefinitionKind.system ||
        slot.sourceAssetId?.trim().isNotEmpty == true ||
        slot.frames.isEmpty) {
      return null;
    }
    final root = widget.projectRootPath.trim();
    if (root.isEmpty) return null;
    final tileset = widget.project.tilesets
        .where((entry) => entry.id == widget.character.tilesetId)
        .firstOrNull;
    if (tileset == null) return null;
    return p.normalize(p.join(root, tileset.relativePath));
  }

  Widget? _animationThumbnail(CharacterAnimationMatrixSlot slot) {
    if (slot.frames.isEmpty) return null;
    final assetId = slot.sourceAssetId?.trim();
    final hasPortableSource = assetId != null && assetId.isNotEmpty;
    final root = widget.projectRootPath.trim();
    final legacyPath = hasPortableSource ? null : _legacySourcePath(slot);
    if (!hasPortableSource && legacyPath == null) return null;
    final mediaRequest = hasPortableSource && root.isNotEmpty
        ? CharacterStudioMediaRequest(
            projectRootPath: root,
            assetId: assetId,
            projectRevision: widget.projectRevision,
          )
        : null;
    if (hasPortableSource && mediaRequest == null) return null;
    return CharacterStudioSpriteThumbnail(
      key: ValueKey<String>('animation-slot-thumbnail-${slot.key.stableId}'),
      semanticLabel: 'Aperçu de ${slot.label}',
      imagePath: legacyPath,
      mediaResolver: mediaRequest == null ? null : widget.mediaResolver,
      mediaRequest: mediaRequest,
      source: slot.frames.first.source,
      framePixelWidth:
          widget.character.frameWidth * widget.project.settings.tileWidth,
      framePixelHeight:
          widget.character.frameHeight * widget.project.settings.tileHeight,
      usesPixelCoordinates: hasPortableSource,
      size: 48,
    );
  }
}
