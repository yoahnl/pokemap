import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/character_animation_matrix_model.dart';
import '../../application/character_animation_source_slicing.dart';
import '../../application/character_studio_media_resolver.dart';
import 'character_animation_frame_timeline.dart';

class CharacterAnimationSourceEditor extends StatefulWidget {
  const CharacterAnimationSourceEditor({
    super.key,
    required this.slot,
    required this.projectRootPath,
    required this.projectRevision,
    required this.mediaResolver,
    required this.enabled,
    required this.onImportSource,
    required this.onFramesChanged,
  });

  final CharacterAnimationMatrixSlot slot;
  final String projectRootPath;
  final String projectRevision;
  final CharacterStudioMediaResolverContract mediaResolver;
  final bool enabled;
  final Future<void> Function() onImportSource;
  final Future<void> Function(List<CharacterAnimationFrame> frames)
  onFramesChanged;

  @override
  State<CharacterAnimationSourceEditor> createState() =>
      _CharacterAnimationSourceEditorState();
}

class _CharacterAnimationSourceEditorState
    extends State<CharacterAnimationSourceEditor> {
  final TextEditingController _columnsController = TextEditingController(
    text: '1',
  );
  final TextEditingController _rowsController = TextEditingController(
    text: '1',
  );
  final TextEditingController _durationController = TextEditingController(
    text: '150',
  );
  Future<Uint8List>? _source;
  String? _sourceIdentity;
  String? _gridError;

  @override
  void initState() {
    super.initState();
    _refreshSource();
  }

  @override
  void didUpdateWidget(covariant CharacterAnimationSourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshSource();
  }

  @override
  void dispose() {
    _columnsController.dispose();
    _rowsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    if (source == null) {
      return PokeMapPanel(
        key: const ValueKey<String>('animation-source-editor-empty'),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PokeMapEmptyState(
              title: 'Aucune source portable',
              description:
                  'Importez un PNG pour découper et éditer ce slot précisément.',
              icon: Icon(CupertinoIcons.photo_on_rectangle),
              compact: true,
            ),
            const SizedBox(height: 14),
            PokeMapButton(
              key: const ValueKey<String>('animation-source-import'),
              onPressed: widget.enabled ? widget.onImportSource : null,
              leading: const Icon(CupertinoIcons.folder_open),
              child: const Text('Choisir une source PNG'),
            ),
          ],
        ),
      );
    }
    return FutureBuilder<Uint8List>(
      future: source,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokeMapPanel(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return PokeMapPanel(
            key: const ValueKey<String>('animation-source-editor-error'),
            child: PokeMapEmptyState(
              title: 'Source indisponible',
              description:
                  'Le PNG portable ne peut pas être chargé. ${snapshot.error ?? ''}',
              icon: const Icon(CupertinoIcons.exclamationmark_triangle),
              action: PokeMapButton(
                onPressed: widget.enabled ? widget.onImportSource : null,
                child: const Text('Remplacer la source'),
              ),
            ),
          );
        }
        try {
          final dimensions = CharacterAnimationSourceDimensions.fromPng(
            snapshot.data!,
          );
          return _content(context, snapshot.data!, dimensions);
        } on CharacterAnimationSlicingException catch (error) {
          return PokeMapPanel(
            child: PokeMapEmptyState(
              title: 'Source PNG invalide',
              description: error.message,
              icon: const Icon(CupertinoIcons.exclamationmark_triangle),
              action: PokeMapButton(
                onPressed: widget.enabled ? widget.onImportSource : null,
                child: const Text('Remplacer la source'),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _content(
    BuildContext context,
    Uint8List bytes,
    CharacterAnimationSourceDimensions dimensions,
  ) {
    return SingleChildScrollView(
      key: const ValueKey<String>('animation-source-editor'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapPanel(
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
                            'Source et découpe',
                            style: TextStyle(
                              color: context.pokeMapColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${dimensions.width} × ${dimensions.height} px · PNG',
                            key: const ValueKey<String>(
                              'animation-source-dimensions',
                            ),
                            style: TextStyle(
                              color: context.pokeMapColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PokeMapButton(
                      key: const ValueKey<String>('animation-source-replace'),
                      onPressed: widget.enabled ? widget.onImportSource : null,
                      variant: PokeMapButtonVariant.secondary,
                      leading: const Icon(CupertinoIcons.arrow_2_circlepath),
                      child: const Text('Remplacer'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.pokeMapColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: context.pokeMapColors.borderSubtle,
                    ),
                  ),
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    gaplessPlayback: true,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PokeMapTextField(
                        label: 'Colonnes',
                        fieldKey: const ValueKey<String>(
                          'animation-grid-columns',
                        ),
                        controller: _columnsController,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapTextField(
                        label: 'Lignes',
                        fieldKey: const ValueKey<String>('animation-grid-rows'),
                        controller: _rowsController,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PokeMapTextField(
                        label: 'Durée (ms)',
                        fieldKey: const ValueKey<String>(
                          'animation-grid-duration',
                        ),
                        controller: _durationController,
                        enabled: widget.enabled,
                        keyboardType: TextInputType.number,
                        inputFormatters: _digitsOnly,
                      ),
                    ),
                  ],
                ),
                if (_gridError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _gridError!,
                    key: const ValueKey<String>('animation-grid-error'),
                    style: TextStyle(
                      color: context.pokeMapColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: PokeMapButton(
                    key: const ValueKey<String>('animation-grid-apply'),
                    onPressed: widget.enabled
                        ? () => _applyGrid(dimensions)
                        : null,
                    leading: const Icon(CupertinoIcons.square_grid_3x2),
                    child: const Text('Appliquer la grille'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CharacterAnimationFrameTimeline(
            frames: widget.slot.frames,
            dimensions: dimensions,
            enabled: widget.enabled,
            onChanged: (frames) => widget.onFramesChanged(frames),
          ),
        ],
      ),
    );
  }

  Future<void> _applyGrid(CharacterAnimationSourceDimensions dimensions) async {
    try {
      final frames = CharacterAnimationSourceSlicing.grid(
        dimensions: dimensions,
        columns: int.tryParse(_columnsController.text) ?? 0,
        rows: int.tryParse(_rowsController.text) ?? 0,
        durationMs: int.tryParse(_durationController.text) ?? 0,
      );
      setState(() => _gridError = null);
      await widget.onFramesChanged(frames);
    } on CharacterAnimationSlicingException catch (error) {
      setState(() => _gridError = error.message);
    }
  }

  void _refreshSource() {
    final assetId = widget.slot.sourceAssetId;
    final identity = assetId == null
        ? null
        : '${widget.projectRootPath}|$assetId|${widget.projectRevision}';
    if (identity == _sourceIdentity) return;
    _sourceIdentity = identity;
    _source = assetId == null
        ? null
        : widget.mediaResolver.resolve(
            CharacterStudioMediaRequest(
              projectRootPath: widget.projectRootPath,
              assetId: assetId,
              projectRevision: widget.projectRevision,
            ),
          );
  }
}

final List<TextInputFormatter> _digitsOnly = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
];
